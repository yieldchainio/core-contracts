/**
 * @notice
 * Dummy "DEX" contract which will just return a 1:1 rate of tokens inputted for other tokens,
 * whilst being responsible of manually manipulating balances on them
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import {IERC20} from "../../../src/interfaces/IERC20.sol";

contract Dex is Test {
    mapping(IERC20 => mapping(IERC20 => uint256)) public swapRates;

    function swap(IERC20 from, IERC20 to, uint256 amount) public {
        uint256 rate = swapRates[from][to];
        if (rate == 0) rate = 1;

        uint256 outAmount = amount;
        uint256 inAmount = amount * rate;

        uint256 prevBalance = from.balanceOf(msg.sender);
        uint256 toPrevBalance = to.balanceOf(msg.sender);

        deal(address(from), msg.sender, prevBalance - outAmount);
        deal(address(to), msg.sender, toPrevBalance + inAmount);
    }
}
