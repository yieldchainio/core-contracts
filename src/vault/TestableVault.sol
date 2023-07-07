// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Vault.sol";
import "forge-std/Test.sol";

contract TestableVault is Test {
    function delegateCall(
        address target,
        bytes memory callData
    ) public returns (bool success, bytes memory res) {
        console.log("Delegate Calling...", target);

        (success, res) = target.delegatecall(callData);
    }

    function approveDaddyDiamond(address token, uint256 amt) external {
        // Cheaper to read msg.sender than YC_DIAMOND, we know it's only the Diamond already here
        IERC20(token).approve(msg.sender, amt);
    }
}
