// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "./utilities/General.sol";
import "../../src/vm/VM.sol";
import "forge-std/console.sol";
import "./utilities/ERC20.sol";
import "./utilities/Staking.sol";
import "./utilities/Context.sol";

contract VMTest is Test, Constants, YieldchainTypes {
    GeneralFunctions public generalFunctions;
    YCVM public ycVM;
    ERC20 public erc20Token;
    SimpleStaking public stakingContract;
    Context public contextContract;

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
        erc20Token = new ERC20("Epic Toecan", "EPIC", 18, 1000000 * 10 ** 18);
        stakingContract = new SimpleStaking(erc20Token);
        contextContract = new Context();
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

        // Encode The Command To Retreive the First String

        bytes memory firstStringCommand = generalFunctions
            .encodeFixedLengthArrFunctionForYCVM(
                generalFunctions.encodeFixedLengthArrFunctionForYCVM(
                    generalFunctions
                        .encodeFixedLengthArrFunctionWithStringForYCVM(
                            string(abi.encodePacked(firstFuzzCompatibleString))
                        )
                )
            );

        // Encode the num getter
        bytes memory numCommand = generalFunctions
            .encodeMultipleSimpleNumForYCVM(num);

        // Encode the second string getter
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

        bytes memory mixedStructCommand = generalFunctions
            .encodeStructFunctionForYCVM(
                mixedStruct.first,
                mixedStruct.someUnrelatedString,
                mixedStruct.second
            );

        bytes memory rootFunctionCall = generalFunctions
            .encodeMixedFunctionForYCVM(
                firstStringCommand,
                numCommand,
                secondStringCommand,
                mixedStructCommand
            );

        bytes memory result = ycVM._runFunction(rootFunctionCall);

        console.log("Before ABI Decode");

        (
            string memory resString,
            uint256 resNum,
            string memory resStringTwo,
            MixedStruct memory resMixedStruct
        ) = abi.decode(result, (string, uint256, string, MixedStruct));

        console.log("After ABI Decode");

        // =====================
        //    DESIRED OUTPUTS
        // =====================

        // Assert equality of the results to desired
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
         * Encode the command on the 0 address
         */
        bytes[] memory args = new bytes[](0);
        FunctionCall memory selfFunctionStaticCall = FunctionCall(
            address(0),
            args,
            "self()",
            false
        );

        bytes memory ycCommand = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(selfFunctionStaticCall)
        );

        address result = abi.decode(ycVM._runFunction(ycCommand), (address));
        assertEq(result, address(ycVM), "ycVM Is Not Self Conscious");
    }

    /**
     * Fuzz test the VM with some mocked real-world-like usecases,
     * ERC20 Basic Operations
     */
    function testFuzzERC20Ops(uint256 amount) public {
        // Make some asserations to make sure our ERC20 configs are correct
        // Balance of us should be the total supply (10M)
        assertEq(erc20Token.balanceOf(address(this)), 1000000 * 10 ** 18);

        // Encode a command to approve
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
            abi.encode(amount)
        );

        // The command
        bytes memory approveCommand = bytes.concat(
            CALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(erc20Token),
                    approveArgs,
                    "approve(address,uint256)",
                    false
                )
            )
        );

        // Run it
        ycVM._runFunction(approveCommand);

        // Get the current allowance on us from the ycVM contract and assert it must be the approveAmount
        assertEq(erc20Token.allowance(address(ycVM), address(this)), amount);

        // If it is OK, we move onto transfer

        // We approve him (we want him to .transferFrom() from us)
        erc20Token.approve(address(ycVM), erc20Token.totalSupply());

        // We encode a command to transferFrom from us all of our balance to the VM
        bytes[] memory transferFromArgs = new bytes[](3);

        transferFromArgs[0] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(address(this))
        );

        transferFromArgs[1] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(address(0), new bytes[](0), "self()", false)
            )
        );

        // Balance of command
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
                    "balanceOf(address)",
                    false
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
                        "transferFrom(address,address,uint256)",
                        false
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

        // Run a command to transfer to us
        bytes[] memory transferArgs = new bytes[](2);

        /**
         * @notice
         * Here we encode a DELEGATE CALL command to Context.sol to get the msg sender (us)
         */
        transferArgs[0] = bytes.concat(
            DELEGATECALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(contextContract),
                    new bytes[](0),
                    "msgSender()",
                    false
                )
            )
        );

        bytes[] memory balanceOfVMArgs = new bytes[](1);

        balanceOfVMArgs[0] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(address(0), new bytes[](0), "self()", false)
            )
        );

        transferArgs[1] = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(erc20Token),
                    balanceOfVMArgs,
                    "balanceOf(address)",
                    false
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
                        "transfer(address,uint256)",
                        false
                    )
                )
            )
        );

        // We assert that our balance should have resumed to what it was,
        // and the ycVM's balance to 0
        assertEq(erc20Token.balanceOf(address(this)), 1000000 * 10 ** 18);
        assertEq(erc20Token.balanceOf(address(ycVM)), 0);
    }
}
