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

    string clientID = "6322aa80-b03a-4e7b-803f-93d205d1f3bf";
    address clientRouterAddress = 0x16e71B13fE6079B4312063F7E81F76d165Ad32Ad;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        bytes32 clientId = keccak256(abi.encode(clientID));

        LpAdapterFacet(address(diamond)).addClient(
            clientId,
            LPClient(
                UniV2LpAdapterFacet.addLiquidityUniV2.selector,
                UniV2LpAdapterFacet.removeLiquidityUniV2.selector,
                0x00000000,
                clientRouterAddress,
                new bytes(0)
            )
        );

        vm.stopBroadcast();
    }
}


// forge script ./script/classifyUniV2Lp.s.sol:AddUniV2Client --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi
