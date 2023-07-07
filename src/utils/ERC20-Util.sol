// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
/**
 * Utilities for ERC20 internal functions
 */

import {SafeERC20} from "../libs/SafeERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "../interfaces/IVault.sol";

contract ERC20Utils {
    using SafeERC20 for IERC20;

    // ===================
    //      ERRORS
    // ===================
    error InsufficientERC20Balance(uint256 requiredAmt, uint256 balanceOf);

    /**
     * Transfer from vault address to us, approve internally if needed
     * @param vault - The vault address
     * @param token - The token
     * @param amt - The amount
     */
    function _transferFromVault(
        address vault,
        IERC20 token,
        uint256 amt
    ) internal {
        _tryApproveSelf(vault, token, amt);
        token.transferFrom(vault, address(this), amt);
    }

    /**
     * Approve some token allowance (as the diamond) on a vault only if allownace is insufficient
     * @param vault - The vault address
     * @param token - The token
     * @param amt - The amount
     */
    function _tryApproveSelf(
        address vault,
        IERC20 token,
        uint256 amt
    ) internal {
        if (token.allowance(vault, address(this)) < amt)
            IVault(vault).approveDaddyDiamond(address(token), amt);
    }

    /**
     * Approve some token allownace on an external trusted contractr only if allowance is insufficient
     * @param token The token to approve on
     * @param target The contract to approve
     * @param amt The amount
     */
    function _tryApproveExternal(
        IERC20 token,
        address target,
        uint256 amt
    ) internal {
        if (token.allowance(address(this), target) < amt)
            token.approve(target, amt);
    }

    /**
     * Approve infinite tokens to an address if allowance is insufficient of some amount
     * @param token - The token to potentially approve
     * @param spender - The spender to check the allowance on
     * @param minAllowance - Minimum allowance it must ave
     */
    function _ensureSufficientAllownace(
        IERC20 token,
        address spender,
        uint256 minAllowance
    ) internal {
        if (token.allowance(address(this), spender) < minAllowance)
            token.approve(spender, type(uint256).max);
    }
}
