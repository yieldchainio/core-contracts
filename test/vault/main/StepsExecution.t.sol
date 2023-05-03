// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../../src/vault/Vault.sol";
import "../../../src/vm/Encoders.sol";
import "../utilities/Dex.sol";
import "./Base.sol";
import "../../utils/Forks.t.sol";

contract ExecutionTest is Test, YieldchainTypes, YCVMEncoders {
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

    function setUp() public {
        networkID = new Forks().ARBITRUM();
        vm.selectFork(networkID);
        vaultContract = new BaseStrategy().getVaultContract();
    }

    /**
     * Test the deposit strategy
     */
    function testDepositAndSeedStrategy() public {
        // Assert the current balances and etc to be initial (0)
        assertEq(getDepositTokenBalance(), 0, "Initial Token Balance Is Not 0");
        assertEq(getGmxStakingBalance(), 0, "Initial GMX Staking is not 0");
        assertEq(getGNSStakingBalance(), 0, "Initial GNS Staking is not 0");

        // Reward ourselves with some 100 tokens
        vm.deal(address(vaultContract.DEPOSIT_TOKEN()), 100 * 10 ** 18);

        // Assert that we must have 100 tokens
        assertEq(
            vaultContract.DEPOSIT_TOKEN().balanceOf(address(this)),
            100 * 10 ** 18,
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
            ) >= 100 * 10 ** 18,
            "Insufficient Allowance"
        );

        // Assert that our balance is sufficient
        

        // Deposit all 100 tokens we have
        vaultContract.deposit(100 * 10 ** 18);

        // Assert that the vault's GMX staking balance should now be half of that
        assertEq(
            getGmxStakingBalance(),
            50 * 10 ** 18,
            "Deposited, But Vault's Staked GMX Mismatches"
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
}
