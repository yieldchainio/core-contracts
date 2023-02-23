// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../YC-Diamond/YC-Diamond-Interface.sol";

contract YieldchainStrategyState {
    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(
        bytes[] memory _steps,
        bytes[] memory _base_strategy_steps,
        address[] memory _base_tokens,
        address[] memory _strategy_tokens,
        uint256 _automation_interval,
        address _deployer
    ) {
        // Diamond address = msg.sender (i.e factory contract)
        YC_DIAMOND_ADDRESS = _deployer;

        // Call getExeuctor on the diamond to get the strategy's executor address (for modifier)
        YC_DIAMOND = IYieldchainDiamond(payable(YC_DIAMOND_ADDRESS));

        // Setting the strategy's steps.
        STEPS = _steps;

        // Setting strategy's related tokens
        tokens = _strategy_tokens;

        // Setting strategy's base steps (triggered on deposit)
        BASE_STEPS = _base_strategy_steps;

        // Setting strategy's base tokens (swap to on deposit, before triggering base steps)
        BASE_TOKENS = _base_tokens;

        // Setting automatio interval
        AUTOMATION_INTERVAL = _automation_interval;

        // Last execution == NOW
        lastExecution = block.timestamp;
    }

    // =============================================================
    //                          IMMUTABLES
    // =============================================================

    // Yieldchain's Diamond Contract Instance
    IYieldchainDiamond immutable YC_DIAMOND;

    // Diamond's address (executes internal functions as well, same as executor)
    address immutable YC_DIAMOND_ADDRESS;

    /**
     * @notice
     * An Array containing Yieldchain Steps of the strategy.
     * Each strategy has it's own set of steps, this is the actual strategy logic, encoded as bytes per step.
     */
    bytes[] internal STEPS;

    // @notice Just as above, for the base steps.
    bytes[] internal BASE_STEPS;

    // Base tokens (multi-swap on deposit)
    address[] internal BASE_TOKENS;

    // The interval that determines how often the strategy automation should run
    uint256 immutable AUTOMATION_INTERVAL;

    // =============================================================
    //                   VAULT-RELATED STORAGE
    // =============================================================

    // Total vault shares (1 deposit token == 1 share)
    uint256 public totalShares;

    // Mapping user addresses => shares balances
    mapping(address => uint256) public balances;

    // All ERC20 tokens relating to the strategy
    address[] public tokens;

    // @notice Strategy LOCK - when locked, deposits/withdrawls are queued offchain
    bool locked;

    // =============================================================
    //                      AUTOMATION STORAGE
    // =============================================================

    // Last timestamp in which the strategy executed
    uint256 lastExecution;
}
