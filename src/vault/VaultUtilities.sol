/**
 * Utilities used by the vault contract
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../vm/VM.sol";
import "forge-std/console.sol";
import "./Schema.sol";

abstract contract VaultUtilities is IVault, YCVM {
    // ===================
    //     FUNCTIONS
    // ===================
    /**
     * @notice
     * getInvestmentAmount()
     * A standard function which is used to call some balance/position getter,
     * and divise it by a divisor.
     * @param amt - THe initial amount to divise
     * @param divisor - A divisor which is meant to be x100 larger than it actually is, to support uints (i.e, a divisor of 3.3 will be 330)
     */
    function getInvestmentAmount(
        uint256 amt,
        uint256 divisor
    ) public pure returns (uint256 investmentAmount) {
        return (amt * 100) / divisor;
    }

    /**
     * @notice
     * decodeAndRequestFullfill()
     * Accepts an encoded FunctionCall struct, and some context, and emits a RequestFullfill event
     * @param encodedFunctionCall - An encoded FunctionCall struct
     * @param index - An index specifying a step to execute when re-entering onchain, within the provided context
     */
    function _decodeAndRequestFullfill(
        bytes memory encodedFunctionCall,
        uint256 index
    ) internal {
        // We begin by decoding the function call
        FunctionCall memory func = abi.decode(
            encodedFunctionCall,
            (FunctionCall)
        );

        // And then emitting the event
        emit RequestFullfill(index, func.signature, func.args);
    }

    /**
     * @notice
     * _determineConditions()
     * Accepts an array of YCStep's, which are meant to be the conditional step's children.
     * It attempts to execute their YC commands in order - Once one resolves to true, it returns their index + 1.
     * Otherwise, it returns 0 (indiciating none went through). The index is +1'ed so that we can use the 0 index as a nullish indicator,
     * where none of the conditions resolved to true.
     * @param conditions - An array of encoded YC steps, the conditions to execute
     */
    function _determineConditions(
        bytes[] memory conditions
    ) internal returns (uint256) {
        for (uint256 i; i < conditions.length; i++) {
            /**
             * Decode the condition to a YC step
             */
            YCStep memory conditionalStep = abi.decode(conditions[i], (YCStep));

            /**
             * Attempt to execute the condition's complex YC command,
             * if it resolves to true, we return it's index,
             * otherwise, we continue
             */
            if (abi.decode(_runFunction(conditionalStep.func), (bool)))
                return i + 1;
        }

        return 0;
    }
}