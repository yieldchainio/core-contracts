/**
 * Lending adapter for AAVE V3
 * @notice clientAddress = PoolAddressesProviderRegistry
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../../storage/adapters/lending/Lending.sol";
import "../../../../storage/adapters/lending/clients/AaveV3.sol";
import {SafeERC20} from "../../../../../libs/SafeERC20.sol";
import {IERC20} from "../../../../../interfaces/IERC20.sol";
import {IAToken} from "lib/aave-v3-core/contracts/interfaces/IAToken.sol";
import {IStableDebtToken} from "lib/aave-v3-core/contracts/interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "lib/aave-v3-core/contracts/interfaces/IVariableDebtToken.sol";
import {IPool} from "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPoolDataProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";
import {IPoolAddressesProviderRegistry} from "lib/aave-v3-core/contracts/interfaces/IPoolAddressesProviderRegistry.sol";
import "src/utils/ERC20-Util.sol";
import "forge-std/console.sol";
import "forge-std/Test.sol";

contract AaveV3LendingAdapterFacet is ERC20Utils, Test {
    // Libs
    using SafeERC20 for IERC20;

    // ==============
    //    ERRORS
    // ==============
    error UnsupportedReserveAsset();

    // ==============
    //    METHODS
    // ==============
    /**
     * Supply to a market on an AAVE V3 Client
     * @param client - The lending client as classified in the Lending adapter storage
     * @param asset - The address of the *underlying* asset
     * @param amount - The amount to supply
     */
    function supplyToAaveV3Market(
        LendingClient calldata client,
        address asset,
        uint256 amount
    ) external {
        IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(
            IPoolAddressesProviderRegistry(client.clientAddress)
                .getAddressesProvidersList()[0]
        );

        IPool pool = IPool(
            IPoolAddressesProvider(poolAddressesProvider).getPool()
        );

        IPoolDataProvider dataProvider = IPoolDataProvider(
            poolAddressesProvider.getPoolDataProvider()
        );

        (address aToken, , ) = dataProvider.getReserveTokensAddresses(asset);

        if (aToken == address(0)) revert UnsupportedReserveAsset();

        AaveV3LendingAdapterStorage
            storage aaveV3Storage = AaveV3LendingAdapterStorageLib.retreive();

        uint16 ycReferralCode = aaveV3Storage.YIELDCHAIN_REFFERAL_CODE;
        IERC20(asset).balanceOf(msg.sender);

        _transferFromVault(msg.sender, IERC20(asset), amount);

        _ensureSufficientAllownace(IERC20(asset), address(pool), amount);

        pool.supply(asset, amount, msg.sender, ycReferralCode);

        // Track principal deposits manually to enable interest harvesting
        aaveV3Storage.principalDeposits[msg.sender][IAToken(aToken)] += amount;
    }

    /**
     * Withdraw from a market on an AAVE V3 Client
     * @param client - The lending client as classified in the Lending adapter storage
     * @param asset - The address of the *underlying* asset
     * @param amount - The amount to supply
     */
    function withdrawFromAaveV3Market(
        LendingClient calldata client,
        address asset,
        uint256 amount
    ) external {
        IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(
            IPoolAddressesProviderRegistry(client.clientAddress)
                .getAddressesProvidersList()[0]
        );

        IPoolDataProvider dataProvider = IPoolDataProvider(
            poolAddressesProvider.getPoolDataProvider()
        );

        (address aToken, , ) = dataProvider.getReserveTokensAddresses(asset);
        if (aToken == address(0)) revert UnsupportedReserveAsset();

        IPool pool = IPool(poolAddressesProvider.getPool());

        AaveV3LendingAdapterStorage
            storage aaveV3Storage = AaveV3LendingAdapterStorageLib.retreive();

        console.log(
            "Requested Amount VS Balance:",
            amount,
            IERC20(aToken).balanceOf(msg.sender)
        );

        uint256 percision = 1000;

        uint256 principal = aaveV3Storage.principalDeposits[msg.sender][
            IAToken(aToken)
        ];

        uint256 bal = IERC20(aToken).balanceOf(msg.sender);

        uint256 amountAsDivisorOfBalance = (amount * percision) / bal;

        uint256 amountWithoutAccuredRewards = (principal * percision) /
            amountAsDivisorOfBalance -
            1;

        _transferFromVault(
            msg.sender,
            IERC20(aToken),
            amountWithoutAccuredRewards
        );

        console.log(
            "Amount Requested, Amount Without Accured Rewards, Balance",
            amount,
            amountWithoutAccuredRewards,
            bal
        );

        console.log(
            "Own aToken balance",
            IERC20(aToken).balanceOf(address(this))
        );

        pool.withdraw(asset, amountWithoutAccuredRewards - 1, msg.sender);

        // Track principal deposits manually to enable interest harvesting
        AaveV3LendingAdapterStorageLib.retreive().principalDeposits[msg.sender][
                IAToken(aToken)
            ] -= (amountWithoutAccuredRewards - 1);
    }

    /**
     * Harvest interest rewards from an AAVE v3 client market
     * @param client - The Lending client
     * @param asset - The underlying reserve asset to claim rewards on
     */
    function harvestAaveV3Interest(
        LendingClient calldata client,
        address asset
    ) external {
        IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(
            IPoolAddressesProviderRegistry(client.clientAddress)
                .getAddressesProvidersList()[0]
        );

        IPoolDataProvider dataProvider = IPoolDataProvider(
            poolAddressesProvider.getPoolDataProvider()
        );

        IPool pool = IPool(poolAddressesProvider.getPool());

        (address aToken, , ) = dataProvider.getReserveTokensAddresses(asset);
        if (aToken == address(0)) revert UnsupportedReserveAsset();

        AaveV3LendingAdapterStorage
            storage aaveV3Storage = AaveV3LendingAdapterStorageLib.retreive();

        uint256 principal = aaveV3Storage.principalDeposits[msg.sender][
            IAToken(aToken)
        ];

        console.log(
            "Principal, BalanceOf:",
            principal,
            IAToken(aToken).balanceOf(msg.sender)
        );

        uint256 aTokenBalance = IAToken(aToken).balanceOf(msg.sender);

        uint256 accuredRewards = aTokenBalance < principal
            ? 0
            : aTokenBalance - principal;

        require(accuredRewards > 11, "No Rewards To Claim");

        _transferFromVault(msg.sender, IERC20(aToken), accuredRewards);

        pool.withdraw(asset, accuredRewards - 10, msg.sender);
    }

    // /**
    //  * Borrow from a market on an AAVE V3 Client
    //  * @param client - The lending client as classified in the Lending adapter storage
    //  * @param asset - The address of the *underlying* asset
    //  * @param amount - The amount to supply
    //  */
    // function borrowFromAaveV3Market(
    //     LendingClient calldata client,
    //     address asset,
    //     uint256 amount
    // ) external {
    //     IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(
    //         IPoolAddressesProviderRegistry(client.clientAddress)
    //             .getAddressesProvidersList()[0]
    //     );

    //     IPoolDataProvider dataProvider = IPoolDataProvider(
    //         poolAddressesProvider.getPoolDataProvider()
    //     );

    //     (address aToken, , ) = dataProvider.getReserveTokensAddresses(asset);

    //     require(aToken != address(0), "Unsupported Asset");

    //     IPool pool = IPool(
    //         poolAddressesProvider.getPool()
    //     );

    //     _transferFromVault(msg.sender, IERC20(aToken), amount);

    //     pool.withdraw(asset, amount, msg.sender);
    // }

    // ==============
    //    GETTERS
    // ==============
    /**
     * Get all supported reserves
     * @param client  - The classified client
     * @return supportedReserveAssets - The supported reserve assets addresses
     */
    function getSupportedReservesAaveV3(
        LendingClient calldata client
    ) external view returns (address[] memory supportedReserveAssets) {
        IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(
            IPoolAddressesProviderRegistry(client.clientAddress)
                .getAddressesProvidersList()[0]
        );

        IPoolDataProvider dataProvider = IPoolDataProvider(
            poolAddressesProvider.getPoolDataProvider()
        );

        IPoolDataProvider.TokenData[] memory tokens = dataProvider
            .getAllReservesTokens();

        supportedReserveAssets = new address[](tokens.length);

        for (uint256 i; i < tokens.length; i++)
            supportedReserveAssets[i] = tokens[i].tokenAddress;
    }

    /**
     * Get the representation (aToken) of a given reserve asset
     * @param token - The underlying reserve token
     * @param client - The classified client
     * @return aToken - The aToken of that underlying asset
     */
    function getReserveAToken(
        LendingClient calldata client,
        address token
    ) external view returns (address aToken) {
        IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(
            IPoolAddressesProviderRegistry(client.clientAddress)
                .getAddressesProvidersList()[0]
        );

        IPoolDataProvider dataProvider = IPoolDataProvider(
            poolAddressesProvider.getPoolDataProvider()
        );

        (aToken, , ) = dataProvider.getReserveTokensAddresses(token);

        if (aToken == address(0)) revert UnsupportedReserveAsset();
    }

    /**
     * Get the balance of an aToken by it's reserve token
     * @param token - The underlying reserve token
     * @param client - The classified client
     * @return aTokenBalance
     */
    function aaveV3PositionBalanceOf(
        address token,
        LendingClient calldata client
    ) external view returns (uint256 aTokenBalance) {
        IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(
            IPoolAddressesProviderRegistry(client.clientAddress)
                .getAddressesProvidersList()[0]
        );

        IPoolDataProvider dataProvider = IPoolDataProvider(
            poolAddressesProvider.getPoolDataProvider()
        );

        (address aToken, , ) = dataProvider.getReserveTokensAddresses(token);

        if (aToken == address(0)) revert UnsupportedReserveAsset();

        aTokenBalance = IERC20(aToken).balanceOf(msg.sender);
    }
}
