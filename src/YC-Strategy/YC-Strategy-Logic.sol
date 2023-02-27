// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../YC-Diamond/YC-Diamond-Interface.sol";
import "./YC-Strategy-Conditionals-Logic.sol";
import "./YC-Strategy-Types.sol";

/**
 * @notice
 * @YCStrategyBase
 * A base contract that is used when creating Yielchain strategies through a factory.
 */

contract YCStrategyBase is YieldchainStrategyConditionals {
    // =======================================
    //            CONSTRUCTOR SUPER
    // ========================================
    constructor(
        bytes[] memory _steps,
        bytes[] memory _base_strategy_steps,
        address[] memory _base_tokens,
        address[] memory _strategy_tokens,
        address[][] memory _tokens_related_addresses,
        uint256 _automation_interval,
        address _deployer
    )
        YieldchainStrategyConditionals(
            _steps,
            _base_strategy_steps,
            _base_tokens,
            _strategy_tokens,
            _tokens_related_addresses,
            _automation_interval,
            _deployer
        )
    {}

    // =========================
    //       MAIN FUNCTIONS
    // =========================

    /**
     * @notice
     * @runStrategy
     * runs runStep at index 0,
     * which means it begins a completely new strategy run
     */
    function runStrategy() external isYieldchain {
        lastExecution = block.timestamp;
        locked = true;
        runStep(0, true, new bytes(0), false, new uint256[](0));
    }

    /**
     * @notice
     * @runStep
     * Begins a recrusive execution of steps starting at a given step index
     */
    function runStep(
        uint256 _step_index,
        bool _isRoot,
        bytes memory _custom_function, // Optional - for callback fullfills
        bool _isFullfill,
        uint256[] memory _childrenToIgnore
    ) public isYieldchain {
        // Decoding our current Step
        YCStep memory current_step = abi.decode(STEPS[_step_index], (YCStep));

        // An array of the step's children to not execute - only relevent for conditional steps.
        uint256[] memory children_to_ignore = _childrenToIgnore;

        // Initiallizing
        FunctionCall memory executedFunc;

        // @notice
        // If the current run is a fullfill - Run the custom function
        if (_isFullfill) (, executedFunc) = _runFunction(_custom_function);

        // If the current call is not an offchain fullfil operation, we run the step (either regularely/as a conditional)
        if (!_isFullfill)
            if (current_step.conditions.length > 0) {
                (, executedFunc) = _runFunction(current_step.step_function);
            } else {
                (
                    children_to_ignore,
                    executedFunc.is_callback
                ) = _runConditional(current_step, _step_index);
            }

        // If the step is a callback step (requires a stop on-chain and a resumption (fulfill) after offchain computation) -
        // We break the recrusion.
        // Note that in the case of it being a callback, either function should handle emitting the request log (that is caught
        // by the backend), which would presumabley include the index of the step it was emitted in (So it can reenter the recrusion loop).
        if (executedFunc.is_callback && !_isFullfill) {
            return;
        }

        // Shorthand for children indexes
        uint256[] memory childrenIndexes = current_step.children_indexes;

        // Looping over each child,
        // If it should be ignored (from conditional), we ignore it -
        // else, we recruse the runStep function on it
        for (uint256 i = 0; i < childrenIndexes.length; i++) {
            // Continue if should be ignored
            if (YC_DIAMOND.findUint(children_to_ignore, childrenIndexes[i]))
                continue;

            // @Recruse
            runStep(
                childrenIndexes[i],
                false,
                new bytes(0),
                false,
                new uint256[](0)
            );
        }

        // Unlocking the "locked" if the inputted step is the root - it means we finished executing it and all of it's hierarchy
        if (_isRoot && locked == true) locked = false;
    }
}
