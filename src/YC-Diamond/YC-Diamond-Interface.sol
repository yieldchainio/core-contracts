// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IYieldchainDiamond {
    function getExecutor() external view returns (address);

    function getExternalFunction(string memory)
        external
        view
        returns (string memory);
}
