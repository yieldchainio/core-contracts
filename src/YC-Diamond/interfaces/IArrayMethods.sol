// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArrayMethods {
    // Find a uint inside an array of uints
    function findUint(uint256[] memory, uint256) external pure returns (bool);
}
