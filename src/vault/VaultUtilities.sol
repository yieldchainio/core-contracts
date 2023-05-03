/**
 * Utilities used by the vault contract
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./Schema.sol";
import "../vm/VM.sol";

abstract contract VaultUtilities is IVault, YCVM {
    // ===================
    //     FUNCTIONS
    // ===================
    /**
     * @notice
     * getInvestmentAmount()
     * A standard function which is used to call some balance/position getter,
     * and divise it by a divisor.
     * @param balanceRetreiver - A YC command used to retreive a balance
     * @param divisor - A divisor which is meant to be x100 larger than it actually is, to support uints (i.e, a divisor of 3.3 will be 330)
     */
    function getInvestmentAmount(
        bytes memory balanceRetreiver,
        uint256 divisor
    ) internal returns (uint256 investmentAmount) {
        // We run the function, multiply the result by 100, and divise it by the (x100 multiplied) divisor
        return
            (abi.decode(_runFunction(balanceRetreiver), (uint256)) * 100) /
            divisor;
    }

    /**
     * @notice
     * decodeAndRequestFullfill()
     * Accepts an encoded FunctionCall struct, and some context, and emits a RequestFullfill event
     * @param encodedFunctionCall - An encoded FunctionCall struct
     * @param context - A string representing some context for the offchain executor, i.e "tree", "seed", "uproot"
     * @param index - An index specifying a step to execute when re-entering onchain, within the provided context
     */
    function _decodeAndRequestFullfill(
        bytes memory encodedFunctionCall,
        ActionTypes context,
        uint256 index
    ) internal {
        // We begin by decoding the function call
        FunctionCall memory func = abi.decode(
            encodedFunctionCall,
            (FunctionCall)
        );

        // And then emitting the event
        emit RequestFullfill(context, func.signature, index, func.args);
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
