// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
struct ClassificationsStorage {
    // Classified Function (i.e "func_30") => External function impl (i,e "addLiquidity(address,address,uint256,uint256)")
    mapping(string => string) classifiedFunctions;
}

// Library for Strategies-related storage, inherited by all strategy orchestration related facets
library ClassificationsStorageLib {
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("com.yieldchain.classifications");

    // Retreive the storage struct
    function getClassificationsStorage()
        internal
        pure
        returns (ClassificationsStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}
