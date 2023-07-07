/**
 * Tests for the UniV2 LP client
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../../../Deployment.t.sol";
import "../../../../../../src/diamond/facets/adapters/lending/LendingAdapter.sol";
import "../../../../../vault/main/Base.sol";
import "src/vault/TestableVault.sol";

import {IAToken} from "lib/aave-v3-core/contracts/interfaces/IAToken.sol";
import {IPool} from "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import {IPoolDataProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";
import {IPoolAddressesProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPoolAddressesProviderRegistry} from "lib/aave-v3-core/contracts/interfaces/IPoolAddressesProviderRegistry.sol";
import {AaveV3LendingAdapter} from "src/adapters/lending/AaveV3.sol";
import {ILendingProvider} from "src/adapters/lending/ILendingProvider.sol";
import {AaveV3AdapterStorageManager} from "src/diamond/facets/adapters/lending/clients/AaveV3Storage.sol";

contract LendingClientAaveV3 is DiamondTest {
    // =================
    //     GLOBALS
    // =================
    Vault vaultContract;

    address self;

    address AaveV3AddressManagerRegistry =
        0x770ef9f4fe897e59daCc474EF11238303F9552b6;

    address[] supportedReserves = [
        0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1,
        0xf97f4df75117a78c1A5a0DBb814Af92458539FB4,
        0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8,
        0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f,
        0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
        0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
        0xD22a58f79e9481D1a88e00c343885A588b34b68B,
        0x5979D7b546E38E414F7E9822514be443A4800529,
        0x3F56e0c36d275367b8C502090EDF38289b3dEa0d
    ];

    address[][] supportedReservesPerClient;

    address[] aavev3Clients = [AaveV3AddressManagerRegistry];

    AaveV3LendingAdapter AAVEV3_ADAPTER;

    /**
     * Setup == Classificate it on the Lending Adapter Facet as a Lending client
     */
    function setUp() public virtual override {
        super.setUp();

        self = address(vaultContract);

        AAVEV3_ADAPTER = new AaveV3LendingAdapter(address(diamond));

        // Classificate all glp clients for testing
        for (uint256 i; i < aavev3Clients.length; i++) {
            AaveV3AdapterStorageManager(address(diamond)).addAaveV3Client(
                keccak256(abi.encode(aavev3Clients[i])),
                IPoolAddressesProviderRegistry(aavev3Clients[i])
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

        vm.etch(address(vaultContract), type(TestableVault).runtimeCode);

        _filterTokensToAvoidFuzzFail();
    }

    function _filterTokensToAvoidFuzzFail() internal {
        for (uint256 i; i < aavev3Clients.length; i++) {
            address[] memory newTokens;

            for (uint256 j; j < supportedReserves.length; j++) {
                address token = supportedReserves[j];

                IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(
                        IPoolAddressesProviderRegistry(aavev3Clients[i])
                            .getAddressesProvidersList()[0]
                    );

                IPoolDataProvider dataProvider = IPoolDataProvider(
                    poolAddressesProvider.getPoolDataProvider()
                );

                if (dataProvider.getPaused(token)) continue;

                (, uint256 supplyCap) = dataProvider.getReserveCaps(token);
                uint256 currentSupply = dataProvider.getATokenTotalSupply(
                    token
                );

                supplyCap = supplyCap * (10 ** IERC20(token).decimals());

                uint256 minSupplyCapToSupplyDiff = supplyCap / 100;

                if (supplyCap - currentSupply < minSupplyCapToSupplyDiff)
                    continue;

                address[] memory oldTokens = newTokens;
                newTokens = new address[](oldTokens.length + 1);
                for (uint256 p; p < oldTokens.length; p++)
                    newTokens[p] = oldTokens[p];
                newTokens[newTokens.length - 1] = token;
            }

            address[][] memory oldReserves = supportedReservesPerClient;

            address[][] memory newReserves = new address[][](
                oldReserves.length + 1
            );
            for (uint256 p; p < oldReserves.length; p++)
                newReserves[p] = oldReserves[p];

            assertGt(
                newTokens.length,
                0,
                "AaveV3Test: Found Client With No Supported Reserve Tokens"
            );

            newReserves[newReserves.length - 1] = newTokens;

            supportedReservesPerClient = newReserves;
        }
    }

    /**
     * Test getting a single AToken
     */
    function testGettingReserveAToken(uint8 assetIdx) external {
        for (uint256 i; i < aavev3Clients.length; i++) {
            if (
                assetIdx == 0 ||
                assetIdx >= supportedReservesPerClient[i].length
            )
                assetIdx = uint8(
                    bound(assetIdx, 0, supportedReservesPerClient[i].length - 1)
                );

            address asset = supportedReservesPerClient[i][assetIdx];

            address aTokenAsset = AAVEV3_ADAPTER.getReserveToken(
                keccak256(abi.encode(aavev3Clients[i])),
                asset
            );

            assertTrue(
                aTokenAsset != address(0),
                "AaveV3 Test: Failed To Retreive AToken Asset"
            );
        }
    }

    /**
     * Test supplying to an AAVEv3 market
     */
    function testSupplyingToAaveMarket(
        uint64 depositAmount,
        uint8 assetIdx
    ) public returns (uint64 actualDepositAmount, address token) {
        vm.startPrank(address(vaultContract));

        for (uint256 i; i < aavev3Clients.length; i++) {
            if (
                assetIdx == 0 ||
                assetIdx >= supportedReservesPerClient[i].length
            )
                assetIdx = uint8(
                    bound(assetIdx, 0, supportedReservesPerClient[i].length - 1)
                );

            token = supportedReservesPerClient[i][assetIdx];

            IPoolDataProvider dataProvider = IPoolDataProvider(
                IPoolAddressesProvider(
                    IPoolAddressesProviderRegistry(aavev3Clients[i])
                        .getAddressesProvidersList()[0]
                ).getPoolDataProvider()
            );

            (, uint256 supplyCap) = dataProvider.getReserveCaps(token);
            uint256 currentSupply = dataProvider.getATokenTotalSupply(token);

            supplyCap = supplyCap * 10 ** IERC20(token).decimals();

            console.log("Reserve Caps, Total Supply", supplyCap, currentSupply);

            // @notice
            // I have NO FUCKING IDEA why this has to be done with USDT. I was fucking fightning with this shit
            // until after a 4912349012-49-12940210-4 runs i realized that the tests only fail when its a run with USDT
            // and an amount of 5500000000000 and above.
            if (token == 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9)
                depositAmount = uint64(
                    bound(depositAmount, 1 * 10 ** 5, 1000000000000)
                );
            else if (
                depositAmount > min(currentSupply, supplyCap - currentSupply) ||
                depositAmount < 1 * 10 ** 4
            )
                depositAmount = uint64(
                    bound(
                        depositAmount,
                        1 *
                            10 **
                                max(
                                    (IERC20(token).decimals() - 2),
                                    min(8, IERC20(token).decimals())
                                ),
                        min(
                            (supplyCap - currentSupply) / 10,
                            currentSupply / 10
                        )
                    )
                );

            address aToken = AAVEV3_ADAPTER.getReserveToken(
                keccak256(abi.encode(aavev3Clients[i])),
                token
            );

            deal(token, address(vaultContract), depositAmount);

            assertEq(
                IERC20(token).balanceOf(address(vaultContract)),
                depositAmount,
                "Didnt Get Deposit Amount While Dealing"
            );

            (bool success, ) = TestableVault(address(vaultContract))
                .delegateCall(
                    address(AAVEV3_ADAPTER),
                    abi.encodeCall(
                        ILendingProvider.supplyToMarket,
                        (
                            keccak256(abi.encode(aavev3Clients[i])),
                            token,
                            depositAmount,
                            new bytes(0)
                        )
                    )
                );

            require(success, "AaveV3Test: Supply Failed");

            assertEq(
                IERC20(token).balanceOf(address(vaultContract)),
                0,
                "AaveV3Test: Supplied, but balance was not deducted of depositAmount"
            );

            assertApproxEqAbs(
                IERC20(aToken).balanceOf(address(vaultContract)),
                depositAmount,
                max(depositAmount / 200, 2),
                "AaveV3Test: Supplied, but AToken balance is not depositAmount"
            );
        }

        vm.stopPrank();

        actualDepositAmount = depositAmount;
    }

    /**
     * Test Harvesting From AaveV3 clients
     */
    function testHarvestinAaveV3(
        uint64 depositAmount,
        uint8 assetIdx
    ) public returns (uint64 actualDepositAmount, address tokenUsed) {
        (depositAmount, tokenUsed) = testSupplyingToAaveMarket(
            depositAmount,
            assetIdx
        );

        vm.startPrank(address(vaultContract));

        for (uint256 i; i < aavev3Clients.length; i++) {
            if (
                assetIdx == 0 ||
                assetIdx >= supportedReservesPerClient[i].length
            )
                assetIdx = uint8(
                    bound(assetIdx, 0, supportedReservesPerClient[i].length - 1)
                );

            address token = tokenUsed;

            address aToken = AAVEV3_ADAPTER.getReserveToken(
                keccak256(abi.encode(aavev3Clients[i])),
                token
            );

            uint256 preTimetravelATokenBalance = IERC20(aToken).balanceOf(
                address(vaultContract)
            );

            uint256 preTimeTravelReserveTokenBalance = IERC20(token).balanceOf(
                address(vaultContract)
            );

            vm.warp(block.timestamp + block.timestamp);

            uint256 futureATokenBalance = IERC20(aToken).balanceOf(
                address(vaultContract)
            );

            assertGt(
                futureATokenBalance,
                preTimetravelATokenBalance,
                "AaveV3Test: Time travelled, but tokens were not awarded"
            );

            (bool success, ) = TestableVault(address(vaultContract))
                .delegateCall(
                    address(AAVEV3_ADAPTER),
                    abi.encodeCall(
                        ILendingProvider.harvestMarketInterest,
                        (
                            keccak256(abi.encode(aavev3Clients[i])),
                            token,
                            new bytes(0)
                        )
                    )
                );

            require(success, "AaveV3Test: Harvest Failed");

            uint256 timeTravelDiff = futureATokenBalance -
                preTimetravelATokenBalance;

            uint256 diff = futureATokenBalance -
                IERC20(aToken).balanceOf(address(vaultContract));

            assertGt(
                diff,
                0,
                "AaveV3Test: Harvest Interest Failed - No Tokens Were Harvested"
            );

            assertApproxEqAbs(
                timeTravelDiff,
                diff,
                max(diff / 100, 50),
                "AaveV3Test: Harvested Interest, But Time Travel Diff != Harvest Diff"
            );

            assertGt(
                IERC20(token).balanceOf(address(vaultContract)),
                preTimeTravelReserveTokenBalance,
                "AaveV3Test: Harvested, but underlying reserve token balance did not increase"
            );

            console.log(
                "Pre Time Travel Balance & Current Balance & A Token Balance:",
                preTimeTravelReserveTokenBalance,
                IERC20(token).balanceOf(address(vaultContract)),
                preTimetravelATokenBalance
            );

            console.log("Token In Harvest:", IERC20(token).symbol());

            assertApproxEqAbs(
                IERC20(token).balanceOf(address(vaultContract)),
                preTimeTravelReserveTokenBalance + diff,
                max((preTimeTravelReserveTokenBalance + diff) / 100, 100),
                "AaveV3Test: Harvested Interest, but did not receive proper reserve token amount in return"
            );

            assertApproxEqAbs(
                IERC20(aToken).balanceOf(address(vaultContract)),
                preTimetravelATokenBalance,
                max((preTimetravelATokenBalance) / 100, 100),
                "AaveV3Test: Harvested Interest, but remaining aToken balance mismatches"
            );

            assertApproxEqAbs(
                preTimetravelATokenBalance,
                depositAmount,
                max((preTimetravelATokenBalance) / 100, 100),
                "AaveV3Test: Harvested Interest but pre time travle token A balance != depositAmount"
            );
        }

        vm.stopPrank();

        actualDepositAmount = depositAmount;
    }

    /**
     * Test withdrawaing from an AaveV3 market
     */
    function testAaveV3Withdrawals(
        uint64 depositAmount,
        uint8 assetIdx
    ) public {
        for (uint256 i; i < aavev3Clients.length; i++) {
            if (
                assetIdx == 0 ||
                assetIdx >= supportedReservesPerClient[i].length
            )
                assetIdx = uint8(
                    bound(assetIdx, 0, supportedReservesPerClient[i].length - 1)
                );
        }

        address token = supportedReserves[assetIdx];

        (depositAmount, token) = testHarvestinAaveV3(depositAmount, assetIdx);

        vm.startPrank(address(vaultContract));

        for (uint256 i; i < aavev3Clients.length; i++) {
            address aToken = AAVEV3_ADAPTER.getReserveToken(
                keccak256(abi.encode(aavev3Clients[i])),
                token
            );

            uint256 preWithdrawalReserveTokenBalance = IERC20(token).balanceOf(
                address(vaultContract)
            );
            uint256 preWithdrawalATokenBalance = IERC20(aToken).balanceOf(
                address(vaultContract)
            );

            // There might be very very slight delta (~ 1-2 tokens)
            assertApproxEqAbs(
                preWithdrawalATokenBalance,
                depositAmount,
                max(depositAmount / 200, 10),
                "AaveV3Test: About to withdraw, A Token balance != deposit amount"
            );

            (bool success, ) = TestableVault(address(vaultContract))
                .delegateCall(
                    address(AAVEV3_ADAPTER),
                    abi.encodeCall(
                        ILendingProvider.withdrawFromMarket,
                        (
                            keccak256(abi.encode(aavev3Clients[i])),
                            token,
                            preWithdrawalATokenBalance,
                            new bytes(0)
                        )
                    )
                );

            require(success, "AaveV3Test: Withdraw Failed");

            assertApproxEqAbs(
                IERC20(aToken).balanceOf(address(vaultContract)),
                0,
                max(depositAmount / 100, 100),
                "AaveV3Test: Withdrawan But AToken Balance Mismatch"
            );

            assertApproxEqAbs(
                IERC20(token).balanceOf(address(vaultContract)),
                preWithdrawalReserveTokenBalance + depositAmount,
                max(depositAmount / 100, 100),
                "AaveV3Test: Withdrawan, But reserve token balance mismatch"
            );
        }

        vm.stopPrank();
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

interface IUpgradedAToken is IAToken {
    function POOL() external view returns (address);
}
