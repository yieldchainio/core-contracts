/**
 * Management for business logic/storage
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AccessControlled} from "@diamond/AccessControlled.sol";
import {BusinessStorageLib, BusinessStorage} from "@diamond-storage/Business.sol";

contract BusinessFacet is AccessControlled {
    /**
     * Set the treasury address
     * @param treasuryAddress - The new treasury address
     */
    function setTreasury(address treasuryAddress) external onlyOwner {
        BusinessStorageLib.retreive().treasury = treasuryAddress;
    }
}
