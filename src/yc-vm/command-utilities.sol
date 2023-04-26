// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../YC-Types.sol";

contract ycVMUtilities is YieldchainTypes {
    // =====================
    //        ERRORS
    // =====================
    error InvalidCallFlag();

    // =====================
    //       FUNCTIONS
    // =====================
    /**
     * @notice
     * Decodes a full encoded YC FunctionCall
     * @param _encodedFunctionCall - An encoded YC FunctionCall struct, with flags
     * @return _decodedFunc The decoded function call
     * @return _typeflag - the typeflag of the FunctionCall
     * @return _returnTypeflag - The typeflag of the FunctionCall's return value
     */

    function decodeFunctionCall(
        bytes memory _encodedFunctionCall
    )
        internal
        pure
        returns (
            FunctionCall memory _decodedFunc,
            uint8 _typeflag,
            uint8 _returnTypeflag
        )
    {
        // Initiating byte for the encoded function call without the flag
        bytes memory encodedFunctionCallNoFlag;

        // Seperating them
        (encodedFunctionCallNoFlag, _typeflag, _returnTypeflag);
    }

    /**
     * @notice
     * Takes in a dynamic-length variable (e.g strings, dynamic arrays, etc) - parses only it's value & length (i.e removes pointer)
     * @param _arg - An encoded argument which is a dynamic-length variable
     */
    function parseDynamicVar(
        bytes memory _arg
    ) public pure returns (bytes memory) {
        bytes memory newVal = new bytes(_arg.length - 0x20);
        assembly {
            // Length of the arg
            let len := sub(mload(_arg), 0x20)

            // Require the argument to be a multiple of 32 bytes
            if iszero(iszero(mod(len, 0x20))) {
                revert(0, 0)
            }

            // Length's multiple of 32
            let iters := div(len, 0x20)

            // Pointer - We use that in a base pointer so that we skip over it (and thus only copy the values)
            let ptr := mload(add(_arg, 0x20))

            // Base pointer for value - Base ptr + ptr pointing to value (first 32 bytes of the value)
            let baseptr := add(add(_arg, 0x20), ptr)

            // Base mstore ptr
            let basemstoreptr := add(newVal, 0x20)

            // Iterating over the variable, copying it's bytes to the new value - except the first 32 bytes (the mem pointer)
            for {
                let i := 0
            } lt(i, iters) {
                i := add(i, 1)
            } {
                // Current 32 bytes
                let currpart := mload(add(baseptr, mul(0x20, i)))

                // Paste them into the new value
                mstore(add(basemstoreptr, mul(0x20, i)), currpart)
            }
        }

        return newVal;
    }

    /**
     * @notice
     * @seperateYCVariable
     * takes in a bytes variable - can be static or FunctionCall... However, must have a flag on it (!!).
     * returns the plain variable without the flag and the flag, seperately
     */
    function seperateYCVariable(
        bytes memory _variable
    )
        public
        pure
        returns (
            bytes memory _plain_variable,
            uint8 _typeflag,
            uint8 _returnTypeFlag,
            uint8 _arrayIdentifierFlag
        )
    {
        // Getting the @Flag of the variable (appended to the end of each YC input)
        (_typeflag, _returnTypeFlag, _arrayIdentifierFlag) = getVarFlags(
            _variable
        );

        // Saving a version of the argument without the appended flag
        _plain_variable = removeVarFlags(_variable);
    }

    /**
     * @notice
     * Checks to see if a YC Variable is an iterative (i.e array)
     */
    function isIterative(
        bytes memory _ycVar
    ) internal pure returns (bool _isIterative) {
        return _ycVar[0] == 0x01;
    }

    /**
     * @notice
     * Get the flags of a YC variable
     * --- Type Flags: ---
     * 0x00 = Static Variable
     * 0x01 = Dynamic variable
     * 0x02 = Static CALL
     * 0x03 = Delegate CALL
     * 0x04 CALL
     * -------------------
     * 
     * --- Iterative Flags: ---
     * 0x00 = Non-Iterative (reguler)
     * 0x01 = Iterative (i.e an array)
     * ------------------------
     */
    function getVarFlags(
        bytes memory _ycVar
    )
        public
        pure
        returns (uint8 typeflag_, uint8 retTypeflag_, uint8 isIterativeFlag_)
    {
        // Flag specifying the type of the variable - FIXED, DYNAMIC, CALL, STATICCALL, DELEGATECALL
        typeflag_ = uint8(_ycVar[_ycVar.length - 1]);

        // Flag specifying the type of the return value - FIXED, DYNAMIC
        retTypeflag_ = uint8(_ycVar[_ycVar.length - 2]);

        // Flag specifying whether or not the variable is an iterative (array)
        isIterativeFlag_ = uint8(_ycVar[0]);
    }

    /**
     * @notice
     * @removeVarFlag
     * Takes in a full encoded YC Variable with flags,
     * returns the variable without the flags
     */
    function removeVarFlags(
        bytes memory _ycVar
    ) public pure returns (bytes memory _ret) {
        // Remove the typeflags & the array identifiers at the end of the byte
        _ret = removeTypeflags(removeArrayIdentifierFlags(_ycVar));
    }

    /**
     * @notice
     * Takes in an encoded YC variable, removes it's typeflags from the end
     * @param _ycVar the encoded YC variable
     * @return The encoded variable without the 1byte-long typeflags at the end
     */
    function removeTypeflags(
        bytes memory _ycVar
    ) internal pure returns (bytes memory) {
        // Initiate new byte of the length of the variable - 1 (to account for the byte we are deleting)
        bytes memory _ycVarNoTypeflags = new bytes(_ycVar.length - 1);

        // Iterate over the bytes, append them in the new byte - should push all but the last byte
        for (uint256 i = 0; i < _ycVarNoTypeflags.length; i++) {
            _ycVarNoTypeflags[i] = _ycVar[i];
        }

        // Finally, return the new byte
        return _ycVarNoTypeflags;
    }

    /**
     * @notice
     * Removes the array identifiers from a YC Variable
     * @param _ycVar - The encoded YC variable with the array flag on it already
     * @return YC Variable without the array flags
     */
    function removeArrayIdentifierFlags(
        bytes memory _ycVar
    ) internal pure returns (bytes memory) {
        // Initiate new byte of the length of the variable - 1 (to account for the byte we are deleting)
        bytes memory _ycVarNoTypeflags = new bytes(_ycVar.length - 1);

        // Iterate over the bytes, append them in the new byte - should push all but the last byte
        for (uint256 i = 1; i < _ycVarNoTypeflags.length; i++) {
            _ycVarNoTypeflags[i] = _ycVar[i];
        }

        // Finally, return the new variable
        return _ycVarNoTypeflags;
    }
}
