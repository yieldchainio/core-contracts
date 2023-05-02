// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "./utilities/General.sol";
import "../../src/vm/VM.sol";
import "forge-std/console.sol";
import "./utilities/ERC20.sol";
import "./utilities/Staking.sol";
import "./utilities/Context.sol";
import "./utilities/Math.sol";

contract VMTest is Test, Constants, YieldchainTypes {
    // =====================
    //       CONTRACTS
    // =====================
    GeneralFunctions public generalFunctions;
    YCVM public ycVM;
    ERC20 public erc20Token;
    SimpleStaking public stakingContract;
    Context public contextContract;
    Math public mathContract;

    // =====================
    //       CONSTANTS
    // =====================
    uint256 public constant ERC20_TOTAL_SUPPLY = 1000000 * 10 ** 18;

    // =====================
    //       STRUCTS
    // =====================
    struct MixedStruct {
        uint64 first; // We do not want arithecmetic overflow, so uint128
        string someUnrelatedString;
        uint64 second; // We do not want arithecmetic overflow, so uint128
    }

    // =====================
    //       EVENTS
    // =====================
    event LogBoolean(bool indexed isTrue);

    function setUp() public {
        generalFunctions = new GeneralFunctions();
        ycVM = new YCVM();
        erc20Token = new ERC20("Epic Toecan", "EPIC", 18, ERC20_TOTAL_SUPPLY);

        // We pretend to be the ycVM so that it gets owner stuff
        stakingContract = new SimpleStaking(erc20Token);
        contextContract = new Context();
        mathContract = new Math();
    }

    // =====================
    //       TESTS
    // =====================
    /**
     * Test the ycVM with a general function, that stress-tests some of it's capabilities
     */
    function testFuzzyNestedGeneralFunctions(
        bytes32 firstFuzzCompatibleString,
        uint64 num, // We do not want arithecmetic overflow, so uint128
        bytes32 secondFuzzCompatiblestring,
        MixedStruct memory mixedStruct
    ) public {
        // Assume parameters to not be nullish and not cause overflows when multiplying
        vm.assume(firstFuzzCompatibleString != bytes32(0));
        vm.assume(secondFuzzCompatiblestring != bytes32(0));
        vm.assume(num != 0 && num < type(uint64).max / 3);
        vm.assume(
            mixedStruct.first != 0 && mixedStruct.first < type(uint64).max / 3
        );
        vm.assume(
            mixedStruct.second != 0 && mixedStruct.second < type(uint64).max / 3
        );
        vm.assume(
            keccak256(bytes(mixedStruct.someUnrelatedString)) !=
                keccak256(bytes(""))
        );

        /**
         * Encode The Command To Retreive the First String (3x nested string command)
         */
        bytes memory firstStringCommand = generalFunctions
            .encodeFixedLengthArrFunctionForYCVM(
                generalFunctions.encodeFixedLengthArrFunctionForYCVM(
                    generalFunctions
                        .encodeFixedLengthArrFunctionWithStringForYCVM(
                            string(abi.encodePacked(firstFuzzCompatibleString))
                        )
                )
            );

        /**
         * Encode the command to get the num arg
         */
        bytes memory numCommand = generalFunctions
            .encodeMultipleSimpleNumForYCVM(num);

        /**
         * Encode the second string getter
         */
        string[] memory ourStringArrAsAnArg = new string[](2);
        ourStringArrAsAnArg[0] = string(
            abi.encodePacked(secondFuzzCompatiblestring)
        );
        ourStringArrAsAnArg[1] = string.concat(
            string(abi.encodePacked(secondFuzzCompatiblestring)),
            " Is Indexed"
        );
        bytes memory secondStringCommand = generalFunctions
            .encodeDynamicLengthStringArr(ourStringArrAsAnArg);

        /**
         * Encode the struct command
         */
        bytes memory mixedStructCommand = generalFunctions
            .encodeStructFunctionForYCVM(
                mixedStruct.first,
                mixedStruct.someUnrelatedString,
                mixedStruct.second
            );

        /**
         * Encode the root function call (uses all of the above complex commands as args)
         */
        bytes memory rootFunctionCall = generalFunctions
            .encodeMixedFunctionForYCVM(
                firstStringCommand,
                numCommand,
                secondStringCommand,
                mixedStructCommand
            );

        // Run it
        bytes memory result = ycVM._runFunction(rootFunctionCall);

        // Decode the results
        (
            string memory resString,
            uint256 resNum,
            string memory resStringTwo,
            MixedStruct memory resMixedStruct
        ) = abi.decode(result, (string, uint256, string, MixedStruct));

        // Assert equality of the results to desired (According to what the functions we called should have emitted)
        assertEq(
            string.concat(
                "New New New ",
                string(abi.encodePacked(firstFuzzCompatibleString)),
                " Works Works Works",
                " Is Valid"
            ),
            resString,
            "First String Does Not Match"
        );
        assertEq(num * 2, resNum, "Desired Num Does Not Match");
        assertEq(
            string.concat(
                string(abi.encodePacked(secondFuzzCompatiblestring)),
                string(abi.encodePacked(secondFuzzCompatiblestring)),
                " Is Indexed",
                " Is Valid"
            ),
            resStringTwo,
            "Second String Does Not Match"
        );
        assertEq(
            mixedStruct.first * 2,
            resMixedStruct.first,
            "Struct First Num DOes Not Match"
        );
        assertEq(
            mixedStruct.second * 2,
            resMixedStruct.second,
            "Struct Second Num Does Not Match"
        );
        assertEq(
            "Mixed Struct",
            resMixedStruct.someUnrelatedString,
            "Struct String Does Not Match"
        );
    }

    /**
     * Test the ycVM's "self" functionality.
     * We not only just call .self() on the VM contract,
     * we make a yc command that makes a call to .self() on the address(0),
     * which the ycVM shall interpret as a call to itself
     */
    function testVMConsciousness() public {
        /**
         * Encode the command on the 0 address, to call self() (which is actually on the ycVM core contract)
         */
        bytes[] memory args = new bytes[](0);
        FunctionCall memory selfFunctionStaticCall = FunctionCall(
            address(0),
            args,
            "self()"
        );

        // Encode it
        bytes memory ycCommand = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(selfFunctionStaticCall)
        );

        // Decode the call result and assert it equals to the ycVM's actual address
        address result = abi.decode(ycVM._runFunction(ycCommand), (address));
        assertEq(result, address(ycVM), "ycVM Is Not Self Conscious");
    }

    /**
     * Fuzz test the VM with some mocked real-world-like usecases,
     * ERC20 Basic Operations
     */
    function testFuzzERC20Ops() public {
        /**
         * Make sure our initial balance (as the deployer of the ERC20 token) is the total supply
         */
        assertEq(erc20Token.balanceOf(address(this)), ERC20_TOTAL_SUPPLY);

        /**
         * Encode an approval command to approve US (test contract) on the ycVM
         */
        bytes[] memory approveArgs = new bytes[](2);

        // Address to approve as VALUE_VAR arg (us)
        approveArgs[0] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(address(this))
        );

        // Amount to approve
        approveArgs[1] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(ERC20_TOTAL_SUPPLY)
        );

        // The command
        bytes memory approveCommand = bytes.concat(
            CALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(erc20Token),
                    approveArgs,
                    "approve(address,uint256)"
                )
            )
        );

        // Run it
        ycVM._runFunction(approveCommand);

        /**
         * Get our current allowance on the ycVM contract to ensure the approval worked
         */
        assertEq(
            erc20Token.allowance(address(ycVM), address(this)),
            ERC20_TOTAL_SUPPLY
        );

        /**
         * We approve the ycVM contract now (to call transferFrom)
         */
        erc20Token.approve(address(ycVM), type(uint256).max - 1);

        /**
         * We encode a command to call transferFrom() on our address, for all of our balance
         */
        bytes[] memory transferFromArgs = new bytes[](3);

        transferFromArgs[0] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(address(this))
        );

        transferFromArgs[1] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(FunctionCall(address(0), new bytes[](0), "self()"))
        );

        /**
         * Complex command of balanceOf as the argument
         */
        bytes[] memory balanceOfArgs = new bytes[](1);
        balanceOfArgs[0] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(address(this))
        );

        transferFromArgs[2] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(erc20Token),
                    balanceOfArgs,
                    "balanceOf(address)"
                )
            )
        );

        // Call the command
        ycVM._runFunction(
            bytes.concat(
                CALL_COMMAND_FLAG,
                VALUE_VAR_FLAG,
                abi.encode(
                    FunctionCall(
                        address(erc20Token),
                        transferFromArgs,
                        "transferFrom(address,address,uint256)"
                    )
                )
            )
        );

        // Assert that the VM's balance now must be the total supply (what was originally ours)
        assertEq(
            erc20Token.balanceOf(address(ycVM)),
            erc20Token.totalSupply(),
            "Transfer From Did Not Work - ycVM's balanceof does not equal to total supply."
        );

        // Run a command to transfer to us again from the ycVM (transfer())
        bytes[] memory transferArgs = new bytes[](2);

        /**
         * @notice
         * Here we encode a DELEGATE CALL command to Context.sol to get the msg sender (us),
         * for additional stress testing
         */
        transferArgs[0] = bytes.concat(
            DELEGATECALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(contextContract),
                    new bytes[](0),
                    "msgSender()"
                )
            )
        );

        bytes[] memory balanceOfVMArgs = new bytes[](1);

        balanceOfVMArgs[0] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(FunctionCall(address(0), new bytes[](0), "self()"))
        );

        transferArgs[1] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(erc20Token),
                    balanceOfVMArgs,
                    "balanceOf(address)"
                )
            )
        );

        ycVM._runFunction(
            bytes.concat(
                CALL_COMMAND_FLAG,
                VALUE_VAR_FLAG,
                abi.encode(
                    FunctionCall(
                        address(erc20Token),
                        transferArgs,
                        "transfer(address,uint256)"
                    )
                )
            )
        );

        // We assert that our balance should have resumed to what it was,
        // and the ycVM's balance to 0
        assertEq(erc20Token.balanceOf(address(this)), ERC20_TOTAL_SUPPLY);
        assertEq(erc20Token.balanceOf(address(ycVM)), 0);
    }

    /**
     * Test some basic ERC20 staking contract functionality
     * through the ycVM
     */
    function testFuzzStakingOps(uint160 lockPeriod) public {
        vm.assume(lockPeriod > 0);
        /**
         * Make sure our initial balance equals to the total supply (1M)
         */
        assertEq(
            erc20Token.balanceOf(address(this)),
            ERC20_TOTAL_SUPPLY,
            "Initial Balance Of U Is Not Total Supply"
        );

        /**
         * Shorthand function DELEGATECALL that will be reused
         * to get the msgsender (inefficient but good for testing purposes)
         */
        bytes memory getMsgSender = bytes.concat(
            DELEGATECALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(contextContract),
                    new bytes[](0),
                    "msgSender()"
                )
            )
        );

        /**
         * Shorthand function to get self() address on the ycVM
         */
        bytes memory getSelf = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(FunctionCall(address(0), new bytes[](0), "self()"))
        );

        /**
         * We make a function call to change the locking period on it
         */
        bytes[] memory timestampArgs = new bytes[](1);
        timestampArgs[0] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(lockPeriod)
        );
        bytes memory timestampCall = bytes.concat(
            CALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(stakingContract),
                    timestampArgs,
                    "setTimestamp(uint256)"
                )
            )
        );

        // Make the call
        ycVM._runFunction(timestampCall);

        // Assert the equality of the timestamp to be the lock period we got as an argument
        assertEq(
            stakingContract.timePeriod(),
            stakingContract.initialTimestamp() + lockPeriod,
            "Timestamp Not Set Correctly"
        );
        assertTrue(
            stakingContract.timestampSet(),
            "Timestamp not set successfully"
        );

        /**
         * Reset it to 0
         */
        timestampArgs[0] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(0)
        );
        ycVM._runFunction(
            bytes.concat(
                CALL_COMMAND_FLAG,
                VALUE_VAR_FLAG,
                abi.encode(
                    FunctionCall(
                        address(stakingContract),
                        timestampArgs,
                        "setTimestamp(uint256)"
                    )
                )
            )
        );

        /**
         * Transfer all of our tokens to the ycVM
         */
        erc20Token.transfer(address(ycVM), ERC20_TOTAL_SUPPLY);

        /**
         * Encode a complex command on the ycVM to stake half of it's balance,
         * by calling these complex commands recrusively:
         * div(balanceOf(self()),2)
         */
        bytes[] memory balanceOfArgs = new bytes[](1);
        // delegate call to get msg sender (ycVM)
        balanceOfArgs[0] = getSelf;

        bytes[] memory mathArgs = new bytes[](2);
        // A function call to get the balance of us
        mathArgs[0] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(erc20Token),
                    balanceOfArgs,
                    "balanceOf(address)"
                )
            )
        );

        // We divide it by 2
        mathArgs[1] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(2)
        );

        // The args for the staking call
        bytes[] memory stakeArgs = new bytes[](2);

        // The ERC20 contract address (we make a static call to the staking contract to get it
        stakeArgs[0] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(stakingContract),
                    new bytes[](0),
                    "erc20Contract()"
                )
            )
        );

        // The divisor command
        stakeArgs[1] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(mathContract),
                    mathArgs,
                    "div(uint256,uint256)"
                )
            )
        );

        /**
         * We first also make an approve function call command on the ycVM to the staking contract so it could call transferFrom
         */
        bytes[] memory approveArgs = new bytes[](2);
        approveArgs[0] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(address(stakingContract))
        );
        approveArgs[1] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(type(uint256).max)
        );

        ycVM._runFunction(
            bytes.concat(
                CALL_COMMAND_FLAG,
                VALUE_VAR_FLAG,
                abi.encode(
                    FunctionCall(
                        address(erc20Token),
                        approveArgs,
                        "approve(address,uint256)"
                    )
                )
            )
        );

        // We make the call
        ycVM._runFunction(
            bytes.concat(
                CALL_COMMAND_FLAG,
                VALUE_VAR_FLAG,
                abi.encode(
                    FunctionCall(
                        address(stakingContract),
                        stakeArgs,
                        "stakeTokens(address,uint256)"
                    )
                )
            )
        );

        /**
         * At this point, we made a staking function call to the staking contract,
         * which:
         *
         * 1) Called transferFrom on the ERC20 contract to transfer all of our balance to the ycVM
         * 2) Called stakeTokens() from the ycVM on HALF of it's balance, the staked balance should be TOTAL SUPPLY / 2
         */
        assertEq(
            stakingContract.balances(address(ycVM)),
            ERC20_TOTAL_SUPPLY / 2,
            "Staking Amount From ycVM Does Not Match Inputted Amount"
        );

        assertEq(
            erc20Token.balanceOf(address(this)),
            0,
            "ERC20 Token Balance On Your Address Does Not Match Leftover Amount"
        );

        assertEq(
            erc20Token.balanceOf(address(ycVM)),
            ERC20_TOTAL_SUPPLY / 2,
            "ERC20 Token Balance On ycVM Does Not Match Leftover Amount"
        );

        /**
         * Now, we unstake the tokens. We make a call to withdraw all of our shares,
         * by using a DELEGATECALL to get msg.sender (us) and retreiving the balance from storage
         */
        bytes[] memory unstakeArgs = new bytes[](2);

        // The ERC20 contract address (we make a static call to the staking contract to get it
        unstakeArgs[0] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(stakingContract),
                    new bytes[](0),
                    "erc20Contract()"
                )
            )
        );

        // The call to get our tokens
        bytes[] memory getUnstakeAmountArgs = new bytes[](1);
        getUnstakeAmountArgs[0] = getSelf;
        unstakeArgs[1] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(stakingContract),
                    getUnstakeAmountArgs,
                    "balances(address)"
                )
            )
        );

        // Make the unstake call
        ycVM._runFunction(
            bytes.concat(
                CALL_COMMAND_FLAG,
                VALUE_VAR_FLAG,
                abi.encode(
                    FunctionCall(
                        address(stakingContract),
                        unstakeArgs,
                        "unstakeTokens(address,uint256)"
                    )
                )
            )
        );

        // Assert staking balance for ycVM 0, and the balanceOf of ERC20 token to be total supply

        assertEq(
            stakingContract.balances(address(ycVM)),
            0,
            "Unstaking Failed - Balance Is Not 0 On Staking Contract"
        );
        assertEq(
            erc20Token.balanceOf(address(ycVM)),
            ERC20_TOTAL_SUPPLY,
            "Unstaking Failed - Balance Is Not Total Supply On ERC20 Contract, on your address"
        );

        // We then transfer tokens back to us (test contract) from ycVM and mark this test as complete
        bytes[] memory lastBalanceOfArgs = new bytes[](1);
        lastBalanceOfArgs[0] = getSelf;
        ycVM._runFunction(
            erc20Token.encodeTransferForYCVM(
                getMsgSender,
                bytes.concat(
                    STATICCALL_COMMAND_FLAG,
                    VALUE_VAR_FLAG,
                    abi.encode(
                        FunctionCall(
                            address(erc20Token),
                            lastBalanceOfArgs,
                            "balanceOf(address)"
                        )
                    )
                )
            )
        );

        assertEq(
            erc20Token.balanceOf(address(ycVM)),
            0,
            "Last Transfer Failed, ycVM balance is not 0."
        );
        assertEq(
            erc20Token.balanceOf(address(this)),
            ERC20_TOTAL_SUPPLY,
            "Last Transfer Failed, your balance is not total supply."
        );
    }
}
