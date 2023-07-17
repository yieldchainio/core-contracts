// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../Deployment.t.sol";
import {UsersFacet, UsersStorageLib} from "@facets/core/Users.sol";
import {BusinessFacet} from "@facets/core/Business.sol";

contract UsersTest is DiamondTest {
    // ===========
    //    STORAGE
    // ===========
    IERC20 PAYMENT_TOKEN = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    address TREASURY = address(4124211);
    uint256 MONTHLY_COST = 200000000;
    uint256 LIFETIME_COST = MONTHLY_COST * 10;

    // ===========
    //    SETUP
    // ===========
    function setUp() public virtual override {
        super.setUp();
        PAYMENT_TOKEN.approve(address(diamond), type(uint256).max);
        BusinessFacet(address(diamond)).setTreasury(TREASURY);
        UsersFacet(address(diamond)).setPaymentToken(address(PAYMENT_TOKEN));
    }

    // ===========
    //    TESTS
    // ===========
    function testPaymentTokenStorage() external {
        assertEq(
            UsersFacet(address(diamond)).getPaymentToken(),
            address(PAYMENT_TOKEN),
            "[UsersFacetTest]: Set payment token, but mismatches in storage"
        );
    }

    function testAddingTier() public {
        Tier memory tier = Tier({
            isActive: true,
            powerLevel: 1,
            monthlyCost: 100000000,
            lifetimeCost: 1000000000
        });

        UsersFacet(address(diamond)).addTier(
            1,
            MONTHLY_COST / 2,
            LIFETIME_COST / 2
        );

        Tier memory addedTier = UsersFacet(address(diamond)).getTier(1);

        assertTrue(
            addedTier.isActive,
            "[UsersFacetTest]: Added tier but is not classified as active"
        );

        assertEq(
            addedTier.powerLevel,
            tier.powerLevel,
            "[UsersFacetTest]: Added tier but powerlevel mismatch"
        );

        assertEq(
            addedTier.monthlyCost,
            tier.monthlyCost,
            "[UsersFacetTest]: Added tier but monthly cost mismatch"
        );

        assertEq(
            addedTier.lifetimeCost,
            tier.lifetimeCost,
            "[UsersFacetTest]: Added tier but lifetime cost mismatch"
        );
    }

    function testUpdateTierCost() public {
        testAddingTier();
        UsersFacet(address(diamond)).updateTierCost(
            1,
            MONTHLY_COST,
            LIFETIME_COST
        );

        Tier memory addedTier = UsersFacet(address(diamond)).getTier(1);
        assertEq(
            addedTier.monthlyCost,
            MONTHLY_COST,
            "[UsersFacetTest]: Updated cost but monthly cost mismatches"
        );
        assertEq(
            addedTier.lifetimeCost,
            LIFETIME_COST,
            "[UsersFacetTest]: Updated cost but lifetime cost mismatches"
        );
    }

    function testRemovingTier() external {
        testAddingTier();
        UsersFacet(address(diamond)).removeTier(1);
        Tier memory removedTier = UsersFacet(address(diamond)).getTier(1);

        assertFalse(
            removedTier.isActive,
            "[UsersFacetTest]: Removed tier but remains active"
        );
    }

    function testUpgradingUserTierSimpleMonthly()
        public
        returns (UserTier memory userTier)
    {
        testUpdateTierCost();

        deal(address(PAYMENT_TOKEN), address(this), MONTHLY_COST);

        uint256 startingTime = block.timestamp;

        UsersFacet(address(diamond)).upgradeTier(1, MONTHLY_COST, false);

        userTier = UsersFacet(address(diamond)).getUserTier(address(this));

        assertEq(
            userTier.tierId,
            1,
            "[UsersFacetTest]: Upgraded own user tier, but tier ID mismatches"
        );

        assertEq(
            userTier.endsOn,
            startingTime + 30 days,
            "[UsersFacetTest]: Upgraded Own User tier but expiration mismatches"
        );

        assertTrue(
            UsersFacet(address(diamond)).isInTier(address(this), 1),
            "[UsersFacetTest]: Upgraded own tier simply but are not considered in tier"
        );
    }

    function testExtendingExistingUserTier() external {
        UserTier memory userTier = testUpgradingUserTierSimpleMonthly();

        uint256 originalExpiration = userTier.endsOn;

        vm.warp(userTier.endsOn - 15 days);

        assertTrue(
            UsersFacet(address(diamond)).isInTier(address(this), 1),
            "[UsersFacetTest]: Timetravelled 15 days but are not considered in tier, while it should retain for 30"
        );

        deal(address(PAYMENT_TOKEN), address(this), MONTHLY_COST);

        UsersFacet(address(diamond)).upgradeTier(1, MONTHLY_COST, false);

        userTier = UsersFacet(address(diamond)).getUserTier(address(this));

        assertEq(
            userTier.endsOn,
            originalExpiration + 30 days,
            "[UsersFacetTest]: Extended existing tier but expiration date did not increase correctly"
        );

        vm.warp(originalExpiration + 30 days + 40 days);

        userTier = UsersFacet(address(diamond)).getUserTier(address(this));

        assertFalse(
            UsersFacet(address(diamond)).isInTier(address(this), 1),
            "[UsersFacetTest]: Timetravelled beyond expiration but are still considered in tier"
        );

        deal(address(PAYMENT_TOKEN), address(this), MONTHLY_COST);

        UsersFacet(address(diamond)).upgradeTier(1, MONTHLY_COST, false);

        userTier = UsersFacet(address(diamond)).getUserTier(address(this));

        assertEq(
            userTier.endsOn,
            block.timestamp + 30 days,
            "[UsersFacetTest]: Extended tier long after expiration, but new expiration date mismatches"
        );
    }

    function testFundsSent() external {
        uint256 preBalance = PAYMENT_TOKEN.balanceOf(TREASURY);
        testUpgradingUserTierSimpleMonthly();
        assertEq(
            PAYMENT_TOKEN.balanceOf(TREASURY),
            preBalance + MONTHLY_COST,
            "[UsersFacetTest]: Upgraded tier but treausyr did not receive funds"
        );
    }
}
