// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../types.sol";
import "../libs/Bytes.sol";

contract YCParsers is YieldchainTypes {
    // =========
    //    LIBS
    // =========
    using BytesLib for bytes[];

    // ================
    //    CONSTANTS
    // ================
    bytes1 internal constant STATIC_VAR_FLAG = 0x00;
    bytes1 internal constant DYNAMIC_VAR_FLAG = 0x01;
    bytes1 internal constant FIXED_LENGTH_COMMANDS_ARR_FLAG = 0x02;
    bytes1 internal constant DYNAMIC_LENGTH_COMMANDS_ARR_FLAG = 0x03;
    bytes1 internal constant STATICCALL_COMMAND_FLAG = 0x04;
    bytes1 internal constant CALL_COMMAND_FLAG = 0x05;
    bytes1 internal constant DELEGATECALL_COMMAND_FLAG = 0x06;

    // ================
    //    FUNCTIONS
    // ================
    /**
     * @notice
     * The main high-level function used to run encoded FunctionCall's, which are stored on the YCStep's.
     * It uses other internal functions to interpret it and it's arguments, build the calldata & call it accordingly.
     * @param encodedFunctionCall - The encoded FunctionCall struct
     * @return returnVal returned by the low-level function calls
     */
    function _runFunction(
        bytes memory encodedFunctionCall
    ) public returns (bytes memory returnVal) {
        /**
         * Seperate the FunctionCall command body from the typeflags
         */
        (bytes memory commandBody, bytes1 typeflag, ) = _separateCommand(
            encodedFunctionCall
        );

        /**
         * Assert that the typeflag must be either 0x04, 0x05, or 0x06
         */
        require(
            typeflag < 0x07 && typeflag > 0x03,
            "ycVM: Invalid Function Typeflag"
        );

        /**
         * Decode the FunctionCall command
         */
        FunctionCall memory decodedFunctionCall = abi.decode(
            commandBody,
            (FunctionCall)
        );

        /**
         * Execute it & assign to the return value
         */
        returnVal = _execFunctionCall(decodedFunctionCall, typeflag);
    }

    /**
     * _execFunctionCall()
     * Accepts a decoded FunctionCall struct, and a typeflag. Builds the calldata,
     * calls the function on the target address, and returns the return value.
     * @param func - The FunctionCall struct which represents the call to make
     * @param typeflag - The typeflag specifying the type of call STATICCALL, CALL, OR DELEGATECALL
     * @return returnVal - The return value of the function call
     */
    function _execFunctionCall(
        FunctionCall memory func,
        bytes1 typeflag
    ) public returns (bytes memory returnVal) {
        /**
         * First, build the calldata for the function & it's args
         */
        bytes memory callData = _buildCalldata(func);

        /**
         * Switch case for the function call type
         */

        // STATICALL
        if (typeflag == STATICCALL_COMMAND_FLAG) {
            (, returnVal) = func.target_address.staticcall(callData);
            return returnVal;
        }
        // CALL
        if (typeflag == CALL_COMMAND_FLAG) {
            (, returnVal) = func.target_address.call(callData);
            return returnVal;
        }
        // DELEGATECALL
        if (typeflag == DELEGATECALL_COMMAND_FLAG) {
            (, returnVal) = func.target_address.delegatecall(callData);
            return returnVal;
        }
    }

    /**
     * _buildCalldata()
     * Builds a complete calldata from a FunctionCall struct
     * @param _func - The FunctionCall struct which represents the function we shall construct a calldata for
     * @return constructedCalldata - A complete constructed calldata which can be used to make the desired call
     */
    function _buildCalldata(
        FunctionCall memory _func
    ) public returns (bytes memory constructedCalldata) {
        /**
         * Get the 4 bytes keccak256 hash selector of the signature (used at the end to concat w the calldata body)
         */
        bytes4 selector = bytes4(keccak256(bytes(_func.signature)));

        /**
         * @notice
         * We call the interpretCommandsAndEncodeChunck() function with the function's array of arguments
         * (which are YC commands), which will:
         *
         * 1) Interpret each argument using the getCommandValue() function
         * 2) Encode all of them as an ABI-compatible chunck, which can be used as the calldata
         *
         * And assign to the constructed calldata the concatinated selector + encoded chunck we recieve
         */
        constructedCalldata = bytes.concat(
            selector,
            interpretCommandsAndEncodeChunck(_func.args)
        );
    }

    /**
     * _getCommandValue()
     * Get a command/argument's actual value, by parsing it, and potentially
     * using it's return value (if a function call)
     * @param command - the full encoded command, including typeflags
     * @return interpretedValue - The interpreted underlying value of the argument
     * @return typeflag - The typeflag of the underlying value
     */
    function _getCommandValue(
        bytes memory command
    ) public returns (bytes memory interpretedValue, bytes1 typeflag) {
        // First, seperate the command/variable from it's typeflag & return var typeflag
        bytes1 retTypeFlag;
        (interpretedValue, typeflag, retTypeFlag) = _separateCommand(command);

        /**
         * Assert that the typeflag must be ranging from 0x00 to
         */

        /**
         * If the typeflag is 0x00, it's a static variable and we just return it (simplest case)
         */
        if (typeflag == STATIC_VAR_FLAG) return (interpretedValue, typeflag);

        /**
         * If the typeflag is 0x01, it's a dynamic-type variable (string, array...), we parse and return it
         */
        if (typeflag == DYNAMIC_VAR_FLAG) {
            interpretedValue = _parseDynamicVar(interpretedValue);
            return (interpretedValue, typeflag);
        }

        /**
         * If the typeflag is 0x02, it's a fixed-length array of YC commands - parse and return it,
         * along with a 0x00 fixed flag.
         * // TODO: I know that it comes with a pointer, check how it's encoded in larger chuncks,
         * because if so then it has to be marked as dynamic, but in that case there's no length specified,
         * so would have to see if it would work well.
         */
        if (typeflag == FIXED_LENGTH_COMMANDS_ARR_FLAG) {
            return (
                parseFixedLengthCommandsArr(interpretedValue),
                STATIC_VAR_FLAG
            );
        }

        /**
         * If the typeflag is 0x03, it's a dynamic-length array of YC commands - parse and return it,
         * along with a 0x01 typeflag (indiicating dynamic variable)
         */
        if (typeflag == DYNAMIC_LENGTH_COMMANDS_ARR_FLAG) {
            return (
                parseDynamicCommandsArr(interpretedValue),
                DYNAMIC_VAR_FLAG
            );
        }

        /**
         * At this point, it can be either 0x04, 0x05, or 0x06.
         * All of those refer to some sort of a function call, which means the body is an encoded
         * FunctionCall struct.
         * we call the internal _execFunction() function with our command body & typeflag,
         * in order to execute this function and retreive it's return value.
         * We also assign to the typeflag the command's returnTypeFlag that we got when separating.
         */
        // Decode it first
        FunctionCall memory functionCallCommand = abi.decode(
            interpretedValue,
            (FunctionCall)
        );

        // Assign command body to the return value of execFunctionCall()
        interpretedValue = _execFunctionCall(functionCallCommand, typeflag);
        typeflag = retTypeFlag;
    }

    /**
     * _seperateCommand()
     * Takes in a full encoded ycCommand, returns it seperated with the type & return type flags
     * @param ycCommand - The full encoded ycCommand to separate
     * @return nakedCommand - the command without it's type flags
     * @return typeflag - the typeflag of the command
     * @return retTypeflag - the typeflag of the return value of the command
     */
    function _separateCommand(
        bytes memory ycCommand
    )
        public
        pure
        returns (bytes memory nakedCommand, bytes1 typeflag, bytes1 retTypeflag)
    {
        // Set the typeflag
        typeflag = ycCommand[0];

        // Set the return type flag
        retTypeflag = ycCommand[1];

        // The new desired length (length of ycCommand - 2 (the flags' length))
        uint256 newLen = ycCommand.length - 2;

        // Assign a new empty byte of that length to nakedCommand
        nakedCommand = new bytes(newLen);

        // Iterate over each byte in the ycCommand (minus the last 2) and assign them to the nakedCommand
        for (uint256 i = 0; i < newLen; i++) {
            nakedCommand[i] = ycCommand[i + 2];
        }
    }

    /**
     * _parseDynamicVar
     * @param _arg - The dynamic-length argument to parse
     * @return the parsed arg. So the dynamic-length argument minus it's ABI-prepended 32 byte offset pointer
     */
    function _parseDynamicVar(
        bytes memory _arg
    ) public pure returns (bytes memory) {
        // We create the new value, which is the length of the argument - 32 bytes
        // (to account for the offset pointer we are about to remove)
        bytes memory newVal = new bytes(_arg.length - 0x20);
        assembly {
            // Length of the arg
            let len := sub(mload(_arg), 0x20)

            // Require the argument to be a multiple of 32 bytes
            if mod(len, 0x20) {
                revert(0, 0)
            }

            // Length's multiple of 32
            let iters := div(len, 0x20)

            // Pointer - We use that in a base pointer so that we skip over it (and thus only copy the values)
            let ptr := mload(add(_arg, 0x20))

            // Base pointer for value - Base ptr + ptr pointing to value (first 32 bytes of the value)
            let baseptr := add(add(_arg, 0x20), ptr)

            // Base mstore ptr
            let basemstoreptr := add(newVal, 0x20)

            // Iterating over the variable, copying it's bytes to the new value - except the first 32 bytes (the mem pointer)
            for {
                let i := 0
            } lt(i, iters) {
                i := add(i, 1)
            } {
                // Current 32 bytes
                let currpart := mload(add(baseptr, mul(0x20, i)))

                // Paste them into the new value
                mstore(add(basemstoreptr, mul(0x20, i)), currpart)
            }
        }

        return newVal;
    }

    /**
     * parseFixedLengthCommandsArr
     * Parse a fixed-length array of YC commands
     * @param ycCommandsArr - An encoded fixed-length array which is made up of YC commands
     * @return interpretedArray - The array, but of the underlying values (using _getCommandValue() on each item),
     * without it's ABI-prepended 32 byte offset pointer
     */
    function parseFixedLengthCommandsArr(
        bytes memory ycCommandsArr
    ) public pure returns (bytes memory interpretedArray) {}

    /**
     * parseDynamicCommandsArr
     * @param ycCommandsArr - An encoded dynamic-length array of YC commands
     */
    function parseDynamicCommandsArr(
        bytes memory ycCommandsArr
    ) public returns (bytes memory interpretedArray) {
        /**
         * We begin by decoding the encoded array into a bytes[]
         */
        bytes[] memory decodedCommandsArray = abi.decode(
            ycCommandsArr,
            (bytes[])
        );

        /**
         * We iterate over each YC command in the array,
         * and call _getCommandValue() on it, then swap the command at the index
         * to the new interpreted underlying value.
         */
        for (uint256 i = 0; i < decodedCommandsArray.length; i++) {
            /**
             * Note that we discard the typeflag for each command as it is not needed in our case,
             * once the contents are interpreted, this array is supposed to be used as-is on the
             * end external contract.
             */
            (decodedCommandsArray[i], ) = _getCommandValue(
                decodedCommandsArray[i]
            );
        }

        interpretedArray = decodedCommandsArray.encodeBytesArray();
    }

    /**
     * @notice
     * interpretCommandsAndEncodeChunck
     * Accepts an array of YC commands - interprets each one of them, then encodes an ABI-compatible chunck of bytes,
     * corresponding of all of these arguments (account for static & dynamic variables)
     * @param ycCommands - an array of yc commands to interpret
     * @return interpretedEncodedChunck - A chunck of bytes which is an ABI-compatible encoded version
     * of all of the interpreted commands
     */
    function interpretCommandsAndEncodeChunck(
        bytes[] memory ycCommands
    ) public returns (bytes memory interpretedEncodedChunck) {
        /**
         * @notice
         * We keep track of all of the dynamic variables we have on the commands,
         * in order to encode them correctly.
         */

        /**
         * We begin by getting the amount of all dynamic variables,
         * in order to instantiate the array.
         *
         * Note that we are looking at the RETURN typeflag of the command at idx 1,
         * and we're doing it since a command may be flagged as some certain type in order to be parsed correctly,
         * but the end result we will be getting from the parsing iteration is different - for example, dynamic
         * commands arrays (dynamic-length arrays which are made up of YC commands) are flagged as 0x03 in order to
         * be parsed differently, yet at the end we're supposed to get a reguler dynamic flag from the parsing
         * (Since that is what the end contract expects - a dynamic-length variable which is some array).
         *
         * This means that for a dynamic variable to be flagged correctly, it's return type need to be flagged
         * also as dynamic (0x01)
         */
        uint256 dynamicVarsAmt = 0;
        for (uint256 i = 0; i < ycCommands.length; i++) {
            if (ycCommands[i][1] == DYNAMIC_VAR_FLAG) ++dynamicVarsAmt;
        }

        // The actual array of dynamic-length variables
        bytes[] memory dynamicVars = new bytes[](dynamicVarsAmt);

        // Their indexes within the chunck
        uint256[] memory dynamicVarsIndexes = new uint256[](dynamicVarsAmt);

        // We save a uint256 variable to keep track of the current available index
        // within the array of dynamic variables. This is because we cannot push into
        // in-memory arrays in Solidity
        uint256 freeDynVarIndexPtr = 0;

        /**
         * Iterate over each one of the ycCommands,
         * call the _getCommandValue() function on them, which returns both the value and their typeflag.
         */
        for (uint256 i = 0; i < ycCommands.length; i++) {
            /**
             * Get the value of the argument and it's underlying typeflag
             */
            (bytes memory argumentValue, bytes1 typeflag) = _getCommandValue(
                ycCommands[i]
            );

            /**
             * Assert that the typeflag must either be a static or a dynamic variable.
             * At this point, the argument should have been interpreted up until the point where
             * it's either dynamic or static length variable.
             */
            require(typeflag < 0x02, "typeflag must < 2 after parsing");

            /**
             * If it's a static variable, we simply concat the existing chunck with it
             */
            if (typeflag == 0x00)
                interpretedEncodedChunck = bytes.concat(
                    interpretedEncodedChunck,
                    argumentValue
                );

                /**
                 * Otherwise, we process it as a dynamic variable
                 */
            else {
                /**
                 * We save the current chunck length as the index of the 32 byte pointer of this dynamic variable,
                 * in our array of dynamicVarIndexes
                 */
                dynamicVarsIndexes[
                    freeDynVarIndexPtr
                ] = interpretedEncodedChunck.length;

                /**
                 * We then append an empty 32 byte placeholder at that index on the chunck
                 * ("mocking" what would have been the offset pointer)
                 */
                interpretedEncodedChunck = bytes.concat(
                    interpretedEncodedChunck,
                    new bytes(32)
                );

                /**
                 * We then, at the same index as we saved the chunck pointer's index,
                 * save the parsed value of the dynamic argument (it was parsed to be just the length + data
                 * by the getCommandValue() function, it does not include the default prepended mem pointer now).
                 */
                dynamicVars[freeDynVarIndexPtr] = argumentValue;

                // Increment the free index pointer of the dynamic variables
                ++freeDynVarIndexPtr;
            }
        }

        /**
         * @notice,
         * at this point we have iterated over each command.
         * The fixed-length arguments were concatinated with our chunck,
         * whilst the dynamic variables have been replaced with an empty 32 byte at their index,
         * and their values & indexes of these empty placeholders were saved into our arrays.
         *
         * We now perform an additional iteration over these arrays, where we append the
         * dynamic variables to the end of the encoded chunck, save that new index of where we appended it,
         * go back to the index of the corresponding empty placeholder, and replace it with a pointer to our new index.
         *
         * the EVM, when accepting this chunck as calldata, will expect this memory pointer at the index, which, points
         * to where our variable is located in terms of offset since the beginning of the chunck
         */
        for (uint256 i = 0; i < dynamicVars.length; i++) {
            // Shorthand for the index of our placeholder pointer
            uint256 index = dynamicVarsIndexes[i];

            // The new index/pointer
            uint256 newPtr = interpretedEncodedChunck.length;

            // Go into assembly (much cheaper & more conveient to just mstore the 32 byte word)
            assembly {
                mstore(add(add(interpretedEncodedChunck, 0x20), index), newPtr)
            }

            // Finally, concat the calldata with our dynamic variable's length + data
            // (At what would now be stored in the  original index
            // as the mem pointer)
            interpretedEncodedChunck = bytes.concat(
                interpretedEncodedChunck,
                dynamicVars[i]
            );
        }
        /**
         * Finally, concat the 4 byte function selector with the arguments body - and return it
         */
        return interpretedEncodedChunck;
    }
}

// The inputted byte where the function call return val was suposed to be used
// 0x
// 00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001c546869732049732054686520617272617920737472696e672073657200000000

// 0000000000000000000000000000000000000000000000000000000000000001
// 000000000000000000000000000000000000000000000000000000000000001c
// 546869732049732054686520617272617920737472696e672073657200000000
