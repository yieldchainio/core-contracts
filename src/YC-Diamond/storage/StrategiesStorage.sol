// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../YC-Strategy-Base.sol";

// Struct representing a basic strategy - only details required for implementation
struct IStrategy {
    string title;
    uint256 id;
    uint256 upkeepID;
    uint256 automation_interval;
    address contract_address;
    YCStrategyBase contract_instance;
}
struct StrategiesStorage {
    // Strategy ID => Strategy Struct
    mapping(uint256 => IStrategy) strategies;
    // Array of all strategy IDs
    uint256[] strategiesIDs;
}

// Library for Strategies-related storage, inherited by all strategy orchestration related facets
library StrategiesStorageLib {
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("com.yieldchain.strategies");

    // Retreive the storage struct
    function getStrategiesStorage()
        internal
        pure
        returns (StrategiesStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}
