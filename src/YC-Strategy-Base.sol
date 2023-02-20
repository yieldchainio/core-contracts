// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./YC-Base.sol";
import "./YC-Diamond/YC-Diamond-Interface.sol";

/**
 * @notice
 * @YCStrategyBase
 * A base contract that is used when creating Yielchain strategies through a factory.
 */
contract YCStrategyBase is IYieldchainBase {
    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    constructor(
        bytes[][] memory _steps_containers,
        bytes[] memory _base_steps_container,
        address[] memory _strategy_tokens_array,
        address[] memory _base_tokens_array
    ) {
        // Diamond address = msg.sender (i.e factory contract)
        YC_DIAMOND = msg.sender;

        // Call getExeuctor on the diamond to get the strategy's executor address (for modifier)
        EXECUTOR = IYieldchainDiamond(YC_DIAMOND).getExecutor();

        // Setting the strategy's steps.
        step_containers = _steps_containers;
    }

    // =============================================================
    //                          IMMUTABLES
    // =============================================================

    // Executor's address (executes strategies, approvals, fullfils, etc)
    address immutable EXECUTOR;

    // Diamond's address (executes internal functions as well, same as executor)
    address immutable YC_DIAMOND;

    /**
     * @notice
     * A 2D Array containing "Containers" Of Yieldchain Steps.
     * Each strategy has it's own set of steps, this is the actual strategy logic, encoded as bytes per step.
     */
    bytes[][] internal step_containers;

    // =============================================================
    //                          MODIFIERS
    // =============================================================
    modifier isExecutor() {
        require(msg.sender == EXECUTOR || msg.sender == YC_DIAMOND);
        _;
    }

    // =============================================================
    //                          FUNCTIONS
    // =============================================================

    /**
     * @notice
     * @RunStrategy
     * Runs the strategy given an index to start in (container-wise & inter-step-wise)
     */
    function runStrategy(uint256 _container_index, uint256 _step_index) public {
        for (
            _container_index;
            _container_index < step_containers.length;
            _container_index++
        ) {
            
        }
    }

    function runStep(YCStep memory _step) internal returns (uint256) {
        FunctionCall memory current_function = _step.step_function;
        string memory function_sig = IYieldchainDiamond(YC_DIAMOND)
            .getExternalFunction(current_function.signature);

        if (current_function.is_condition) {}
    }

    function executeCondition(FunctionCall memory _condition_function)
        internal
        view
        returns (uint256 _container_index)
    {
     
    }
}
