// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "../../YC-Types.sol";

/**
 * @notice Contains various utility/generic methods that will be used, inherited / delegated to throughout Yieldchain's
 * contracts set.
 */
interface IExecutionHelpers is YieldchainTypes {
    function prepareFunctionCall(bytes memory)
        external
        view
        returns (FunctionCall memory, uint8);

    function getCalldata(string memory, bytes[] memory)
        external
        pure
        returns (bytes memory);

    function getArgValue(bytes memory) external returns (bytes memory);

    function seperateYCVariable(bytes memory)
        external
        pure
        returns (bytes memory, uint8);

    function getVarFlag(bytes memory) external pure returns (uint8);

    function removeVarFlag(bytes memory) external pure returns (bytes memory);
}
