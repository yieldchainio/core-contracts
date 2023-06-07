/**
 * A Global LP Adapter,
 * enables onchain storage classification of clients
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./ClientsManager.sol";

contract LendingAdapterFacet is LendingClientsManagerFacet {
    /**
     * Supply tokens to a market on a client
     */
    function supplyToMarket(
        address asset,
        uint256 amount,
        bytes32 clientId,
        bytes memory extraArgs
    ) external {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.supplySelector;

        require(clientSel != bytes4(0), "Lending Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(clientSel, client, asset, amount, extraArgs)
        );

        require(success, "Supplying Failed");
    }

    /**
     * Withdraw tokens from a market on a client
     */
    function withdrawFromMarket(
        address asset,
        uint256 amount,
        bytes32 clientId,
        bytes memory extraArgs
    ) external {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.withdrawSelector;

        require(clientSel != bytes4(0), "Lending Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(clientSel, client, asset, amount, extraArgs)
        );

        require(success, "Withdrawing Failed");
    }

    /**
     * Borrow tokens from a market on a client
     */
    function borrowFromMarket(
        address asset,
        uint256 amount,
        bytes32 clientId,
        bytes memory extraArgs
    ) external {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.borrowSelector;

        require(clientSel != bytes4(0), "Lending Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(clientSel, client, asset, amount, extraArgs)
        );

        require(success, "Borrowing Failed");
    }

    /**
     * Repay debt to a market on a client
     */
    function repayDebtOnMarket(
        address asset,
        uint256 amount,
        bytes32 clientId,
        bytes memory extraArgs
    ) external {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.repaySelector;

        require(clientSel != bytes4(0), "Lending Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(clientSel, client, asset, amount, extraArgs)
        );

        require(success, "Repayment Failed");
    }

    /**
     * Make a flash loan on a client's market
     */
    function flashLoanOnMarket(
        address asset,
        uint256 amount,
        bytes memory params,
        bytes32 clientId,
        bytes memory extraArgs
    ) external {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.flashLoanSelector;

        require(clientSel != bytes4(0), "Lending Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(
                clientSel,
                client,
                asset,
                params,
                amount,
                extraArgs
            )
        );

        require(success, "Flashloan Failed");
    }

    /**
     * Set an asset reserve as collateral, or as non-collateral, on a client's market
     */
    function setAssetCollateralStatus(
        address asset,
        bool useAsCollateral,
        bytes32 clientId,
        bytes memory extraArgs
    ) external {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.setTokenAsCollateralSelector;

        require(clientSel != bytes4(0), "Lending Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(
                clientSel,
                client,
                asset,
                useAsCollateral,
                extraArgs
            )
        );

        require(success, "Setting Collateral Failed");
    }

    /**
     * Harvest accurated interest on deposits on a given client
     */
    function harvestLendingInterest(
        address token,
        bytes32 clientId,
        bytes memory extraArgs
    ) external {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.harvestInterestSelector;

        require(clientSel != bytes4(0), "Lending Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(clientSel, client, token, extraArgs)
        );

        require(success, "Harvesting Interest Failed");
    }

    /**
     * Harvest accurated incentivzed interest on a given client
     */
    function harvestLendingIncentives(
        bytes32 clientId,
        bytes memory extraArgs
    ) external {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.harvestIncentivesSelector;

        require(clientSel != bytes4(0), "Lending Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(clientSel, client, extraArgs)
        );

        require(success, "Harvesting Incentives Failed");
    }

    /**
     * "Loop" into some asset on a lending market.
     * i.e - Supply, use as collat, borrow, use borrowed funds to add to collateral,
     * etc etc to exponentially increase interest earned
     */
    function loopOnLendingMarket(
        address asset,
        uint256 amount,
        bytes32 clientId,
        bytes memory extraArgs
    ) external {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.loopSelector;

        require(clientSel != bytes4(0), "Lending Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(clientSel, client, asset, amount, extraArgs)
        );

        require(success, "Harvesting Interest Failed");
    }

    // ===============
    //     READ
    // ===============
    function getAllReserveTokens(
        bytes32 clientId
    ) external returns (address[] memory reserveTokens) {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.getSupportedReservesSelector;

        require(clientSel != bytes4(0), "Lending Client Not Supported");

        (bool success, bytes memory res) = address(this).delegatecall(
            abi.encodeWithSelector(clientSel, client)
        );

        require(success, "Getting Rserve Tokens Failed");

        reserveTokens = abi.decode(res, (address[]));
    }

    function getReserveTokenRepresentation(
        address token,
        bytes32 clientId
    ) external returns (address representationToken) {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.getRepresentationTokenSelector;

        require(clientSel != bytes4(0), "Lending Client Not Supported");

        (bool success, bytes memory res) = address(this).delegatecall(
            abi.encodeWithSelector(clientSel, client, token)
        );

        require(success, "Getting Rserve Tokens Failed");

        representationToken = abi.decode(res, (address));
    }

    function getRepresentationTokenBalance(
        address token,
        bytes32 clientId
    ) external returns (uint256 representationTokenBalance) {
        LendingAdapterStorage storage lendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingClient memory client = lendingStorage.clientsSelectors[clientId];
        bytes4 clientSel = client.balanceOfReserveSelector;

        require(clientSel != bytes4(0), "Lending Client Not Supported");

        (bool success, bytes memory res) = address(this).delegatecall(
            abi.encodeWithSelector(clientSel, client, token)
        );

        require(success, "Getting Rserve Tokens Balance Of Failed");

        representationTokenBalance = abi.decode(res, (uint256));
    }
}
