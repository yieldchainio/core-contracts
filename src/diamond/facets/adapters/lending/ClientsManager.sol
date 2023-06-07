/**
 * Clients manager for the Lending Adapter
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../Modifiers.sol";
import "../../../storage/adapters/lending/Lending.sol";

abstract contract LendingClientsManagerFacet is Modifiers {
    // ================
    //    SETTERS
    // ================
    /**
     * Add a client
     * @param clientID - ID of the client
     * @param client - Client representation to classify
     */
    function addLendingClient(
        bytes32 clientID,
        LendingClient calldata client
    ) public onlyOwner {
        LendingAdapterStorage storage LendingStorage = LendingAdapterStorageLib
            .retreive();

        require(
            LendingStorage.clientsSelectors[clientID].supplySelector ==
                bytes4(0),
            "Client Already Set. Use updateClient"
        );

        LendingStorage.clientsSelectors[clientID] = client;
        LendingStorage.clients.push(clientID);
    }

    /**
     * Batch add clients
     * @param clientsIds - IDs of the clients
     * @param clients - Array of the clients
     */
    function batchAddLendingClients(
        bytes32[] calldata clientsIds,
        LendingClient[] calldata clients
    ) external onlyOwner {
        require(clientsIds.length == clients.length, "Clients Length Mismatch");
        LendingAdapterStorage storage LendingStorage = LendingAdapterStorageLib
            .retreive();

        for (uint48 i; i < clientsIds.length; i++) {
            bytes32 clientID = clientsIds[i];
            require(
                LendingStorage.clientsSelectors[clientID].supplySelector ==
                    bytes4(0),
                "Client Already Set. Use updateClient"
            );

            LendingStorage.clientsSelectors[clientID] = clients[i];
            LendingStorage.clients.push(clientID);
        }
    }

    /**
     * Remove a client
     * @param clientID - ID of the client
     */
    function removeLendingClient(bytes32 clientID) external onlyOwner {
        LendingAdapterStorage storage LendingStorage = LendingAdapterStorageLib
            .retreive();

        uint256 idx = 500000;

        bytes32[] memory clients = LendingStorage.clients;

        for (uint256 i; i < clients.length; i++)
            if (clients[i] == clientID) {
                idx = i;
                break;
            }

        require(idx != 500000, "Didnt Find Existing Client");
        
        LendingStorage.clientsSelectors[clientID] = LendingClient(
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            address(0),
            new bytes(0)
        );

        LendingStorage.clients[idx] = clients[clients.length - 1];
        LendingStorage.clients.pop();
    }

    /**
     * Update a client
     * @param clientID - ID of the client
     * @param newClient - New client config to set
     */
    function updateLendingClient(
        bytes32 clientID,
        LendingClient calldata newClient
    ) external onlyOwner {
        LendingAdapterStorage storage LendingStorage = LendingAdapterStorageLib
            .retreive();

        LendingStorage.clientsSelectors[clientID] = newClient;
    }

    // ================
    //    GETTERS
    // ================
    function getLendingClients()
        external
        view
        returns (LendingClient[] memory clients)
    {
        LendingAdapterStorage storage LendingStorage = LendingAdapterStorageLib
            .retreive();

        bytes32[] memory clientsIds = LendingStorage.clients;

        clients = new LendingClient[](clientsIds.length);

        for (uint256 i; i < clients.length; i++)
            clients[i] = LendingStorage.clientsSelectors[clientsIds[i]];
    }

    function getLendingClient(
        bytes32 id
    ) external view returns (LendingClient memory client) {
        LendingAdapterStorage storage LendingStorage = LendingAdapterStorageLib
            .retreive();

        client = LendingStorage.clientsSelectors[id];
    }
}
