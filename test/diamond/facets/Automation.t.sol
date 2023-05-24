/**
 * Tests for AutomationFacet
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../Deployment.t.sol";
import "../../vault/main/Base.sol";
import "../../../src/diamond/facets/core/Factory.sol";
import "../../../src/diamond/facets/core/TokenStash.sol";
import "../../../src/diamond/facets/core/StrategiesViewer.sol";

contract AutomationFacetTest is DiamondTest {
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

    function testRegisteringAutomation() external {
        (
            bytes[] memory SEED_STEPS,
            bytes[] memory STEPS,
            bytes[] memory UPROOT_STEPS,
            address[2][] memory approvalPairs,
            IERC20 depositToken,
            bool isPublic,

        ) = new BaseStrategy().getVaultArgs();

        Trigger[] memory triggers = new Trigger[](1);

        uint256 automationinterval = 300;

        triggers[0] = Trigger(TriggerTypes.AUTOMATION, abi.encode(300));

        // Assign to vault state
        vaultContract = FactoryFacet(address(diamond)).createVault(
            SEED_STEPS,
            STEPS,
            UPROOT_STEPS,
            approvalPairs,
            triggers,
            ERC20(address(depositToken)),
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

        // Make assertions about the automation storage now
        ScheduledAutomation memory registeredAutomation = AutomationFacet(
            address(diamond)
        ).getRegisteredAutomation(vaultContract, 0);

        assertEq(
            registeredAutomation.interval,
            automationinterval,
            "Registered Automation, But Registered interval mismatches"
        );

        assertEq(
            registeredAutomation.lastExecutedTimestamp,
            block.timestamp,
            "Registered Automation, But Last Executed Timestamp Mismatches"
        );
    }
}
