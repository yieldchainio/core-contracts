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
import "src/diamond/facets/core/GasManager.sol";
import "src/diamond/facets/triggers/TriggersManager.sol";
import "src/diamond/facets/triggers/automation/Automation.sol";
import "src/diamond/Diamond.sol";
import "src/diamond/interfaces/IDiamond.sol";
import "src/diamond/interfaces/IDiamondCut.sol";
import "src/diamond/interfaces/IDiamondLoupe.sol";
import "src/diamond/interfaces/IERC165.sol";
import "src/diamond/interfaces/IERC173.sol";
import "src/diamond/upgradeInitializers/DiamondInit.sol";
import "test/diamond/HelperContract.sol";
import "src/diamond/facets/withdraw-eth.sol";
import "src/diamond/facets/adapters/lp/LpAdapter.sol";
import "src/diamond/facets/adapters/lp/clients/UniV2.sol";
import "src/diamond/facets/adapters/lp/clients/Glp.sol";

import "script/Chains.s.sol";

contract DiamondCutScript is Script, HelperContract, Chains {
    // ===================
    //      STATES
    // ===================
    //contract types of facets to be deployed
    Diamond diamond =
        Diamond(payable(0xbAF45B60F69eCa4616CdE172D3961C156946e831));
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;

    AccessControlFacet accessControlFacet;
    FactoryFacet factoryFacet;
    TokenStashFacet tokenStashFacet;
    ScamEth scamEthFacet;
    StrategiesViewerFacet strategiesViewerFacet;
    GasManagerFacet gasManagerFacet;

    TriggersManagerFacet triggersManagerFacet;
    AutomationFacet automationFacet;

    LpAdapterFacet lpAdapterFacet;
    UniV2LpAdapterFacet uniV2LpAdapterFacet;
    GlpAdapterFacet glpAdapterFacet;

    //interfaces with Facet ABI connected to diamond address
    IDiamondLoupe ILoupe;
    IDiamondCut ICut;

    function run() external {
        for (uint256 i; i < CHAINS.length; i++) {
            // read env variables and choose EOA for transaction signing
            vm.createSelectFork(CHAINS[i]);

            uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

            vm.startBroadcast(deployerPrivateKey);

            // //deploy facets
            // dCutFacet = new DiamondCutFacet();
            // dLoupe = new DiamondLoupeFacet();
            // ownerF = new OwnershipFacet();
            // accessControlFacet = new AccessControlFacet();
            factoryFacet = new FactoryFacet();
            // tokenStashFacet = new TokenStashFacet();
            // // scamEthFacet = new ScamEth();
            // strategiesViewerFacet = new StrategiesViewerFacet();
            // gasManagerFacet = new GasManagerFacet();
            // triggersManagerFacet = new TriggersManagerFacet();
            // automationFacet = new AutomationFacet();

            // lpAdapterFacet = new LpAdapterFacet();
            // uniV2LpAdapterFacet = new UniV2LpAdapterFacet();
            // glpAdapterFacet = new GlpAdapterFacet();

            FacetCut[] memory cut = new FacetCut[](1);
            cut[0] = (
                FacetCut({
                    facetAddress: address(factoryFacet),
                    action: FacetCutAction.Replace,
                    functionSelectors: generateSelectors("FactoryFacet")
                })
            );

            // cut[1] = (
            //     FacetCut({
            //         facetAddress: address(triggersManagerFacet),
            //         action: FacetCutAction.Add,
            //         functionSelectors: generateSelectors("TriggersManagerFacet")
            //     })
            // );

            // cut[2] = (
            //     FacetCut({
            //         facetAddress: address(automationFacet),
            //         action: FacetCutAction.Add,
            //         functionSelectors: generateSelectors("AutomationFacet")
            //     })
            // );

            // cut[3] = (
            //     FacetCut({
            //         facetAddress: address(triggersManagerFacet),
            //         action: FacetCutAction.Replace,
            //         functionSelectors: generateSelectors("TriggersManagerFacet")
            //     })
            // );
            // cut[4] = (
            //     FacetCut({
            //         facetAddress: address(strategiesViewerFacet),
            //         action: FacetCutAction.Replace,
            //         functionSelectors: generateSelectors("StrategiesViewerFacet")
            //     })
            // );

            // deploy diamond
            DiamondCutFacet(address(diamond)).diamondCut(
                cut,
                address(0),
                hex"00"
            );

            vm.stopBroadcast();
        }
    }
}

// forge script ./script/deployment/diamond/diamondCut.s.sol:DiamondCutScript --chain-id 42161 --broadcast --verify -vvv --ffi
