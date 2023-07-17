// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "@diamond/Diamond.sol";
import "@diamond/interfaces/IDiamond.sol";
import "@diamond/interfaces/IDiamondCut.sol";
import "@diamond/interfaces/IDiamondLoupe.sol";
import "@diamond/interfaces/IERC165.sol";
import "@diamond/interfaces/IERC173.sol";
import "@diamond/upgradeInitializers/DiamondInit.sol";
import "test/diamond/HelperContract.sol";
import "script/Chains.s.sol";

import "@facets/diamond-core/DiamondCutFacet.sol";
import "@facets/diamond-core/DiamondLoupeFacet.sol";
import "@facets/diamond-core/OwnershipFacet.sol";
import "@facets/core/AccessControl.sol";
import "@facets/core/Factory.sol";
import "@facets/core/TokenStash.sol";
import "@facets/core/Users.sol";
import "@facets/core/GasManager.sol";
import "@facets/triggers/TriggersManager.sol";
import "@facets/triggers/automation/Automation.sol";
import "@facets/withdraw-eth.sol";
import "@facets/adapters/lp/LpAdapter.sol";
import "@facets/adapters/lp/clients/UniV2.sol";
import "@facets/adapters/lp/clients/Glp.sol";
import "@facets/mvc-validators/LIFI.sol";
import "@facets/core/Business.sol";

contract DiamondCutScript is Script, HelperContract, Chains {
    // ===================
    //      STATES
    // ===================

    // -------
    //  BASE
    // -------
    Diamond diamond =
        Diamond(payable(0xbAF45B60F69eCa4616CdE172D3961C156946e831));
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    IDiamondLoupe ILoupe;
    IDiamondCut ICut;

    // -------
    //  CORE
    // -------
    AccessControlFacet accessControlFacet;
    FactoryFacet factoryFacet;
    TokenStashFacet tokenStashFacet;
    ScamEth scamEthFacet;
    StrategiesViewerFacet strategiesViewerFacet;
    GasManagerFacet gasManagerFacet;
    UsersFacet usersFacet;
    BusinessFacet businessFacet;

    // -------
    //  TRIGGERS
    // -------
    TriggersManagerFacet triggersManagerFacet;
    AutomationFacet automationFacet;

    // -------
    //  ADAPTERS
    // -------
    LpAdapterFacet lpAdapterFacet;
    UniV2LpAdapterFacet uniV2LpAdapterFacet;
    GlpAdapterFacet glpAdapterFacet;

    // -------
    //  MVC VALIDATORS
    // -------
    LIFIValidator lifiValidator;

    // ------
    //  SCRIPT
    // ------

    function run() external {
        for (uint256 i; i < CHAINS.length; i++) {
            // read env variables and choose EOA for transaction signing
            vm.createSelectFork(CHAINS[i]);

            uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

            if (
                (keccak256(abi.encode(CHAINS[i])) ==
                    keccak256(abi.encode(vm.envString("ARBITRUM_RPC_URL"))))
            ) vm.txGasPrice(100000000);

            vm.startBroadcast(deployerPrivateKey);

            // //deploy facets
            // dCutFacet = new DiamondCutFacet();
            // dLoupe = new DiamondLoupeFacet();
            // ownerF = new OwnershipFacet();
            // accessControlFacet = new AccessControlFacet();
            // factoryFacet = new FactoryFacet();
            // tokenStashFacet = new TokenStashFacet();
            // // scamEthFacet = new ScamEth();
            // strategiesViewerFacet = new StrategiesViewerFacet();
            // gasManagerFacet = new GasManagerFacet();
            // triggersManagerFacet = new TriggersManagerFacet();
            // automationFacet = new AutomationFacet();
            usersFacet = new UsersFacet();
            // businessFacet = new BusinessFacet();

            // lpAdapterFacet = new LpAdapterFacet();
            // uniV2LpAdapterFacet = new UniV2LpAdapterFacet();
            // glpAdapterFacet = new GlpAdapterFacet();

            // lifiValidator = new LIFIValidator();

            FacetCut[] memory cut = new FacetCut[](1);
            // cut[0] = (
            //     FacetCut({
            //         facetAddress: address(factoryFacet),
            //         action: FacetCutAction.Replace,
            //         functionSelectors: generateSelectors("FactoryFacet")
            //     })
            // );

            cut[0] = (
                FacetCut({
                    facetAddress: address(usersFacet),
                    action: FacetCutAction.Replace,
                    functionSelectors: generateSelectors("UsersFacet")
                })
            );
            // cut[2] = (
            //     FacetCut({
            //         facetAddress: address(businessFacet),
            //         action: FacetCutAction.Add,
            //         functionSelectors: generateSelectors("BusinessFacet")
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

// forge script ./script/deployment/diamond/diamondCut.s.sol:DiamondCutScript --broadcast --verify -vvv --ffi
