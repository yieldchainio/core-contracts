/**
 * Facet for verifying LI.FI related offchain commands
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "src/Types.sol";
import {LibSwap} from "@lifi/Libraries/LibSwap.sol";

contract LIFIValidator {
    /**
     * @param encodedOffchainValidation - OffchainValidation, encoded
     * @return isValid - Whether it is a valid offchain command or not
     */
    // For now simply verify receiver is correct (The msg.sender - i.e the vault)
    function validateLifiswapCalldata(
        bytes calldata encodedOffchainValidation
    ) public pure returns (bool isValid) {
        OffchainCommandValidation memory validationData = abi.decode(
            encodedOffchainValidation,
            (OffchainCommandValidation)
        );

        address receiver;
        uint256 receivingAmount;
        LibSwap.SwapData memory swapData;
        LibSwap.SwapData[] memory swapData;
        (, , , receiver, receivingAmount, swapData) = abi.decode(
            data[4:],
            (bytes32, string, string, address, uint256, LibSwap.SwapData[])
        );

        if (receiver == msg.sender) isValid = true;
    }

    function extractGenericSwapParameters(
        bytes calldata data
    )
        internal
        pure
        returns (
            address sendingAssetId,
            uint256 amount,
            address receiver,
            address receivingAssetId,
            uint256 receivingAmount
        )
    {
        LibSwap.SwapData[] memory swapData;
        (, , , receiver, receivingAmount, swapData) = abi.decode(
            data[4:],
            (bytes32, string, string, address, uint256, LibSwap.SwapData[])
        );
        sendingAssetId = swapData[0].sendingAssetId;
        amount = swapData[0].fromAmount;
        receivingAssetId = swapData[swapData.length - 1].receivingAssetId;
        return (
            sendingAssetId,
            amount,
            receiver,
            receivingAssetId,
            receivingAmount
        );
    }
}
