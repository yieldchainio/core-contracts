// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../src/vm/Encoders.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract getSelfCommand is Test, YCVMEncoders {
    function setUp() external {}

    function testPenis() view external {
        console.logBytes(encodeSelfCommand());
    }
}
