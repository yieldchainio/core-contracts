// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Struct representing the storage of the AaveV3 adapter
struct AaveV3LendingAdapterStorage {
    uint256 unused;
}

library AaveV3LendingAdapterStorageLib {
    // Storage slot hash
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.adapters.lending.clients.aavev3");

    // Retreive the storage struct
    function retreive()
        internal
        pure
        returns (AaveV3LendingAdapterStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}
