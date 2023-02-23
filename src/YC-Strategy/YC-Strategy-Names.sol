// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./YC-Strategy-State.sol";

abstract contract YieldchainStrategyNames is YieldchainStrategyState {
    // =============================================================
    //                 CONSTRUCTOR SUPER
    // =============================================================
    constructor(
        bytes[] memory _steps,
        bytes[] memory _base_strategy_steps,
        address[] memory _base_tokens,
        address[] memory _strategy_tokens,
        uint256 _automation_interval,
        address _deployer
    )
        YieldchainStrategyState(
            _steps,
            _base_strategy_steps,
            _base_tokens,
            _strategy_tokens,
            _automation_interval,
            _deployer
        )
    {}

    // =============================================================
    //                          ERRORS
    // =============================================================

    /**
     * Strategy-Related Errors
     */
    // When you attempt to withdraw an amount above your shares
    error InsufficientShares();

    // When you attempt to withdraw/deposit 0 shares
    error InvalidAmountZero();

    /**
     * Execution-Related Errors
     */
    error InvalidCallFlag();

    // =============================================================
    //                          MODIFIERS
    // =============================================================
    modifier isYieldchain() {
        require(msg.sender == YC_DIAMOND_ADDRESS);
        _;
    }

    // =============================================================
    //                          EVENTS
    // =============================================================

    // System-related events
    event RequestCallback(
        string indexed origin_function,
        uint256 indexed index,
        bytes[] indexed params
    );

    // Vault-related events
    event Deposit(address indexed depositer, uint256 indexed amount);
    event Withdraw(address indexed depositer, uint256 indexed amount);
}
