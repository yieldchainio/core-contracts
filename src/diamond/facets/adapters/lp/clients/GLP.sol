/**
 * LP adapter for minting GLP using it's basket assets
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../../storage/adapters/lp-adapter/clients/UniV2.sol";
import "../../../../storage/adapters/lp-adapter/LpAdapter.sol";
import {SafeERC20} from "../../../../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../../../../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../../../../libs/UniswapV2/Univ2Lib.sol";
import "../../../../../interfaces/IUniv2Router.sol";
import "../../../../../interfaces/IVault.sol";
import "../../../../../interfaces/IUniV2Factory.sol";

contract GlpAdapterFacet {
    // Libs
    using SafeERC20 for IERC20;
    using UniswapV2Library for *;

    // ===================
    //      STRUCTS
    // ===================
    /**
     * Represents the extra data of the client
     * @param lpToken - The address of the end LP token to receive, which represents the basket of assets
     * @param transferrer - The address which we use to transfer these LP tokens.
     */
    struct GlpClientData {
        address lpToken;
        address transferrer;
    }

    // ===================
    //      FUNCTIONS
    // ===================
    /**
     * Add Liquidity To A GLP LPClient
     * @param client - LP Adapter compliant LPClient struct
     * @param mintToken - The token to use to mint GLP
     * @param unusedAddress - An unused address
     * @param tokenAmount - amount for token #1
     */
    function addLiquidityGLP(
        LPClient calldata client,
        address mintToken,
        address unusedAddress,
        uint256 tokenAmount
    ) external payable {
        GlpClientData memory clientData = abi.decode(
            client.extraData,
            (GlpClientData)
        );


        
    }

    /**
     * Remove liquidity
     * @param client - LP Adapter compliant LPClient struct
     * @param tokenA - token #1
     * @param tokenB - token #2
     * @param lpAmount - Amount of LP tokens to remove
     */
    function removeLiquidityUniV2(
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

        pair.safeTransferFrom(msg.sender, address(this), lpAmount);

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
     * @param unusedTokenA unused tokenA param
     * @param unusedTokenB unused tokenB param
     * @param owner owner to check the balance of
     * @return ownerLpBalance
     */
    function balanceOfGLP(
        LPClient calldata client,
        address unusedTokenA,
        address unusedTokenB,
        address owner
    ) external view returns (uint256 ownerLpBalance) {
        return 5;
    }
}
