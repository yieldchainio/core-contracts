// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../storage/ClassificationsStorage.sol";

contract YCClassificationsFacet {
    /**
     * @notice
     * @classifyBatchFunctions
     * OnlyOwner!!
     * Multi-calls classifyFunction
     */
    function classifyBatchFunction(
        string[] memory _classified_functions_names,
        string[] memory _external_functions_signatures
    ) external returns (bool) {
        require(
            _classified_functions_names.length ==
                _external_functions_signatures.length,
            "Length of Classified Function Names Does Not Match Length Of External Function Signatures"
        );

        for (uint256 i = 0; i < _classified_functions_names.length; i++) {
            classifyFunction(
                _classified_functions_names[i],
                _external_functions_signatures[i]
            );
        }

        return true;
    }

    /**
     * @notice
     * @classifyFunction
     * OnlyOwner!!
     * Adds a new function to the classification
     */
    function classifyFunction(
        string memory _classified_function_name,
        string memory _external_function_signature
    ) public returns (bool) {
        // Getting classification storage
        ClassificationsStorage
            storage classificationStorage = ClassificationsStorageLib
                .getClassificationsStorage();

        classificationStorage.classifiedFunctions[
                _classified_function_name
            ] = _external_function_signature;

        // Requiring the insertion to succeed
        require(
            keccak256(
                abi.encode(
                    classificationStorage.classifiedFunctions[
                        _classified_function_name
                    ]
                )
            ) == keccak256(abi.encode(_external_function_signature)),
            "Classification Unsuccessfull."
        );

        // Indiciating the classification succeeded
        return true;
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
        // Getting classification storage
        ClassificationsStorage
            storage classificationStorage = ClassificationsStorageLib
                .getClassificationsStorage();

        return
            classificationStorage.classifiedFunctions[
                _classified_function_signature
            ];
    }
}
