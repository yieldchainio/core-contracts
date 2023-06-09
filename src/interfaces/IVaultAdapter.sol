/**
 * An interface every vault adapter shall comply with
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract VaultAdapterCompatible {
    function diamond() internal view returns (address diamondAddress) {
        bytes32 diamondStorageNamespace = keccak256(
            "adapters.yieldchain_diamond"
        );
        assembly {
            diamondAddress := sload(diamondStorageNamespace)
        }
    }

    modifier vaultCompatible(address diamondAddress) {
        bytes32 diamondStorageNamespace = keccak256(
            "adapters.yieldchain_diamond"
        );
        assembly {
            sstore(diamondStorageNamespace, diamondAddress)
        }
        _;
    }
}
