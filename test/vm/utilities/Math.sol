/**
 * Math contract
 */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Math {
    function div(uint256 arg, uint256 divisor) public pure returns (uint256) {
        return arg / divisor;
    }
}
