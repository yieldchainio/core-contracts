// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Classify a Uni V2 LP Client
 */

import "src/diamond/facets/adapters/lp/LpAdapter.sol";
import "src/diamond/Diamond.sol";
import "forge-std/Script.sol";
import "src/diamond/facets/adapters/lp/clients/UniV2.sol";

contract AddUniV2Client is Script {
    Diamond diamond =
        Diamond(payable(0xbAF45B60F69eCa4616CdE172D3961C156946e831));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        bytes32[] memory clientsIds = new bytes32[](6);
        address[] memory clientsAddresses = new address[](6);

        // Sushiswap
        clientsIds[0] = bytes32(
            keccak256(abi.encode("b5659605-0ce0-47b0-a93a-cb0dc6dac33e"))
        );
        clientsAddresses[0] = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

        // Camelot
        clientsIds[1] = bytes32(
            keccak256(abi.encode("702ddaa4-8077-494d-91e1-dc771b7d9936"))
        );
        clientsAddresses[1] = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;

        // Fraxswap
        clientsIds[2] = bytes32(
            keccak256(abi.encode("35675b11-7a7e-464f-99f5-93e966a91f39"))
        );
        clientsAddresses[2] = 0xCAAaB0A72f781B92bA63Af27477aA46aB8F653E7;

        // ApeSwap
        clientsIds[3] = bytes32(
            keccak256(abi.encode("fe7f8c43-a4d5-4028-8041-981898c6c8fa"))
        );
        clientsAddresses[3] = 0x7d13268144adcdbEBDf94F654085CC15502849Ff;

        // Arbidex
        clientsIds[4] = bytes32(
            keccak256(abi.encode("1281d2c9-168b-416f-8359-511deefc6f4f"))
        );
        clientsAddresses[4] = 0x7238FB45146BD8FcB2c463Dc119A53494be57Aac;

        // Arbswap
        clientsIds[5] = bytes32(
            keccak256(abi.encode("3c76104d-5148-48d4-bc75-4f22125c3ad4"))
        );
        clientsAddresses[5] = 0xD01319f4b65b79124549dE409D36F25e04B3e551;

        LPClient[] memory clients = new LPClient[](clientsAddresses.length);

        for (uint256 i; i < clients.length; i++)
            clients[i] = LPClient(
                UniV2LpAdapterFacet.addLiquidityUniV2.selector,
                UniV2LpAdapterFacet.removeLiquidityUniV2.selector,
                0x00000000,
                UniV2LpAdapterFacet.balanceOfUniV2LP.selector,
                clientsAddresses[i],
                new bytes(0)
            );

        LpAdapterFacet(address(diamond)).batchAddClients(clientsIds, clients);

        vm.stopBroadcast();
    }
}

// forge script ./script/classifyUniV2Lp.s.sol:AddUniV2Client --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi
