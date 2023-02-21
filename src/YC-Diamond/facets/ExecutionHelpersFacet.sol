// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "../../YC-Base.sol";

/**
 * @notice Contains various utility/generic methods that will be used, inherited / delegated to throughout Yieldchain's
 * contracts set.
 */
contract YC_Utilities is IYieldchainBase {
    /// @notice Exeuctes a function
    /// @dev Calls getCalldata to get the call data, has a switch-case for function call types
    /// @param _funcObj A YC FunctionCall struct object, has all the details for the function cal
    /// @return _ret  a bytes return value from the low-level function call
    function _executeFunc(FunctionCall memory _funcObj)
        internal
        returns (bytes memory _ret)
    {
        // Getting calldata for the call
        bytes memory _calldata = getCalldata(_funcObj.signature, _funcObj.args);

        // Preparing success variable for the call
        bool success;

        // Switch-Case for function's calltype, assigning return value to _ret

        // Regular call
        if (_funcObj.call_type == CallTypes.CALL)
            (success, _ret) = _funcObj.target_address.call{value: msg.value}(
                _calldata
            );

            // Delegate Call
        else if (_funcObj.call_type == CallTypes.DELEGATECALL)
            (success, _ret) = _funcObj.target_address.delegatecall(_calldata);

            // Static Call (Cheapest)
        else if (_funcObj.call_type == CallTypes.STATICCALL)
            (success, _ret) = _funcObj.target_address.staticcall(_calldata);

        // Require the call to go through
        require(success, "Call Failed");
    }

    /**
     * @notice
     * @Method getCalldata
     * dynamic, generic encoding of calldata.
     * ----- // PARAMETERS // -----
     * @param _function_signature - @string, The function signature to encode (e.g, "addLiquidity(address,address,uint256,uint256)"
     *
     * @param _arguments - bytes[] - An array of arguments (as bytes) that will be appended to the calldata when concatanating it.
     * -----------------------------
     *
     * @return _calldata - bytes - The encoded calldata, should be used directly in a low-level call
     */
    // ------------------------------------------
    function getCalldata(
        string memory _function_signature,
        bytes[] memory _arguments
    ) public pure returns (bytes memory _calldata) {
        // Encoding the function signature
        _calldata = abi.encodeWithSignature(_function_signature);

        // For each one of the arguments
        for (uint256 i = 0; i < _arguments.length; i++) {
            // Concat the existing calldata with the argument
            _calldata = bytes.concat(_calldata, _arguments[i]);
        }
        // Return the new calldata
        return _calldata;
    }

    // --------------------------------------------

    // TODO: Make actual impl of this
    function isFunctionCall(bytes memory _functionCall_or_primitive)
        internal
        pure
        returns (bool _isFunctionCall)
    {
        // Attempting to decode
        abi.decode(_functionCall_or_primitive, (FunctionCall));

        // If does not work, returns false when used in try-catch.
        // else, we set return value to true.
        _isFunctionCall = true;
    }

    /**
     * A recrusive function that accepts a byte argument, attempts to decode it using
     * YC's "Function" struct - if fails, returns the byte as-is. If it goes through, it
     * makes the desired function call, whilst recrusing the same process for each one of the function's
     * arguments.
     */
    function getArgValue(bytes memory arg)
        public
        returns (bytes memory returnArg)
    {
        if (!isFunctionCall(arg)) {
            return arg;
        }
        // If we fail to decode the argument as a FunctionCall struct, we assume it is static and return it as-is.
        // If we do manage to decode the argument as a FunctionCall struct, we call the function and return it's return value.
        else {
            // Getting the actual struct
            FunctionCall memory decodedFunc = abi.decode(arg, (FunctionCall));

            // Initiating an array for the new arguments
            bytes[] memory newArgs = new bytes[](decodedFunc.args.length);

            // @notice
            // For each one of the function's arguments, we recruse the function (getArgValue).
            // Since dynamic return values may be used as an argument for this function (a dynamic return value...) as well.
            for (uint256 i = 0; i < newArgs.length; i++) {
                newArgs[i] = getArgValue(decodedFunc.args[i]); // Recrusion
            }

            // Concat bytes into single calldata (using the function signature and our new arguments)
            bytes memory callData = getCalldata(decodedFunc.signature, newArgs);

            // success & return value prep
            bool success;
            bytes memory result;

            // Finally, calling the step's function
            if (decodedFunc.is_callback) {
                // TODO: placegholder callback
                (success, result) = decodedFunc.target_address.staticcall(
                    callData
                );
            } else
                (success, result) = decodedFunc.target_address.call(callData);
        }
    }
}
