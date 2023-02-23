// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./YC-Strategy-Names.sol";
import "../YC-Diamond/interfaces/IERC20.sol";

abstract contract YieldchainStrategyVaultOps is YieldchainStrategyNames {
    // =============================================================
    //                 CONSTRUCTOR SUPER
    // =============================================================
    constructor(
        bytes[] memory _steps,
        bytes[] memory _base_strategy_steps,
        address[] memory _base_tokens,
        address[] memory _strategy_tokens,
        address[][] memory _tokens_related_addresses,
        uint256 _automation_interval,
        address _deployer
    )
        // Super()
        YieldchainStrategyNames(
            _steps,
            _base_strategy_steps,
            _base_tokens,
            _strategy_tokens,
            _automation_interval,
            _deployer
        )
    {
        // Approve all tokens and their related addresses
        approveAllTokens(_strategy_tokens, _tokens_related_addresses);
    }

    // =============================================================
    //                   VAULT OPERATIONS FUNCTIONS
    // =============================================================
    function deposit(uint256 amount) public {}

    function _depositFullfill(bytes memory _calldata) external isYieldchain {}

    function withdraw(uint256 amount) public {}

    function _withdrawFullfill(bytes memory _calldata) external isYieldchain {}

    // =============================================================
    //                 ADDITIONAL UTILITY OPERATIONS
    // =============================================================
    function approveAllTokens(
        address[] memory _tokens,
        address[][] memory _related_addresses
    ) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address[] memory relatedAddresses = _related_addresses[i];
            for (uint256 j = 0; j < relatedAddresses.length; j++) {
                IERC20(_tokens[i]).approve(relatedAddresses[j], 2 ** 256 - 1);
            }
        }
    }

    // Internal approve, only called by Yieldchain diamond if ever needed
    function internalApproval(
        address _token,
        address _spender
    ) external isYieldchain {
        IERC20(_token).approve(_spender, 2 ** 256 - 1);
    }
}
