/**
 * Storage for the Automation trigger facet
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../vault/Vault.sol";

struct AutomationStorage {
    /**
     * Mapping each registered strategy to it's upkeep ID, which manages it's automations
     */
    mapping(Vault => uint256) upkeepIDs;
}

/**
 * The lib to use to retreive the storage
 */
library AutomationStorageLib {
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.triggers.automation");

    // Function to retreive our storage
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
