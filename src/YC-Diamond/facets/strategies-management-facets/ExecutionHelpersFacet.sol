// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./ClassificationsFacet.sol";
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
        (_func, _typeflag, ) = decodeFunctionCall(_encodedFunctionCall);

        // Get the verified function
        _func = YCClassificationsFacet(address(this)).verifyYCFunction(_func);
    }

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
        returns (
            FunctionCall memory _function_call,
            uint8 _typeflag,
            uint8 _retTypeflag
        )
    {
        // Getting the plain encoded function call & it's typeflag seperated.
        bytes memory encodedFunctionCallNoFlag;

        // Seperating the function byte from it's flag
        (
            encodedFunctionCallNoFlag,
            _typeflag,
            _retTypeflag
        ) = seperateYCVariable(_encodedFunctionCall);

        // Sufficient check
        require(
            _typeflag >= 0x02 && _typeflag < 0x05,
            "Not A Function Call Flag!"
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
    )
        public
        pure
        returns (
            bytes memory _plain_variable,
            uint8 _typeflag,
            uint8 _retTypeflag
        )
    {
        // Getting the @Flag of the variable (appended to the end of each YC input)
        (_typeflag, _retTypeflag) = getVarFlags(_variable);

        // Saving a version of the argument without the appended flag
        _plain_variable = removeVarFlag(_variable);
    }

    /**
     * @notice
     * Get the flag of a YC variable
     * 0x00 = Static Variable
     * 0x01 = Dynamic variable
     * 0x02 = Static CALL
     * 0x03 = Delegate CALL
     * 0x04 CALL
     */
    function getVarFlags(
        bytes memory _var
    ) public pure returns (uint8 typeflag_, uint8 retTypeflag_) {
        assembly {
            let len := mload(_var)

            // Getting typeflag
            typeflag_ := mload(add(add(_var, 0x20), sub(len, 1)))

            // Getting retTypeFlag
            retTypeflag_ := mload(add(add(_var, 0x20), sub(len, 2)))
        }
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
        assembly {
            let baseptr := add(_var, 0x20)
            let retptr := add(_ret, 0x20)
            for {
                let i := 0
            } lt(i, sub(mload(_var), 2)) {
                i := add(i, 1)
            } {
                mstore(add(retptr, i), mload(add(baseptr, i)))
            }
        }
    }
}
