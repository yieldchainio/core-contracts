// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./YCClassificationsFacet.sol";
import "../../../YC-Types.sol";

/**
 * @notice Contains various utility/generic methods that will be used, inherited / delegated to throughout Yieldchain's
 * contracts set.
 */
contract ExecutionHelpersFacet is YieldchainTypes {
    /**
     * @notice
     * High-level function called by the strategy contract, receives a full encoded FunctionCall.
     * Prepares the FunctionCall by decoding it & seperating the flag(s), verifying the external sig & replaacing
     * the internal classification name with it.
     */
    function prepareFunctionCall(
        bytes memory _encodedFunctionCall
    ) external view returns (FunctionCall memory _func, uint8 _typeflag) {
        // Decode the function call
        (_func, _typeflag) = decodeFunctionCall(_encodedFunctionCall);

        // Get the verified function
        _func = YCClassificationsFacet(address(this)).verifyYCFunction(_func);
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
     * @notice
     * @decodeFunctionCall
     * Takes in an encoded function call (INCLUDING FLAG!!),
     * returns the FunctionCall object (struct) and a uint8 which is the type flag (0x01/0x02/0x03)
     */
    function decodeFunctionCall(
        bytes memory _encodedFunctionCall
    )
        public
        pure
        returns (FunctionCall memory _function_call, uint8 _typeflag)
    {
        // Getting the plain encoded function call & it's typeflag seperated.
        bytes memory encodedFunctionCallNoFlag;

        // Seperating the function byte from it's flag
        (encodedFunctionCallNoFlag, _typeflag) = seperateYCVariable(
            _encodedFunctionCall
        );

        // Decoding the result
        _function_call = abi.decode(encodedFunctionCallNoFlag, (FunctionCall));
    }

    /**
     * @notice
     * @seperateYCVariable
     * takes in a bytes variable - can be static or FunctionCall... However, must have a flag on it (!!).
     * returns the plain variable without the flag and the flag, seperately
     */
    function seperateYCVariable(
        bytes memory _variable
    ) public pure returns (bytes memory _plain_variable, uint8 _typeflag) {
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
    function removeVarFlag(
        bytes memory _var
    ) public pure returns (bytes memory _ret) {
        _ret = new bytes(_var.length - 2);
        for (uint256 i = 0; i < _var.length - 2; i++) {
            _ret[i] = _var[i];
        }
    }
}
