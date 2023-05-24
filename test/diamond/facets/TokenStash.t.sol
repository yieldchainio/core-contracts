/**
 * Tests for the Diamond's TokenStash facet.
 * Used to save tokens on the Diamond temporarely to avoid balances mixing whilst executing vault operations
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../Deployment.t.sol";
import "../../vault/main/Base.sol";
import "../../../src/diamond/facets/core/Factory.sol";
import "../../../src/diamond/facets/core/TokenStash.sol";


contract TokenStashFacetTest is DiamondTest {
    // =================
    //      STATES
    // =================
    Vault vaultContract;
    address public constant GMX_TOKEN_ADDRESS =
        0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;

    uint256 internal constant DEPOSIT_AMOUNT = 1000 * 10 ** 18;

    // =================
    //    CONSTRUCTOR
    // =================
    function setUp() public virtual override {
        super.setUp();
        // Get the args for deployment and deploy the vault
        (
            bytes[] memory SEED_STEPS,
            bytes[] memory STEPS,
            bytes[] memory UPROOT_STEPS,
            address[2][] memory approvalPairs,
            IERC20 depositToken,
            bool isPublic,

        ) = new BaseStrategy().getVaultArgs();

        // Assign to vault state
        vaultContract = FactoryFacet(address(diamond)).createVault(
            SEED_STEPS,
            STEPS,
            UPROOT_STEPS,
            approvalPairs,
                        new Trigger[](0),

            ERC20(address(depositToken)),
            isPublic
        );
    }

    // =================
    //      TESTS
    // =================
    /**
     * Test stashing, unstashing
     */
    function testTokenStashing() public {
        // Begin by awarding ourselves with 1000 GMX tokens
        deal(GMX_TOKEN_ADDRESS, address(this), DEPOSIT_AMOUNT);

        // Approve b4 depositing
        ERC20(GMX_TOKEN_ADDRESS).approve(
            address(vaultContract),
            type(uint256).max
        );

        // Then, initiate a deposit to the vault
        uint256 requiredGasPrepay = vaultContract.approxDepositGas();
        vaultContract.deposit{value: requiredGasPrepay * 2}(DEPOSIT_AMOUNT);

        // Assert that our balance is 0
        assertEq(
            ERC20(GMX_TOKEN_ADDRESS).balanceOf(address(this)),
            0,
            "Deposited Into Vault But Balance Remains"
        );

        // Assert that the vault's stash balance for this token is our deposit amount
        assertEq(
            TokenStashFacet(address(diamond)).getStrategyStash(
                vaultContract,
                ERC20(GMX_TOKEN_ADDRESS)
            ),
            DEPOSIT_AMOUNT,
            "Deposited, But Tokens Not Stashed"
        );

        // Now execute the deposit, and expect the stash to be now 0
        vm.startPrank(vaultContract.YC_DIAMOND());
        vaultContract.hydrateAndExecuteRun(0, new bytes[](0));
        vm.stopPrank();

        // Assert that the vault's stash is now 0
        assertEq(
            TokenStashFacet(address(diamond)).getStrategyStash(
                vaultContract,
                ERC20(GMX_TOKEN_ADDRESS)
            ),
            0,
            "Executed Deposit, But Tokens Still Stashed"
        );
    }
}
