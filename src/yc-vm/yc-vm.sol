// SPDX-License-Identifier: SPDX
pragma solidity ^0.8.18;
import "../YC-Types.sol";
import "./command-utilities.sol";

contract YieldchainStrategyExecHelpers is YieldchainTypes, ycVMUtilities {
    /**
     * @notice
     * _runFunction
     * Called by the strategy contract, takes in an encoded YC function (raw, with the flags embedded)
     * @param _encodedFunctionCall - The encoded FunctionCall struct, with the flags embedded
     * @return _ret - The return value of the the function call
     * @return _calledFunc - The parsed called function, decoded
     */
    function _runFunction(
        bytes memory _encodedFunctionCall
    ) internal returns (bytes memory _ret, FunctionCall memory _calledFunc) {
        // Initiallizing
        uint8 typeflag;

        // TODO: Add some r,s,v signature in here to retain pureness of function verification?
        // Preparing the function call.
        (_calledFunc, typeflag) = YC_DIAMOND.prepareFunctionCall(
            _encodedFunctionCall
        );

        // Execute the function
        _ret = _execFunctionCall(_calledFunc, typeflag);
    }

    /**
     * @notice
     * _execFunctionCall
     * Used internally by the high-level _runFunction function, takes in a decoded YC FunctionCall struct and a typeflag.
     * Builds the callData using the _buildCalldata function, sends a low-level call depending on the type flag using the calldata.
     * Returns the return data of the function call
     * @param _func - A decoded FunctionCall struct
     * @param _typeflag - The typeflag to call with (i.e CALL, DELEGATECALL, STATICCALL)
     * @return ret_ - The return value of the function call
     */
    // TODO: Enter the future r,s,v as args here
    function _execFunctionCall(
        FunctionCall memory _func,
        uint8 _typeflag
    ) internal returns (bytes memory ret_) {
        // Get the calldata
        bytes memory callData = _buildCalldata(_func);

        // Switch-Case for the call type based on the flag
        if (_typeflag == 0x02)
            (, ret_) = _func.target_address.staticcall(callData);
        else if (_typeflag == 0x03)
            (, ret_) = _func.target_address.delegatecall(callData);
        else if (_typeflag == 0x04)
            (, ret_) = _func.target_address.call(callData);
        else revert InvalidCallFlag();
    }

    /**
     * @notice
     * Takes in a FunctionCall struct, maps the arguments using ``getArgValue``,
     * builds the calldata for the function call.
     * Responsible for parsing various different types of variables
     * @param _func FunctionCall struct with a verified signature
     */
    function _buildCalldata(
        FunctionCall memory _func
    ) internal returns (bytes memory _calldata) {
        // Encoding the function signature
        _calldata = abi.encode(_func.signature);

        /**
         * @notice
         * Keeping track of dynamic variables, to be inserted at the end after inserting all the fixed-length variables
         */
        bytes[] memory dynamicVars;
        uint256[] memory dynamicVarsIndexes;

        // Mapping the arguments
        for (uint256 i = 0; i < _func.args.length; i++) {
            // Get arg's variable value

            (bytes memory argval, uint8 typeflag) = _getArgValue(_func.args[i]);

            // Concat the existing calldata with the argument
            require(
                typeflag < 0x02,
                "Flag Must Be A Static/Dynamic When Encoding Calldata"
            );

            // If it's static, just concat it
            if (typeflag == 0x00)
                _calldata = bytes.concat(_calldata, argval);

                // Else - parse it's value, keep track of the length, and the index of it
            else {
                // Save the index - will use it later on to append the new pointer
                dynamicVarsIndexes[dynamicVarsIndexes.length - 1] = _calldata
                    .length;

                // Append an empty 32 byte placeholder
                _calldata = bytes.concat(_calldata, new bytes(32));

                // Push the variable's value to the array of dynamic variables
                dynamicVars[dynamicVars.length - 1] = parseDynamicVar(argval);
            }
        }

        // Sufficient check
        require(
            dynamicVars.length == dynamicVarsIndexes.length,
            "Dynamic vars arr length does not match corresponding indexes arr length!"
        );

        // @notice
        // Iterate over the saved dynamic variables,
        // Append them to the end of our calldata, whilst updating the pointer at their corresponding index
        for (uint256 i = 0; i < dynamicVars.length; i++) {
            uint256 index = dynamicVarsIndexes[i];

            // Iterating over the calldata, appending the new pointer at the specified index
            assembly {
                // Loading the new pointer
                let newptr := mload(_calldata)
                // Doing 32 iterations (size of our placeholder pointer) and inserting the new bytes of the new ptr

                // Shorthand
                let baseindex := add(add(_calldata, 0x20), mload(index))

                for {
                    let j := 0
                } lt(j, 32) {
                    j := add(i, 1)
                } {
                    mstore(add(baseindex, j), newptr)
                }
            }

            // Append the variable value (The pointer is now pointing to it e.g to what was up until this point the calldata's length)
            _calldata = bytes.concat(_calldata, dynamicVars[i]);
        }
        // Return the new calldata
        return _calldata;
    }

    /**
     * A recrusive function that accepts a byte argument, attempts to decode it using
     * YC's "Function" struct - if fails, returns the byte as-is. If it goes through, it
     * makes the desired function call, whilst recrusing the same process for each one of the function's
     * arguments.
     * @param _arg A YC Encoded variable - can be either plain (A static variable), or any kind of FunctionCall type.
     * @return returnArg_ The result - the actual value of that argument. If static, would just be the argument without
     * the flags (i.e plain). If it's a FunctionCall, it would be the return data of that function call
     * @return typeflag_ - The typeflag of the (potential) return value.
     */
    function _getArgValue(
        bytes memory _arg
    ) internal returns (bytes memory returnArg_, uint8 typeflag_) {
        // Seperating the argument & the flag
        bytes memory plainArg;

        // Shorthand for the return type flag - may not be used if the variable is not a function call
        uint8 retTypeFlag;
        // Seperating the argument from it's typeflags
        (plainArg, typeflag_, retTypeFlag) = seperateYCVariable(_arg);

        // If the flag is 0, it means it is static so we return the plain arg as-is
        if (typeflag_ == 0x00) returnArg_ = plainArg;

        // If the flag is 1, it means it is a dynamic-length variable. We parse and return it
        if (typeflag_ == 0x01) returnArg_ = parseDynamicVar(plainArg);

        // @notice
        // If the flag is not 0, 1 (i.e its either 1, 2, 3 - the CALL types), we call prepareFunctionCall.
        // the function will in turn decode the function as needed, recruse back to us for each
        // one of it's arguments, and at the end return the calldata

        // Getting the FunctionCall struct (Since the arg is not static)

        // Execute the function call.
        (returnArg_, ) = _runFunction(_arg);

        // Typeflag now equals to the return value's type flag (Since this will be now used as the argument)
        typeflag_ = retTypeFlag;

        // If the return type flag is equal to the dynamic-length variable flag we parse it before returning it
        if (retTypeFlag == 0x01) returnArg_ = parseDynamicVar(returnArg_);
    }
}
