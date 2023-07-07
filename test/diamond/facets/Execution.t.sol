/**
 * Tests for the Diamond's Vault Execution facet.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../Deployment.t.sol";
import "../../vault/main/Base.sol";
import "../../../src/diamond/facets/core/Factory.sol";
import "../../../src/diamond/facets/core/TokenStash.sol";
import "../../../src/vm/Constants.sol";
import "../../../src/diamond/interfaces/IGasManager.sol";

/**
 * Tests for the Diamond's Access Control facet
 */

contract ExecutionFacetTest is DiamondTest, Constants {
    // =================
    //      STATES
    // =================
    Vault vaultContract;
    address public constant GMX_TOKEN_ADDRESS =
        0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;

    address public constant GMX_STAKING_CONTRACT =
        0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;

    address public constant GMX_REWARDS_ROUTER =
        0x908C4D94D34924765f1eDc22A1DD098397c59dD4;

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
            IERC20(address(depositToken)),
            isPublic
        );
    }

    // =================
    //      TESTS
    // =================
    /**
     * Test execution
     */
    function testVaultExecution() public {}

    function getGmxStakingBalance() public returns (uint256 stakedAmount) {
        bytes[] memory args = new bytes[](1);
        args[0] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(address(vaultContract))
        );
        return
            abi.decode(
                vaultContract._runFunction(
                    bytes.concat(
                        STATICCALL_COMMAND_FLAG,
                        VALUE_VAR_FLAG,
                        abi.encode(
                            FunctionCall(
                                GMX_REWARDS_ROUTER,
                                args,
                                "stakedAmounts(address)"
                            )
                        )
                    )
                ),
                (uint256)
            );
    }

    receive() external payable {}
}
