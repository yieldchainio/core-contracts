// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../interfaces/LinktokenInterface.sol";
import "../interfaces/AutomationRegistryInterface2_0.sol";

struct AutomationStorage {
    // Link Token Interface
    LinkTokenInterface i_link;
    address registrar;
    AutomationRegistryInterface i_registry;
    bytes4 registerSig;
}

// Library for Strategies-related storage, inherited by all strategy orchestration related facets
library AutomationStorageLib {
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("com.yieldchain.automation");

    // Retreive the storage struct
    function getAutomationStorage()
        internal
        pure
        returns (AutomationStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}
