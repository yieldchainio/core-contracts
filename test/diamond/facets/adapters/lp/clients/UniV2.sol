/**
 * Tests for the UniV2 LP client
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../../../Deployment.t.sol";
import "../../../../../../src/diamond/facets/adapters/lp/ClientsManager.sol";
import "../../../../../../src/diamond/facets/adapters/lp/LpAdapter.sol";
import "../../../../../../src/diamond/facets/adapters/lp/clients/UniV2.sol";
import "../../../../../vault/main/Base.sol";
import "../../../../../../src/interfaces/IUniV2Factory.sol";

contract LpClientUniV2Test is DiamondTest {
    using UniswapV2Library for *;

    // =================
    //     GLOBALS
    // =================
    address zyberSwapRouter = 0x16e71B13fE6079B4312063F7E81F76d165Ad32Ad;
    address sushiswap = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address camelot = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;
    address fraxswap = 0xCAAaB0A72f781B92bA63Af27477aA46aB8F653E7;
    address apeswap = 0x7d13268144adcdbEBDf94F654085CC15502849Ff;
    address arbidex = 0x7238FB45146BD8FcB2c463Dc119A53494be57Aac;
    address arbswap = 0xD01319f4b65b79124549dE409D36F25e04B3e551;

    address[] uniV2Clients = [
        zyberSwapRouter,
        sushiswap,
        camelot,
        fraxswap,
        apeswap,
        arbidex,
        arbswap
    ];

    address WETH_TOKEN = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address USDC_TOKEN = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address tokenA = WETH_TOKEN;
    address tokenB = USDC_TOKEN;

    Vault vaultContract;

    /**
     * Setup == Classificate it on the Lp Adapter Facet as an LP client
     */
    function setUp() public virtual override {
        super.setUp();

        // Classificate all univ2 clients for testing
        for (uint256 i; i < uniV2Clients.length; i++) {
            LpAdapterFacet(address(diamond)).addClient(
                keccak256(abi.encode(uniV2Clients[i])),
                LPClient(
                    UniV2LpAdapterFacet.addLiquidityUniV2.selector,
                    UniV2LpAdapterFacet.removeLiquidityUniV2.selector,
                    0x00000000,
                    UniV2LpAdapterFacet.balanceOfUniV2LP.selector,
                    uniV2Clients[i],
                    new bytes(0)
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
     * Test add liquidity
     */
    function testUniV2AddLiquidity(
        uint256 amountA,
        uint256 amountB
    ) public returns (uint256[2][] memory amountsAddedToClients) {
        // vm.assume(amountA > 0 && amountB > 0);
        // vm.assume(amountA > 1 * 10 ** 14);
        // vm.assume(amountB > 1 * 10 ** 14);
        // vm.assume(amountA < IERC20(tokenA).totalSupply());
        // vm.assume(amountB < IERC20(tokenA).totalSupply());
        // Amounts should be realistically big (0.00001 w/ normal IERC20 decimals). Otherwise it would fail due to insufficient burn (which is OK if it were mid strategy run)
        amountA = bound(amountA, 1 * 10 ** 14, IERC20(tokenA).totalSupply());
        amountB = bound(amountB, 1 * 10 ** 14, IERC20(tokenB).totalSupply());

        amountsAddedToClients = new uint256[2][](uniV2Clients.length);

        // Prank as the vault contract
        vm.startPrank(address(vaultContract));

        (tokenA, tokenB) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        // Add Liquidity On Each One Of The Clients
        for (uint256 i; i < uniV2Clients.length; i++) {
            // Deal us exactly the fuzz amounts
            deal(tokenA, address(vaultContract), amountA);
            deal(tokenB, address(vaultContract), amountB);

            // Sufficient check
            assertEq(
                IERC20(tokenA).balanceOf(address(vaultContract)),
                amountA,
                "Dealt TokenA, but None Was Given"
            );
            assertEq(
                IERC20(tokenB).balanceOf(address(vaultContract)),
                amountB,
                "Dealt TokenA, but None Was Given"
            );

            address factory = IUniswapV2Router(uniV2Clients[i]).factory();

            // Calculate the end result we should be getting (to assert)
            (
                uint256 desiredAmountAOut,
                uint256 desiredAmountBOut
            ) = _determineAddAmounts(factory, tokenA, tokenB, amountA, amountB);

            amountsAddedToClients[i] = [desiredAmountAOut, desiredAmountBOut];

            console.log(
                "Amount A, Desired Amount A:",
                amountA,
                desiredAmountAOut
            );
            console.log(
                "Amount B, Desired Amount B:",
                amountB,
                desiredAmountBOut
            );

            uint256 desiredLpAmount = _getDesiredLpAmount(
                factory,
                tokenA,
                tokenB,
                desiredAmountAOut,
                desiredAmountBOut
            );

            // Add Liq thru the adapter
            LpAdapterFacet(address(diamond)).addLiquidity(
                tokenA,
                tokenB,
                amountA,
                amountB,
                keccak256(abi.encode(uniV2Clients[i])),
                new bytes[](0)
            );

            // (We take a tiny amount (10%) of potential delta in mind)
            assertApproxEqAbs(
                IERC20(tokenA).balanceOf(address(vaultContract)),
                amountA - desiredAmountAOut,
                desiredAmountAOut / 10,
                "Added Liquidity For UniV2 Client, but new tokenA balance out of delta"
            );
            assertApproxEqAbs(
                IERC20(tokenB).balanceOf(address(vaultContract)),
                amountB - desiredAmountBOut,
                desiredAmountBOut / 10,
                "Added Liquidity For UniV2 Client, but new tokenB balance out of delta"
            );

            assertApproxEqAbs(
                IERC20(IUniswapV2Factory(factory).getPair(tokenA, tokenB))
                    .balanceOf(address(vaultContract)),
                desiredLpAmount,
                desiredLpAmount / 10,
                "Added Liquidity For UniV2 Client, but new LP Pair balance out of delta"
            );

            // Reset balances for next iterations
            deal(tokenA, address(vaultContract), 0);
            deal(tokenB, address(vaultContract), 0);
        }

        vm.stopPrank();
    }

    /**
     * Test remove liquidity
     */
    function testUniV2RemoveLiquidity(uint256 amountA, uint256 amountB) public {
        // Add Liquidity on all clients
        uint256[2][] memory amountsAdded = testUniV2AddLiquidity(
            amountA,
            amountB
        );

        // Prank as the vault contract
        vm.startPrank(address(vaultContract));

        // Remove Liquidity On Each One Of The Clients
        for (uint256 i; i < uniV2Clients.length; i++) {
            // We should have LP tokens here from adding the liquidity

            address factory = IUniswapV2Router(uniV2Clients[i]).factory();
            address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);

            uint256 lpTokensToWithdraw = IERC20(pair).balanceOf(
                address(vaultContract)
            );

            // Delta is less forgiving here (Rates should be what they are)
            (uint256 depositedAmountA, uint256 depositedAmountB) = (
                amountsAdded[i][0],
                amountsAdded[i][1]
            );

            uint256 amountADelta = depositedAmountA / 100;
            uint256 amountBDelta = depositedAmountB / 100;

            assertEq(
                IERC20(tokenA).balanceOf(address(vaultContract)),
                0,
                "Before remvoing liquidity, tokenA balance is bigger than 0"
            );

            assertEq(
                IERC20(tokenB).balanceOf(address(vaultContract)),
                0,
                "Before remvoing liquidity, tokenB balance is bigger than 0"
            );

            assertTrue(
                IERC20(pair).balanceOf(address(vaultContract)) > 0,
                "Before remvoing liquidity, LP pair balance is 0"
            );

            // Add Liq thru the adapter
            LpAdapterFacet(address(diamond)).removeLiquidity(
                tokenA,
                tokenB,
                lpTokensToWithdraw,
                keccak256(abi.encode(uniV2Clients[i])),
                new bytes[](0)
            );

            // (We take a tiny amount (10%) of potential delta in mind)
            assertApproxEqAbs(
                IERC20(tokenA).balanceOf(address(vaultContract)),
                depositedAmountA,
                amountADelta,
                "Removed Liquidity For UniV2 Client, but new tokenA balance out of delta"
            );
            assertApproxEqAbs(
                IERC20(tokenB).balanceOf(address(vaultContract)),
                depositedAmountB,
                amountBDelta,
                "Removed Liquidity For UniV2 Client, but new tokenB balance out of delta"
            );

            assertEq(
                IERC20(pair).balanceOf(address(vaultContract)),
                0,
                "Removed Liquidity For UniV2 Client, but new LP Pair balance is not 0 (All tokens should have been removed from liquidity)"
            );

            // Reset balances for next iterations
            deal(tokenA, address(vaultContract), 0);
            deal(tokenB, address(vaultContract), 0);
        }
    }

    function _determineAddAmounts(
        address factory,
        address _tokenA,
        address _tokenB,
        uint256 amountA,
        uint256 amountB
    ) internal view returns (uint256 desiredAmountA, uint256 desiredAmountB) {
        (uint256 reserveA, uint256 reserveB) = factory.getReserves(
            _tokenA,
            _tokenB
        );

        if (reserveA == 0 && reserveB == 0) return (amountA, amountB);

        uint256 requiredAmountBForAmountA = amountA.quote(reserveA, reserveB);

        uint256 requiredAmountAForAmountB = amountB.quote(reserveB, reserveA);

        (desiredAmountA, desiredAmountB) = requiredAmountBForAmountA > amountB
            ? (requiredAmountAForAmountB, amountB)
            : (amountA, requiredAmountBForAmountA);
    }

    function _getDesiredLpAmount(
        address factory,
        address _tokenA,
        address _tokenB,
        uint256 desiredAmountA,
        uint256 desiredAmountB
    ) internal view returns (uint256 desiredLp) {
        IUniswapV2Pair pair = IUniswapV2Pair(
            IUniswapV2Factory(factory).getPair(_tokenA, _tokenB)
        );

        if (address(pair) == address(0))
            return _getNewLpPairLpAmount(desiredAmountA, desiredAmountB);

        (uint reserveA, uint reserveB, ) = address(pair) == address(0)
            ? (0, 0, 0)
            : pair.getReserves();

        console.log("after determine amounts");

        uint256 totalSupply = address(pair) == address(0)
            ? 0
            : IERC20(address(pair)).totalSupply();

        (uint256 firstNum, uint256 secondNum) = (
            (desiredAmountA * totalSupply) / reserveA,
            (desiredAmountB * totalSupply) / reserveB
        );

        desiredLp = firstNum < secondNum ? firstNum : secondNum;
    }

    function _getNewLpPairLpAmount(
        uint256 amountA,
        uint256 amountB
    ) internal pure returns (uint256 lpamt) {
        return sqrt(amountA * amountB) - 10 ** 3;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
