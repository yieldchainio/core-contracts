/**
 * Storage for the TokenStash facet
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../vault/Vault.sol";
import {IERC20} from "../../interfaces/IERC20.sol";

struct TokenStashStorage {
    /**
     * Nested mapping of
     * Vault address => token address => balance
     */
    mapping(Vault => mapping(IERC20 => uint256)) strategyStashes;
}

/**
 * The lib to use to retreive the storage
 */
library TokenStashStorageLib {
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.yieldchain.storage.token_stasher");

    // Function to retreive our storage
    function retreive() internal pure returns (TokenStashStorage storage s) {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function addToStrategyStash(
        Vault strategy,
        IERC20 token,
        uint256 amount
    ) internal {
        retreive().strategyStashes[strategy][token] += amount;
    }

    function removeFromStrategyStash(
        Vault strategy,
        IERC20 token,
        uint256 amount
    ) internal {
        require(
            retreive().strategyStashes[strategy][token] >= amount,
            "Insufficient Balance To Deduct From Stash"
        );

        retreive().strategyStashes[strategy][token] -= amount;
    }
}
