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
import "src/diamond/facets/core/GasManager.sol";
import "src/diamond/facets/core/StrategiesViewer.sol";

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
        executionFacet = new ExecutionFacet();
        factoryFacet = new FactoryFacet();
        tokenStashFacet = new TokenStashFacet();
        strategiesViewerFacet = new StrategiesViewerFacet();
        gasManagerFacet = new GasManagerFacet();

        DiamondInit diamondInit = new DiamondInit();

        // diamond arguments
        DiamondArgs memory _args = DiamondArgs({
            owner: deployerAddress,
            init: address(diamondInit),
            initCalldata: abi.encodeWithSignature("init()")
        });

        FacetCut[] memory cut = new FacetCut[](9);

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
                facetAddress: address(executionFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("ExecutionFacet")
            })
        );
        cut[5] = (
            FacetCut({
                facetAddress: address(factoryFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("FactoryFacet")
            })
        );
        cut[6] = (
            FacetCut({
                facetAddress: address(tokenStashFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("TokenStashFacet")
            })
        );

        cut[7] = (
            FacetCut({
                facetAddress: address(gasManagerFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("GasManagerFacet")
            })
        );

        cut[8] = (
            FacetCut({
                facetAddress: address(strategiesViewerFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("StrategiesViewerFacet")
            })
        );

        // deploy diamond
        diamond = new Diamond(cut, _args);

        vm.stopBroadcast();
    }
}
// forge script ./script/deployDiamond.s.sol:DeployScript --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvvv --ffi
// forge script ./script/deployDiamond.s.sol:DeployScript --chain-id 42161 --fork-url $ARBITRUM_RPC_URL  --broadcast --verify -vvvv --ffi
