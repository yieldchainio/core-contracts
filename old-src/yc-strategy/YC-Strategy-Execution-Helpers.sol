// SPDX-License-Identifier: SPDX
pragma solidity ^0.8.18;
import "./YC-Strategy-Vault-Operations.sol";
import "./YC-Strategy-Types.sol";

contract YieldchainStrategyExecHelpers is
    YieldchainStrategyVaultOps,
    YieldchainTypes
{
    // =============================================================
    //                 CONSTRUCTOR SUPER
    // =============================================================
    constructor(
        bytes[] memory _steps,
        bytes[] memory _base_strategy_steps,
        address[] memory _base_tokens,
        address[] memory _strategy_tokens,
        address[][] memory _tokens_related_addresses,
        uint256 _automation_interval,
        address _deployer
    )
        YieldchainStrategyVaultOps(
            _steps,
            _base_strategy_steps,
            _base_tokens,
            _strategy_tokens,
            _tokens_related_addresses,
            _automation_interval,
            _deployer
        )
    {}

    /**
     * @notice
     * requestFullfill
     * Called by offchain executors (through YC Diamond) when fullfilling a non-step-related action request fullfillment
     */
    function fullfillRequest(bytes memory _functionCall) external isYieldchain {
        // Just passing onto internal function
        _runFunction(_functionCall);
    }

    /**
     * @notice
     * _runFunction
     * Called by the strategy contract, takes in an encoded YC function (raw, with the flags embedded)
     * @param _encodedFunctionCall - The encoded FunctionCall struct, with the flags embedded
     * @return _ret - The return value of the the function call
     * @return _calledFunc - The parsed called function, decoded
     */
    function _runFunction(
        bytes memory _encodedFunctionCall
    ) internal returns (bytes memory _ret, FunctionCall memory _calledFunc) {
        // Initiallizing
        uint8 typeflag;

        // TODO: Add some r,s,v signature in here to retain pureness of function verification?
        // Preparing the function call.
        (_calledFunc, typeflag) = YC_DIAMOND.prepareFunctionCall(
            _encodedFunctionCall
        );

        // Execute the function
        _ret = _execFunctionCall(_calledFunc, typeflag);
    }

    /**
     * @notice
     * _execFunctionCall
     * Used internally by the high-level _runFunction function, takes in a decoded YC FunctionCall struct and a typeflag.
     * Builds the callData using the _buildCalldata function, sends a low-level call depending on the type flag using the calldata.
     * Returns the return data of the function call
     * @param _func - A decoded FunctionCall struct
     * @param _typeflag - The typeflag to call with (i.e CALL, DELEGATECALL, STATICCALL)
     * @return ret_ - The return value of the function call
     */
    // TODO: Enter the future r,s,v as args here
    function _execFunctionCall(
        FunctionCall memory _func,
        uint8 _typeflag
    ) internal returns (bytes memory ret_) {
        // Get the calldata
        bytes memory callData = _buildCalldata(_func);

        // Switch-Case for the call type based on the flag
        if (_typeflag == 0x02)
            (, ret_) = _func.target_address.staticcall(callData);
        else if (_typeflag == 0x03)
            (, ret_) = _func.target_address.delegatecall(callData);
        else if (_typeflag == 0x04)
            (, ret_) = _func.target_address.call(callData);
        else revert InvalidCallFlag();
    }

    /**
     * @notice
     * Takes in a FunctionCall struct, maps the arguments using ``getArgValue``,
     * builds the calldata for the function call.
     * Responsible for parsing various different types of variables
     * @param _func FunctionCall struct with a verified signature
     */
    function _buildCalldata(
        FunctionCall memory _func
    ) internal returns (bytes memory _calldata) {
        // Encoding the function signature
        _calldata = abi.encode(_func.signature);

        /**
         * @notice
         * Keeping track of dynamic variables, to be inserted at the end after inserting all the fixed-length variables
         */
        bytes[] memory dynamicVars;
        uint256[] memory dynamicVarsIndexes;

        // Mapping the arguments
        for (uint256 i = 0; i < _func.args.length; i++) {
            // Get arg's variable value

            (bytes memory argval, uint8 typeflag) = _getArgValue(_func.args[i]);

            // Concat the existing calldata with the argument
            require(
                typeflag < 0x02,
                "Flag Must Be A Static/Dynamic When Encoding Calldata"
            );

            // If it's static, just concat it
            if (typeflag == 0x00)
                _calldata = bytes.concat(_calldata, argval);

                // Else - parse it's value, keep track of the length, and the index of it
            else {
                // Save the index - will use it later on to append the new pointer
                dynamicVarsIndexes[dynamicVarsIndexes.length - 1] = _calldata
                    .length;

                // Append an empty 32 byte placeholder
                _calldata = bytes.concat(_calldata, new bytes(32));

                // Push the variable's value to the array of dynamic variables
                dynamicVars[dynamicVars.length - 1] = parseDynamicVar(argval);
            }
        }

        // Sufficient check
        require(
            dynamicVars.length == dynamicVarsIndexes.length,
            "Dynamic vars arr length does not match corresponding indexes arr length!"
        );

        // @notice
        // Iterate over the saved dynamic variables,
        // Append them to the end of our calldata, whilst updating the pointer at their corresponding index
        for (uint256 i = 0; i < dynamicVars.length; i++) {
            uint256 index = dynamicVarsIndexes[i];

            // Iterating over the calldata, appending the new pointer at the specified index
            assembly {
                // Loading the new pointer
                let newptr := mload(_calldata)
                // Doing 32 iterations (size of our placeholder pointer) and inserting the new bytes of the new ptr

                // Shorthand
                let baseindex := add(add(_calldata, 0x20), mload(index))

                for {
                    let j := 0
                } lt(j, 32) {
                    j := add(i, 1)
                } {
                    mstore(add(baseindex, j), newptr)
                }
            }

            // Append the variable value (The pointer is now pointing to it e.g to what was up until this point the calldata's length)
            _calldata = bytes.concat(_calldata, dynamicVars[i]);
        }
        // Return the new calldata
        return _calldata;
    }

    /**
     * A recrusive function that accepts a byte argument, attempts to decode it using
     * YC's "Function" struct - if fails, returns the byte as-is. If it goes through, it
     * makes the desired function call, whilst recrusing the same process for each one of the function's
     * arguments.
     * @param _arg A YC Encoded variable - can be either plain (A static variable), or any kind of FunctionCall type.
     * @return returnArg_ The result - the actual value of that argument. If static, would just be the argument without
     * the flags (i.e plain). If it's a FunctionCall, it would be the return data of that function call
     * @return typeflag_ - The typeflag of the (potential) return value.
     */
    function _getArgValue(
        bytes memory _arg
    ) internal returns (bytes memory returnArg_, uint8 typeflag_) {
        // Seperating the argument & the flag
        bytes memory plainArg;

        // Shorthand for the return type flag - may not be used if the variable is not a function call
        uint8 retTypeFlag;
        // Seperating the argument from it's typeflags
        (plainArg, typeflag_, retTypeFlag) = seperateYCVariable(_arg);

        // If the flag is 0, it means it is static so we return the plain arg as-is
        if (typeflag_ == 0x00) returnArg_ = plainArg;

        // If the flag is 1, it means it is a dynamic-length variable. We parse and return it
        if (typeflag_ == 0x01) returnArg_ = parseDynamicVar(plainArg);

        // @notice
        // If the flag is not 0, 1 (i.e its either 1, 2, 3 - the CALL types), we call prepareFunctionCall.
        // the function will in turn decode the function as needed, recruse back to us for each
        // one of it's arguments, and at the end return the calldata

        // Getting the FunctionCall struct (Since the arg is not static)

        // Execute the function call.
        (returnArg_, ) = _runFunction(_arg);

        // Typeflag now equals to the return value's type flag (Since this will be now used as the argument)
        typeflag_ = retTypeFlag;

        // If the return type flag is equal to the dynamic-length variable flag we parse it before returning it
        if (retTypeFlag == 0x01) returnArg_ = parseDynamicVar(returnArg_);
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
            uint8 _returnTypeFlag
        )
    {
        // Getting the @Flag of the variable (appended to the end of each YC input)
        (_typeflag, _returnTypeFlag) = getVarFlags(_variable);

        // Saving a version of the argument without the appended flag
        _plain_variable = removeVarFlag(_variable);

        // TODO: update this
        _returnTypeFlag = _typeflag;
    }

    /**
     * @notice
     * Get the flag of a YC variable
     * 0x00 = Static Variable
     * 0x01 = Dynamic variable
     * 0x02 = Static CALL
     * 0x03 = Delegate CALL
     * 0x04 CALL
     */
    function getVarFlags(
        bytes memory _var
    ) public pure returns (uint8 typeflag_, uint8 retTypeflag_) {
        assembly {
            let len := mload(_var)

            // Getting typeflag
            typeflag_ := mload(add(add(_var, 0x20), sub(len, 1)))

            // Getting retTypeFlag
            retTypeflag_ := mload(add(add(_var, 0x20), sub(len, 2)))
        }
    }

    /**
     * @notice
     * @removeVarFlag
     * Takes in a full encoded YC Variable with flag,
     * returns the variable without the flag
     */
    function removeVarFlag(
        bytes memory _var
    ) public pure returns (bytes memory _ret) {
        _ret = new bytes(_var.length - 2);
        assembly {
            let baseptr := add(_var, 0x20)
            let retptr := add(_ret, 0x20)
            for {
                let i := 0
            } lt(i, sub(mload(_var), 2)) {
                i := add(i, 1)
            } {
                mstore(add(retptr, i), mload(add(baseptr, i)))
            }
        }
    }
}
