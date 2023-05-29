/**
 * Tests for the LP adapters managers
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../../../Deployment.t.sol";
import "../../../../../src/diamond/facets/adapters/lp/ClientsManager.sol";
import "../../../../../src/diamond/facets/adapters/lp/LpAdapter.sol";

contract LpAdapterTest is DiamondTest {
    /**
     * Test adding, managing clients
     */
    function testClientsManagement() external {
        bytes32 clientID = keccak256("Random Ass Client");
        bytes4 addSel = 0x44444444;
        bytes4 removeSel = 0x55555555;
        bytes4 harvestSel = 0x66666666;
        bytes4 balanceOfSel = 0x77777777;
        address clientAddress = address(25);
        bytes memory extraData = new bytes(50);

        LPClient memory client = LPClient(
            addSel,
            removeSel,
            harvestSel,
            balanceOfSel,
            clientAddress,
            extraData
        );

        LpClientsManagerFacet lpManagerFacet = LpClientsManagerFacet(
            address(diamond)
        );

        // Add a client
        lpManagerFacet.addClient(clientID, client);

        // Assert it was added
        LPClient memory clientAdded = lpManagerFacet.getClient(clientID);

        assertEq(
            clientAdded.addSelector,
            addSel,
            "Added Client, But Add Selector Mismatch"
        );
        assertEq(
            clientAdded.removeSelector,
            removeSel,
            "Added Client, But Remove Selector Mismatch"
        );
        assertEq(
            clientAdded.harvestSelector,
            harvestSel,
            "Added Client, But Harvest Sel Mismatch"
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
            lpManagerFacet.getClients().length,
            1,
            "Added CLient, but length mismatch"
        );

        // Update the add selector
        bytes4 newAddSelector = 0x99999999;

        client.addSelector = newAddSelector;

        lpManagerFacet.updateClient(clientID, client);

        assertEq(
            lpManagerFacet.getClient(clientID).addSelector,
            newAddSelector,
            "Added Client, But Add Selector Mismatch"
        );

        // Add Another Client, to test remvoing thereafter
        bytes32 newClientID = keccak256("Some Other Client");
        LPClient memory randomClient = LPClient(
            0x12121212,
            0x12121212,
            0x12121212,
            0x12121212,
            address(500),
            new bytes(0)
        );

        lpManagerFacet.addClient(newClientID, randomClient);

        assertEq(
            lpManagerFacet.getClients().length,
            2,
            "Added Another Client, But Length is not 2"
        );

        lpManagerFacet.removeClient(clientID);

        assertEq(
            lpManagerFacet.getClients().length,
            1,
            "Removed Original Client, But Length Is Not 1 (only random client shall remain)"
        );

        // Assert it was added
        LPClient memory supposedlyEmptyClient = lpManagerFacet.getClient(
            clientID
        );

        assertEq(
            supposedlyEmptyClient.addSelector,
            0x00000000,
            "Removed Client, But Add Selector Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.removeSelector,
            0x00000000,
            "Removed Client, But Remove Selector Is not Empty"
        );
        assertEq(
            supposedlyEmptyClient.harvestSelector,
            0x00000000,
            "Removed Client, But Harvest Selector Is not Empty"
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
