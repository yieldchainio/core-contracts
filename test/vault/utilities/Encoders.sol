// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../src/vm/Encoders.sol";
import "../../../src/vault/Constants.sol";

/**
 * UTility encoders for the vault tests
 */

contract UtilityEncoder is YCVMEncoders, VaultConstants {
    function encodeGetInvestmentAmount(
        bytes memory amountRetreiver,
        uint256 bigDivisor
    ) public pure returns (bytes memory) {
        // Args for the call
        bytes[] memory args = new bytes[](2);
        args[0] = amountRetreiver;
        args[1] = encodeValueVar(abi.encode(bigDivisor));

        // Encoded function call
        bytes memory callCommand = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(0),
                    args,
                    "getInvestmentAmount(uint256,uint256)"
                )
            )
        );

        return callCommand;
    }

    function encodeGetInvestmentAmount(
        bytes memory amountRetreiver,
        bytes memory bigDivisor
    ) public pure returns (bytes memory) {
        // Args for the call
        bytes[] memory args = new bytes[](2);
        args[0] = amountRetreiver;
        args[1] = bigDivisor;

        // Encoded function call
        bytes memory callCommand = bytes.concat(
            STATICCALL_COMMAND_FLAG,
            VALUE_VAR_FLAG,
            abi.encode(
                FunctionCall(
                    address(0),
                    args,
                    "getInvestmentAmount(uint256,uint256)"
                )
            )
        );

        return callCommand;
    }

    function encodeFirstWordExtracter(
        bytes memory arg
    ) public pure returns (bytes memory) {
        bytes[] memory args = new bytes[](1);
        args[0] = arg;
        return
            bytes.concat(
                STATICCALL_COMMAND_FLAG,
                VALUE_VAR_FLAG,
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

        args[0] = encodeValueVar(abi.encode(tokenAddress));

        FunctionCall memory balanceOfStaticCall = FunctionCall(
            address(0),
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

    function encodeDepositAmountGetter() public pure returns (bytes memory) {
        bytes[] memory mloadArgs = new bytes[](1);
        mloadArgs[0] = abi.encode(DEPOSIT_AMT_MEM_LOCATION);

        return
            bytes.concat(
                INTERNAL_LOAD_FLAG,
                VALUE_VAR_FLAG,
                abi.encode(FunctionCall(address(0), mloadArgs, "MLOAD"))
            );
    }

    function encodeWithdrawSharesGetter() public pure returns (bytes memory) {
        bytes[] memory mloadArgs = new bytes[](1);
        mloadArgs[0] = abi.encode(WITHDRAW_SHARES_MEM_LOCATION);

        return
            bytes.concat(
                INTERNAL_LOAD_FLAG,
                VALUE_VAR_FLAG,
                abi.encode(FunctionCall(address(0), mloadArgs, "MLOAD"))
            );
    }
}

// 0x000000000000000000000000000000000000000000001cd4e87913aadcac9a6a

// 0x000000000000000000000000000000000000000000001cd4e87913aadcac9a6a
