// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
 * @notice
 * Base YC Contract, inherited by every core (or, utility) Yieldchain contract.
 */
contract IYieldchainBase {
    //===============================================//
    //                   ENUMS                       //
    //===============================================//

    enum CallTypes {
        CALL,
        DELEGATECALL,
        STATICCALL
    }

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
        CallTypes call_type;
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
     *
     * @param children_index
     * @uint256
     * A uint representing the index within the strategy's containers array of the step's children container.
     * Since nesting structs poses some issues.
     * -----------------------------
     */
    struct YCStep {
        FunctionCall step_function;
        bytes protocol_details;
        bytes token_flows;
        uint256[] children_indexes;
        bool is_conditional;
        bytes[] conditions;
    }

    // TODO: Non-critical. Define protoocl details & token flow structs
}
