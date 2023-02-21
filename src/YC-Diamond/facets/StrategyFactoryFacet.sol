// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../YC-Strategy-Base.sol";

contract StrategyFactory {
    YCStrategyBase[] strategies;

    function deployStrategy(
        bytes[] memory _steps_arr,
        bytes[] memory _base_steps_arr,
        address[] memory _base_tokens_arr,
        address[] memory _tokens_arr
    ) external returns (address _strategy_address) {
        YCStrategyBase current_strategy = new YCStrategyBase(
            _steps_arr,
            _base_steps_arr,
            _base_tokens_arr,
            _tokens_arr,
            address(this)
        );
        strategies.push(current_strategy);
        _strategy_address = address(current_strategy);
    }
}
