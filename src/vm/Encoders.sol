/**
 * NOT INHERITED BY THE VM,
 * SOLELY FOR UTILITY TESTING PURPOSES
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../types.sol";
import "./Constants.sol";

contract YCVMEncoders is Constants, YieldchainTypes {
    function encodeValueVar(
        bytes memory value
    ) public pure returns (bytes memory) {
        return bytes.concat(VALUE_VAR_FLAG, VALUE_VAR_FLAG, value);
    }

    function encodeRefValueVar(
        bytes memory value
    ) public pure returns (bytes memory) {
        return bytes.concat(REF_VAR_FLAG, REF_VAR_FLAG, value);
    }

    function encodeValueStaticCall(
        bytes memory callCommand
    ) public pure returns (bytes memory) {
        return
            bytes.concat(STATICCALL_COMMAND_FLAG, VALUE_VAR_FLAG, callCommand);
    }

    function encodeRefVarStaticCall(
        bytes memory callCommand
    ) public pure returns (bytes memory) {
        return bytes.concat(STATICCALL_COMMAND_FLAG, REF_VAR_FLAG, callCommand);
    }

    function encodeCall(
        bytes memory callCommand
    ) public pure returns (bytes memory) {
        return bytes.concat(CALL_COMMAND_FLAG, VALUE_VAR_FLAG, callCommand);
    }

    function encodeArray(
        bytes memory callCommand
    ) public pure returns (bytes memory) {}

    function encodeSelfCommand() public pure returns (bytes memory) {
        return
            bytes.concat(
                STATICCALL_COMMAND_FLAG,
                VALUE_VAR_FLAG,
                abi.encode(FunctionCall(address(0), new bytes[](0), "self()"))
            );
    }
}
