// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./interfaces/IArrayMethods.sol";
import "./interfaces/IDiamondCut.sol";
import "./interfaces/IDiamondLoupe.sol";
import "./interfaces/IYCClassifcations.sol";
import "./interfaces/IExecutionHelpers.sol";
import "./interfaces/IStrategyFactory.sol";

// Interface for our Diamond, Importing all facets' interfaces
interface IYieldchainDiamond is
    IArrayMethods,
    IDiamondCut,
    IDiamondLoupe,
    IYCClassifications,
    IExecutionHelpers
{
    function getExternalFunction(string memory)
        external
        view
        returns (string memory);

    function getCalldata(string memory, bytes[] memory)
        external
        pure
        returns (bytes memory);

    function decodeFunctionCall(bytes memory)
        external
        pure
        returns (FunctionCall memory, uint8);
}
