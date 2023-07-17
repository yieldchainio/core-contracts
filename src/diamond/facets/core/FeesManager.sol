/**
 * Fees Manager contract
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AccessControlled} from "@diamond/AccessControlled.sol";
import {BusinessStorageLib} from "@diamond-storage/Business.sol";
import {SafeERC20} from "@libs/SafeERC20.sol";
import {IERC20} from "@ifaces/IERC20.sol";

contract FeesManager is AccessControlled {
    // ================
    //       LIBS
    // ================
    using SafeERC20 for IERC20;

    // ================
    //      ERRORS
    // ================
    error NotEnoughNativeValue(uint256 expected, uint256 provided);

    // ================
    //      METHODS
    // ================
    /**
     * Receive a fee
     * @param token - ERC20 token (or 0x00 for native ETH) to accept
     * @param amount - The amount to take from the caller
     */
    function sendFee(address token, uint256 amount) external payable {
        address treasury = BusinessStorageLib.retreive().treasury;

        if (token == address(0)) {
            if (msg.value != amount)
                revert NotEnoughNativeValue(amount, msg.value);
            payable(treasury).transfer(msg.value);
            return;
        }

        IERC20(token).safeTransferFrom(msg.sender, treasury, amount);
    }
}
