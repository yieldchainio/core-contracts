// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../Deployment.t.sol";
import "../../vault/main/Base.sol";
import "../../../src/diamond/facets/core/Factory.sol";
import "../../../src/diamond/facets/core/AccessControl.sol";

/**
 * Tests for the Diamond's Access Control facet
 */

contract AccessControlFacetTest is DiamondTest {
    // =================
    //      STATES
    // =================
    Vault vaultContract;
    address public constant GMX_TOKEN_ADDRESS =
        0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;

    // =================
    //      TESTS
    // =================
    /**
     * Test whitelisting, blacklisting
     */
    function testExecutorsModifications() public {
        // Assert that we are owner
        assertEq(
            AccessControlFacet(address(diamond)).getOwner(),
            address(this),
            "We Are Not Owner"
        );

        // Bob
        address Bob = address(1);

        // Alice
        address Alice = address(2);

        // Prank to be Bob and expect a revert whilst trying to whitelist an executor
        vm.startPrank(Bob);
        vm.expectRevert();
        AccessControlFacet(address(diamond)).whitelistExecutor(Alice);
        vm.stopPrank();

        // Now try to whitelist Alice as us (deployer of the diamond)
        AccessControlFacet(address(diamond)).whitelistExecutor(Alice);

        // Assert that she is whitelisted, and the executors array is of length 1
        assertEq(
            AccessControlFacet(address(diamond)).getExecutors().length,
            1,
            "Whitelisted Alice, But Length Is Not 1"
        );
        assertTrue(
            AccessControlFacet(address(diamond)).isAnExecutor(Alice),
            "Whitelisted Alice, But Not Updated In Storage"
        );

        // Blacklist Alice as Bob, expect revert
        vm.startPrank(Bob);
        vm.expectRevert();
        AccessControlFacet(address(diamond)).blacklistExecutor(Alice);
        vm.stopPrank();

        // Blacklist Alice as us, expect it to blacklist here
        AccessControlFacet(address(diamond)).blacklistExecutor(Alice);

        // Assert that the length of the new array is 0, and that Alice is set to false in the mapping
        assertEq(
            AccessControlFacet(address(diamond)).getExecutors().length,
            0,
            "Blacklisted Alice, But Length Remains > 0"
        );
        assertFalse(
            AccessControlFacet(address(diamond)).isAnExecutor(Alice),
            "Blacklisted Alice, But Not Updated In Storage"
        );

        // Transfer ownership to Bob
        OwnershipFacet(address(diamond)).transferOwnership(Bob);

        // Assert that Owner is now Bob
        assertEq(
            AccessControlFacet(address(diamond)).getOwner(),
            Bob,
            "Transfered Ownership, But Bob Is Not The Owner"
        );

        // Have Bob Whitelist Alice & Assert that she's whitelisted
        vm.startPrank(Bob);
        AccessControlFacet(address(diamond)).whitelistExecutor(Alice);
        vm.stopPrank();

        assertTrue(
            AccessControlFacet(address(diamond)).isAnExecutor(Alice),
            "Bob Whitelisted Alice, But Storage Mismatch"
        );
    }
}
