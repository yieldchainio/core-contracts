// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IStrategyFactory {
    function deployStrategy(
        bytes[] memory,
        bytes[] memory,
        address[] memory,
        address[] memory
    ) external returns (address);

    function runStrategyByID(uint256 _strategy_id) external;
}
