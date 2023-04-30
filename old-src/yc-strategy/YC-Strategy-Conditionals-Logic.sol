// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../YC-Diamond/YC-Diamond-Interface.sol";
import "./YC-Strategy-Execution-Helpers.sol";
import "./YC-Strategy-Types.sol";

/**
 * @notice
 * The logical functions for running YC conditionals
 */

contract YieldchainStrategyConditionals is
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

    // Execute a conditional (Internal)
    function _runConditional(
        YCStep memory _step,
        uint256 _stepIndex
    )
        internal
        returns (uint256[] memory _children_to_ignore, bool _isCallback)
    {
        // Execute the determineCondition function - which executes each condition function, returns the index
        // of the child to execute fro the children's array
        uint256 conditionChildrenIndex;
        bool foundTrueCondition;
        (
            conditionChildrenIndex,
            foundTrueCondition,
            _isCallback
        ) = _determineCondition(_step.conditions);

        // @notice
        // If we found a callback condition, we emit a request for offchain conditional - Using all of the conditions.
        // The offchain conditional action will iterate over them individually and also simulate our condition,
        // Potentially with offchain data. Once it determines the condition, it will re-enter the runStep
        // function as our current (parent) step, with a boolean indiciating it is a fullfill,
        // And an array of children to ignore - which we will use instead of the reguler one.
        if (_isCallback) {
            emit RequestCallback(
                "_runConditional",
                "determineConditions",
                _stepIndex,
                _step.conditions
            );
        }
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
    // @return _step_to_run
    function _determineCondition(
        bytes[] memory _conditions
    )
        internal
        returns (
            uint256 _step_to_run,
            bool _found_true_condition,
            bool _waitForCallback
        )
    {
        // Looping over each condition
        for (uint256 i = 0; i < _conditions.length; i++) {
            // Call the condition FunctionCall
            (bytes memory ret, FunctionCall memory calledFunc) = _runFunction(
                _conditions[i]
            );

            // @notice
            // Breaking the loop if current iteration is a callback.
            // The functiin call is returned from the caller (runStep) function regardless,
            // but this is sufficient in order to ensure efficiency & no executions of un-wanted, potentially state-chaning functions.
            if (calledFunc.is_callback) {
                // We indiciate that we should break the condition determination and have the offchain fullfill it
                _waitForCallback = true;
                break;
            }

            // Decoding return value as a boolean
            _found_true_condition = abi.decode(ret, (bool));

            // @notice
            // If the condition is true, we return the index of it - Caller will execute it's children
            // (which will be now ignored when looping)
            if (_found_true_condition) {
                _step_to_run = i;
                break;
            }
        }
    }
}
