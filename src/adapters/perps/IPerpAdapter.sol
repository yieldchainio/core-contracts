/**
 * Interface for a lending provider
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IPerpsProvider {
    struct Trigger {
        uint256 priceUsd;
        bool triggerAbovePrice;
    }

    function increaseMarketPosition(
        bytes32 clientId,
        address index,
        bool isLong,
        address collateral,
        uint256 amountIn,
        uint32 leverage, // Precision = lev * 10,000
        Trigger positionTrigger,
        Trigger stoploss,
        Trigger takeProfit
    ) external;

    function decreaseMarketPosition(
        bytes32 clientId,
        address index,
        bool isLong,
        address collateral,
        uint256 percentageOfPosition,
        address receiveToken,
        Trigger positionTrigger,
    ) external;
}
