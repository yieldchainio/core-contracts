/**
 * Tests for the LP adapters managers
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../../Deployment.t.sol";
import "../../../../../src/diamond/facets/adapters/lending/LendingAdapter.sol";
import "../../../../../src/diamond/facets/adapters/lending/ClientsManager.sol";

contract LendingAdapterTest is DiamondTest {
    /**
     * Test adding, managing clients
     */
    function testClientsManagement() external {
        bytes32 clientID = keccak256("Random Ass Client");

        address clientAddress = address(25);
        bytes memory extraData = new bytes(50);

        LendingClient memory client = LendingClient(
            0x44444444,
            0x55555555,
            0x66666666,
            0x77777777,
            0x88888888,
            0x99999999,
            0xaaaaaaaa,
            0xbbbbbbbb,
            0xcccccccc,
            0xdddddddd,
            0xeeeeeeee,
            0xffffffff,
            0xaaaaffff,
            clientAddress,
            extraData
        );

        LendingAdapterFacet lendingManagerFacet = LendingAdapterFacet(
            address(diamond)
        );

        // Add a client
        lendingManagerFacet.addLendingClient(clientID, client);

        // Assert it was added
        LendingClient memory clientAdded = lendingManagerFacet.getLendingClient(
            clientID
        );

        assertEq(
            clientAdded.supplySelector,
            client.supplySelector,
            "Added Client, But Supply Selector Mismatch"
        );
        assertEq(
            clientAdded.withdrawSelector,
            client.withdrawSelector,
            "Added Client, But Withdraw Selector Mismatch"
        );
        assertEq(
            clientAdded.harvestInterestSelector,
            client.harvestInterestSelector,
            "Added Client, But Harvest Interest Sel Mismatch"
        );
        assertEq(
            clientAdded.harvestIncentivesSelector,
            client.harvestIncentivesSelector,
            "Added Client, But Harvest Incentives Sel Mismatch"
        );
        assertEq(
            clientAdded.loopSelector,
            client.loopSelector,
            "Added Client, But Loop Sel Mismatch"
        );
        assertEq(
            clientAdded.borrowSelector,
            client.borrowSelector,
            "Added Client, But Borrow Sel Mismatch"
        );
        assertEq(
            clientAdded.repaySelector,
            client.repaySelector,
            "Added Client, But Repay Sel Mismatch"
        );
        assertEq(
            clientAdded.balanceOfReserveSelector,
            client.balanceOfReserveSelector,
            "Added Client, But Bal Of Reserve Sel Mismatch"
        );
        assertEq(
            clientAdded.balanceOfDebtSelector,
            client.balanceOfDebtSelector,
            "Added Client, But Bal Of Debt Sel Mismatch"
        );
        assertEq(
            clientAdded.setTokenAsCollateralSelector,
            client.setTokenAsCollateralSelector,
            "Added Client, But Set Token As Collat Sel Mismatch"
        );
        assertEq(
            clientAdded.flashLoanSelector,
            client.flashLoanSelector,
            "Added Client, But Flashloan Sel Mismatch"
        );
        assertEq(
            clientAdded.extraData,
            extraData,
            "Added Client, But Extra Data Mismatch"
        );
        assertEq(
            clientAdded.clientAddress,
            clientAddress,
            "Added Client, But Client Address Mismatch"
        );

        assertEq(
            lendingManagerFacet.getLendingClients().length,
            1,
            "Added CLient, but length mismatch"
        );

        // Update the add selector
        bytes4 newAddSelector = 0x99999999;

        client.supplySelector = newAddSelector;

        lendingManagerFacet.updateLendingClient(clientID, client);

        assertEq(
            lendingManagerFacet.getLendingClient(clientID).supplySelector,
            newAddSelector,
            "Added Client, But Add Selector Mismatch"
        );

        // Add Another Client, to test remvoing thereafter
        bytes32 newClientID = keccak256("Some Other Client");
        LendingClient memory randomClient = LendingClient(
            0x12121212,
            0x12121212,
            0x12121212,
            0x12121212,
            0x12121212,
            0x12121212,
            0x12121212,
            0x12121212,
            0x12121212,
            0x12121212,
            0x12121212,
            0x12121212,
            0x12121212,
            address(500),
            new bytes(0)
        );

        lendingManagerFacet.addLendingClient(newClientID, randomClient);

        assertEq(
            lendingManagerFacet.getLendingClients().length,
            2,
            "Added Another Client, But Length is not 2"
        );

        lendingManagerFacet.removeLendingClient(clientID);

        assertEq(
            lendingManagerFacet.getLendingClients().length,
            1,
            "Removed Original Client, But Length Is Not 1 (only random client shall remain)"
        );

        // Assert it was added
        LendingClient memory supposedlyEmptyClient = lendingManagerFacet
            .getLendingClient(clientID);

        assertEq(
            supposedlyEmptyClient.supplySelector,
            0x00000000,
            "Removed Client, But Supply Selector Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.withdrawSelector,
            0x00000000,
            "Removed Client, But Withdraw Selector Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.borrowSelector,
            0x00000000,
            "Removed Client, But Borrow Selector Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.repaySelector,
            0x00000000,
            "Removed Client, But Repay Selector Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.harvestIncentivesSelector,
            0x00000000,
            "Removed Client, But Harvest Incentives Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.harvestInterestSelector,
            0x00000000,
            "Removed Client, But Harvest Incentives Selector Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.flashLoanSelector,
            0x00000000,
            "Removed Client, But flashloan Selector Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.balanceOfReserveSelector,
            0x00000000,
            "Removed Client, But balance of reserves Selector Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.balanceOfDebtSelector,
            0x00000000,
            "Removed Client, But balance of debt Selector Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.setTokenAsCollateralSelector,
            0x00000000,
            "Removed Client, But Set Token As Collat Selector Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.loopSelector,
            0x00000000,
            "Removed Client, But Loop Selector Is not Empty"
        );
        assertEq(
            bytes32(supposedlyEmptyClient.extraData),
            bytes32(0x00),
            "Removed Client, But Extra Data Not Empty"
        );
        assertEq(
            supposedlyEmptyClient.clientAddress,
            address(0),
            "Removed Client, But Client Address Not Empty"
        );
    }
}
