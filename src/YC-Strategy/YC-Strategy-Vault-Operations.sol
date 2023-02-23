// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./YC-Strategy-Names.sol";

abstract contract YieldchainStrategyVaultOps is YieldchainStrategyNames {
     // =============================================================
    //                 CONSTRUCTOR SUPER
    // =============================================================
    constructor( bytes[] memory _steps,
        bytes[] memory _base_strategy_steps,
        address[] memory _base_tokens,
        address[] memory _strategy_tokens,
        uint256 _automation_interval,
        address _deployer) YieldchainStrategyNames(_steps, _base_strategy_steps, _base_tokens, _strategy_tokens, _automation_interval, _deployer) {

    }

    // =============================================================
    //                   VAULT OPERATIONS FUNCTIONS
    // =============================================================
    function deposit(uint256 amount) public {}

    function _depositFullfill(bytes memory _calldata) external isYieldchain {}

    function withdraw(uint256 amount) public {}

    function _withdrawFullfill(bytes memory _calldata) external isYieldchain {}
}
