/**
 * Test vault factory
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../Deployment.t.sol";
import "../../vault/main/Base.sol";
import "../../../src/diamond/facets/core/Factory.sol";
import "../../../src/diamond/facets/core/StrategiesViewer.sol";

contract FactoryFacetTest is DiamondTest {
    // =================
    //      STATES
    // =================
    Vault vaultContract;
    address public constant GMX_TOKEN_ADDRESS =
        0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;

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

    /**
     * Test that we deploy a vault in the factory, and it is saved as a registered vault
     */
    function testVaultDeploymentAndRegistration() public {
        // Make sure the dry configurations match on the vault contract

        // Assert that the creator must be us
        assertEq(vaultContract.CREATOR(), address(this), "Creator Incorrect");

        // Assert that the deposit token must be gmx
        assertEq(
            address(vaultContract.DEPOSIT_TOKEN()),
            GMX_TOKEN_ADDRESS,
            "Deposit Token Incorrect"
        );

        // Assert that the publicty should be public
        assertTrue(vaultContract.isPublic(), "Privacy Incorrect");

        // Now make sure the strategy is registered on the Diamond facet
        StrategyState memory vaultState = StrategiesViewerFacet(
            address(diamond)
        ).getStrategyState(vaultContract);

        assertTrue(
            vaultState.registered,
            "Deployed Vault, But Is Not Registered On Facet"
        );

        Vault[] memory vaults = StrategiesViewerFacet(address(diamond))
            .getStrategiesList();
        assertEq(
            address(vaults[vaults.length - 1]),
            address(vaultContract),
            "Deployed Vault, But Not Pushed To Facet Array"
        );
    }
}
