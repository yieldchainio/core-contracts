// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Struct representing the storage of the LP Proxy
struct LpAdapterStorage {
    // Mapping client IDs (protocol IDs from the DB) => their implementation selectors on the diamond
    mapping(string => bytes4) clientsSelectors;
}

library LpAdapterStorageLib {
    // Storage slot hash
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.adapters.lp");

    // Retreive the storage struct
    function getLpAdapterStorage()
        internal
        pure
        returns (LpAdapterStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}