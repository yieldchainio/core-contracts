// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ArrayMethods {
    /**
     * @notice
     * @find
     * Find a number within an array of numbers
     */
    function findUint(uint256[] memory _arr, uint256 _item)
        internal
        pure
        returns (bool _isFound)
    {
        for (uint256 i = 0; i < _arr.length; i++) {
            // Cant be found if array is empty.
            if (_arr.length == 0) break;

            // Return true if found
            if (_arr[i] == _item) {
                _isFound = true;
                break;
            }
        }
    }
}
