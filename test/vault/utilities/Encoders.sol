// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../src/vm/Encoders.sol";

/**
 * UTility encoders for the vault tests
 */

contract UtilityEncoder is YCVMEncoders {
    function encodeGetInvestmentAmount(
        bytes memory amountRetreiver,
        uint256 bigDivisor
    ) public view returns (bytes memory) {
        // Args for the call
        bytes[] memory args = new bytes[](2);
        args[0] = amountRetreiver;
        args[1] = encodeValueVar(abi.encode(bigDivisor));

        // Encoded function call
        bytes memory callCommand = encodeValueStaticCall(
            abi.encode(
                FunctionCall(
                    address(0),
                    args,
                    "getInvestmentAmount(bytes,uint256)"
                )
            )
        );

        return callCommand;
    }

    function encodeFirstWordExtracter(
        bytes memory arg
    ) public view returns (bytes memory) {
        bytes[] memory args = new bytes[](1);
        args[0] = arg;
        return
            encodeValueStaticCall(
                abi.encode(
                    FunctionCall(address(0), args, "extractFirstWord(bytes)")
                )
            );
    }

    function encodeBalanceOf(
        address tokenAddress
    ) public pure returns (bytes memory) {
        // The args for the function call
        bytes[] memory args = new bytes[](1);

        args[0] = encodeSelfCommand();

        FunctionCall memory balanceOfStaticCall = FunctionCall(
            tokenAddress,
            args,
            "balanceOf(address)"
        );

        return
            bytes.concat(
                STATICCALL_COMMAND_FLAG, // Static call Command (non state changing)
                VALUE_VAR_FLAG, // Value variable return value (uint)
                abi.encode(balanceOfStaticCall) // Encoded balanceOf staticcall
            );
    }

    function encodeBalanceOf(
        address tokenAddress,
        bytes memory userAddressCommand
    ) public pure returns (bytes memory) {
        // The args for the function call
        bytes[] memory args = new bytes[](1);

        args[0] = userAddressCommand;

        FunctionCall memory balanceOfStaticCall = FunctionCall(
            tokenAddress,
            args,
            "balanceOf(address)"
        );

        return
            bytes.concat(
                STATICCALL_COMMAND_FLAG, // Static call Command (non state changing)
                VALUE_VAR_FLAG, // Value variable return value (uint)
                abi.encode(balanceOfStaticCall) // Encoded balanceOf staticcall
            );
    }
}
