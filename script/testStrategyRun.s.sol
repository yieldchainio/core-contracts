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

contract TestStrategyFully is Script, HelperContract {
    function run() external {
        //read env variables and choose EOA for transaction signing
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Diamond diamond = Diamond(
            payable(0xdDa4fcF0C099Aa9900c38F1e6A01b8B96B1480d3)
        );
        Vault vaultAddress = Vault(0xD24Fdd11ECD6F57e86D019ACe68138bc16f03d4e);

        GasManagerFacet(address(diamond)).fundGasBalance{value: 0.001 ether}(
            address(vaultAddress)
        );

        ERC20(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a).approve(
            address(vaultAddress),
            type(uint256).max
        );

        uint256 requiredGas = vaultAddress.approxDepositGas() * 2;

        vaultAddress.deposit{value: requiredGas}(1 * 10 ** 16);
        ExecutionFacet(address(diamond)).triggerStrategyRun(vaultAddress);
        vaultAddress.withdraw{value: requiredGas}(1 * 10 ** 16);

        // address(diamond).call(
        //     hex"4d7133ec00000000000000000000000036040f67111a7fc2b4dc86d06783809116d4aab5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006e2060000000000000000000000000000000000000000000000000000000000000000200000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000620000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000028000000000000000000000000000000000000000000000000000000000000002e0000000000000000000000000000000000000000000000000000000000000034000000000000000000000000000000000000000000000000000000000000000220000da9b133b3f5ce05228dc2d8134bf0c3322858ff55b235d6d04bbeae0aab5182a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006201010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000d7969656c64636861696e2e696f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008201010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002a307830303030303030303030303030303030303030303030303030303030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000036040f67111a7fc2b4dc86d06783809116d4aab50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000b9118d255c3138000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022201010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001111111254eeb25477b68fb85ed929f73a9605820000000000000000000000001111111254eeb25477b68fb85ed929f73a960582000000000000000000000000fc5a1a6eb076a2c7ad06ed22c90d7e710e35ad0a00000000000000000000000018c11fd286c5ec11c3b683caa813b77f5163a1220000000000000000000000000000000000000000000000000011c37937e0800000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a8e449022e0000000000000000000000000000000000000000000000000011c37937e0800000000000000000000000000000000000000000000000000000b9118d255c3137000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000018000000000000000000000003884312c7711e857dea4278883cf91a042ce03df2e9b3012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006f73776170546f6b656e7347656e6572696328627974657333322c737472696e672c737472696e672c616464726573732c75696e743235362c28616464726573732c616464726573732c616464726573732c616464726573732c75696e743235362c62797465732c626f6f6c295b5d290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        // );

        vm.stopBroadcast();
    }
}

// forge script ./script/testStrategyRun.s.sol:TestStrategyFully --chain-id 42161 --fork-url $ARBITRUM_RPC_URL --broadcast -vvvv --ffi
