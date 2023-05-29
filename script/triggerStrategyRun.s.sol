// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "src/diamond/facets/diamond-core/DiamondCutFacet.sol";
import "src/diamond/facets/diamond-core/DiamondLoupeFacet.sol";
import "src/diamond/facets/diamond-core/OwnershipFacet.sol";
import "src/diamond/facets/core/AccessControl.sol";
import "src/diamond/facets/core/Execution.sol";
import "src/diamond/facets/core/GasManager.sol";
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

        console.log("Hey");

        Diamond diamond = Diamond(
            payable(0xbAF45B60F69eCa4616CdE172D3961C156946e831)
        );
        Vault vaultAddress = Vault(0xFba4846d1bd5211060c99c37996afaA8f1859a70);

        Vault[] memory strategies = StrategiesViewerFacet(address(diamond))
            .getStrategiesList();

        uint256 idx;

        for (uint256 i; i < strategies.length; i++)
            if (address(strategies[i]) == address(vaultAddress)) {
                idx = i;
                break;
            }

        require(idx != 0, "Didnt find strat");

        console.log("after loop");

        uint256[] memory indices = new uint256[](1);
        indices[0] = idx;

        bool[][] memory triggs = new bool[][](1);
        bool[] memory trigg = new bool[](1);
        trigg[0] = true;
        triggs[0] = trigg;

        console.log("b4 check");

     

        bool[][] memory check = TriggersManagerFacet(address(diamond))
            .checkStrategiesTriggers();

        console.log("Chec Length", check.length);

        if (!check[idx][0]) revert("Trigger Not Ready So Cannot Execute");

        vm.startBroadcast(deployerPrivateKey);

        GasManagerFacet(address(diamond)).fundGasBalance{value: 0.001 ether}(
            address(vaultAddress)
        );

        TriggersManagerFacet(address(diamond)).executeStrategiesTriggers(
            indices,
            triggs
        );

        vm.stopBroadcast();
    }
}

// forge script ./script/triggerStrategyRun.s.sol:TriggerRunScript --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --broadcast -vvvv --ffi
