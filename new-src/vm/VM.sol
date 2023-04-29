// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../types.sol";

contract YCParsers is YieldchainTypes {
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
         * 1) Interpret each argument using the _separateAndGetCommandValue() function
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
     * _separateAndGetCommandValue()
     * Separate & get a command/argument's actual value, by parsing it, and potentially
     * using it's return value (if a function call)
     * @param command - the full encoded command, including typeflags
     * @return interpretedValue - The interpreted underlying value of the argument
     * @return typeflag - The typeflag of the underlying value
     */
    function _separateAndGetCommandValue(
        bytes memory command
    ) public returns (bytes memory interpretedValue, bytes1 typeflag) {
        // First, seperate the command/variable from it's typeflag & return var typeflag
        bytes1 retTypeFlag;
        (interpretedValue, typeflag, retTypeFlag) = _separateCommand(command);

        /**
         * Then, check to see if it's either one of the CALL typeflags, to determine
         * whether it's a function call or not
         */
        if (typeflag >= STATICCALL_COMMAND_FLAG) {
            /*
             * If it is, it means the body is an encoded FunctionCall struct.
             * We call the internal _execFunction() function with our command body & typeflag,
             * in order to execute this function and retreive it's return value - And then use the
             * usual _getCommandValue() function to parse it's primitive value, with the return typeflag.
             * We also assign to the typeflag the command's returnTypeFlag that we got when separating.
             */
            // Decode it first
            FunctionCall memory functionCallCommand = abi.decode(
                interpretedValue,
                (FunctionCall)
            );

            /**
             * To the interpretedValue variable, assign the interpreted result
             * of the return value of the function call. And to the typeflag, assign
             * the returned typeflag (which should be the typeflag of the underlying return value)
             * Note that, to avoid any doubts -
             * The underlying typeflag in this case should always just be the return type flag of the function call,
             * that we input into the function. It's just the uniform API of the function that requires us to receive
             * it anyway.
             *
             * The additional interpretation is done in order to comply the primitive underlying return value
             * with the rest of the system (i.e chunck/calldata encoder). For example, if the function returns
             * a dynamic variable - We need to remove it's initial 32-byte offset pointer in order for it to
             * be compliant with the calldata builder.
             */

            return (
                _getCommandValue(
                    _execFunctionCall(functionCallCommand, typeflag),
                    retTypeFlag
                )
            );
        }

        /**
         * At this point, if it's not a FunctionCall - It is another command type.
         *
         * We call the _getCommandValue() function with our command body & typeflag,
         * which will interpret it and return the underlying value, along with the underlying typeflag.
         */
        (interpretedValue, typeflag) = _getCommandValue(
            interpretedValue,
            typeflag
        );
    }

    /**
     * @notice
     * _getCommandValue
     * Accepts a primitive value, a typeflag - and interprets it
     * @param commandVariable - A command variable without the typeflags
     * @param typeFlag - The typeflag
     */

    function _getCommandValue(
        bytes memory commandVariable,
        bytes1 typeflag
    ) public returns (bytes memory parsedPrimitiveValue, bytes1 typeFlag) {
        /**
         * We initially set parsed primitive value and typeFlag to the provided ones
         */
        parsedPrimitiveValue = commandVariable;
        typeFlag = typeflag;

        /**
         * If the typeflag is 0x00, it's a static variable and we just return it (simplest case)
         */
        if (typeflag == STATIC_VAR_FLAG)
            return (parsedPrimitiveValue, typeflag);

        /**
         * If the typeflag is 0x01, it's a dynamic-type variable (string, array...), we parse and return it
         */
        if (typeflag == DYNAMIC_VAR_FLAG) {
            parsedPrimitiveValue = _parseDynamicVar(parsedPrimitiveValue);
            return (parsedPrimitiveValue, typeflag);
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
                parseFixedLengthCommandsArr(parsedPrimitiveValue),
                STATIC_VAR_FLAG
            );
        }

        /**
         * If the typeflag is 0x03, it's a dynamic-length array of YC commands - parse and return it,
         * along with a 0x01 typeflag (indiicating dynamic variable)
         */
        if (typeflag == DYNAMIC_LENGTH_COMMANDS_ARR_FLAG) {
            return (
                parseDynamicCommandsArr(parsedPrimitiveValue),
                DYNAMIC_VAR_FLAG
            );
        }
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
        // Assign the typeflag & retTypeFlag
        typeflag = ycCommand[0];
        retTypeflag = ycCommand[1];

        // The length of the original command
        uint256 originalLen = ycCommand.length;

        // The new desired length
        uint256 newLen = originalLen - 2;

        /**
         * We load the first word of the command,
         * by mloading it's first 32 bytes, shifting them 2 bytes to the left,
         * then convering assigning that to bytes30. The result is the first 30 bytes of the command,
         * minus the typeflags.
         */
        bytes30 firstWord;
        assembly {
            firstWord := shl(16, mload(add(ycCommand, 0x20)))
        }

        /**
         * Initiate the naked command to a byte the length of the original command, minus 32 bytes.
         * -2 to account for the flags we are omitting, and -30 to account for the first loaded bytes.
         * We will later concat the first 30 bytes from the original command (that does not include the typeflags)
         */
        nakedCommand = new bytes(newLen - 30);

        assembly {
            /**
             * We begin by getting the base origin & destination pointers.
             * For the base destination, it is 62 bytes - 32 bytes to skip the length,
             * and an additional 30 bytes to account for the first word (minus the typeflags) which we have loaded
             * For the baseOrigin, it is 64 bytes - 32 bytes for the length skipping, and an additional 32 bytes
             * to skip the first word, including the typeflags
             *
             * Note that there should not be any free memory issue. It is true that we may go off a bit with
             * the new byte assignment than our naked command's length (nit-picking would be expsv here), but
             * it shouldnt matter as the size we care about is already allocated to our new naked command,
             * and anything that would like to override the extra empty bytes after it is more than welcome
             */
            let baseOrigin := add(ycCommand, 0x40)
            let baseDst := add(nakedCommand, 0x20)

            // If there should be an additional iteration that may be needed
            // (depending on whether it is a multiple of 32 or not)
            let extraIters := and(1, mod(newLen, 32))

            // The iterations amount to do
            let iters := add(div(newLen, 32), extraIters)

            /*
             * We iterate over our original command in 32 byte increments,
             * and copy over the bytes to the new nakedCommand (again, with the base
             * of the origin being 32 bytes late, to skip the first word
             */
            for {
                let i := 0
            } lt(i, iters) {
                i := add(i, 1)
            } {
                mstore(
                    add(baseDst, mul(i, 0x20)),
                    mload(add(baseOrigin, mul(i, 0x20)))
                )
            }
        }

        // We concat the first 30 byte word with the new naked command - completeing the operation, and returning.
        nakedCommand = bytes.concat(firstWord, nakedCommand);
    }

    /**
     * _parseDynamicVar
     * @param _arg - The dynamic-length argument to parse
     * @return the parsed arg. So the dynamic-length argument minus it's ABI-prepended 32 byte offset pointer
     */
    function _parseDynamicVar(
        bytes memory _arg
    ) public pure returns (bytes memory) {
        /**
         * We call the _removePrependedBytes() function with our arg,
         * and 32 as the amount of bytes to remove.
         * this will remove the first 32 bytes of our argument, which is supposed to be the
         * offset pointer to hence - and hence return a "parsed" version of it (just the length + data)
         */
        return _removePrependedBytes(_arg, 32);
    }

    /**
     * parseFixedLengthCommandsArr
     * Parse a fixed-length array of YC commands
     * @param ycCommandsArr - An encoded fixed-length array which is made up of YC commands
     * @return interpretedArray - The array, but of the underlying values
     * (using _separateAndGetCommandValue() on each item),
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
         * We then call the interpretCommandsAndEncodeChunck() function with our array of YC commands,
         * which will interpret each command, and encode it into a single chunck, depending on it's underlying type.
         *
         * We then prepend the result (using bytes.concat) with the array's length (32 byte padded, ofc).
         * This is needed for arrays in the EVM, otherwise it's just a chunck of the items in it, without anything
         * identifying it as an iterable array.
         * A pointer will be prepended to it where needed lower in the stack - out of scope for this function.
         */
        interpretedArray = bytes.concat(
            abi.encode(decodedCommandsArray.length),
            interpretCommandsAndEncodeChunck(decodedCommandsArray)
        );
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
         * call the _separateAndGetCommandValue() function on them, which returns both the value and their typeflag.
         */
        for (uint256 i = 0; i < ycCommands.length; i++) {
            /**
             * Get the value of the argument and it's underlying typeflag
             */
            (
                bytes memory argumentValue,
                bytes1 typeflag
            ) = _separateAndGetCommandValue(ycCommands[i]);

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

            // Finally, concat the existing chunck with our dynamic variable's length + data
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

    /**
     * @notice
     * interpretFixedLengthCommandsArray
     * Interprets a fixed-length array of YC commands, and returns a fixed-length array with the underlying
     * interpreted values.
     *
     * It will also remove any potential memory pointer from the beggining of it (if contains dyn-length items),
     * and the synthetic 32-byte length prepended in the encoding.
     *
     * @param ycCommands - An ABI encoded chunck of bytes, which is supposed to be a fixed-length array,
     * of either dynamic-length or fixed-length ("static") contents and their corresponding attributes,
     * as well as 32 bytes appended at the top, which are supposed to be the length of the array (synthetically added
     * during encoding)
     *
     * @param typeflag - A typeflag specifying the type of contents in the array. This is used to parse it correcrtly,
     * and the "returnTypeFlag" of the command should be used here.
     *
     * @return interpretedCommands - An array of interpreted commands. I.e their underlying values
     */
    function interpretCommandsAndEncodeChunck(
        bytes memory ycCommands,
        bytes1 typeflag
    ) public returns (bytes memory interpretedCommands) {}

    /**
     * @notice
     * _removePrependedBytes
     * Takes in a chunck of bytes (must be a multiple of 32 in length!!!!!!!),
     * Note that the chunck must be a "dynamic" variable, so the first 32 bytes must specify it's length.
     * and a uint specifying how many  bytes to remove (also must be a multiple of 32 length) from the beggining.
     * @param chunck - a chunck of bytes
     * @param bytesToRemove - A multiple of 32, amount of bytes to remove from the beginning
     * @return parsedChunck - the chunck without the first multiples of 32 bytes
     */
    function _removePrependedBytes(
        bytes memory chunck,
        uint256 bytesToRemove
    ) public pure returns (bytes memory parsedChunck) {
        // Shorthand for the length of the bytes chunck
        uint256 len = chunck.length;

        // We create the new value, which is the length of the argument *minus* the bytes to remove
        parsedChunck = new bytes(len - bytesToRemove);

        assembly {
            // Require the argument & bytes to remove to be a multiple of 32 bytes
            if or(mod(len, 0x20), mod(bytesToRemove, 0x20)) {
                revert(0, 0)
            }

            // New length's multiple of 32 (the amount of iterations we need to do)
            let iters := div(sub(len, bytesToRemove), 0x20)

            // Base pointer for the original value - Base ptr + ptr pointing to value + bytes to remove
            //  (first 32 bytes of the value)
            let baseOriginPtr := add(chunck, add(0x20, bytesToRemove))

            // Base destination pointer
            let baseDstPtr := add(parsedChunck, 0x20)

            // Iterating over the variable, copying it's bytes to the new value - except the first *bytes to remove*
            for {
                let i := 0
            } lt(i, iters) {
                i := add(i, 1)
            } {
                // Current 32 bytes
                let currpart := mload(add(baseOriginPtr, mul(0x20, i)))

                // Paste them into the new value
                mstore(add(baseDstPtr, mul(0x20, i)), currpart)
            }
        }
    }
}

// // ABI encoded chunck with fixed-length string[]
// 0x
// 00000000000000000000000000000000000000000000000000000000000000a0
// 00000000000000000000000000000000000000000000000000000000030f8f37
// 00000000000000000000000000000000000000000000000000000000000000e0
// 0000000000000000000000000000000000000000000000000000000000000203
// 00000000000000000000000000000000000000000000000000000000000001a0
// 000000000000000000000000000000000000000000000000000000000000001b
// 4c616c616c616c616c205572206d756d20697320612062697463680000000000
// 0000000000000000000000000000000000000000000000000000000000000040
// 0000000000000000000000000000000000000000000000000000000000000080
// 0000000000000000000000000000000000000000000000000000000000000015
// 4669727374204974656d20686568656865686865650000000000000000000000
// 000000000000000000000000000000000000000000000000000000000000000b
// 7365636f6e64206974656d000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000010
// 466972737420537472696e672053657200000000000000000000000000000000

// // ABI encoded chunck with fixed-length uint256[]
// 0x
// 00000000000000000000000000000000000000000000000000000000000000c0 // "strang" offset pointer
// 00000000000000000000000000000000000000000000000000000000030f8f37 // 51351351
// ///////////////////////////////Fixed length Arr///////////////////////////////////////////////
// 00000000000000000000000000000000000000000000000000000000000003e7 // First Num (999)
// 00000000000000000000000000000000000000000000000000000000000003e7 // Second Num (999)
// //////////////////////////////////////////////////////////////////////////////
// 0000000000000000000000000000000000000000000000000000000000000203 // 515
// 0000000000000000000000000000000000000000000000000000000000000100 // "First String Ser" Offset pointer (WTF!?!?!?!?!?!?)
// 000000000000000000000000000000000000000000000000000000000000001b // "strang" length
// 4c616c616c616c616c205572206d756d20697320612062697463680000000000 // "strang" value
// 0000000000000000000000000000000000000000000000000000000000000010 // "First String String" length
// 466972737420537472696e672053657200000000000000000000000000000000 // "First String String" Value

// 0x
// 00000000000000000000000000000000000000000000000000000000000000a0
// 00000000000000000000000000000000000000000000000000000000030f8f37
// 00000000000000000000000000000000000000000000000000000000000000e0
// 0000000000000000000000000000000000000000000000000000000000000203
// 0000000000000000000000000000000000000000000000000000000000000140
// 000000000000000000000000000000000000000000000000000000000000001b
// 4c616c616c616c616c205572206d756d20697320612062697463680000000000
// 0000000000000000000000000000000000000000000000000000000000000002
// 00000000000000000000000000000000000000000000000000000000000003e7
// 00000000000000000000000000000000000000000000000000000000000003e7
// 0000000000000000000000000000000000000000000000000000000000000010
// 466972737420537472696e672053657200000000000000000000000000000000
