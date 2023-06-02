/**
 * Tests for the UniV2 LP client
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../../../Deployment.t.sol";
import "../../../../../../src/diamond/facets/adapters/lp/ClientsManager.sol";
import "../../../../../../src/diamond/facets/adapters/lp/LpAdapter.sol";
import "../../../../../vault/main/Base.sol";
import {GlpAdapterFacet, GlpClientData} from "../../../../../../src/diamond/facets/adapters/lp/clients/Glp.sol";
import {IGmxVault} from "../../../../../../src/interfaces/IGlp.sol";

contract LpClientGlpTest is DiamondTest {
    // =================
    //     GLOBALS
    // =================

    Vault vaultContract;

    address[] availableTokens = [
        address(0),
        0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f,
        0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8,
        0xf97f4df75117a78c1A5a0DBb814Af92458539FB4,
        0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0,
        0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
        0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A,
        0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F,
        0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1
    ];

    address glpRouter = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
    GlpClientData gmxClientData =
        GlpClientData(
            0x1aDDD80E6039594eE970E5872D247bf0414C8903,
            0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf,
            0x489ee077994B6658eAfA855C308275EAd8097C4A
        );

    address[] glpClients = [glpRouter];
    bytes[] glpClientsDatas = [abi.encode(gmxClientData)];

    /**
     * Setup == Classificate it on the Lp Adapter Facet as an LP client
     */
    function setUp() public virtual override {
        super.setUp();

        // Classificate all glp clients for testing
        for (uint256 i; i < glpClients.length; i++) {
            LpAdapterFacet(address(diamond)).addClient(
                keccak256(abi.encode(glpClients[i])),
                LPClient(
                    GlpAdapterFacet.addLiquidityGLP.selector,
                    GlpAdapterFacet.removeLiquidityGLP.selector,
                    GlpAdapterFacet.harvestGlpRewards.selector,
                    GlpAdapterFacet.balanceOfGLP.selector,
                    glpClients[i],
                    abi.encode(abi.decode(glpClientsDatas[i], (GlpClientData)))
                )
            );
        }
        // Get the args for deployment and deploy the vault
        (
            bytes[] memory SEED_STEPS,
            bytes[] memory STEPS,
            bytes[] memory UPROOT_STEPS,
            address[2][] memory approvalPairs,
            IERC20 depositToken,
            bool isPublic,

        ) = new BaseStrategy().getVaultArgs();

        // Assign to vault state
        vaultContract = FactoryFacet(address(diamond)).createVault(
            SEED_STEPS,
            STEPS,
            UPROOT_STEPS,
            approvalPairs,
            new Trigger[](0),
            IERC20(address(depositToken)),
            isPublic
        );
    }

    /**
     * Test minting GLP w/ IERC20's
     */
    function testMintingGlpWithErc20(
        uint256 tokenInAmount,
        uint256 tokenIdx
    ) public returns (uint256[2][] memory mintTokensDeposited) {
        vm.assume(tokenIdx < availableTokens.length && tokenIdx > 1);
        address token = availableTokens[tokenIdx];
        uint256 tokenDecimals = IERC20(token).decimals();
        tokenInAmount = bound(
            tokenInAmount,
            1 * 10 ** tokenDecimals,
            IERC20(token).totalSupply()
        );

        mintTokensDeposited = new uint256[2][](glpClients.length);

        vm.startPrank(address(vaultContract));

        for (uint256 i; i < glpClients.length; i++) {
            GlpClientData memory clientData = abi.decode(
                glpClientsDatas[i],
                (GlpClientData)
            );

            uint256 clientMaxTokenReserveInVault = _getInputTokenUpperbound(
                IERC20(token),
                clientData.vault
            );

            console.log(
                "Client Max Token Reserve In vaukt",
                clientMaxTokenReserveInVault
            );

            if (tokenInAmount > clientMaxTokenReserveInVault)
                if (clientMaxTokenReserveInVault < 1 * 10 ** tokenDecimals)
                    tokenInAmount = clientMaxTokenReserveInVault / 2;
                else
                    tokenInAmount = bound(
                        tokenInAmount,
                        1 * 10 ** tokenDecimals,
                        clientMaxTokenReserveInVault
                    );

            deal(token, address(vaultContract), tokenInAmount);

            uint256 preLpTokenBalance = IERC20(clientData.lpToken).balanceOf(
                address(vaultContract)
            );

            LpAdapterFacet(address(diamond)).addLiquidity(
                token,
                address(0),
                tokenInAmount,
                0,
                keccak256(abi.encode(glpClients[i])),
                new bytes[](0)
            );

            assertEq(
                IERC20(token).balanceOf(address(vaultContract)),
                0,
                "Added Liquidity, But ERC20 Tokens Remain"
            );
            assertTrue(
                IERC20(clientData.lpToken).balanceOf(address(vaultContract)) >
                    preLpTokenBalance,
                "Added Liquidity, But Didnt Get Any Additional GLP Tokens"
            );

            mintTokensDeposited[i][1] =
                IERC20(clientData.lpToken).balanceOf(address(vaultContract)) -
                preLpTokenBalance;

            mintTokensDeposited[i][0] = tokenInAmount;

            deal(token, address(vaultContract), 0);
            // deal(clientData.lpToken, address(vaultContract), 0);
        }

        vm.stopPrank();
    }

    /**
     * Test removing liquidity
     */
    function testRemoveGlpLiquidityWithERC20(
        uint256 tokenInAmount,
        uint256 tokenIdx
    ) public {
        uint256[2][] memory tokensDepositedPerClient = testMintingGlpWithErc20(
            tokenInAmount,
            tokenIdx
        );

        address token = availableTokens[tokenIdx];

        vm.startPrank(address(vaultContract));

        for (uint256 i; i < tokensDepositedPerClient.length; i++) {
            GlpClientData memory clientData = abi.decode(
                glpClientsDatas[i],
                (GlpClientData)
            );

            uint256 lpTokensGotFromMinting = tokensDepositedPerClient[i][1];
            uint256 mintTokenDepositedOriginally = tokensDepositedPerClient[i][
                0
            ];

            uint256 preMintTokenBalance = IERC20(token).balanceOf(
                address(vaultContract)
            );
            uint256 preLpTokenBalance = IERC20(clientData.lpToken).balanceOf(
                address(vaultContract)
            );

            LpAdapterFacet(address(diamond)).removeLiquidity(
                token,
                address(0),
                lpTokensGotFromMinting,
                keccak256(abi.encode(glpClients[i])),
                new bytes[](0)
            );

            assertApproxEqAbs(
                IERC20(token).balanceOf(address(vaultContract)),
                preMintTokenBalance + mintTokenDepositedOriginally,
                mintTokenDepositedOriginally / 50,
                "Removed Liquidity, But Mint Token Balance Mismatch"
            );

            assertApproxEqAbs(
                IERC20(clientData.lpToken).balanceOf(address(vaultContract)),
                preLpTokenBalance - lpTokensGotFromMinting,
                lpTokensGotFromMinting / 50,
                "Removed Liquidity, But Mint Token Balance Mismatch"
            );
        }

        vm.stopPrank();
    }

    /**
     * Test minting GLP w/ native ETH
     */
    // function testMintingGlpWithNativeEth(uint256 ethInAmount) public {
    //     ethInAmount = bound(ethInAmount, 1 ether / 1000, 1000000 ether);

    //     vm.startPrank(address(vaultContract));

    //     for (uint256 i; i < glpClients.length; i++) {
    //         GlpClientData memory clientData = abi.decode(
    //             glpClientsDatas[i],
    //             (GlpClientData)
    //         );

    //         uint256 clientMaxEthReserveInVault = _getInputEthUpperbound(
    //             clientData.vault
    //         );

    //         console.log(
    //             "Client Max Token Reserve In vaukt",
    //             clientMaxEthReserveInVault
    //         );

    //         if (ethInAmount > clientMaxEthReserveInVault)
    //             if (clientMaxEthReserveInVault < 1 * 10 ** 18)
    //                 ethInAmount = clientMaxEthReserveInVault / 2;
    //             else
    //                 ethInAmount = bound(ethInAmount, 1 * 10 ** 18, ethInAmount);

    //         deal(address(vaultContract), ethInAmount);

    //         uint256 preLpTokenBalance = IERC20(clientData.lpToken).balanceOf(
    //             address(vaultContract)
    //         );

    //         LpAdapterFacet(address(diamond)).addLiquidity{value: ethInAmount}(
    //             address(0),
    //             address(0),
    //             ethInAmount,
    //             0,
    //             keccak256(abi.encode(glpClients[i])),
    //             new bytes[](0)
    //         );

    //         assertEq(
    //             address(vaultContract).balance,
    //             0,
    //             "Added Liquidity, But ERC20 Tokens Remain"
    //         );

    //         assertTrue(
    //             IERC20(clientData.lpToken).balanceOf(address(vaultContract)) >
    //                 preLpTokenBalance,
    //             "Added Liquidity, But Didnt Get Any Additional GLP Tokens"
    //         );

    //         deal(address(vaultContract), 0);
    //         // deal(clientData.lpToken, address(vaultContract), 0);
    //     }

    //     vm.stopPrank();
    // }

    /**
     * Internal function to get the upper bound of a fuzz input token when minting GLP,
     * in order to not go above max usdg amts
     * @param token - The token
     * @param vault - The vault address
     * @return maxAmt - The max amount
     */
    function _getInputTokenUpperbound(
        IERC20 token,
        address vault
    ) internal view returns (uint256 maxAmt) {
        uint256 tokenDecimals = token.decimals();

        uint256 usdDecimals = 30;

        uint256 usdgDecimals = IERC20(IGmxVault(vault).usdg()).decimals();

        uint256 decimalsToDivideBy = usdDecimals -
            (usdgDecimals - tokenDecimals);

        uint256 vaultUsdgCapForToken = IGmxVault(vault).maxUsdgAmounts(
            address(token)
        );

        uint256 vaultCurrentUsdgReservesForToken = IGmxVault(vault).usdgAmounts(
            address(token)
        );

        uint256 usdgDeltaLeftForCap = vaultUsdgCapForToken -
            vaultCurrentUsdgReservesForToken;

        uint256 singleTokenToUsdgQuote = IGmxVault(vault).getMinPrice(
            address(token)
        );
        // Maximum amount of tokens we can deposit is:
        // max usdg delta (18 decimals) / (price of single token adjusted for decimals)
        uint256 maxTokensAmt = usdgDeltaLeftForCap /
            (singleTokenToUsdgQuote / 10 ** decimalsToDivideBy);

        // We just shave off an additional 1% to account for any fees
        uint256 feesPercentage = 2;

        uint256 safeMathDelta = 100;

        return ((maxTokensAmt / (feesPercentage * safeMathDelta)) *
            (safeMathDelta - feesPercentage));
    }

    function _getInputEthUpperbound(
        address vault
    ) internal view returns (uint256 maxAmt) {
        uint256 ethDecimals = 18;

        uint256 usdDecimals = 30;

        uint256 usdgDecimals = IERC20(IGmxVault(vault).usdg()).decimals();

        uint256 decimalsToDivideBy = usdDecimals - (usdgDecimals - ethDecimals);

        uint256 vaultUsdgCapForToken = IGmxVault(vault).maxUsdgAmounts(
            address(0)
        );

        uint256 vaultCurrentUsdgReservesForToken = IGmxVault(vault).usdgAmounts(
            address(0)
        );

        uint256 usdgDeltaLeftForCap = vaultUsdgCapForToken -
            vaultCurrentUsdgReservesForToken;

        uint256 singleTokenToUsdgQuote = IGmxVault(vault).getMinPrice(
            address(0)
        );
        // Maximum amount of tokens we can deposit is:
        // max usdg delta (18 decimals) / (price of single token adjusted for decimals)
        uint256 maxTokensAmt = usdgDeltaLeftForCap /
            (singleTokenToUsdgQuote / 10 ** decimalsToDivideBy);

        // We just shave off an additional 1% to account for any fees
        uint256 feesPercentage = 2;

        uint256 safeMathDelta = 100;

        return ((maxTokensAmt / (feesPercentage * safeMathDelta)) *
            (safeMathDelta - feesPercentage));
    }
}
