// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../../src/vault/Vault.sol";
import "../utilities/Dex.sol";
import "./Base.sol";
import "../../utils/Forks.t.sol";

contract ExecutionTest is Test, YCVMEncoders {
    address public constant GMX_TOKEN_ADDRESS =
        0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;

    address public constant GMX_STAKING_CONTRACT =
        0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;

    address public constant GMX_REWARDS_ROUTER =
        0x908C4D94D34924765f1eDc22A1DD098397c59dD4;

    address public constant GNS_TOKEN_ADDRESS =
        0x18c11FD286C5EC11c3b683Caa813B77f5163A122;

    address public constant GNS_STAKING_CONTRACT =
        0x6B8D3C08072a020aC065c467ce922e3A36D3F9d6;

    address public constant WETH_TOKEN_CONTRACT =
        0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address public constant DAI_TOKEN_ADDRESS =
        0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    // ==================
    //     CONSTRUCTOR
    // ==================

    Vault public vaultContract;
    uint256 networkID;

    function setVaultContract(Vault _vaultContract) public {
        vaultContract = _vaultContract;
    }

    function setUp() public {
        networkID = new Forks().ARBITRUM();
        vm.selectFork(networkID);
        vaultContract = new BaseStrategy().getVaultContract();
    }

    /**
     * Test the deposit strategy
     * @param depositAmount - uint80, the amount to deposit (for fuzzing)
     */
    function testDepositAndSeedStrategy(uint256 depositAmount) public {
        /**
         * @notice
         * We make 2 assumptions:
         * 1) Deposit amount is between 0.01 and 1B
         * 2) Deposit amount is an even number. This is in order to be able to make assertions on the different balances/positions percisely
         * (Since we usually use a divisor of 2 )
         */
        vm.assume(depositAmount % 2 == 0);
        vm.assume(
            depositAmount <= 1000000000 * 10 ** 18 &&
                depositAmount >= 1 * 10 ** 16
        );

        // Reward ourselves with some *depositAmount* tokens
        deal(
            address(vaultContract.DEPOSIT_TOKEN()),
            address(this),
            depositAmount
        );

        // Assert that we must have *depositAmount* amount of tokens
        assertEq(
            vaultContract.DEPOSIT_TOKEN().balanceOf(address(this)),
            depositAmount,
            "vm.deal() did not reward"
        );

        // Approve the tokens to the vault
        vaultContract.DEPOSIT_TOKEN().approve(
            address(vaultContract),
            type(uint256).max
        );

        // Assert that hte allownace is sufficient
        assertTrue(
            vaultContract.DEPOSIT_TOKEN().allowance(
                address(this),
                address(vaultContract)
            ) > depositAmount,
            "Insufficient Allowance"
        );

        // Pre balances of the vault ins taking pools
        uint256 preGMXBalance = getGmxStakingBalance();
        uint256 preGNSBalance = getGNSStakingBalance();
        uint256 preTotalShares = vaultContract.totalShares();

        // Deposit all 100 tokens we have
        vaultContract.deposit(depositAmount);
        routeLatestRequest();

        // Assert that the vault's GMX staking balance should now be half of that
        assertEq(
            getGmxStakingBalance(),
            preGMXBalance + ((depositAmount * 100) / 200),
            "Deposited, But Vault's Staked GMX Mismatches"
        );

        // Assert that the vault's GNS Staking balance should now be half of that
        assertEq(
            getGNSStakingBalance(),
            preGNSBalance + ((depositAmount * 100) / 200),
            "Deposited, But Vault's Staked GNS Mismatches"
        );

        // Assert that the vault's total supply is now depositAmount, and so are our shares
        assertEq(
            vaultContract.totalShares(),
            preTotalShares + depositAmount,
            "Deposited, But Total Supply Mismatches"
        );
        assertEq(
            vaultContract.balances(address(this)),
            depositAmount,
            "Deposited, But User Shares Mismatche"
        );
    }

    /**
     * Test the strategy body
     */
    function testStrategyRun(uint256 depositAmount) public {
        /**
         * @notice
         * We begin by making a deposit like in the deposit test
         */
        vm.assume(depositAmount % 2 == 0);
        vm.assume(
            depositAmount <= 1000000000 * 10 ** 18 &&
                depositAmount >= 1 * 10 ** 16
        );

        // Begin by re-running deposit test
        testDepositAndSeedStrategy(depositAmount);

        // Expect this to revert (We are not the yieldchain diamond)
        vm.expectRevert();
        vaultContract.runStrategy();

        // Keep track of current balances prior to strategy run, to assert diffs later
        uint256 preGMXPoolBalance = getGmxStakingBalance();
        // uint256 preGNSPoolBalance = getGNSStakingBalance();

        // Move time forward to simulate reward cumlation
        vm.warp((block.timestamp * 110) / 100);

        // Prank as the diamond
        vm.prank(vaultContract.YC_DIAMOND());

        // Make a strategy run
        vaultContract.runStrategy();
        routeLatestRequest();

        // Assert that the pool balances be bigger than what they were
        assertTrue(
            getGmxStakingBalance() > preGMXPoolBalance,
            "Strategy Run, But GMX Position Did Not Grow."
        );

        // @notice We do not assert the GNS staking balance as it does not grow like this w the block.timestamp
        // TODO: Manual storage manipulation? not sure if worth it sine if GMX changed we know it worked.
        // assertTrue(
        //     getGNSStakingBalance() > preGNSPoolBalance,
        //     "Strategy Run, But GNS Position Did Not Grow."
        // );
    }

    /**
     * Test withdrawls
     */

    function testWithdrawAndUprootStrategy(uint256 depositAmount) public {
        // Begin by rerunning strategy test, which will deposit & run the strategy
        testStrategyRun(depositAmount);
        // Make the vault public
        vm.prank(vaultContract.YC_DIAMOND());
        vaultContract.changePrivacy(true);

        // Then, "deploy" a new test contract and begin pranking it as Bob, and have him deposit a similar amount
        address Bob = address(1);
        vm.startPrank(Bob);
        deal(address(vaultContract.DEPOSIT_TOKEN()), Bob, depositAmount);
        vaultContract.DEPOSIT_TOKEN().approve(
            address(vaultContract),
            type(uint256).max
        );
        vaultContract.deposit(depositAmount);
        vm.stopPrank();
        routeLatestRequest();

        vm.prank(vaultContract.YC_DIAMOND());
        vaultContract.runStrategy();
        routeLatestRequest();

        // Keep track of GMX and GNS balances, totalShares, our balance and Bob's blaance b4 the withdrawal
        uint256 preGMXPoolBalance = getGmxStakingBalance();
        uint256 preGNSPoolBalance = getGNSStakingBalance();

        uint256 preTotalShares = vaultContract.totalShares();
        uint256 preSelfShares = vaultContract.balances(address(this));
        uint256 preBobShares = vaultContract.balances(Bob);

        // Assert existing shares amount
        assertEq(
            preTotalShares / preSelfShares,
            2,
            "Pre Self Shares Incorrrect"
        );
        assertEq(preTotalShares / preBobShares, 2, "Pre Bob Shares Incorrrect");

        // Execute a withdrawal of all of our shares (should be 50% of total shares)
        vaultContract.withdraw(preSelfShares);
        routeLatestRequest();

        // Assert that the shares of us are now 0
        assertEq(
            vaultContract.balances(address(this)),
            0,
            "Withdrawn, But Shares Are Not 0"
        );
        // Assert that Bob's shares now equal to 100% of the shares
        assertEq(
            vaultContract.balances(Bob),
            vaultContract.totalShares(),
            "Withdrawn, But Bob Does Not Hold All Shares"
        );
        // Assert that the total shares are now exacrtly half from before
        assertEq(
            vaultContract.totalShares(),
            preTotalShares / 2,
            "Withdrawan, But Total Shares mismatch"
        );

        // Assert that our GMX balance is bigger than our deposit amount
        assertTrue(
            vaultContract.DEPOSIT_TOKEN().balanceOf(address(this)) >
                depositAmount,
            "Withdrawan, But Did Not Receive Extra GMX"
        );

        // PRE:121876424073932558078
        // POS 91408122474697096249

        // Assert that vault contract's GMX balance is 0
        assertEq(
            vaultContract.DEPOSIT_TOKEN().balanceOf(address(vaultContract)),
            0,
            "Withdrawan But GMX remains in pool"
        );

        // Assert that the GMX  & GNS pool balances of the vault are now half from prev
        assertTrue(
            getGmxStakingBalance() == preGMXPoolBalance / 2 ||
                getGmxStakingBalance() == preGMXPoolBalance / 2 - 1 ||
                getGmxStakingBalance() == preGMXPoolBalance / 2 + 1,
            "Withdrawn, but GMX pool balance mismatch"
        );
        assertTrue(
            getGNSStakingBalance() == preGNSPoolBalance / 2 ||
                getGNSStakingBalance() == preGNSPoolBalance / 2 - 1 ||
                getGNSStakingBalance() == preGNSPoolBalance / 2 + 1,
            "Withdrawn, but GNS pool balance mismatch"
        );

        // Keep track of GMX and GNS balances, totalShares, our balance and Bob's blaance b4 the withdrawal
        preGMXPoolBalance = getGmxStakingBalance();
        preGNSPoolBalance = getGNSStakingBalance();
        preTotalShares = vaultContract.totalShares();
        preSelfShares = vaultContract.balances(address(this));
        preBobShares = vaultContract.balances(Bob);

        // Prank Bob Contract, Withdraw his shares as him
        vm.startPrank(Bob);
        vaultContract.withdraw(vaultContract.balances(Bob) / 2);
        vm.stopPrank();
        routeLatestRequest();

        // BOB Got THis Amount: 61070876437181831762585
        // Deposit Amount Was:  61070476549147019107646
        // We Got this Amount: 61070876437181831762585
        // Deposit Amount Was: 61070476549147019107646

        // Assert that his balance & total shares are 0
        assertEq(
            vaultContract.balances(Bob),
            depositAmount / 2,
            "Bob Withdrawn But Shares Mismatch"
        );
        assertEq(
            vaultContract.totalShares(),
            depositAmount / 2,
            "Bob Withdrawn But Total Shares Mismatch"
        );

        // Assert that the vault's GMX and GNS balances in pools are now 0
        assertTrue(
            getGmxStakingBalance() == preGMXPoolBalance / 2 ||
                getGmxStakingBalance() == preGMXPoolBalance / 2 - 1 ||
                getGmxStakingBalance() == preGMXPoolBalance / 2 + 1,
            "Bob Withdrawan But GMX Remains In Pool"
        );
        assertTrue(
            getGNSStakingBalance() == preGNSPoolBalance / 2 ||
                getGNSStakingBalance() == preGNSPoolBalance / 2 - 1 ||
                getGNSStakingBalance() == preGNSPoolBalance / 2 + 1,
            "Bob Withdrawan But GNS Remains In Pool"
        );

        // Assert that Bob's GMX balance is bigger than his deposited amount
        assertTrue(
            vaultContract.DEPOSIT_TOKEN().balanceOf(Bob) > depositAmount / 2,
            "Bob Withdrawan But Did Not Receive Extra GMX"
        );

        // Assert that vault contract's GMX balance is 0
        assertEq(
            vaultContract.DEPOSIT_TOKEN().balanceOf(address(vaultContract)),
            0,
            "Bob Withdrawan But GMX remains in pool"
        );
    }

    // ==================
    //      HELPERS
    // ==================
    function getGmxStakingBalance() public returns (uint256 stakedAmount) {
        bytes[] memory args = new bytes[](1);
        args[0] = encodeValueVar(abi.encode(address(vaultContract)));
        return
            abi.decode(
                vaultContract._runFunction(
                    encodeCall(
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

    function getGNSStakingBalance() public returns (uint256 stakedAmount) {
        bytes[] memory args = new bytes[](1);
        args[0] = encodeValueVar(abi.encode(address(vaultContract)));
        return
            abi.decode(
                vaultContract._runFunction(
                    encodeCall(
                        abi.encode(
                            FunctionCall(
                                GNS_STAKING_CONTRACT,
                                args,
                                "users(address)"
                            )
                        )
                    )
                ),
                (uint256)
            );
    }

    function getDepositTokenBalance() public view returns (uint256 balance) {
        return vaultContract.DEPOSIT_TOKEN().balanceOf(address(vaultContract));
    }

    function routeLatestRequest() internal {
        uint256 lastIndex = vaultContract.getOperationRequests().length;
        vm.startPrank(vaultContract.YC_DIAMOND());
        vaultContract.hydrateAndExecuteRun(lastIndex - 1, new bytes[](0));
        vm.stopPrank();
    }
}
