// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./DiamondBase.sol";
import "../Ownable.sol";

abstract contract YieldchainDiamond is DiamondBase, Ownable {
    // Mapping of classified functions (i.e func_30) => external functions (i.e addLiquidity()) signatures.
    mapping(string => string) internal classifiedFunctions;

    /**
     * @notice
     * @classifyFunction
     * OnlyOwner!!
     * Adds a new function to the classification
     */
    function classifyFunction(
        string memory _classified_function_name,
        string memory _external_function_signature
    ) external returns (bool) {
        classifiedFunctions[
            _classified_function_name
        ] = _external_function_signature;

        if (
            keccak256(
                abi.encode(classifiedFunctions[_classified_function_name])
            ) == keccak256(abi.encode(_external_function_signature))
        ) return true;

        return false;
    }

    /**
     * @notice
     * @getExternalFunction
     * Returns
     */
    function getExternalFunction(string memory _classified_function_signature)
        external
        view
        returns (string memory)
    {
        return classifiedFunctions[_classified_function_signature];
    }
}
