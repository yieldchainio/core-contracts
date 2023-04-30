// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface YieldchainTypes {
    //===============================================//
    //                   STRUCTS                     //
    //===============================================//
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
        address target_address;
        bytes[] args;
        string signature;
        bool is_callback;
    }
}
