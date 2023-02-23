// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../YC-Types.sol";

interface YieldchainStrategyTypes is YieldchainTypes {
    //===============================================//
    //                   ENUMS                       //
    //===============================================//

    enum FlowDirection {
        INFLOW,
        OUTFLOW
    }

    //===============================================//
    //                   STRUCTS                     //
    //===============================================//

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
        bytes step_function;
        ProtocolDetails protocol_details;
        Flow[] token_flows;
        uint256[] children_indexes;
        bytes[] conditions;
    }

    struct ProtocolDetails {
        string name;
        string website;
        string logo_uri;
        string color;
        uint256 id;
    }

    struct Token {
        string symbol;
        string name;
        string logo_uri;
        uint256 id;
    }

    struct Flow {
        Token token_details;
        FlowDirection direction;
    }
}
