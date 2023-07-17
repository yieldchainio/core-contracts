/**
 * Test deployment of Diamond and facets
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "@facets/diamond-core/DiamondCutFacet.sol";
import "@facets/diamond-core/DiamondLoupeFacet.sol";
import "@facets/diamond-core/OwnershipFacet.sol";
import "@facets/core/AccessControl.sol";
import "@facets/core/Factory.sol";
import "@facets/core/GasManager.sol";
import "@facets/core/Users.sol";
import "@facets/core/Business.sol";

import "@facets/core/TokenStash.sol";
import "@facets/core/Users.sol";
import "@facets/adapters/lp/LpAdapter.sol";
import "@facets/adapters/lp/clients/UniV2.sol";
import {GlpAdapterFacet} from "@facets/adapters/lp/clients/Glp.sol";
import {LendingAdapterFacet} from "@facets/adapters/lending/LendingAdapter.sol";
import {AaveV3AdapterStorageManager} from "@facets/adapters/lending/clients/AaveV3Storage.sol";
import "@diamond/Diamond.sol";
import "@diamond/interfaces/IDiamond.sol";
import "@diamond/interfaces/IDiamondCut.sol";
import "@diamond/interfaces/IDiamondLoupe.sol";
import "@diamond/interfaces/IERC165.sol";
import "@diamond/interfaces/IERC173.sol";
import "./HelperContract.sol";
import "../utils/Forks.t.sol";

contract DiamondTest is Test, HelperContract {
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
    UsersFacet usersFacet;
    BusinessFacet businessFacet;

    TriggersManagerFacet triggersManagerFacet;
    AutomationFacet automationFacet;

    LpAdapterFacet lpAdapterFacet;
    UniV2LpAdapterFacet uniV2LpAdapterFacet;
    GlpAdapterFacet glpLpAdapterFacet;

    LendingAdapterFacet lendingAdapterFacet;
    AaveV3AdapterStorageManager aaveV3StorageManager;

    //interfaces with Facet ABI connected to diamond address
    IDiamondLoupe ILoupe;
    IDiamondCut ICut;

    string[] facetNames;
    address[] facetAddressList;

    /**
     * Setup function
     */
    function setUp() public virtual {
        uint256 networkID = new Forks().ARBITRUM();
        vm.selectFork(networkID);
        deployAndGetDiamond();
    }

    function deployAndGetDiamond() public returns (Diamond) {
        // Core Facets
        dCutFacet = new DiamondCutFacet();
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        accessControlFacet = new AccessControlFacet();
        factoryFacet = new FactoryFacet();
        tokenStashFacet = new TokenStashFacet();
        strategiesViewerFacet = new StrategiesViewerFacet();
        gasManagerFacet = new GasManagerFacet();
        usersFacet = new UsersFacet();
        businessFacet = new BusinessFacet();

        // Triggers Facets
        triggersManagerFacet = new TriggersManagerFacet();
        automationFacet = new AutomationFacet();

        // Adapters Facets
        lpAdapterFacet = new LpAdapterFacet();
        uniV2LpAdapterFacet = new UniV2LpAdapterFacet();
        glpLpAdapterFacet = new GlpAdapterFacet();

        lendingAdapterFacet = new LendingAdapterFacet();
        aaveV3StorageManager = new AaveV3AdapterStorageManager();

        facetNames = [
            "DiamondCutFacet",
            "DiamondLoupeFacet",
            "OwnershipFacet",
            "AccessControlFacet",
            "ExecutionFacet",
            "FactoryFacet",
            "TokenStashFacet",
            "StrategiesViewerFacet",
            "GasManagerFacet",
            "TriggersManagerFacet",
            "AutomationFacet",
            "LpAdapterFacet",
            "UniV2LpAdapterFacet",
            "GlpAdapterFacet",
            "LendingAdapterFacet",
            "AaveV3LendingAdapterFacet",
            "UsersFacet",
            "BusinessFacet"
        ];

        // diamod arguments
        DiamondArgs memory _args = DiamondArgs({
            owner: address(this),
            init: address(0),
            initCalldata: " "
        });

        // FacetCut with CutFacet for initialisation
        FacetCut[] memory cut0 = new FacetCut[](1);
        cut0[0] = FacetCut({
            facetAddress: address(dCutFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondCutFacet")
        });

        // deploy diamond
        diamond = new Diamond(cut0, _args);

        vm.makePersistent(address(diamond));

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](16);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(accessControlFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AccessControlFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(factoryFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("FactoryFacet")
            })
        );
        cut[4] = (
            FacetCut({
                facetAddress: address(tokenStashFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("TokenStashFacet")
            })
        );

        cut[5] = (
            FacetCut({
                facetAddress: address(strategiesViewerFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("StrategiesViewerFacet")
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
                facetAddress: address(triggersManagerFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("TriggersManagerFacet")
            })
        );
        cut[8] = (
            FacetCut({
                facetAddress: address(automationFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AutomationFacet")
            })
        );

        cut[9] = (
            FacetCut({
                facetAddress: address(lpAdapterFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("LpAdapterFacet")
            })
        );

        cut[10] = (
            FacetCut({
                facetAddress: address(uniV2LpAdapterFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("UniV2LpAdapterFacet")
            })
        );

        cut[11] = (
            FacetCut({
                facetAddress: address(glpLpAdapterFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("GlpAdapterFacet")
            })
        );

        cut[12] = (
            FacetCut({
                facetAddress: address(lendingAdapterFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("LendingAdapterFacet")
            })
        );

        cut[13] = (
            FacetCut({
                facetAddress: address(aaveV3StorageManager),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors(
                    "AaveV3AdapterStorageManager"
                )
            })
        );

        cut[14] = (
            FacetCut({
                facetAddress: address(usersFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("UsersFacet")
            })
        );

        cut[15] = (
            FacetCut({
                facetAddress: address(businessFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors(
                    "BusinessFacet"
                )
            })
        );

        for (uint256 i; i < cut.length; i++)
            vm.makePersistent(cut[i].facetAddress);

        // initialise interfaces
        ILoupe = IDiamondLoupe(address(diamond));
        ICut = IDiamondCut(address(diamond));

        //upgrade diamond
        ICut.diamondCut(cut, address(0), "");

        // get all addresses
        facetAddressList = ILoupe.facetAddresses();

        return diamond;
    }
}
