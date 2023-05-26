/**
 * Clients manager for the Lp Adapter
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../Modifiers.sol";
import "../../../storage/adapters/lp-adapter/LpAdapter.sol";

contract LpClientsManagerFacet is Modifiers {
    /**
     * Add a client
     * @param clientID - ID of the client
     * @param client - Client representation to classify
     */
    function addClient(
        bytes32 clientID,
        Client memory client
    ) external onlyOwner {
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib
            .getLpAdapterStorage();

        require(
            lpStorage.clientsSelectors[clientID].addSelector == bytes4(0),
            "Client Already Set. Use updateClient"
        );

        lpStorage.clientsSelectors[clientID] = client;
    }

    /**
     * Remove a client
     * @param clientID - ID of the client
     */
    function removeClient(bytes32 clientID) external onlyOwner {
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib
            .getLpAdapterStorage();

        lpStorage.clientsSelectors[clientID] = Client(
            bytes4(0),
            bytes4(0),
            bytes4(0)
        );
    }

    /**
     * Update a client
     * @param clientID - ID of the client
     * @param newClient - New client config to set
     */
    function updateClient(
        bytes32 clientID,
        Client memory newClient
    ) external onlyOwner {
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib
            .getLpAdapterStorage();

        lpStorage.clientsSelectors[clientID] = newClient;
    }
}
