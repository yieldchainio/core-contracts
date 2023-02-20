// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./YC-Base.sol";
import "./YC-Diamond/YC-Diamond.sol";
import "./YC-Helpers.sol";

/**
 * @notice
 * @YCStrategyBase
 * A base contract that is used when creating Yielchain strategies through a factory.
 */
contract YCStrategyBase is IYieldchainBase, YC_Utilities {
    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    constructor(
        bytes[] memory _steps // bytes[] memory _base_steps_container, // address[] memory _strategy_tokens_array, // address[] memory _base_tokens_array
    ) {
        // Diamond address = msg.sender (i.e factory contract)
        YC_DIAMOND_ADDRESS = msg.sender;

        // Call getExeuctor on the diamond to get the strategy's executor address (for modifier)
        YC_DIAMOND = YieldchainDiamond(payable(YC_DIAMOND_ADDRESS));

        // Setting the strategy's steps.
        steps = _steps;
    }

    // =============================================================
    //                          IMMUTABLES
    // =============================================================

    // Yieldchain's Diamond Contract Instance
    YieldchainDiamond immutable YC_DIAMOND;

    // Diamond's address (executes internal functions as well, same as executor)
    address immutable YC_DIAMOND_ADDRESS;

    /**
     * @notice
     * A 2D Array containing "Containers" Of Yieldchain Steps.
     * Each strategy has it's own set of steps, this is the actual strategy logic, encoded as bytes per step.
     */
    bytes[] internal steps;

    // =============================================================
    //                          MODIFIERS
    // =============================================================
    modifier isExecutor() {
        require(msg.sender == YC_DIAMOND_ADDRESS);
        _;
    }

    // =============================================================
    //                          FUNCTIONS
    // =============================================================

    // Execute a reguler step
    function _runStep(YCStep memory _step) internal {
        // Execute the step's function
        _executeFunc(_step.step_function);
    }

    // Execute a conditional
    function _runConditional(YCStep memory _step)
        internal
        returns (uint256[] memory _children_to_ignore)
    {
        // Execute the determineCondition function - which executes each condition function, returns the index
        // of the child to execute fro the children's array
        (
            uint256 conditionChildrenIndex,
            bool foundTrueCondition
        ) = determineCondition(_step.conditions);

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

    /**
     * @notice
     * @RunStrategy
     * Runs the strategy given an index to start in (container-wise & inter-step-wise)
     */
    function runStep(uint256 _step_index) public {
        // Decoding our current Step
        YCStep memory current_step = abi.decode(steps[_step_index], (YCStep));

        uint256[] memory children_to_ignore;

        // If not a conditional, run the step regularly
        if (!current_step.is_conditional) {
            _runStep(current_step);
        } else {
            children_to_ignore = _runConditional(current_step);
        }

        // Shorthand for children indexes
        uint256[] memory childrenIndexes = current_step.children_indexes;

        // Looping over each child,
        // If it should be ignored (from conditional), we ignore it -
        // else, we recruse the runStep function on it
        for (uint256 i = 0; i < childrenIndexes.length; i++) {
            // Continue if should be ignored
            if (findUint(children_to_ignore, childrenIndexes[i])) continue;

            // @Recruse
            runStep(childrenIndexes[i]);
        }
    }

    /// @notice Receives a container of conditional steps (i.e steps that run a function which returns a boolean),
    // determines which one of them is the first one to turn out true,
    // and returns the index of it. If none are true, it returns false additionaly. The caller will execute the correct condition's
    // children container - or none at all.
    // @dev similar to the usual in-code if/elseif/else statements
    // @param _conditions_container The container (array) of encoded YCSteps - the conditions.
    // @return _should_exec_conditions
    // @return _container_to_run
    function determineCondition(bytes[] memory _conditions)
        internal
        returns (uint256 _container_to_run, bool _found_true_condition)
    // TODO: Think of how you secure this so that it's not completely arbitrary (Similar to runStep... Classify all interfaced
    // TODO: opcodes in Diamond?)
    {
        // Looping over each condition
        for (uint256 i = 0; i < _conditions.length; i++) {
            // Decoding the condition
            FunctionCall memory current_condition_function = abi.decode(
                _conditions[i],
                (FunctionCall)
            );

            // @notice
            // executing the condition's function, using return value as a boolean to see if it is true
            _found_true_condition = abi.decode(
                _executeFunc(current_condition_function),
                (bool)
            );

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
