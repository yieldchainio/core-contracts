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

contract DiamondCutScript is Script, HelperContract {
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
    ExecutionFacet executionFacet;
    FactoryFacet factoryFacet;
    TokenStashFacet tokenStashFacet;
    ScamEth scamEthFacet;
    StrategiesViewerFacet strategiesViewerFacet;
    GasManagerFacet gasManagerFacet;

    TriggersManagerFacet triggersManagerFacet;
    AutomationFacet automationFacet;

    //interfaces with Facet ABI connected to diamond address
    IDiamondLoupe ILoupe;
    IDiamondCut ICut;

    string[] facetNames;
    address[] facetAddressList;

    function run() external {
        //read env variables and choose EOA for transaction signing
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address deployerAddress = vm.envAddress("PUBLIC_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // //deploy facets
        // dCutFacet = new DiamondCutFacet();
        // dLoupe = new DiamondLoupeFacet();
        // ownerF = new OwnershipFacet();
        // accessControlFacet = new AccessControlFacet();
        // executionFacet = new ExecutionFacet();
        // factoryFacet = new FactoryFacet();
        // tokenStashFacet = new TokenStashFacet();
        // scamEthFacet = new ScamEth();
        strategiesViewerFacet = new StrategiesViewerFacet();
        // gasManagerFacet = new GasManagerFacet();
        // triggersManagerFacet = new TriggersManagerFacet();
        // automationFacet = new AutomationFacet();

        FacetCut[] memory cut = new FacetCut[](1);

        bytes4[] memory arr = new bytes4[](1);
        arr[0] = 0x56bd21c5;
        cut[0] = (
            FacetCut({
                facetAddress: address(strategiesViewerFacet),
                action: FacetCutAction.Add,
                functionSelectors: arr
            })
        );

        // deploy diamond
        DiamondCutFacet(address(diamond)).diamondCut(cut, address(0), hex"00");

        vm.stopBroadcast();
    }
}

// forge script ./script/diamondCut.s.sol:DiamondCutScript --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --etherscan-api-key $ARBISCAN_API_KEY --verifier-url https://api.arbiscan.io/api --broadcast --verify -vvv --ffi
