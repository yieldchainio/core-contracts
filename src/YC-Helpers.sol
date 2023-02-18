// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
 * @notice
 * Base YC Contract, inherited by every core (or, utility) Yieldchain contract.
 */
abstract contract IYieldchainBase {
    //////////////////////////////////////////////////
    ////////////////// STRUCTS //////////////////////
    //////////////////////////////////////////////////

    /**
     * @notice
     * @FunctionCall
     * A struct that defines a function call. Is used as a standard to pass on steps' functions, or
     * functions to be used to retreive some return value, as some sort of a dynamic variable that can be
     * pre-encoded & standardized.
     *
     *
     * ----- // @PARAMETERS // -----
     * @param target_address
     * @address -  The target address the function should be called on.
     *
     * @param args
     * @bytes[] - The arguments for the function call, encoded. Should be wrapped inside getArgValue()
     *
     * @param signature
     * @string - The function sig. Can be either external (When function is a dynamic variable),
     * or a YC Classified function (e.g "func_30(bytes[])")
     *
     * @param is_callback
     * @bool - Specifies whether the function is a callback. Callback means it submits an off-chain request, which
     * should stop the current execution context - Which, in turn, may have itself/another process resumed by the request's
     * fullfill operation.
     *
     * @param is_static
     * @bool - Specifies whether the function can be called with staticcall. If true, can save significant (9000) gas.
     *
     * @param is_condition
     * @bool - Specifies whether the function is actually a condition. Get's executed differently (checked for boolean result,
     * executes functions from next container based on it)
     * -----------------------------
     */
    struct FunctionCall {
        // @address
        //
        address target_address;
        bytes[] args;
        string signature;
        bool is_callback;
        // @bool - Specifies whether the function can be called with staticcall. If true, can save significant (9000) gas.
        bool is_static;
        bool is_condition; // Function acts differently if it is a condition (Checks condition...)
    }

    /**
     * @notice
     * @YCStep
     * A struct defining a Yieldchain strategy step. Is used to standardized a classification of each one of a strategy's
     * steps. Defining it's function call, as well as it's underlying protocol's details, and it's tokens flows.
     * While this will be used in the strategy's logic (The function calls), it can also be consumed by frontends
     * (which have access to our ABI).
     * ----- // @PARAMETERS // -----
     * @param step_function
     * @FunctonCall
     * The function to call on this step.
     *
     * @param protocol_details
     * @ProtocolDetails
     * The details of the protocol the function reaches. Consumed by frontends.
     *
     * @param token_flows
     * @TokenFlow[]
     * An array of TokenFlow structs, consumed by frontends.
     * -----------------------------
     */
    struct YCStep {
        FunctionCall step_function;
        bytes protocol_details;
        bytes token_flows;
    }

    // TODO: Non-critical. Define protoocl details & token flow structs

    /**
     * @notice
     * A 2D Array containing "Containers" Of Yieldchain Steps.
     * Each strategy has it's own set of steps, this is the actual strategy logic, encoded as bytes per step.
     */
    bytes[][] step_containers;
}

/**
 * @notice Contains various utility/generic methods that will be used, inherited / delegated to throughout Yieldchain's
 * contracts set.
 */
contract YC_Utilities {
    /**
     * @notice
     * @Method getCalldata
     * dynamic, generic encoding of calldata.
     * ----- // PARAMETERS // -----
     * @param _function_signature - @string, The function signature to encode (e.g, "addLiquidity(address,address,uint256,uint256)"
     *
     * @param _arguments - bytes[] - An array of arguments (as bytes) that will be appended to the calldata when concatanating it.
     * -----------------------------
     *
     * @return _calldata - bytes - The encoded calldata, should be used directly in a low-level call
     */
    // ------------------------------------------
    function getCalldata(
        string memory _function_signature,
        bytes[] memory _arguments
    ) external pure returns (bytes memory _calldata) {
        // Encoding the function signature
        _calldata = abi.encodeWithSignature(_function_signature);

        // For each one of the arguments
        for (uint256 i = 0; i < _arguments.length; i++) {
            // Concat the existing calldata with the argument
            _calldata = bytes.concat(_calldata, _arguments[i]);
        }
        // Return the new calldata
        return _calldata;
    }
    // --------------------------------------------


    
}
