/**
 * Abstract contract should be inherited from in all tests,
 * provides variables for mainnet forks
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract Forks is Test {
    // ==================
    //     CONSTANTS
    // ==================
    uint256 public ARBITRUM;

    function setUp() public {
        ARBITRUM = vm.createFork("https://arb1.arbitrum.io/rpc");
    }

    constructor() {
        ARBITRUM = vm.createFork("https://arb1.arbitrum.io/rpc");
    }
}
