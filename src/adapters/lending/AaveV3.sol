/**
 * Lending adapter for AAVE V3
 * @notice clientAddress = PoolAddressesProviderRegistry
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import "../../../../storage/adapters/lending/Lending.sol";
import "src/diamond/storage/adapters/lending/clients/AaveV3.sol";
import "src/diamond/facets/adapters/lending/clients/AaveV3Storage.sol";
import {IAToken} from "lib/aave-v3-core/contracts/interfaces/IAToken.sol";
import {IStableDebtToken} from "lib/aave-v3-core/contracts/interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "lib/aave-v3-core/contracts/interfaces/IVariableDebtToken.sol";
import {IPool} from "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPoolDataProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolDataProvider.sol";
import {IPoolAddressesProviderRegistry} from "lib/aave-v3-core/contracts/interfaces/IPoolAddressesProviderRegistry.sol";
import {SafeERC20} from "src/libs/SafeERC20.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {ILendingProvider} from "./ILendingProvider.sol";
import {VaultAdapterCompatible} from "src/interfaces/IVaultAdapter.sol";
import "src/utils/ERC20-Util.sol";

contract AaveV3LendingAdapter is
    VaultAdapterCompatible,
    ILendingProvider,
    ERC20Utils
{
    // Libs
    using SafeERC20 for IERC20;

    // ==============
    //    ERRORS
    // ==============
    error UnsupportedReserveAsset();
    error UnsupportedClient();

    // ==============
    //     TYPES
    // ==============
    enum BorrowInterestRateTypes {
        STABLE,
        VARIABLE
    }

    struct ExtraBorrowArgs {
        BorrowInterestRateTypes interestRateType;
    }

    // =================
    //    CONSTRUCTOR
    // =================
    constructor(address diamond) vaultCompatible(diamond) {}

    // ==============
    //    METHODS
    // ==============

    function supplyToMarket(
        bytes32 clientId,
        address asset,
        uint256 amount,
        bytes calldata /** extraArgs */
    ) external {
        address YC_DIAMOND = diamond();

        (IPoolDataProvider dataProvider, IPool pool) = _getDataProviderAndPool(
            clientId
        );

        (address aToken, , ) = dataProvider.getReserveTokensAddresses(asset);

        if (aToken == address(0)) revert UnsupportedReserveAsset();

        uint16 ycReferralCode = AaveV3AdapterStorageManager(YC_DIAMOND)
            .getYcReferralCode();

        _ensureSufficientAllownace(IERC20(asset), address(pool), amount);

        pool.supply(asset, amount, address(this), ycReferralCode);

        AaveV3AdapterStorageManager(YC_DIAMOND).increaseVaultPrincipal(
            IAToken(aToken),
            amount
        );
    }

    function withdrawFromMarket(
        bytes32 clientId,
        address underlyingAsset,
        uint256 amount,
        bytes calldata /** extraArgs */
    ) external {
        address YC_DIAMOND = diamond();

        (IPoolDataProvider dataProvider, IPool pool) = _getDataProviderAndPool(
            clientId
        );

        (address aToken, , ) = dataProvider.getReserveTokensAddresses(
            underlyingAsset
        );
        if (aToken == address(0)) revert UnsupportedReserveAsset();

        uint256 percision = 1000;

        uint256 principal = AaveV3AdapterStorageManager(address(YC_DIAMOND))
            .getVaultPrincipal(address(this), IAToken(aToken));

        uint256 bal = IERC20(aToken).balanceOf(address(this));

        uint256 amountAsDivisorOfBalance = (amount * percision) / bal;

        uint256 amountWithoutAccuredRewards = (principal * percision) /
            amountAsDivisorOfBalance -
            1;

        pool.withdraw(
            underlyingAsset,
            amountWithoutAccuredRewards - 1,
            address(this)
        );

        AaveV3AdapterStorageManager(YC_DIAMOND).decreaseVaultPrincipal(
            IAToken(aToken),
            amountWithoutAccuredRewards - 1
        );
    }

    function harvestMarketInterest(
        bytes32 clientId,
        address underlyingAsset,
        bytes calldata /** extraArgs */
    ) external {
        address YC_DIAMOND = diamond();

        (IPoolDataProvider dataProvider, IPool pool) = _getDataProviderAndPool(
            clientId
        );

        (address aToken, , ) = dataProvider.getReserveTokensAddresses(
            underlyingAsset
        );

        uint256 principal = AaveV3AdapterStorageManager(YC_DIAMOND)
            .getVaultPrincipal(address(this), IAToken(aToken));

        uint256 aTokenBalance = IAToken(aToken).balanceOf(address(this));

        uint256 accuredRewards = aTokenBalance < principal
            ? 0
            : aTokenBalance - principal;

        require(accuredRewards > 2, "No Rewards To Claim");

        pool.withdraw(underlyingAsset, accuredRewards - 1, address(this));
    }

    function borrowFromMarket(
        bytes32 clientId,
        address underlyingAsset,
        uint256 amount,
        bytes calldata extraArgs
    ) external {
        address YC_DIAMOND = diamond();

        (, IPool pool) = _getDataProviderAndPool(clientId);

        ExtraBorrowArgs memory extraArguments = abi.decode(
            extraArgs,
            (ExtraBorrowArgs)
        );

        uint256 interestRateMode = extraArguments.interestRateType ==
            BorrowInterestRateTypes.STABLE
            ? 1
            : 2;

        pool.borrow(
            underlyingAsset,
            amount,
            interestRateMode,
            AaveV3AdapterStorageManager(YC_DIAMOND).getYcReferralCode(),
            address(this)
        );
    }

    function repayToMarket(
        bytes32 clientId,
        address positionToRepay,
        uint256 amount,
        bytes calldata extraArgs
    ) external {
        (, IPool pool) = _getDataProviderAndPool(clientId);

        ExtraBorrowArgs memory extraArguments = abi.decode(
            extraArgs,
            (ExtraBorrowArgs)
        );

        uint256 interestRateMode = extraArguments.interestRateType ==
            BorrowInterestRateTypes.STABLE
            ? 1
            : 2;

        pool.repay(positionToRepay, amount, interestRateMode, address(this));
    }

    // ===============
    //    GETTERS
    // ===============

    function getSupportedReserves(
        bytes32 clientId
    ) external view returns (address[] memory supportedReserveAssets) {
        (IPoolDataProvider dataProvider, ) = _getDataProviderAndPool(clientId);

        IPoolDataProvider.TokenData[] memory tokens = dataProvider
            .getAllReservesTokens();

        supportedReserveAssets = new address[](tokens.length);

        for (uint256 i; i < tokens.length; i++)
            supportedReserveAssets[i] = tokens[i].tokenAddress;
    }

    function getReserveToken(
        bytes32 clientId,
        address underlyingToken
    ) external view returns (address aToken) {
        (IPoolDataProvider dataProvider, ) = _getDataProviderAndPool(clientId);

        (aToken, , ) = dataProvider.getReserveTokensAddresses(underlyingToken);

        if (aToken == address(0)) revert UnsupportedReserveAsset();
    }


    function getPositionBalance(
        bytes32 clientId,
        address underlyingToken
    ) external view returns (uint256 marketBalance) {
        (IPoolDataProvider dataProvider, ) = _getDataProviderAndPool(clientId);

        (address aToken, , ) = dataProvider.getReserveTokensAddresses(
            underlyingToken
        );

        if (aToken == address(0)) revert UnsupportedReserveAsset();

        marketBalance = IERC20(aToken).balanceOf(address(this));
    }

    // ===============
    //    INTERNALS
    // ===============
    function _getDataProviderAndPool(
        bytes32 clientId
    ) internal view returns (IPoolDataProvider dataProvider, IPool pool) {
        address YC_DIAMOND = diamond();

        IPoolAddressesProviderRegistry poolRegistry = AaveV3AdapterStorageManager(
                address(YC_DIAMOND)
            ).getAaveV3Client(clientId);

        if (address(poolRegistry) == address(0)) revert UnsupportedClient();

        IPoolAddressesProvider poolAddressesProvider = IPoolAddressesProvider(
            poolRegistry.getAddressesProvidersList()[0]
        );

        pool = IPool(IPoolAddressesProvider(poolAddressesProvider).getPool());

        dataProvider = IPoolDataProvider(
            poolAddressesProvider.getPoolDataProvider()
        );
    }
}
