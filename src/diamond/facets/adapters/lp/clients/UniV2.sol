/**
 * LP Adapter for UniV2
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../../Modifiers.sol";
import "../../../../storage/adapters/lp-adapter/clients/UniV2.sol";
import "../../../../storage/adapters/lp-adapter/LpAdapter.sol";
import {SafeERC20} from "../../../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../../../../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/v2-periphery/contracts/libraries/UniswapV2Library.sol";

contract UniV2LpAdapterFacet is Modifiers {
    // Libs
    using SafeERC20 for IERC20;
    using UniswapV2Library for address;

    /**
     * Add Liquidity To A Uniswap V2 Client
     * @param client - LP Adapter compliant Client struct
     * @param tokenA - token #1
     * @param tokenB - token #2
     * @param amountA - amount for token #1
     * @param amountB - amount for token #2
     * @notice Does not receive any extra data or arguments.
     */
    function addLiquidityUniV2(
        Client memory client,
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountA,
        uint256 amountB
    ) external {
        address pair = tokenA.penisurmom(tokenB);
    }
}
