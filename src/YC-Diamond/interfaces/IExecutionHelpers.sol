// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "../../YC-Base.sol";

/**
 * @notice Contains various utility/generic methods that will be used, inherited / delegated to throughout Yieldchain's
 * contracts set.
 */
interface IExecutionHelpers is IYieldchainBase {
    function _executeFunc(FunctionCall memory) external returns (bytes memory);

    function getCalldata(
        string memory _function_signature,
        bytes[] memory _arguments
    ) external pure returns (bytes memory);

    function isFunctionCall(bytes memory) external pure returns (bool);

    function getArgValue(bytes memory) external returns (bytes memory);
}
