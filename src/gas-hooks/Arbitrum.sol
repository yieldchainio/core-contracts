/**
 * Hook to get gas spent in arbi transaction on the L1 (not otherwise available through gasleft())
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IGasHook} from "./IGasHook.sol";

contract ArbitrumL1GasHook is IGasHook {
    address internal constant ARB_GASINFO_PRECOMPILE =
        0x000000000000000000000000000000000000006C;

    function getAdditionalGasCost(
        bytes calldata msgData
    ) external view returns (uint256 additionalCost) {
        (, bytes memory res) = ARB_GASINFO_PRECOMPILE.staticcall(
            "getPricesInWei()"
        );
        (uint256 perL2Tx, uint256 perCalldataUnit, , , , ) = abi.decode(
            res,
            (uint256, uint256, uint256, uint256, uint256, uint256)
        );

        additionalCost = perL2Tx + (perCalldataUnit * msgData.length);
    }
}
