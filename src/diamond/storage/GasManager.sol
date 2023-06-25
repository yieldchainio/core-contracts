/**
 * Storage for the gas manager
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../vault/Vault.sol";

struct GasManagerStorage {
    /**
     * L2 hook selector to call as own facet, that returns the gas left in the transaction
     * from an L1 standpoint
     */
    bytes4 l2GasLeftSelector;
}

/**
 * The lib to use to retreive the storage
 */
library GasManagerStorageLib {
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.strategies");

    // Function to retreive our storage
    function retreive() internal pure returns (GasManagerStorage storage s) {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function getL2GasLeft() internal view returns (uint256 l2GasLeft) {
    bytes4 l2GasLeftSel =     retreive().l2GasLeftSelector;

    if (l2GasLeftSel == )

        (bool success, bytes memory res) = address(this).staticcall(
            abi.encodeWithSelector(l2GasLeftSel)
        );

        require(success, "Failed to get L1 gas")
    }
}
