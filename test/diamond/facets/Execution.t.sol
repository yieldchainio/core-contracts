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
    function testVaultExecution() public {
        vm.txGasPrice(1);
        // Bob will be used as the Executor
        address BobTheExecutor = address(10);

        // Whitelist him as an executor
        AccessControlFacet(address(diamond)).whitelistExecutor(BobTheExecutor);

        // Deposit some money into the vault
        deal(GMX_TOKEN_ADDRESS, address(this), DEPOSIT_AMOUNT);
        IERC20(GMX_TOKEN_ADDRESS).approve(
            address(vaultContract),
            type(uint256).max
        );

        // We give ourselves 1 ETHER
        uint256 SINGLE_ETHER = 1 * 10 ** 14;
        uint256 DOUBLE_ETHER = SINGLE_ETHER * 2;
        vm.deal(address(this), DOUBLE_ETHER);

        // Set the approximate gas cost of deposit, withdraw, and strategy run to 1 ETHER
        vm.startPrank(address(diamond));

        vm.stopPrank();

        // Make a deposit
        vaultContract.deposit{value: DOUBLE_ETHER}(DEPOSIT_AMOUNT);

        // Keep track of our balance prior to actual execution
        uint256 preOwnBalance = address(this).balance;

        assertEq(
         0,
            DOUBLE_ETHER,
            "Deposited, But Prepaid Gas Mismatch"
        );

        vm.deal(BobTheExecutor, DOUBLE_ETHER);

        uint256 preEtherBobBalance = BobTheExecutor.balance;

        // Start pranking as Bob for the entire operation (He will be executing the operation request)
        vm.startPrank(BobTheExecutor);

        vm.resumeGasMetering();

        // Execute the operation request at index 0 (The deposit operation), with empty commands calldata (no offchain shiet)
        uint256 gasUsed = 0;

        vm.stopPrank();

        /**
         * @notice
         * I am manually deducting the gas used from Bob's wallet for now,
         * since it seems like forge wont do it automatically, not sure how to set that configuraiton.
         */
        vm.prank(BobTheExecutor);
        payable(address(20)).transfer(gasUsed);

        // First, assert that the deposit went through by looking at the GMX staking pool balance of the vault (sufficient)
        assertTrue(
            getGmxStakingBalance() > 0,
            "Deposited In Execution, But GMX Staking Balance Is 0"
        );

        // Then, assert that our balance is like it was before (fully reimbrused)
        assertEq(
            BobTheExecutor.balance,
            preEtherBobBalance,
            "Executed, But Bob's Ether Balance Mismatches"
        );

        // Assert that our own balance is the balance prior to the execution, + (1 ETHER - Gas used)
        assertEq(
            address(this).balance,
            preOwnBalance + (DOUBLE_ETHER - gasUsed),
            "Executed, But Gas Reimburanse failed"
        );
    }

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
