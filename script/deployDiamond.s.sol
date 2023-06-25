// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Authors: Timo Neumann <timo@fyde.fi>, Rohan Sundar <rohan@fyde.fi>
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535

* Script to deploy template diamond with Cut, Loupe and Ownership facet
/******************************************************************************/

import "forge-std/Script.sol";
import "src/diamond/facets/diamond-core/DiamondCutFacet.sol";
import "src/diamond/facets/diamond-core/DiamondLoupeFacet.sol";
import "src/diamond/facets/diamond-core/OwnershipFacet.sol";
import "src/diamond/facets/core/AccessControl.sol";
import "src/diamond/facets/core/Factory.sol";
import "src/diamond/facets/core/GasManager.sol";
import "src/diamond/facets/core/TokenStash.sol";
import "src/diamond/facets/core/Users.sol";
import "src/diamond/Diamond.sol";
import "src/diamond/interfaces/IDiamond.sol";
import "src/diamond/interfaces/IDiamondCut.sol";
import "src/diamond/facets/adapters/lp/LpAdapter.sol";
import "src/diamond/facets/adapters/lp/clients/UniV2.sol";
import "src/diamond/facets/adapters/lp/clients/Glp.sol";
import "src/diamond/interfaces/IDiamondLoupe.sol";
import "src/diamond/interfaces/IERC165.sol";
import "src/diamond/interfaces/IERC173.sol";
import "src/diamond/upgradeInitializers/DiamondInit.sol";
import "test/diamond/HelperContract.sol";
import "src/diamond/facets/core/GasManager.sol";
import "src/diamond/facets/core/StrategiesViewer.sol";
import "src/diamond/facets/triggers/TriggersManager.sol";
import "src/diamond/facets/triggers/automation/Automation.sol";

contract DeployScript is Script, HelperContract {
    // ===================
    //      STATES
    // ===================
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;

    AccessControlFacet accessControlFacet;

    FactoryFacet factoryFacet;
    TokenStashFacet tokenStashFacet;
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

    string[] facetNames;
    address[] facetAddressList;

    function run() external {
        //read env variables and choose EOA for transaction signing
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.envAddress("PUBLIC_KEY");

        vm.startBroadcast(deployerPrivateKey);

        //deploy facets
        dCutFacet = new DiamondCutFacet();
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        accessControlFacet = new AccessControlFacet();
        factoryFacet = new FactoryFacet();
        tokenStashFacet = new TokenStashFacet();
        strategiesViewerFacet = new StrategiesViewerFacet();
        gasManagerFacet = new GasManagerFacet();
        triggersManagerFacet = new TriggersManagerFacet();
        automationFacet = new AutomationFacet();

        // Adapters Facets
        lpAdapterFacet = new LpAdapterFacet();
        uniV2LpAdapterFacet = new UniV2LpAdapterFacet();
        glpAdapterFacet = new GlpAdapterFacet();

        DiamondInit diamondInit = new DiamondInit();

        // diamond arguments
        DiamondArgs memory _args = DiamondArgs({
            owner: deployerAddress,
            init: address(diamondInit),
            initCalldata: abi.encodeWithSignature("init()")
        });

        FacetCut[] memory cut = new FacetCut[](13);

        cut[0] = FacetCut({
            facetAddress: address(dCutFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondCutFacet")
        });

        cut[1] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(accessControlFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AccessControlFacet")
            })
        );

        cut[4] = (
            FacetCut({
                facetAddress: address(factoryFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("FactoryFacet")
            })
        );
        cut[5] = (
            FacetCut({
                facetAddress: address(tokenStashFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("TokenStashFacet")
            })
        );

        cut[6] = (
            FacetCut({
                facetAddress: address(gasManagerFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("GasManagerFacet")
            })
        );

        cut[7] = (
            FacetCut({
                facetAddress: address(strategiesViewerFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("StrategiesViewerFacet")
            })
        );

        cut[8] = (
            FacetCut({
                facetAddress: address(triggersManagerFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("TriggersManagerFacet")
            })
        );

        cut[9] = (
            FacetCut({
                facetAddress: address(automationFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AutomationFacet")
            })
        );

        cut[10] = (
            FacetCut({
                facetAddress: address(lpAdapterFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("LpAdapterFacet")
            })
        );

        cut[11] = (
            FacetCut({
                facetAddress: address(uniV2LpAdapterFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("UniV2LpAdapterFacet")
            })
        );

        cut[12] = (
            FacetCut({
                facetAddress: address(glpAdapterFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("GlpAdapterFacet")
            })
        );

        // deploy diamond
        diamond = new Diamond(cut, _args);

        vm.stopBroadcast();
    }
}
// forge script ./script/deployDiamond.s.sol:DeployScript --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi
// forge script ./script/deployDiamond.s.sol:DeployScript --chain-id 42161 --fork-url $ARBITRUM_RPC_URL  --broadcast --verify -vvvv --ffi
