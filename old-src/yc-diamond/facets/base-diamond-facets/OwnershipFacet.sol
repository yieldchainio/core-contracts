// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../libraries/LibDiamond.sol";
import {IERC173} from "../../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    // Enforces ownership on function calls
    modifier isOwner() {
        require(
            msg.sender == LibDiamond.contractOwner(),
            "Only the owner can run this function"
        );
        _;
    }

    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
