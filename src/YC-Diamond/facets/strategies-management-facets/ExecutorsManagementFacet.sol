// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../storage/StrategiesStorage.sol";
import "../../storage/ExecutorsStorage.sol";
import "../base-diamond-facets/OwnershipFacet.sol";

/***
 * @notice
 * A facet that orchestrates the management of Yieldchain's executors.
 * We can whitelist/remove executors that are allowed to call strategies.
 * Executors call functions directly on this facet to interact with the strategies
 */

contract ExecutorsFacet is OwnershipFacet {
    // =======================
    //        MODIFIERS
    // =======================
    // Allows only a whitelisted Yieldchain executor to execute a function
    modifier isExecutor() {
        ExecutorsStorage storage executorsStorage = ExecutorsStorageLib
            .getExecutorsStorage();
        bool _isExecutor;
        for (uint256 i = 0; i < executorsStorage.executors.length; i++)
            if (executorsStorage.executors[i] == msg.sender) {
                _isExecutor = true;
                break;
            }
        require(_isExecutor, "Must Be a YC Executor To Run This Function");
        _;
    }

    // ==============================================
    //             EXECUTOR FUNCTIONS
    // ==============================================
    /**
     * @notice
     * Called by executors to runStep on strategies via their IDs
     */
    function runStrategyStep(
        uint256 _strategy_id,
        uint256 _step_index
    ) external isExecutor {
        // Retreiving storage ref of strategies
        StrategiesStorage storage strategiesStorage = StrategiesStorageLib
            .getStrategiesStorage();

        // Current Strategy
        IStrategy memory currentStrategy = strategiesStorage.strategies[
            _strategy_id
        ];

        // Sufficient check to make sure the strategy exists
        require(
            currentStrategy.contract_address != address(0),
            "Strategy Attempted To Execute Does Not Exist"
        );

        // Run the step with the step index
        currentStrategy.contract_instance.runStep(_step_index);
    }

    // ==============================================
    //             MANAGEMENT FUNCTIONS
    // ==============================================
    /**
     * @notice
     * addExecutor
     */
    function addExecutor(address _executorAddress) external isOwner {
        ExecutorsStorage storage executorsStorage = ExecutorsStorageLib
            .getExecutorsStorage();

        executorsStorage.executors.push(_executorAddress);
    }

    /**
     * @notice
     * removeExecutor
     */
    function removeExecutor(address _executorAddress) external isOwner {
        // Initiating storage ref
        ExecutorsStorage storage executorsStorage = ExecutorsStorageLib
            .getExecutorsStorage();

        // Shorthand for executors arr (accessed a bunch of times)
        address[] storage executorsArr = executorsStorage.executors;

        // Finding the index
        uint256 index;
        for (index; index < executorsArr.length; index++) {
            if (executorsArr[index] == _executorAddress) break;
        }

        // Must retain the executor at index 0
        require(index > 0, "Cannot remove the first executor");

        // No need to do storage mod if we're just removing the last item regardless
        if (index != executorsArr.length - 1) {
            // Reassigning the last executor to the index
            executorsArr[index] = executorsArr[executorsArr.length - 1];
        }

        // Removing the last item (Now a duplicate since we copied it to the index)
        executorsArr.pop();
    }
}
