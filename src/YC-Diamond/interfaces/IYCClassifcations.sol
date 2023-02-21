// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IYCClassifications {
    /**
     * @notice
     * @classifyFunction
     * OnlyOwner!!
     * Adds a new function to the classification
     */
    function classifyFunction(string memory, string memory)
        external
        returns (bool);

    /**
     * @notice
     * @getExternalFunction
     * Returns
     */
    function getExternalFunction(string memory)
        external
        view
        returns (string memory);
}
