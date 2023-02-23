// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../YC-Diamond/YC-Diamond-Interface.sol";
import "./YC-Strategy-Execution-Helpers.sol";
import "./YC-Strategy-Types.sol";

/**
 * @notice
 * @YCStrategyBase
 * A base contract that is used when creating Yielchain strategies through a factory.
 */

contract YCStrategyBase is
    YieldchainStrategyExecHelpers,
    YieldchainStrategyTypes
{
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
        YieldchainStrategyExecHelpers(
            _steps,
            _base_strategy_steps,
            _base_tokens,
            _strategy_tokens,
            _tokens_related_addresses,
            _automation_interval,
            _deployer
        )
    {}

    // ======================================
    //          AUTOMATION FUNCTIONS
    // ======================================

    // Gets called by upkeep orchestrator to determine whether the strategy should run now
    function shouldPerform() external view returns (bool) {
        // If AUTOMATION_INTERVAL has passed since last execution
        if (block.timestamp - lastExecution >= AUTOMATION_INTERVAL) return true;
        return false;
    }

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
        runStep(0);
    }

    /**
     * @notice
     * @runStep
     * Begins a recrusive execution of steps starting at a given step index
     */
    function runStep(uint256 _step_index) public isYieldchain {
        // Decoding our current Step
        YCStep memory current_step = abi.decode(STEPS[_step_index], (YCStep));

        // An array of the step's children to not execute - only relevent for conditional steps.
        uint256[] memory children_to_ignore;

        // Initiallizing
        FunctionCall memory executedFunc;

        // If not a conditional, run the step regularly
        if (current_step.conditions.length > 0) {
            (, executedFunc) = _runStep(current_step);
        } else {
            children_to_ignore = _runConditional(current_step);
        }

        // Shorthand for current function

        // If the step is a callback step (requires a stop on-chain and a resumption after offchain computation) -
        // We break the recrusion.
        // Note that in the case of it being a callback, either function should handle emitting the request log (that is caught
        // by the backend), which would presumabley include the index of the step it was emitted in (So it can reenter the recrusion loop).
        if (executedFunc.is_callback) {
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
            runStep(childrenIndexes[i]);
        }
    }

    // Execute a reguler step (Internal)
    function _runStep(
        YCStep memory _step
    ) internal returns (bytes memory _ret, FunctionCall memory _calledFunc) {
        // Execute the step's function
        (_ret, _calledFunc) = runFunction(_step.step_function);
    }

    // Execute a conditional (Internal)
    function _runConditional(
        YCStep memory _step
    ) internal returns (uint256[] memory _children_to_ignore) {
        // Execute the determineCondition function - which executes each condition function, returns the index
        // of the child to execute fro the children's array
        (
            uint256 conditionChildrenIndex,
            bool foundTrueCondition
        ) = _determineCondition(_step.conditions);

        // Children indexes shorthand (accessed 3 times)
        uint256[] memory children_indexes = _step.children_indexes;

        // Looping over each one of the children - If no condition was true, we push em all.
        // Else, we push everyone but the condition that evaluated to true.
        if (!foundTrueCondition) _children_to_ignore = children_indexes;
        else
            for (uint256 j = 0; j < children_indexes.length; j++)
                if (children_indexes[j] != conditionChildrenIndex)
                    _children_to_ignore[j] = (children_indexes[j]);
    }

    /// @notice Receives a container of conditional steps (i.e steps that run a function which returns a boolean),
    // determines which one of them is the first one to turn out true,
    // and returns the index of it. If none are true, it returns false additionaly. The caller will execute the correct condition's
    // children container - or none at all.
    // @dev similar to the usual in-code if/elseif/else statements
    // @param _conditions_container The container (array) of encoded YCSteps - the conditions.
    // @return _should_exec_conditions
    // @return _container_to_run
    function _determineCondition(
        bytes[] memory _conditions
    ) internal returns (uint256 _container_to_run, bool _found_true_condition) {
        // Looping over each condition
        for (uint256 i = 0; i < _conditions.length; i++) {
            // Call the condition FunctionCall
            (bytes memory ret, FunctionCall memory calledFunc) = runFunction(
                _conditions[i]
            );

            // @notice
            // Breaking the loop if current iteration is a callback.
            // The functiin call is returned from the caller (runStep) function regardless,
            // but this is sufficient in order to ensure efficiency & no executions of un-wanted, potentially state-chaning functions.
            if (calledFunc.is_callback) break;

            // Decoding return value as a boolean
            _found_true_condition = abi.decode(ret, (bool));

            // @notice
            // If the condition is true, we return the index of it - Caller will execute it's children
            // (which will be now ignored when looping)
            if (_found_true_condition) {
                _container_to_run = i;
                break;
            }
        }
    }
}
