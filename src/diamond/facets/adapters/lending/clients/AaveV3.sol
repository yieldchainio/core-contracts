/**
 * Lending adapter for AAVE V3
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../../storage/adapters/lending/Lending.sol";
import {SafeERC20} from "../../../../../libs/SafeERC20.sol";
import {IERC20} from "../../../../../interfaces/IERC20.sol";

contract AaveV3LendingAdapterFacet {
    using SafeERC20 for IERC20;

    /**
     * Supply to a market on an AAVE V3 Client
     * @param client - The lending client as classified in the Lending adapter storage
     * @param asset - The address of the *underlying* asset
     * @param amount - The amount to supply
     */
    function supplyToAaveV3Market(
        LendingClient calldata client,
        address asset,
        uint256 amount
    ) external {
        
    }
}
