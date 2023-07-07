// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// /******************************************************************************\
// * Authors: Timo Neumann <timo@fyde.fi>, Rohan Sundar <rohan@fyde.fi>
// * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535

// * Script to deploy template diamond with Cut, Loupe and Ownership facet
// /******************************************************************************/

// import "forge-std/Script.sol";
// import "src/CCIPTest.sol";

// contract DeployScript is Script {
//     function run() external {
//         //read env variables and choose EOA for transaction signing
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

//         vm.startBroadcast(deployerPrivateKey);

//         new CCIPTest();

//         vm.stopBroadcast();
//     }
// }
// // forge script ./script/deployCCIPTest.s.sol:DeployScript --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi
