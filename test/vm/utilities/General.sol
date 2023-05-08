// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../src/Types.sol";
import "../../../src/vm/Constants.sol";

contract GeneralFunctions is Constants {
    // =====================
    //       STRUCTS
    // =====================
    struct MixedStruct {
        uint256 first;
        string someUnrelatedString;
        uint256 second;
    }

    // =====================
    //       EVENTS
    // =====================
    event LogBoolean(bool indexed isTrue);

    // =====================
    //      FUNCTIONS
    // =====================

    /**
     * Encoders
     */
    function encodeMixedFunctionForYCVM(
        bytes memory stringOneYcCommand,
        bytes memory numYcCommand,
        bytes memory stringTwoYcCommand,
        bytes memory uintArrYcCommand
    ) public view returns (bytes memory) {
        // Init arr of arguments
        bytes[] memory args = new bytes[](4);

        args[0] = stringOneYcCommand;
        args[1] = numYcCommand;
        args[2] = stringTwoYcCommand;
        args[3] = uintArrYcCommand;

        // Get the function call
        FunctionCall memory mixedFunctionCall = FunctionCall(
            address(this),
            args,
            "generalFunction(string,uint256,string,(uint256,string,uint256))"
        );

        // Return encoded
        return
            bytes.concat(
                CALL_COMMAND_FLAG, // Is call (state changing, emits an event)
                REF_VAR_FLAG, // Returns a string (reference variable)
                abi.encode(mixedFunctionCall) // The encoded call
            );
    }

    function encodeStructFunctionForYCVM(
        uint256 firstNum,
        string memory structString,
        uint256 secondNum
    ) public view returns (bytes memory) {
        // Init arr of arguments
        bytes[] memory args = new bytes[](1);
        bytes[] memory arrMockingStruct = new bytes[](3);

        arrMockingStruct[0] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(firstNum)
        );
        arrMockingStruct[1] = bytes.concat(
            REF_VAR_FLAG,
            REF_VAR_FLAG,
            abi.encode(structString)
        );
        arrMockingStruct[2] = bytes.concat(
            VALUE_VAR_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(secondNum)
        );

        args[0] = bytes.concat(
            COMMANDS_LIST_FLAG,
            REF_VAR_FLAG,
            abi.encode(arrMockingStruct)
        );

        // Get the function call
        FunctionCall memory structFunctionCall = FunctionCall(
            address(this),
            args,
            "multiplyFixedStructAndAssignString((uint256,string,uint256))"
        );

        // Return encoded
        return
            bytes.concat(
                STATICCALL_COMMAND_FLAG, // Is staticcall (non state chaning)
                REF_VAR_FLAG, // Returns a struct with a linkage (has an offset ptr)
                abi.encode(structFunctionCall) // The encoded call
            );
    }

    function encodeFixedLengthArrFunctionForYCVM(
        bytes memory stringYcCommand
    ) public view returns (bytes memory) {
        // Init arr of arguments
        bytes[] memory args = new bytes[](1);
        bytes[] memory stringArrAsArg = new bytes[](1);
        stringArrAsArg[0] = stringYcCommand;

        args[0] = bytes.concat(
            COMMANDS_LIST_FLAG,
            REF_VAR_FLAG,
            abi.encode(stringArrAsArg)
        );

        // Get the function call
        FunctionCall memory fixedLengthArrStaticcall = FunctionCall(
            address(this),
            args,
            "fixedLengthStringArray(string[1])"
        );

        // Return encoded
        return
            bytes.concat(
                STATICCALL_COMMAND_FLAG, // Is staticcall (non state chaning)
                REF_VAR_FLAG, // Returns a struct with a linkage (has an offset ptr)
                abi.encode(fixedLengthArrStaticcall) // The encoded call
            );
    }

    function encodeFixedLengthArrFunctionWithStringForYCVM(
        string memory stringArg
    ) public view returns (bytes memory) {
        // Init arr of arguments
        bytes[] memory args = new bytes[](1);
        bytes[] memory stringArr = new bytes[](1);
        stringArr[0] = bytes.concat(
            REF_VAR_FLAG,
            REF_VAR_FLAG,
            abi.encode(stringArg)
        );
        args[0] = bytes.concat(
            COMMANDS_LIST_FLAG,
            REF_VAR_FLAG,
            abi.encode(stringArr)
        );

        // Get the function call
        FunctionCall memory fixedLengthArrStaticcall = FunctionCall(
            address(this),
            args,
            "fixedLengthStringArray(string[1])"
        );

        // Return encoded
        return
            bytes.concat(
                STATICCALL_COMMAND_FLAG, // Is staticcall (non state chaning)
                REF_VAR_FLAG, // Returns a struct with a linkage (has an offset ptr)
                abi.encode(fixedLengthArrStaticcall) // The encoded call
            );
    }

    function encodeMultipleSimpleNumForYCVM(
        uint256 num
    ) public view returns (bytes memory) {
        bytes[] memory args = new bytes[](1);
        args[0] = bytes.concat(VALUE_VAR_FLAG, VALUE_VAR_FLAG, abi.encode(num));

        FunctionCall memory simpleNumStaticcall = FunctionCall(
            address(this),
            args,
            "multiplySimpleNum(uint256)"
        );

        return
            bytes.concat(
                STATICCALL_COMMAND_FLAG,
                VALUE_VAR_FLAG,
                abi.encode(simpleNumStaticcall)
            );
    }

    function encodeDynamicLengthStringArr(
        string[] memory dynamicStringArrArg
    ) public view returns (bytes memory) {
        bytes[] memory args = new bytes[](1);
        bytes[] memory stringArrArg = new bytes[](2);
        for (uint256 i = 0; i < dynamicStringArrArg.length; i++) {
            stringArrArg[i] = bytes.concat(
                REF_VAR_FLAG,
                REF_VAR_FLAG,
                abi.encode(dynamicStringArrArg[i])
            );
        }
        args[0] = bytes.concat(
            COMMANDS_REF_ARR_FLAG,
            REF_VAR_FLAG,
            abi.encode(stringArrArg)
        );

        FunctionCall memory stringArrFunctionCall = FunctionCall(
            address(this),
            args,
            "dynamicLengthStringArray(string[])"
        );

        return
            bytes.concat(
                STATICCALL_COMMAND_FLAG,
                REF_VAR_FLAG,
                abi.encode(stringArrFunctionCall)
            );
    }

    /**
     * Actual Functions
     */
    function generalFunction(
        string memory stringOne,
        uint256 num,
        string memory stringTwo,
        MixedStruct memory mixedStruct
    )
        public
        returns (string memory, uint256, string memory, MixedStruct memory)
    {
        // If the first word's first 32 bytes equals to the second word's 32 bytes, the num is equal to 515
        // and the num arr's index 1 is equal to 999 - log true. Otherwise, log false
        bool isTrue = keccak256(bytes(stringOne)) ==
            keccak256(
                bytes("New New New First String Ser Works Works Works Works")
            ) &&
            keccak256(bytes(stringTwo)) ==
            keccak256(bytes("Second String SerSecond String Ser")) &&
            num == 500 &&
            mixedStruct.first == 100 &&
            mixedStruct.second == 100 &&
            keccak256(bytes(mixedStruct.someUnrelatedString)) ==
            keccak256(bytes("Mixed Struct"));

        // Log it
        emit LogBoolean(isTrue);

        // Return the string one + two + "Is A Valid Statement"
        return (
            string.concat(stringOne, " Is Valid"),
            num,
            string.concat(stringTwo, " Is Valid"),
            mixedStruct
        );
    }

    function fixedLengthStringArray(
        string[1] memory fixedStringArr
    ) public pure returns (string memory) {
        string memory newString = string.concat("New ", fixedStringArr[0]);
        return string.concat(newString, " Works");
    }

    function dynamicLengthStringArray(
        string[] memory dynamicStringArr
    ) public pure returns (string memory) {
        return string.concat(dynamicStringArr[0], dynamicStringArr[1]);
    }

    function multiplyFixedStructAndAssignString(
        MixedStruct memory mixedStruct
    ) public pure returns (MixedStruct memory) {
        return
            MixedStruct(
                mixedStruct.first * 2,
                "Mixed Struct",
                mixedStruct.second * 2
            );
    }

    function multiplySimpleNum(uint256 num) public pure returns (uint256) {
        return num * 2;
    }
}
