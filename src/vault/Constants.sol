/**
 * Utility constants for the vault
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract VaultConstants {
    /**
     * Constant memory location for where user's withdraw shares are stored in memory
     */
    uint256 internal constant WITHDRAW_SHARES_MEM_LOCATION = 0x2c0;
    /**
     * Constant memory location for where user's deposit amount is stored in memory
     */
    uint256 internal constant DEPOSIT_AMT_MEM_LOCATION = 0x2c0;
}
