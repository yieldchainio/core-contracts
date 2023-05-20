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

contract TriggerRunScript is Script, HelperContract {
    function run() external {
        //read env variables and choose EOA for transaction signing
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Diamond diamond = Diamond(
            payable(0xdDa4fcF0C099Aa9900c38F1e6A01b8B96B1480d3)
        );
        Vault vaultAddress = Vault(0x2A85A8CC042CCaB938C724439314d15427A36Bd2);

        FactoryFacet(address(diamond)).fundGasBalance{value: 0.01 ether}(
            address(vaultAddress)
        );

        ExecutionFacet(address(diamond)).triggerStrategyRun(vaultAddress);

        vm.stopBroadcast();
    }
}

// forge script ./script/triggerStrategyRun.s.sol:TriggerRunScript --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --broadcast -vvvv --ffi
