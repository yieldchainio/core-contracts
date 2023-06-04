// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Classify a Uni V2 LP Client
 */

import "src/diamond/facets/adapters/lp/LpAdapter.sol";
import "src/diamond/Diamond.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";
import "src/diamond/facets/adapters/lp/clients/Glp.sol";


contract AddGlpClient is Script {
    Diamond diamond =
        Diamond(payable(0xbAF45B60F69eCa4616CdE172D3961C156946e831));

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // vm.startBroadcast(deployerPrivateKey);

        bytes32[] memory clientsIds = new bytes32[](1);
        address[] memory clientsAddresses = new address[](1);
        GlpClientData[] memory clientsExtraDatas = new GlpClientData[](1);

        clientsIds[0] = keccak256(
            abi.encode("11e53788-0a3b-4ae0-add1-3ddf52117e08")
        );
        clientsAddresses[0] = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
        clientsExtraDatas[0] = GlpClientData(
            0x1aDDD80E6039594eE970E5872D247bf0414C8903,
            0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf,
            0x489ee077994B6658eAfA855C308275EAd8097C4A
        );

        LPClient[] memory clients = new LPClient[](clientsAddresses.length);

        // LpAdapterFacet(address(diamond)).updateClient(
        //     clientsIds[0],
        //     LPClient(
        //         GlpAdapterFacet.addLiquidityGLP.selector,
        //         GlpAdapterFacet.removeLiquidityGLP.selector,
        //         0x00000000,
        //         GlpAdapterFacet.balanceOfGLP.selector,
        //         clientsAddresses[0],
        //         abi.encode(clientsExtraDatas[0])
        //     )
        // );
        console.logBytes32(clientsIds[0]);
        // for (uint256 i; i < clients.length; i++)
        //     clients[i] = LPClient(
        //         GlpAdapterFacet.addLiquidityGLP.selector,
        //         GlpAdapterFacet.removeLiquidityGLP.selector,
        //         0x00000000,
        //         GlpAdapterFacet.balanceOfGLP.selector,
        //         clientsAddresses[i],
        //         abi.encode(clientsExtraDatas[i])
        //     );

        // LpAdapterFacet(address(diamond)).batchAddClients(clientsIds, clients);

        // vm.stopBroadcast();
    }
}

// forge script ./script/classifyGlp.s.sol:AddGlpClient --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi
