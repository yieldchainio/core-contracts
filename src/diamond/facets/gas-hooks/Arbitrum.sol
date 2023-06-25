/**
 * Hook to get gas spent in arbi transaction on the L1 (not otherwise available through gasleft())
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IGasHook} from "./IGasHook.sol";

contract ArbitrumL1GasHook is IGasHook {
    function getGasLeft() external view returns (uint256 gasLeft) {
        
    }
}
