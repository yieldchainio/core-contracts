/**
 * Access control, managing execution permissions to whitelisted executors
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../vault/Vault.sol";
import "../../storage/Strategies.sol";
import "../../storage/AccessControl.sol";
import "../../Modifiers.sol";

contract AccessControlFacet is Modifiers {
    // ======================
    //      CONSTRUCTOR
    // ======================
    constructor() {
        AccessControlStorageLib.getAccessControlStorage().owner = msg.sender;
    }

    // ======================
    //       FUNCTIONS
    // ======================
    /**
     * @notice
     * Whitelist an executor
     * @param executor - Address of the executor to whitelist
     */
    function whitelistExecutor(address executor) public onlyOwner {
        // Storage ref
        AccessControlStorage
            storage accessControlStorage = AccessControlStorageLib
                .getAccessControlStorage();

        // Avoid dupes
        require(
            !accessControlStorage.isWhitelisted[executor],
            "Executor Already Whitelisted"
        );
        accessControlStorage.executors.push(executor);
        accessControlStorage.isWhitelisted[executor] = true;
    }

    /**
     * @notice
     * Blacklist an executor
     * @param executor - Address of the executor to blacklist
     *
     */
    function blacklistExecutor(address executor) public onlyOwner {
        // Storage ref
        AccessControlStorage
            storage accessControlStorage = AccessControlStorageLib
                .getAccessControlStorage();

        // Avoid dupes
        require(
            accessControlStorage.isWhitelisted[executor],
            "Executor Not Whitelisted"
        );

        // Create a new array of executors
        address[] memory newArr = new address[](
            accessControlStorage.executors.length - 1
        );
        // Push all exsiting executors to it, other than the one to blacklist
        for (uint256 i; i < accessControlStorage.executors.length; i++) {
            if (accessControlStorage.executors[i] == executor) continue;
            newArr[i] = accessControlStorage.executors[i];
        }

        // Set the storage
        accessControlStorage.executors = newArr;
        accessControlStorage.isWhitelisted[executor] = false;
    }
}
