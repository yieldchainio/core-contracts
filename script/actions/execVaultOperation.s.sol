// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "src/diamond/facets/diamond-core/DiamondCutFacet.sol";
import "src/diamond/facets/diamond-core/DiamondLoupeFacet.sol";
import "src/diamond/facets/diamond-core/OwnershipFacet.sol";
import "src/diamond/facets/core/AccessControl.sol";
import "src/diamond/facets/core/Factory.sol";
import "src/diamond/facets/core/TokenStash.sol";
import "src/diamond/facets/core/Users.sol";
import "src/diamond/Diamond.sol";
import "src/diamond/interfaces/IDiamond.sol";
import "src/diamond/interfaces/IDiamondCut.sol";
import "src/diamond/interfaces/IDiamondLoupe.sol";
import "src/diamond/interfaces/IERC165.sol";
import "src/diamond/interfaces/IERC173.sol";
import "src/diamond/upgradeInitializers/DiamondInit.sol";
import "test/diamond/HelperContract.sol";
import "forge-std/console.sol";

contract ExecutionScript is Script, HelperContract {
    function run() external {
        //read env variables and choose EOA for transaction signing
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Vault vaultAddress = Vault(0x776DdFb090479fC77bF857595c11D2B4ee1Cb61B);
        uint256 operationIdx = 2;
        bytes[] memory calldatas = new bytes[](5);
        calldatas[
            0
        ] = hex"0000000000000000000000000000000000000000000000000000000000000000";
        calldatas[
            1
        ] = hex"0000000000000000000000000000000000000000000000000000000000000000";
        calldatas[
            2
        ] = hex"0000000000000000000000000000000000000000000000000000000000000000";
        calldatas[
            3
        ] = hex"0000000000000000000000000000000000000000000000000000000000000000";
        calldatas[
            4
        ] = hex"050000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000673656c6628290000000000000000000000000000000000000000000000000000";

        // address(diamond).call(
        //     abi.encodeWithSignature(
        //         "hydrateAndExecuteRun(address,uint256,bytes[])",
        //         vaultAddress,
        //         operationIdx,
        //         calldatas
        //     )
        // );

        vm.stopBroadcast();
    }
}

// forge script ./script/execVaultOperation.s.sol:ExecutionScript --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --broadcast -vvv --ffi
