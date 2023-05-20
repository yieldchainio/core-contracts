// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "src/diamond/facets/diamond-core/DiamondCutFacet.sol";
import "src/diamond/facets/diamond-core/DiamondLoupeFacet.sol";
import "src/diamond/facets/diamond-core/OwnershipFacet.sol";
import "src/diamond/facets/core/AccessControl.sol";
import "src/diamond/facets/core/Execution.sol";
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

        Diamond diamond = Diamond(
            payable(0xdDa4fcF0C099Aa9900c38F1e6A01b8B96B1480d3)
        );
        Vault vaultAddress = Vault(0x4E03524c3316246c775886500384601399B79Add);
        uint256 operationIdx = 0;
        bytes[] memory calldatas = new bytes[](0);

        console.logBytes(
            abi.encodeWithSignature(
                "hydrateAndExecuteRun(address,uint256,bytes[])",
                vaultAddress,
                operationIdx,
                calldatas
            )
        );

        ExecutionFacet(address(diamond)).hydrateAndExecuteRun(
            vaultAddress,
            operationIdx,
            calldatas
        );

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

// forge script ./script/execVaultOperation.s.sol:ExecutionScript --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --broadcast -vvvv --ffi
