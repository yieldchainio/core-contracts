/**
 * Test deployment of Diamond and facets
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../src/diamond/facets/diamond-core/DiamondCutFacet.sol";
import "../../src/diamond/facets/diamond-core/DiamondLoupeFacet.sol";
import "../../src/diamond/facets/diamond-core/OwnershipFacet.sol";
import "../../src/diamond/facets/core/AccessControl.sol";
import "../../src/diamond/facets/core/Execution.sol";
import "../../src/diamond/facets/core/Factory.sol";
import "../../src/diamond/facets/core/TokenStash.sol";
import "../../src/diamond/facets/core/Users.sol";
import "../../src/diamond/Diamond.sol";
import "../../src/diamond/interfaces/IDiamond.sol";
import "../../src/diamond/interfaces/IDiamondCut.sol";
import "../../src/diamond/interfaces/IDiamondLoupe.sol";
import "../../src/diamond/interfaces/IERC165.sol";
import "../../src/diamond/interfaces/IERC173.sol";
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
    ExecutionFacet executionFacet;
    FactoryFacet factoryFacet;
    TokenStashFacet tokenStashFacet;
    StrategiesViewerFacet strategiesViewerFacet;
    GasManagerFacet gasManagerFacet;

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
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        accessControlFacet = new AccessControlFacet();
        executionFacet = new ExecutionFacet();
        factoryFacet = new FactoryFacet();
        tokenStashFacet = new TokenStashFacet();
        strategiesViewerFacet = new StrategiesViewerFacet();
        gasManagerFacet = new GasManagerFacet();

        vm.makePersistent(address(dCutFacet));
        vm.makePersistent(address(dLoupe));
        vm.makePersistent(address(ownerF));
        vm.makePersistent(address(accessControlFacet));
        vm.makePersistent(address(factoryFacet));
        vm.makePersistent(address(tokenStashFacet));
        vm.makePersistent(address(strategiesViewerFacet));
        vm.makePersistent(address(gasManagerFacet));

        facetNames = [
            "DiamondCutFacet",
            "DiamondLoupeFacet",
            "OwnershipFacet",
            "AccessControlFacet",
            "ExecutionFacet",
            "FactoryFacet",
            "TokenStashFacet",
            "StrategiesViewerFacet",
            "GasManagerFacet"
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
        FacetCut[] memory cut = new FacetCut[](8);

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
                facetAddress: address(executionFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ExecutionFacet")
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
                facetAddress: address(strategiesViewerFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("StrategiesViewerFacet")
            })
        );

        cut[7] = (
            FacetCut({
                facetAddress: address(gasManagerFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("GasManagerFacet")
            })
        );

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
