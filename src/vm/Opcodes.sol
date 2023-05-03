/**
 * A bunch of simple functions, reimplementing native opcodes or solidity features
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Opcodes {
    /**
     * self()
     * get own address
     * @return ownAddress
     */
    function self() public view returns (address ownAddress) {
        ownAddress = address(this);
    }

    /**
     * extractFirstWord()
     * Takes in a byte, extracts it's first 32 byte word
     */
    function extractFirstWord(
        bytes memory arg
    ) public pure returns (bytes memory firstWord) {
        assembly {
            firstWord := mload(add(arg, 0x20))
        }
    }
}
