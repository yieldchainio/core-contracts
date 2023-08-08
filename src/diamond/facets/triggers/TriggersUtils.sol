/**
 * Utils used by the Triggers facets
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "src/vault/Vault.sol";
import {BytesLib} from "lib/solidity-bytes-utils/contracts/BytesLib.sol";
error OffchainLookup(
    address sender,
    string[] urls,
    bytes callData,
    bytes4 callbackFunction,
    bytes extraData
);

// @production-facet
contract TriggersUtils {
    function safeRunStrategy(Vault vault) internal {
        try vault.runStrategy() {} catch (bytes memory revertData) {
            bytes4 OffchainLookupSel = 0x556f1830;

            // Bubble up revert regulerly if not an offchain lookup
            if (bytes4(revertData) != OffchainLookupSel)
                assembly {
                    revert(revertData, mload(revertData))
                }

            // Otherwise re-bubble with ourselves as the sneder
            bytes memory args = BytesLib.slice(
                revertData,
                4,
                revertData.length - 4
            );

            (
                ,
                string[] memory urls,
                bytes memory callData,
                bytes4 callbackFunction,
                bytes memory extraData
            ) = abi.decode(args, (address, string[], bytes, bytes4, bytes));

            revert OffchainLookup(
                address(this),
                urls,
                callData,
                callbackFunction,
                extraData
            );
        }
    }
}
