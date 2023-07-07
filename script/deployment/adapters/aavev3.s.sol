// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Classify a Uni V2 LP Client
 */

import "src/diamond/facets/adapters/lp/LpAdapter.sol";
import "src/diamond/Diamond.sol";
import "forge-std/Script.sol";
import "src/diamond/facets/adapters/lp/clients/UniV2.sol";
import "src/adapters/lending/AaveV3.sol";

contract DeployAaveV3Adapter is Script {
    Diamond diamond =
        Diamond(payable(0xbAF45B60F69eCa4616CdE172D3961C156946e831));


    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        new AaveV3LendingAdapter(address(diamond));

        vm.stopBroadcast();
    }
}

// forge script ./script/deployAaveV3Adapter.s.sol:DeployAaveV3Adapter --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi
