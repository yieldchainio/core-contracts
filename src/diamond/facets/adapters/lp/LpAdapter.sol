/**
 * A Global LP Adapter,
 * enables onchain storage classification of clients
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./ClientsManager.sol";

contract LpAdapterFacet is LpClientsManagerFacet {
    /**
     * Add Liquidity To A Protocol
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        bytes32 clientId,
        bytes[] memory extraArgs
    ) external {
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib
            .getLpAdapterStorage();

        bytes4 clientSel = lpStorage.clientsSelectors[clientId].addSelector;

        require(clientSel != bytes4(0), "Lp Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(
                clientSel,
                tokenA,
                tokenB,
                amountA,
                amountB,
                clientId,
                extraArgs
            )
        );

        require(success, "Adding Lp Failed");
    }

    /**
     * Remove Liquidity From A Protocol
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        bytes32 clientId,
        bytes[] memory extraArgs
    ) external {
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib
            .getLpAdapterStorage();

        bytes4 clientSel = lpStorage.clientsSelectors[clientId].addSelector;

        require(clientSel != bytes4(0), "Lp Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(
                clientSel,
                tokenA,
                tokenB,
                amountA,
                amountB,
                clientId,
                extraArgs
            )
        );

        require(success, "Adding Lp Failed");
    }

    /**
     * Harvest Rewards From A Protocol
     */
    function harvestLiquidityRewards(
        address tokenA,
        address tokenB,
        bytes32 clientId,
        bytes[] memory extraArgs
    ) external {
        LpAdapterStorage storage lpStorage = LpAdapterStorageLib
            .getLpAdapterStorage();

        bytes4 clientSel = lpStorage.clientsSelectors[clientId].addSelector;

        require(clientSel != bytes4(0), "Lp Client Non Existant");

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSelector(
                clientSel,
                tokenA,
                tokenB,
                clientId,
                extraArgs
            )
        );

        require(success, "Adding Lp Failed");
    }
}
