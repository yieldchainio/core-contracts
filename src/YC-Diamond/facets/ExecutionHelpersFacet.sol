// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "../../YC-Base.sol";
import "./YCClassificationsFacet.sol";

/**
 * @notice Contains various utility/generic methods that will be used, inherited / delegated to throughout Yieldchain's
 * contracts set.
 */
contract YC_Utilities is IYieldchainBase {
    /**
     * @notice
     * @executeYCFunction
     * High-level function called by the strategy, receives a full encoded FunctionCall.
     * @ Maps arguments by calling getArgValue on each one,
     * returns the return data
     */
    function executeYCFunction(bytes memory _encodedFunctionCall)
        public
        returns (bytes memory _ret, FunctionCall memory _func)
    {
        // Initating variable
        uint8 typeflag;
        // Getting the FunctionCall object & typeflag of our function
        (_func, typeflag) = decodeFunctionCall(_encodedFunctionCall);

        // Mapping the arguments
        for (uint256 i = 0; i < _func.args.length; i++)
            _func.args[i] = getArgValue(_func.args[i]);

        // Execute lower-level _executeFunc function, that get's the calldata, executes the function
        // based on the typeflag, and returns it's return data
        _ret = _executeFunc(_func, typeflag);
    }

    /// @notice Exeuctes a function
    /// @dev Calls getCalldata to get the call data, has a switch-case for function call types
    /// @param _funcObj A YC FunctionCall struct object, has all the details for the function cal
    /// @return _ret  a bytes return value from the low-level function call
    function _executeFunc(FunctionCall memory _funcObj, uint8 _type_flag)
        internal
        returns (bytes memory _ret)
    {
        // Retreiving the actual external function signature
        string memory externalSignature = YCClassificationsFacet(address(this))
            .getExternalFunction(_funcObj.signature);

        // Require function to be YC classified
        require(
            keccak256(abi.encode(externalSignature)) !=
                keccak256(abi.encode("")),
            "Function Called Does Is Not Classified!"
        );

        // Getting calldata for the call
        bytes memory _calldata = getCalldata(externalSignature, _funcObj.args);

        // Preparing success variable for the call
        bool success;

        /**
         * Switch-Case for function's calltype, assigning return value to _ret
         */
        // Static call (Cheapest)
        if (_type_flag == 0x01)
            (success, _ret) = _funcObj.target_address.staticcall(_calldata);

            // Delegate Call
        else if (_type_flag == 0x02)
            (success, _ret) = _funcObj.target_address.delegatecall(_calldata);

            // Reguler Call
        else if (_type_flag == 0x03)
            (success, _ret) = _funcObj.target_address.call{value: msg.value}(
                _calldata
            );

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
        // Seperating the argument & the flag
        (bytes memory plainArg, uint8 typeflag) = seperateYCVariable(arg);

        // If the flag is 0, it means it is static so we return the plain arg as-is
        if (typeflag == 0x00) return plainArg;

        // Getting the FunctionCall struct (Since the arg is not static)
        FunctionCall memory decodedFunc = abi.decode(arg, (FunctionCall));

        // Initiating an array for the new arguments
        bytes[] memory newArgs = new bytes[](decodedFunc.args.length);

        // @notice
        // For each one of the function's arguments, we recruse the function (getArgValue).
        // Since dynamic return values may be used as an argument for this function (a dynamic return value...) as well.
        for (uint256 i = 0; i < newArgs.length; i++) {
            newArgs[i] = getArgValue(decodedFunc.args[i]); // Recrusion
        }

        // We now re-assign the arguments of our in-memory copy of the FunctionCall object
        decodedFunc.args = newArgs;

        // Execute the FunctionCall function
        returnArg = _executeFunc(decodedFunc, typeflag);
    }

    /**
     * @notice
     * @decodeFunctionCall
     * Takes in an encoded function call (INCLUDING FLAG!!),
     * returns the FunctionCall object (struct) and a uint8 which is the type flag (0x01/0x02/0x03)
     */
    function decodeFunctionCall(bytes memory _encodedFunctionCall)
        public
        pure
        returns (FunctionCall memory _function_call, uint8 _typeflag)
    {
        // Getting the plain encoded function call & it's typeflag seperated.
        (
            bytes memory encodedFunctionCallNoFlag,
            uint8 typeflag
        ) = seperateYCVariable(_encodedFunctionCall);

        _function_call = abi.decode(encodedFunctionCallNoFlag, (FunctionCall));
        _typeflag = typeflag; // TODO: why tf did it not let me reassign directly when destructring it?
    }

    /**
     * @notice
     * @seperateYCVariable
     * takes in a bytes variable - can be static or FunctionCall... However, must have a flag on it (!!).
     * returns the plain variable without the flag and the flag, seperately
     */
    function seperateYCVariable(bytes memory _variable)
        public
        pure
        returns (bytes memory _plain_variable, uint8 _typeflag)
    {
        // Getting the @Flag of the variable (appended to the end of each YC input)
        _typeflag = getVarFlag(_variable);

        // Saving a version of the argument without the appended flag
        _plain_variable = removeVarFlag(_variable);
    }

    /**
     * @notice
     * Get the flag of a YC variable
     * 0x00 = Static Variable
     * 0x01 = Static CALL
     * 0x02 = Delegate CALL
     * 0x03 = CALL
     */
    function getVarFlag(bytes memory _var) public pure returns (uint8) {
        bytes2 lastTwo = bytes2(
            uint16(uint8(_var[_var.length - 2]) + uint8(_var[_var.length - 1]))
        );
        return uint8(uint16(lastTwo) / uint16(0x10));
    }

    /**
     * @notice
     * @removeVarFlag
     * Takes in a full encoded YC Variable with flag,
     * returns the variable without the flag
     */
    function removeVarFlag(bytes memory _var)
        public
        pure
        returns (bytes memory _ret)
    {
        _ret = new bytes(_var.length - 2);
        for (uint256 i = 0; i < _var.length - 2; i++) {
            _ret[i] = _var[i];
        }
    }
}
