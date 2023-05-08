// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../../src/vault/Vault.sol";
import "../utilities/Dex.sol";
import "./Base.sol";
import "../../utils/Forks.t.sol";

import "../../diamond/Deployment.t.sol";

/**
 * Testing the access control of the vault contract,
 * i.e adding admins/moderators, etc
 */

contract AccessControlTest is DiamondTest, YCVMEncoders {
    // ==================
    //      STATES
    // ==================
    Vault public vaultContract;
    uint256 networkID;

    // ==================
    //     CONSTRUCTOR
    // ==================
    function setUp() public virtual override {
        super.setUp();
        networkID = new Forks().ARBITRUM();
        vm.selectFork(networkID);
        (
            bytes[] memory SEED_STEPS,
            bytes[] memory STEPS,
            bytes[] memory UPROOT_STEPS,
            address[2][] memory approvalPairs,
            IERC20 depositToken,
            bool isPublic,

        ) = new BaseStrategy().getVaultArgs();
        vaultContract = FactoryFacet(address(diamond)).createVault(
            SEED_STEPS,
            STEPS,
            UPROOT_STEPS,
            approvalPairs,
            ERC20(address(depositToken)),
            isPublic
        );
    }

    // ==================
    //      TESTS
    // ==================
    /**
     * Test Creator Permissions
     */
    function testCreatorOps() public {
        // Check that we can add moderators, administrators
        vaultContract.addModerator(address(1));
        vaultContract.addAdministrator(address(2));
        // Check that it added them
        assertTrue(vaultContract.mods(address(1)), "Creator Cannot Add Mods");
        assertTrue(
            vaultContract.admins(address(2)),
            "Creator Cannot Add Admins"
        );
    }

    /**
     * Mods tests
     */
    function testModOps() public {
        // We are the creator so should go through

        vaultContract.addModerator(address(1));

        // Check that it added them
        assertTrue(vaultContract.mods(address(1)), "Creator Cannot Add Mods");

        // Check that the moderator can whitelist and blacklist users
        vm.startPrank(address(1));
        vaultContract.whitelist(address(2));
        assertTrue(
            vaultContract.whitelistedUsers(address(2)),
            "Mod Cannot Whitelist"
        );
        vaultContract.blacklist(address(2));
        assertFalse(
            vaultContract.whitelistedUsers(address(2)),
            "Mod Cannot Blacklist"
        );
        vm.stopPrank();

        // Add Another Moderator
        vaultContract.addModerator(address(3));

        // Check that they cannot blacklist each other
        vm.startPrank(address(1));
        vm.expectRevert();
        vaultContract.blacklist(address(3));
        assertTrue(
            vaultContract.whitelistedUsers(address(3)),
            "Mods Are In War"
        );

        vm.stopPrank();
        // Remove both ourselves
        vaultContract.removeModerator(address(1));
        vaultContract.removeModerator(address(3));

        // Assert that it was removed
        assertFalse(vaultContract.mods(address(1)));
        assertFalse(vaultContract.mods(address(3)));
    }

    /**
     * Admin tests
     */
    function testAdminOps() public {
        // We are the creator so should go through
        vaultContract.addAdministrator(address(1));

        // Check that it added them
        assertTrue(
            vaultContract.admins(address(1)),
            "Creator Cannot Add Admins"
        );

        // Check that the adminstrator can whitelist and blacklist users
        vm.startPrank(address(1));
        vaultContract.whitelist(address(2));
        assertTrue(
            vaultContract.whitelistedUsers(address(2)),
            "Admin Cannot Whitelist"
        );
        vaultContract.blacklist(address(2));
        assertFalse(
            vaultContract.whitelistedUsers(address(2)),
            "Admin Cannot Blacklist"
        );
        vm.stopPrank();

        // Add Another ADmin
        vaultContract.addAdministrator(address(3));

        // Check that they cannot blacklist each other
        vm.startPrank(address(1));
        vm.expectRevert();
        vaultContract.blacklist(address(3));
        assertTrue(
            vaultContract.whitelistedUsers(address(3)),
            "Admins Are In War"
        );

        // Check that they cannot remove each other's mod permissions
        vm.expectRevert();
        vaultContract.removeModerator(address(3));
        assertTrue(
            vaultContract.mods(address(3)),
            "Admins Are In War Political War"
        );

        vm.stopPrank();

        // Remove both ourselves
        vaultContract.removeAdministrator(address(1));
        vaultContract.removeAdministrator(address(3));

        // Assert that it was removed
        assertFalse(vaultContract.mods(address(1)));
        assertFalse(vaultContract.mods(address(3)));
        assertFalse(vaultContract.admins(address(1)));
        assertFalse(vaultContract.admins(address(3)));
    }
}
