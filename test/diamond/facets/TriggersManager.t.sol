/**
 * Tests for TriggersManager
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../Deployment.t.sol";
import "../../vault/main/Base.sol";
import "../../../src/diamond/facets/core/Factory.sol";
import "../../../src/diamond/facets/core/TokenStash.sol";
import "../../../src/diamond/facets/core/StrategiesViewer.sol";
import "../../../src/diamond/facets/triggers/TriggersManager.sol";
import "../../../src/Types.sol";
import "src/vault/Schema.sol";

contract TriggersManagerTest is DiamondTest, VaultTypes {
    // =================
    //      STATES
    // =================
    Vault vaultContract;

    // =================
    //    CONSTRUCTOR
    // =================
    function setUp() public virtual override {
        super.setUp();
    }

    // =================
    //      TESTS
    // =================

    function testRegisteringTrigger() public {
        (
            bytes[] memory SEED_STEPS,
            bytes[] memory STEPS,
            bytes[] memory UPROOT_STEPS,
            address[2][] memory approvalPairs,
            IERC20 depositToken,
            bool isPublic,

        ) = new BaseStrategy().getVaultArgs();

        Trigger[] memory triggers = new Trigger[](1);

        triggers[0] = Trigger(TriggerTypes.AUTOMATION, abi.encode(60));

        // Assign to vault state
        vaultContract = FactoryFacet(address(diamond)).createVault(
            SEED_STEPS,
            STEPS,
            UPROOT_STEPS,
            approvalPairs,
            triggers,
            IERC20(address(depositToken)),
            isPublic
        );

        // assert that the trigger has been registered
        RegisteredTrigger[] memory registeredTriggers = StrategiesViewerFacet(
            address(diamond)
        ).getStrategyTriggers(vaultContract);

        assertEq(
            registeredTriggers.length,
            1,
            "Registered Triggers On Vault Deployment, But Length Of Registered Triggers Mismatches"
        );

        assertEq(
            uint8(registeredTriggers[0].triggerType),
            uint8(TriggerTypes.AUTOMATION),
            "Registered Trigger On Vault Deployment, But Type Mismatches"
        );

        assertEq(
            registeredTriggers[0].lastStrategyRun,
            block.timestamp,
            "Registered Trigger On Vault Deployment, But Last Strategy Run Mismatch"
        );
    }

    function testCheckingTriggers() public {
        // Register
        testRegisteringTrigger();

        // Test that checker returns false for that triggers
        bool[][] memory checkerRes = TriggersManagerFacet(address(diamond))
            .checkStrategiesTriggers();

        assertFalse(
            checkerRes[0][0],
            "Registered Triggers, But Checker Returned True Right Away"
        );

        // Advance block timestamp to 30 seconds from now
        vm.warp(block.timestamp + 30);

        // Shuldnt work (required delay + automation is 60)
        checkerRes = TriggersManagerFacet(address(diamond))
            .checkStrategiesTriggers();

        assertFalse(
            checkerRes[0][0],
            "Registered Triggers, But Checker Returned True Half Way Through"
        );

        // Set it to 31 more seconds
        vm.warp(block.timestamp + 31);

        checkerRes = TriggersManagerFacet(address(diamond))
            .checkStrategiesTriggers();

        // Should Work Now
        assertFalse(
            checkerRes[0][0],
            "Vault has 0 shares but checker returned true"
        );

        deal(address(vaultContract.DEPOSIT_TOKEN()), address(this), 10 * 10 ** 18);

        vaultContract.DEPOSIT_TOKEN().approve(address(vaultContract), type(uint256).max);
        vaultContract.deposit(10 * 10 ** 18);

        checkerRes = TriggersManagerFacet(address(diamond))
            .checkStrategiesTriggers();

        // Should Work Now
        assertTrue(
            checkerRes[0][0],
            "Enough Time Has Passed But Checker Returned False"
        );
    }

    function testPostExecutionState() public {
        vm.txGasPrice(1);
        testCheckingTriggers();

        bool[][] memory triggs = new bool[][](1);
        bool[] memory trigg = new bool[](1);
        trigg[0] = true;
        triggs[0] = trigg;

        uint256[] memory indices = new uint256[](1);
        indices[0] = 0;

        deal(address(this), 1 ether);

        GasManagerFacet(address(diamond)).fundGasBalance{value: 1 ether}(
            address(vaultContract)
        );

        TriggersManagerFacet(address(diamond)).executeStrategyTriggerWithData(
            abi.encode(new bytes[](0)),
            abi.encode(vaultContract, indices[0])
        );

        // Assert that checker now returns false
        bool[][] memory checkerRes = TriggersManagerFacet(address(diamond))
            .checkStrategiesTriggers();

        assertFalse(
            checkerRes[0][0],
            "Executed Trigger, But Checker Returns True Right After"
        );

        vm.warp(block.timestamp + 61);

        checkerRes = TriggersManagerFacet(address(diamond))
            .checkStrategiesTriggers();

        assertTrue(
            checkerRes[0][0],
            "Executed Trigger, Warped Time - But Checker Returns False"
        );
    }

    function testRevertOnInsufficientVaultBalance() external {
        vm.txGasPrice(1);
        testCheckingTriggers();

        bool[][] memory triggs = new bool[][](1);
        bool[] memory trigg = new bool[](1);
        trigg[0] = true;
        triggs[0] = trigg;

        uint256[] memory indices = new uint256[](1);
        indices[0] = 0;

        vm.warp(block.timestamp + 61);
        vm.expectRevert();
        TriggersManagerFacet(address(diamond)).executeStrategyTriggerWithData(
            abi.encode(new bytes[](0)),
            abi.encode(vaultContract, indices[0])
        );
    }

    function testExecutingTriggers() public {
        vm.txGasPrice(1);
        testCheckingTriggers();

        bool[][] memory triggs = new bool[][](1);
        bool[] memory trigg = new bool[](1);
        trigg[0] = true;
        triggs[0] = trigg;

        uint256[] memory indices = new uint256[](1);
        indices[0] = 0;

        deal(address(this), 1 ether);

        GasManagerFacet(address(diamond)).fundGasBalance{value: 1 ether}(
            address(vaultContract)
        );

        vm.warp(block.timestamp + 61);

        uint256 preBalance = address(diamond).balance;
        TriggersManagerFacet(address(diamond)).executeStrategyTriggerWithData(
            abi.encode(new bytes[](0)),
            abi.encode(vaultContract, indices[0])
        );
        uint256 postBalance = address(diamond).balance;
        uint256 ownBalance = address(this).balance;

        assertEq(
            preBalance - postBalance,
            ownBalance,
            "[TriggersManagerTest]: Executed, But did not receive appropriate gas refund"
        );
    }

    fallback() external payable {}

    receive() external payable {}
}
