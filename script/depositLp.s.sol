// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Classify a Uni V2 LP Client
 */

import "src/diamond/facets/adapters/lp/LpAdapter.sol";
import "src/diamond/Diamond.sol";
import "forge-std/Script.sol";
import "src/diamond/facets/adapters/lp/clients/UniV2.sol";
import "../src/diamond/facets/adapters/lp/ClientsManager.sol";
import "../src/diamond/facets/adapters/lp/LpAdapter.sol";
import "../src/diamond/facets/adapters/lp/clients/UniV2.sol";
import "../src/interfaces/IUniV2Factory.sol";

contract DepositLp is Script {
    Diamond diamond =
        Diamond(payable(0xbAF45B60F69eCa4616CdE172D3961C156946e831));

    string clientID = "6322aa80-b03a-4e7b-803f-93d205d1f3bf";
    address clientRouterAddress = 0x16e71B13fE6079B4312063F7E81F76d165Ad32Ad;

    address tokenA = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address tokenB = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address pair = 0x8b8149Dd385955DC1cE77a4bE7700CCD6a212e65;

    address ownAddress = 0x634176EcC95D326CAe16829d923C1373Df6ECe95;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        bytes32 clientId = keccak256(abi.encode(clientID));

        LpAdapterFacet(address(diamond)).removeLiquidity(
            tokenA,
            tokenB,
            IERC20(pair).balanceOf(ownAddress),
            clientId,
            new bytes[](0)
        );

        vm.stopBroadcast();
    }
}

// forge script ./script/depositLp.s.sol:DepositLp --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi
