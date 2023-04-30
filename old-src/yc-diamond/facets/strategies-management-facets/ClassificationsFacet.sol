// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../../storage/ClassificationsStorage.sol";
import "../../../YC-Types.sol";

contract YCClassificationsFacet is YieldchainTypes {
    /**
     * @notice
     * @classifyBatchFunctions
     * OnlyOwner!!
     * Multi-calls classifyFunction
     */
    function classifyBatchFunction(
        string[] memory _classifiedFunctionsNames,
        string[] memory _externalFunctionsSignatures
    ) external returns (bool) {
        require(
            _classifiedFunctionsNames.length ==
                _externalFunctionsSignatures.length,
            "Length of Classified Function Names Does Not Match Length Of External Function Signatures"
        );

        for (uint256 i = 0; i < _classifiedFunctionsNames.length; i++) {
            classifyFunction(
                _classifiedFunctionsNames[i],
                _externalFunctionsSignatures[i]
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
        string memory _classifiedFunctionName,
        string memory _externalFunctionSignature
    ) public returns (bool) {
        // Getting classification storage
        ClassificationsStorage
            storage classificationStorage = ClassificationsStorageLib
                .getClassificationsStorage();

        classificationStorage.classifiedFunctions[
            _classifiedFunctionName
        ] = _externalFunctionSignature;

        // Requiring the insertion to succeed
        require(
            keccak256(
                abi.encode(
                    classificationStorage.classifiedFunctions[
                        _classifiedFunctionName
                    ]
                )
            ) == keccak256(abi.encode(_externalFunctionSignature)),
            "Classification Unsuccessfull."
        );

        // Indiciating the classification succeeded
        return true;
    }

    /**
     * @notice
     * @verifyYCFunction
     * Takes in a YC FunctionCall struct,
     * verifies it's classified signature by looking at the mapping of classifications,
     * @return _verifiedFunc struct with the signature modified to be the new one
     */
    function verifyYCFunction(FunctionCall memory _func)
        public
        view
        returns (FunctionCall memory _verifiedFunc)
    {
        // Getting the classified function's external func sig
        string memory res = getExternalFunction(_func.signature);

        // Verifying it is not empty
        require(
            keccak256(abi.encode(res)) != keccak256(abi.encode("")),
            "Function Called Does Is Not Classified!"
        );

        // Copy inputted func as return func, change signature
        _verifiedFunc = _func;
        _verifiedFunc.signature = res;
    }

    // TODO: Remove this? Is this needed when we ahve the verification function?
    /**
     * @notice
     * @getExternalFunction
     * Returns
     */
    function getExternalFunction(string memory _classifiedFunctionSignature)
        internal
        view
        returns (string memory)
    {
        // Getting classification storage
        ClassificationsStorage
            storage classificationStorage = ClassificationsStorageLib
                .getClassificationsStorage();

        return
            classificationStorage.classifiedFunctions[
                _classifiedFunctionSignature
            ];
    }
}
