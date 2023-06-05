// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Struct representing the storage of the Lending Adapter
struct LendingAdapterStorage {
    // Mapping client IDs (protocol IDs from the DB) => their implementation selectors on the diamond
    mapping(bytes32 => LendingClient) clientsSelectors;
    // All of the client IDs
    bytes32[] clients;
}

// Represents a client classification
struct LendingClient {
    bytes4 supplySelector;
    bytes4 withdrawSelector;
    bytes4 borrowSelector;
    bytes4 repaySelector;
    bytes4 flashLoanSelector;
    bytes4 setTokenAsCollateralSelector;
    bytes4 harvestInterestSelector;
    bytes4 harvestIncentivesSelector;
    bytes4 loopSelector;
    address clientAddress;
    bytes extraData;
}

library LendingAdapterStorageLib {
    // Storage slot hash
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.adapters.lending");

    // Retreive the storage struct
    function retreive()
        internal
        pure
        returns (LendingAdapterStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}
