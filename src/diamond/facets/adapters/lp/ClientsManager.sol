/**
 * Clients manager for the Lp Adapter
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../AccessControlled.sol";
import "../../../storage/adapters/lp/LpAdapter.sol";

abstract contract LpClientsManagerFacet is AccessControlled {
    // ================
    //    SETTERS
    // ================
    /**
     * Add a client
     * @param clientID - ID of the client
     * @param client - Client representation to classify
     */
    function addClient(
        bytes32 clientID,
        LPClient calldata client
    ) public onlyOwner {
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib.retreive();

        require(
            lpStorage.clientsSelectors[clientID].addSelector == bytes4(0),
            "Client Already Set. Use updateClient"
        );

        lpStorage.clientsSelectors[clientID] = client;
        lpStorage.clients.push(clientID);
    }

    /**
     * Batch add clients
     * @param clientsIds - IDs of the clients
     * @param clients - Array of the clients
     */
    function batchAddClients(
        bytes32[] calldata clientsIds,
        LPClient[] calldata clients
    ) external onlyOwner {
        require(clientsIds.length == clients.length, "Clients Length Mismatch");
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib.retreive();

        for (uint48 i; i < clientsIds.length; i++) {
            bytes32 clientID = clientsIds[i];
            require(
                lpStorage.clientsSelectors[clientID].addSelector == bytes4(0),
                "Client Already Set. Use updateClient"
            );

            lpStorage.clientsSelectors[clientID] = clients[i];
            lpStorage.clients.push(clientID);
        }
    }

    /**
     * Remove a client
     * @param clientID - ID of the client
     */
    function removeClient(bytes32 clientID) external onlyOwner {
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib.retreive();

        uint256 idx = 500000;

        bytes32[] memory clients = lpStorage.clients;

        for (uint256 i; i < clients.length; i++)
            if (clients[i] == clientID) {
                idx = i;
                break;
            }

        require(idx != 500000, "Didnt Find Existing Client");

        lpStorage.clientsSelectors[clientID] = LPClient(
            0x00000000,
            0x00000000,
            0x00000000,
            0x00000000,
            address(0),
            new bytes(0)
        );

        lpStorage.clients[idx] = clients[clients.length - 1];
        lpStorage.clients.pop();
    }

    /**
     * Update a client
     * @param clientID - ID of the client
     * @param newClient - New client config to set
     */
    function updateClient(
        bytes32 clientID,
        LPClient calldata newClient
    ) external onlyOwner {
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib.retreive();

        lpStorage.clientsSelectors[clientID] = newClient;
    }

    // ================
    //    GETTERS
    // ================
    function getClients() external view returns (LPClient[] memory clients) {
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib.retreive();

        bytes32[] memory clientsIds = lpStorage.clients;

        clients = new LPClient[](clientsIds.length);

        for (uint256 i; i < clients.length; i++)
            clients[i] = lpStorage.clientsSelectors[clientsIds[i]];
    }

    function getClient(
        bytes32 id
    ) external view returns (LPClient memory client) {
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib.retreive();

        client = lpStorage.clientsSelectors[id];
    }
}
