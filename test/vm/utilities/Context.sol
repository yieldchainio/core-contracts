// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

contract Context {
    // Get the msg.sender (delegatecall to this)
    function msgSender() public view returns (address) {
        return msg.sender;
    }
}
