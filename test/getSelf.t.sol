// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../src/vm/Encoders.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./vault/utilities/Encoders.sol";

contract getSelfCommand is Test, YCVMEncoders, UtilityEncoder {
    function setUp() external {}

    function testPenis() external view {
        // console.logBytes(encodeSelfCommand());
        // console.logBytes(encodeWithdrawSharesGetter());
        bytes[] memory mloadArgs = new bytes[](1);
        mloadArgs[
            0
        ] = hex"00000000000000000000000000000000000000000000000000000000000000000140";
        FunctionCall memory func = FunctionCall(address(1), mloadArgs, "MLOAD");
        bytes32 ptr;
        bytes memory ptrRaw = func.args[0];
        assembly {
            ptr := mload(add(ptrRaw, 34))
        }
        console.logBytes32(ptr);
    }
}
