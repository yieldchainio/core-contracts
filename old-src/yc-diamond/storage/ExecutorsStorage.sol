// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Struct representing a basic strategy - only details required for implementation
struct ExecutorsStorage {
    address[] executors;
}

// Library for Strategies-related storage, inherited by all strategy orchestration related facets
library ExecutorsStorageLib {
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("com.yieldchain.executors");

    // Retreive the storage struct
    function getExecutorsStorage()
        internal
        pure
        returns (ExecutorsStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}
