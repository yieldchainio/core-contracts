// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/Script.sol";
import "src/diamond/facets/diamond-core/DiamondCutFacet.sol";
import "src/diamond/facets/diamond-core/DiamondLoupeFacet.sol";
import "src/diamond/facets/diamond-core/OwnershipFacet.sol";
import "src/diamond/facets/core/AccessControl.sol";
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

contract TestStrategyFully is Script, HelperContract {
    function run() external {
        //read env variables and choose EOA for transaction signing
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Diamond diamond = Diamond(
            payable(0xbAF45B60F69eCa4616CdE172D3961C156946e831)
        );
        Vault vaultAddress = Vault(0x3F774aAD69f949b36F268DC49c55DC8C6A93D3Cc);
        address self = 0x634176EcC95D326CAe16829d923C1373Df6ECe95;

        GasManagerFacet(address(diamond)).fundGasBalance{value: 0.001 ether}(
            address(vaultAddress)
        );

        // IERC20(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a).approve(
        //     address(vaultAddress),
        //     type(uint256).max
        // );


        // vaultAddress.deposit{value: requiredGas}(1 * 10 ** 16);

        Vault[] memory strategies = StrategiesViewerFacet(address(diamond))
            .getStrategiesList();

        uint256 idx = 50000;

        for (uint256 i; i < strategies.length; i++)
            if (address(strategies[i]) == address(vaultAddress)) {
                idx = i;
                break;
            }

        require(idx != 50000, "Didnt find strat");

        console.log("after loop");

        bool[][] memory check = TriggersManagerFacet(address(diamond))
            .checkStrategiesTriggers();

        console.log("Chec Length", check.length);

        if (!check[idx][0]) revert("Trigger Not Ready So Cannot Execute");

        for (uint256 i; i < check.length; i++)
            for (uint256 j; j < check[i].length; j++) console.log(check[i][j]);

        uint256[] memory indices = new uint256[](1);

        indices[0] = idx;

        check = new bool[][](1);
        check[0] = new bool[](1);
        check[0][0] = true;

        // TriggersManagerFacet(address(diamond)).executeStrategiesTriggers(
        //     indices,
        //     check
        // );

        // requiredGas = vaultAddress.approxWithdrawalGas() * 2;
        // uint256 shares = vaultAddress.balances(self);
        // vaultAddress.withdraw{value: requiredGas}(shares);

        address(vaultAddress).call(
            hex"c24ba9b20000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        );

        vm.stopBroadcast();
    }
}

// forge script ./script/testStrategyRun.s.sol:TestStrategyFully --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --broadcast -vvvv --ffi
