// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../storage/StrategiesStorage.sol";
import "./AutomationFacet.sol";

contract StrategyFactory {
    // Deploys a new strategy
    function deployStrategy(
        bytes[] memory _steps_arr,
        bytes[] memory _base_steps_arr,
        address[] memory _base_tokens_arr,
        address[] memory _tokens_arr,
        address[][] memory _tokens_related_addresses,
        uint256 _automation_interval,
        uint256 _fundingAmount,
        string memory name
    ) public returns (address _strategy_address) {
        // Getting strategies storage
        StrategiesStorage storage strategiesStorage = StrategiesStorageLib
            .getStrategiesStorage();

        // Generate Strategy ID
        // TODO: - is this reliable enough? What if creations of strategies clash?
        uint256 strategy_id = strategiesStorage.strategiesIDs.length;

        // Deploy the strategy
        YCStrategyBase current_strategy = new YCStrategyBase(
            _steps_arr,
            _base_steps_arr,
            _base_tokens_arr,
            _tokens_arr,
            _tokens_related_addresses,
            _automation_interval,
            address(this)
        );

        // Creating a struct instance of the current strategy
        IStrategy memory current_strategy_struct = IStrategy(
            name,
            strategy_id,
            0,
            _automation_interval,
            address(current_strategy),
            current_strategy
        );

        // Registering an automation upkeep
        current_strategy_struct.upkeepID = AutomationFacet(address(this))
            .registerAutomation(current_strategy_struct, _fundingAmount);

        // Pushing the strategy ID & assigning it to the strategy struct
        strategiesStorage.strategies[strategy_id] = current_strategy_struct;
        strategiesStorage.strategiesIDs.push(strategy_id);

        // Returning the strategy's address
        _strategy_address = address(current_strategy);
    }

    // Receives an ID, runs a strategy
    function runStrategyByID(uint256 _strategy_id) public {
        // Getting strategies storage
        StrategiesStorage storage strategiesStorage = StrategiesStorageLib
            .getStrategiesStorage();

        // Strategy Struct
        IStrategy memory current_strategy = strategiesStorage.strategies[
            _strategy_id
        ];

        // Run Strategy
        current_strategy.contract_instance.runStrategy();
    }
}
