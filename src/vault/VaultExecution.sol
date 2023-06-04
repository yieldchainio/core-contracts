/**
 * The execution functions for the vault (Internal/Used by YC Diamond)
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// ===============
//    IMPORTS
// ===============
import {SafeERC20} from "../libs/SafeERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import "../vm/VM.sol";
import "./OperationsQueue.sol";
import "./State.sol";
import "./Constants.sol";
import "./VaultUtilities.sol";
import "../diamond/interfaces/IAccessControl.sol";

abstract contract VaultExecution is
    YCVM,
    OperationsQueue,
    VaultUtilities,
    VaultConstants,
    VaultState
{
    // ============================
    //          ERRORS
    // ============================
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    // Libs
    using SafeERC20 for IERC20;

    // ============================
    //       EXTERNAL METHODS
    // ============================

    /**
     * Called by the client after simulating some offchain action lookup mid run
     * @param offchainResponse - The response received from the offchain actions gateway
     * @param actionContext - The CCIP "extraData" encoded by the run. Specifies the action type,
     * and an amount if needed.
     *
     * Responsible for re-executing whatever action was originally intended, whilst being CCIP compatible.
     * Sort of a router.
     */
    function offchainActionCallback(
        bytes memory offchainResponse,
        bytes memory actionContext
    ) external {
        (ExecutionTypes executionType, uint256 amount) = abi.decode(
            actionContext,
            (ExecutionTypes, uint256)
        );

        if (executionType == ExecutionTypes.SEED) {}
    }

    // ============================
    //       INTERNAL METHODS
    // ============================

    /**
     * @notice
     * executeDeposit()
     * The actual deposit execution handler,
     * @dev Should be called once hydrated with the operation offchain computed data
     * @param depositItem - OperationItem from the operations queue, representing the deposit request
     */
    function executeDeposit(
        OperationItem memory depositItem,
        uint256[] memory startingIndices
    ) internal {
        uint256 amount = abi.decode(depositItem.arguments[0], (uint256));

        assembly {
            // We MSTORE at the deposit amount memory location the deposit amount
            // (may be accessed by commands to determine amount arguments)
            mstore(DEPOSIT_AMT_MEM_LOCATION, amount)
        }

        /**
         * @notice  We execute the seed steps, starting from the root step
         */
        executeStepTree(SEED_STEPS, startingIndices, depositItem);
    }

    /**
     * @notice
     * handleWithdraw()
     * The actual withdraw execution handler
     * @param withdrawItem - OperationItem from the operations queue, representing the withdrawal request
     */
    function executeWithdraw(
        OperationItem memory withdrawItem,
        uint256[] memory startingIndices
    ) internal {
        uint256 amount = abi.decode(withdrawItem.arguments[0], (uint256));

        uint256 shareOfVaultInPercentage = (totalShares + amount) / amount;

        assembly {
            // We MSTORE at the withdraw share memory location the % share of the withdraw amount of the total vault, times 100
            // (e.g, 100 shares to withdraw, 1000 total shares = 1000 / 100 * 100(%) = 1000 (10% multipled by 100, for safe maths...))
            mstore(
                WITHDRAW_SHARES_MEM_LOCATION,
                mul(shareOfVaultInPercentage, 100)
            )
        }

        /**
         * @notice We keep track of what the deposit token balance was prior to the execution
         */
        uint256 preVaultBalance = DEPOSIT_TOKEN.balanceOf(address(this));

        executeStepTree(UPROOTING_STEPS, startingIndices, withdrawItem);

        uint256 debt = DEPOSIT_TOKEN.balanceOf(address(this)) - preVaultBalance;

        DEPOSIT_TOKEN.safeTransfer(withdrawItem.initiator, debt);
    }

    // ==============================
    //        STEPS EXECUTION
    // ==============================
    /**
     * @notice
     * executeStepTree()
     * Accepts a linked-list (array) of YCStep, and a starting index to begin executing.
     * Note this function is recursive - It executes a step, then all of it's children, then all of their children, etc.
     *
     * @param virtualTree - A linked list array of YCSteps to execute
     * @param startingIndices - An array of indicies of the steps to begin executing the tree from
     */
    function executeStepTree(
        bytes[] memory virtualTree,
        bytes[] memory offchainComputedCommands,
        uint256[] memory startingIndices,
        bytes4 callbackFunction,
        bytes memory actionContext
    ) internal {
        /**
         * Iterate over each one of the starting indices
         */
        for (uint256 i = 0; i < startingIndices.length; i++) {
            uint256 stepIndex = startingIndices[i];

            YCStep memory step = abi.decode(virtualTree[stepIndex], (YCStep));

            /**
             * We first check to see if this step is a callback step.
             */
            if (step.isCallback) {
                // If already got the command, run it
                if (
                    offchainComputedCommands.length > stepIndex &&
                    bytes32(offchainComputedCommands[stepIndex]) != bytes32(0)
                )
                    _runFunction(offchainComputedCommands[stepIndex]);

                    // Revert with OffchainLookup, CCIP read will fetch from corresponding Offchain Action.
                else {
                    (bytes memory nakedFunc, , ) = _separateCommand(step.func);

                    FunctionCall memory originalCall = abi.decode(
                        nakedFunc,
                        (FunctionCall)
                    );

                    bytes
                        memory interpretedArgs = interpretCommandsAndEncodeChunck(
                            originalCall.args
                        );

                    string memory offchainActionsUrl = IAccessControlFacet(
                        address(YC_DIAMOND)
                    ).getOffchainActionsUrl();
                    string[] memory urls = new string[](1);
                    urls[0] = offchainActionsUrl;

                    OffchainActionRequest
                        memory offchainRequest = OffchainActionRequest(
                            stepIndex,
                            address(this),
                            offchainComputedCommands,
                            originalCall.target_address,
                            originalCall.signature,
                            interpretedArgs
                        );

                    revert OffchainLookup(
                        address(this),
                        urls,
                        abi.encode(offchainRequest),
                        callbackFunction,
                        actionContext
                    );
                }
            }
            /**
             * If the step is not a callback (And also not empty), we execute the step's function
             */
            else if (bytes32(step.func) != bytes32(0)) _runFunction(step.func);

            uint256[] memory childrenStartingIndices = step.childrenIndices;

            executeStepTree(
                virtualTree,
                offchainComputedCommands,
                childrenStartingIndices,
                callbackFunction,
                actionContext
            );
        }
    }
}
