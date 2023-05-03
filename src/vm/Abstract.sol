/**
 * An Abstract Contract Interface for the ycVM
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../Types.sol";

abstract contract IYCVM is YieldchainTypes {
    function _runFunction(
        bytes memory command
    ) internal virtual returns (bytes memory);

    function _parseDynamicVar(
        bytes memory _arg
    ) internal pure virtual returns (bytes memory);

    function _separateCommand(
        bytes memory ycCommand
    )
        internal
        pure
        virtual
        returns (
            bytes memory nakedCommand,
            bytes1 typeflag,
            bytes1 retTypeflag
        );

    function _separateAndRemovePrependedBytes(
        bytes memory chunck,
        uint256 bytesToRemove
    )
        internal
        pure
        virtual
        returns (bytes memory parsedChunck, bytes memory junk);

    function _removePrependedBytes(
        bytes memory chunck,
        uint256 bytesToRemove
    ) internal pure virtual returns (bytes memory parsedChunck);

    function self() public view virtual returns (address ownAddress);

    function _execFunctionCall(
        FunctionCall memory func,
        bytes1 typeflag
    ) internal virtual returns (bytes memory returnVal);

    function _buildCalldata(
        FunctionCall memory _func
    ) internal virtual returns (bytes memory constructedCalldata);

    function _separateAndGetCommandValue(
        bytes memory command
    ) internal virtual returns (bytes memory interpretedValue, bytes1 typeflag);

    function _getCommandValue(
        bytes memory commandVariable,
        bytes1 typeflag,
        bytes1 retTypeflag
    )
        internal
        virtual
        returns (bytes memory parsedPrimitiveValue, bytes1 typeFlag);

    function interpretCommandsAndEncodeChunck(
        bytes[] memory ycCommands
    ) internal virtual returns (bytes memory interpretedEncodedChunck);

    function interpretCommandsArr(
        bytes memory ycCommandsArr,
        bytes1 typeflag
    ) internal virtual returns (bytes memory interpretedArray);
}
