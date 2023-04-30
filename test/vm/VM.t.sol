// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "./utilities/General.sol";
import "../../src/vm/VM.sol";
import "forge-std/console.sol";

contract VMTest is Test, Constants {
    GeneralFunctions public generalFunctions;
    YCVM public ycVM;

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
    }

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
}
