/**
 * LP adapter for minting gDAI using DAI
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../../storage/adapters/lp-adapter/clients/UniV2.sol";
import "../../../../storage/adapters/lp-adapter/LpAdapter.sol";
import {SafeERC20} from "../../../../../libs/SafeERC20.sol";
import {IERC20} from "../../../../../interfaces/IERC20.sol";
import "../../../../../libs/UniswapV2/Univ2Lib.sol";
import "../../../../../interfaces/IUniv2Router.sol";
import "../../../../../interfaces/IVault.sol";
import "../../../../../interfaces/IUniV2Factory.sol";

contract gDAILpAdapterFacet {
    // Libs
    using SafeERC20 for IERC20;
    using UniswapV2Library for *;

    /**
     * Add Liquidity To A gDAI-like client
     * @param client - LP Adapter compliant LPClient struct
     * @param unusedToken - All tokens are unused
     * @param unusedTokenB - Unused
     * @param tokenAmount - amount for the deposit token
     * @param unusedAmount - An unused amount parameter
     * @param encodedLockDuration - Encoded lock duration (or 0 if none)
     * @notice Collateral & LP tokens are encoded into the client itself
     */
    function addLiquiditygDAI(
        LPClient calldata client,
        address unusedToken,
        address unusedTokenB,
        uint256 tokenAmount,
        uint256 unusedAmount,
        bytes calldata encodedLockDuration
    ) external payable {
        uint256 lockDuration = abi.decode(encodedLockDuration, (uint256));
        (address mintToken, address lpToken) = abi.decode(
            client.extraData,
            (address, address)
        );

        uint256 lpTokenDebt;
        uint256 nftId;

        if (lockDuration == 0) _depositReguler(client, mintToken, tokenAmount);
    }

    /**
     * Make a reguler deposit into the vault, no lock
     * @param client - The client to use
     * @param mintToken - The token to use to mint the LP token (DAI for GNS)
     * @param tokenAmount - amount for the deposit token
     */
    function _depositReguler(
        LPClient calldata client,
        address mintToken,
        uint256 tokenAmount
    ) internal returns (uint256 lpTokenDebt) {}

    /**
     * Make a deposit with a lock
     * @param client - The client to use
     * @param mintToken - The token to use to mint the LP token (DAI for GNS)
     * @param tokenAmount - amount for the deposit token
     */
    function _depositWithLock(
        LPClient calldata client,
        address mintToken,
        uint256 tokenAmount
    ) internal {}

    /**
     * Withdraw DAI from the vault, give gDAI
     * @param client - LP Adapter compliant LPClient struct
     * @param tokenA - token #1
     * @param tokenB - token #2
     * @param lpAmount - Amount of LP tokens to remove
     */
    function removeLiquiditygDAI(
        LPClient calldata client,
        address tokenA,
        address tokenB,
        uint256 lpAmount
    ) external {
        IUniswapV2Router router = IUniswapV2Router(client.clientAddress);

        address factory = router.factory();

        IERC20 pair = IERC20(
            IUniswapV2Factory(factory).getPair(tokenA, tokenB)
        );

        if (IERC20(pair).allowance(msg.sender, address(this)) < lpAmount)
            IVault(msg.sender).approveDaddyDiamond(
                address(pair),
                type(uint256).max
            );

        // pair.safeTransferFrom(msg.sender, address(this), lpAmount);

        // Approve client for LP token (transferFrom from us)
        if (
            IERC20(pair).allowance(address(this), client.clientAddress) <
            lpAmount
        ) IERC20(pair).approve(client.clientAddress, type(uint256).max);

        bool includesNativeToken = tokenA == address(0) || tokenB == address(0);

        if (includesNativeToken) {
            address token = tokenA == address(0) ? tokenB : tokenA;

            router.removeLiquidityETH(
                token,
                lpAmount,
                0,
                0,
                msg.sender,
                type(uint256).max
            );

            return;
        }

        router.removeLiquidity(
            tokenA,
            tokenB,
            lpAmount,
            0,
            0,
            msg.sender,
            type(uint256).max
        );
    }

    // ==================
    //     GETTERS
    // ==================
    /**
     * Get an address' balance of an LP pair token
     * @param client The LP client to check on
     * @param tokenA First token of the pair (unsorted)
     * @param tokenB Second token of the pair(unsorted)
     * @param owner owner to check the balance of
     * @return ownerLpBalance
     */
    function balanceOfgDAiLP(
        LPClient calldata client,
        address tokenA,
        address tokenB,
        address owner
    ) external view returns (uint256 ownerLpBalance) {
        address factory = client.clientAddress;
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        ownerLpBalance = IERC20(pair).balanceOf(owner);
    }
}
