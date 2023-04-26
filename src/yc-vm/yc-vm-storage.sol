// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract YCVMStorage {
    address YC_DIAMOND;

    constructor() {
        YC_DIAMOND = msg.sender;
    }
}
