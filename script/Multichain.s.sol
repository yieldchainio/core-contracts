/**
 * All supported chains
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Script.sol";

contract Chains is Script {
    string[] internal CHAINS = [vm.envString("ARBITRUM_RPC_URL")];
}
