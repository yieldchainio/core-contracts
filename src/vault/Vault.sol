// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// ===============
//    IMPORTS
// ===============
import {SafeERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./AccessControl.sol";
import "./OperationsQueue.sol";
import "./Schema.sol";
import "../vm/VM.sol";
import "./VaultUtilities.sol";

/**
 * The part of the vault contract containing various
 * state (storage) variables and immutables.
 *
 * This is the root contract being inherited
 */

contract Vault is YCVM, OperationsQueue, AccessControl, VaultUtilities {
    // LIBS
    using SafeERC20 for IERC20;

    // =====================
    //      CONSTRUCTOR
    // =====================
    /**
     * @notice
     * The constructor,
     * accepts all of the different configs for this strategy contract
     * @param steps - A linked list of YCStep. a YCStep specifies the encoded FunctionCall of a step,
     * the indexes of it's children within the array, and an optional array of "conditions".
     * In which case it means the step is a conditional block.
     * @param seedSteps - A linked list of YCStep like the above, this time,
     * for the seed strategy (i.e, the strategy that runs on deposit)
     * @param uprootSteps - Another linked list of YCStep,
     * but for the "Uprooting" strategy (the reverse version of the strategy)
     * @param approvalPairs - A 2D array of addresses -
     * at index 0 there is an ERC20-compatible token contract address, and at index 1 there is a
     * contract address to approve. This is in order to iterate over and pre-approve all addresses required.
     * @param depositToken - The token of this vault that users deposit into here, as an address
     *
     * @param ispublic - Whether the vault is publicly accessible or not
     */
    constructor(
        bytes[] memory steps,
        bytes[] memory seedSteps,
        bytes[] memory uprootSteps,
        address[][] memory approvalPairs,
        IERC20 depositToken,
        bool ispublic,
        address creator
    ) AccessControl(creator, msg.sender) {
        /**
         * @dev We set the immutable set of steps, seed steps, and uproot steps
         */
        STEPS = steps;
        SEED_STEPS = seedSteps;
        UPROOTING_STEPS = uprootSteps;

        /**
         * @dev We set the depositToken immutable variable
         */
        DEPOSIT_TOKEN = depositToken;

        /**
         * @dev
         * We set the vault's initial privacy
         */
        isPublic = ispublic;

        /**
         * @dev We set the initial admin & mod (The creator)
         */

        /**
         * @dev We iterate over each approval pair and approve them as needed.
         */
        for (uint256 i = 0; i < approvalPairs.length; i++) {
            IERC20(approvalPairs[i][0]).approve(
                approvalPairs[i][1],
                type(uint256).max
            );
        }

        /**
         * @dev We also add mods and admin permission to the creator
         */
        admins[creator] = true;
        mods[creator] = true;
        whitelistedUsers[creator] = true;
    }

    // =====================
    //      IMMUTABLES
    // =====================

    /**
     * @dev The deposit token of the vault
     */
    IERC20 immutable DEPOSIT_TOKEN;

    /**
     * @notice
     * @dev
     * A linked list containing the tree of (encoded) steps to execute on the main triggers
     */
    bytes[] internal STEPS;

    /**
     * @dev Just as the above -
     * A linked list of encoded steps, but for the seed strategy (runs on deposit, i.e initial allocations)
     */
    bytes[] internal SEED_STEPS;

    /**
     * @dev Another linked list of steps,
     * but for the "uprooting" strategy (A "reverse" version of the strategy, executed on withdrawals)
     */
    bytes[] internal UPROOTING_STEPS;

    // ==============================
    //           STORAGE
    // ==============================
    /**
     * @notice
     * The total amount of shares of this vault, directly correlated with deposit tokens
     * 1 token deposited += totalShares(1)
     * 1 token withdrawan -= totalShares(1)
     */
    uint256 public totalShares;

    /**
     * @notice
     * Mapping user addresses to their corresponding balances of vault shares
     */
    mapping(address => uint256) public balances;

    // ==============================
    //     VAULT CONFIG METHODS
    // ==============================

    /**
     * routeQueueOperation
     * Dequeues an item from the queue and handles it,
     * depending on the requested operation.
     * Does not take any arguments, just has to be initiated.
     */
    function routeQueueOperation() public override {
        // Require the lock state to be unlocked. Otherwise this will be required to be called whne it's unlocked later
        require(!locked, "Lock Is On");
        /**
         * We dequeue & retreive the current operation to handle
         */
        QueueItem memory operation = dequeueOp();

        /**
         * Switch statement for the operation to run
         */
        if (operation.action == ActionTypes.DEPOSIT)
            return handleDeposit(operation);

        if (operation.action == ActionTypes.WITHDRAW)
            return handleWithdraw(operation);

        if (operation.action == ActionTypes.STRATEGY_RUN) {
            uint256[] memory startingIndices = new uint256[](1);
            startingIndices[0] = 0;
            return
                executeStepTree(
                    STEPS,
                    startingIndices,
                    new bytes(0),
                    ActionTypes.STRATEGY_RUN
                );
        }

        revert();
    }

    // ==============================
    //      VAULT OPS METHODS
    // ==============================

    /**
     * @notice
     * Request A Deposit Into The Vault
     * @param amount - The amount of the deposit token to deposit
     */
    function deposit(uint256 amount) external onlyWhitelistedOrPublicVault {
        /**
         * We assert that the user must have given us appropriate allowance.
         * This will be checked offchain as well of course and on the deposit fullfil call,
         * but is done in order to ensure easy spamming
         */
        if (DEPOSIT_TOKEN.allowance(msg.sender, address(this)) >= amount)
            revert InsufficientAllowance();

        /**
         * @notice
         * We do not transfer the user's funds right away and begin the operation - But enqueue the request
         * in order to avoid clashes with other operations, which may not be completed in a single transaction.
         */

        // We create an args array which includes our amount - Deposit processor will look for this
        bytes[] memory depositArgs = new bytes[](1);
        depositArgs[0] = abi.encode(amount);

        // Create the queue item
        QueueItem memory depositRequest = QueueItem(
            ActionTypes.DEPOSIT,
            msg.sender,
            depositArgs
        );

        // Enqueue it, potentially beggining the operation
        enqueueOp(depositRequest);
    }

    /**
     * @notice
     * Request to withdraw out of the vault
     * @param amount - the amount of shares to withdraw
     */
    function withdraw(uint256 amount) external onlyWhitelistedOrPublicVault {
        /**
         * We assert the user's shares are sufficient
         * Note this is re-checked when handling the actual withdrawal
         */
        if (balances[msg.sender] > amount) revert InsufficientShares();

        /**
         * We create a QueueItem for our withdrawal and enqueue it, which should either begin executing it,
         * or begin waiting for it's turn
         */
        bytes[] memory withdrawArgs = new bytes[](1);
        withdrawArgs[0] = abi.encode(amount);

        // Create the queue item
        QueueItem memory withdrawRequest = QueueItem(
            ActionTypes.WITHDRAW,
            msg.sender,
            withdrawArgs
        );

        // Enqueue it, potentially beggining the operation
        enqueueOp(withdrawRequest);
    }

    /**
     * @notice
     * handleDeposit()
     * The actual deposit execution handler
     * @param depositItem - QueueItem from the operations queue, representing the deposit request
     */
    function handleDeposit(QueueItem memory depositItem) internal {
        /**
         * @notice Lock the execution of other operations in the meantime
         */
        locked = true;

        /**
         * Decode the first byte argument as an amount
         */
        uint256 amount = abi.decode(depositItem.arguments[0], (uint256));

        /**
         * We require the allowance of the user to be sufficient
         */
        if (DEPOSIT_TOKEN.allowance(msg.sender, address(this)) >= amount)
            revert InsufficientAllowance();

        /**
         * We do a safeTransferFrom to get the user's tokens
         */
        DEPOSIT_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        /**
         * @notice  We begin executing the seed steps
         */
        // Starting indices would be just the root step
        uint256[] memory startingIndices = new uint256[](1);
        startingIndices[0] = 0;
        executeStepTree(
            SEED_STEPS,
            startingIndices,
            new bytes(0),
            ActionTypes.DEPOSIT
        );
    }

    /**
     * @notice
     * handleWithdraw()
     * The actual withdraw execution handler
     * @param withdrawItem - QueueItem from the operations queue, representing the withdrawal request
     */
    function handleWithdraw(QueueItem memory withdrawItem) internal {
        /**
         * Decode the first byte argument as an amount
         */
        uint256 amount = abi.decode(withdrawItem.arguments[0], (uint256));

        /**
         * We require the shares of the user to be sufficient
         */
        if (balances[msg.sender] > amount) revert InsufficientShares();

        /**
         * @notice Lock the execution of other operations in the meantime
         */
        locked = true;

        /**
         * @notice We keep track of what the deposit token balance was prior to the execution
         */
        uint256 preVaultBalance = DEPOSIT_TOKEN.balanceOf(address(this));

        /**
         * @notice  We begin executing the uproot (reverse) steps
         */
        // Starting indices would be just the root step
        // TODO: New approach for reverse strategies?
        uint256[] memory startingIndices = new uint256[](1);
        startingIndices[0] = 0;
        executeStepTree(
            UPROOTING_STEPS,
            startingIndices,
            new bytes(0),
            ActionTypes.DEPOSIT
        );

        /**
         * After executing all of the steps, we get the balance difference,
         * and transfer to the user.
         * We use safeERC20, so if the debt is 0, the execution reverts
         */
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
     * @param fullfillCommand - An optional fullfilling YC command. If a step is a callback, and this is an empty byte -
     * we emit an event requesting the offchain fullfill, which should in turn re-enter this function with the fullfillment.
     * @param context - An ActionTypes enum representing the context to emit in RequestFullfill events (i.e, when executing seed strategy,
     * it would be "DEPOSIT", so that the offchain knows which steps to reenter with)
     */
    function executeStepTree(
        bytes[] memory virtualTree,
        uint256[] memory startingIndices,
        bytes memory fullfillCommand,
        ActionTypes context
    ) public onlyDiamond {
        /**
         * Iterate over each one of the starting indices
         */
        for (uint256 i = 0; i < startingIndices.length; i++) {
            /**
             * Load the current virtualTree step index
             */
            uint256 stepIndex = startingIndices[i];

            /**
             * Begin by retreiving & decoding the current YC step from the virtual tree
             */
            YCStep memory step = abi.decode(virtualTree[stepIndex], (YCStep));

            /**
             * @notice Initiating a variable for the "chosenOffspringIdx", which is ONLY RELEVENT
             * for conditional steps.
             *
             * When a conditional step runs, it will reassign to this variable either:
             * - An index of one of it's children
             * - 0
             * If it's an index of one of it's children, it means that it found a case where
             * one of it's children conditions returned true, and we should only execute it (rather than all of it's children indexes).
             * Otherwise, if the index is 0, it means it did not find any, and we should not execute any of it's children.
             * (It is impossible for a condition index to be 0, since it will always be the root)
             */
            uint256 chosenOffspringIdx;

            /**
             * Check to see if current step is a condition - Execute the conditional function with it's children if it is.
             */
            if (step.conditions.length > 0) {
                // Sufficient check to make sure there are as many conditions as there are children
                require(
                    step.conditions.length == step.children_indexes.length,
                    "Conditions & Children Mismatch"
                );

                // Assign to the chosenOffspringIdx variable the return value from the conditional checker
                chosenOffspringIdx = _determineConditions(step.conditions);
            }

            /**
             * We first check to see if this step is a callback step.
             */
            if (step.isCallback) {
                /**
                 * If we got a fullfill function, we execute it - It means that this is a reenterence from the offchain
                 * after the external computation was completed, with the final YC command.
                 * Note that in this case we stop the execution of the step here, as we do not want to execute it's
                 * children any further. This will be handled by the offchain when re-entering.
                 */
                if (bytes32(fullfillCommand) != bytes32(0)) {
                    _runFunction(fullfillCommand);
                    return;
                }
                /**
                 * Otherwise, it means this is the first touch of the function, and we should emit the appropriate event to request
                 * the offchain processing of it
                 *
                 * @notice The standard for offchain action requests is the following:
                 * - The signature of the function is the string of the action name
                 * - The arguments of the FunctionCall are the data we pass to the event
                 * We decode the step's function call manually and emit an event using the DecodeAndRequestFullfill() function
                 */
                else _decodeAndRequestFullfill(step.func, context, stepIndex);
            }

            /**
             * If the step is not a callback, we execute the step's function
             */
            _runFunction(step.func);

            /**
             * @notice
             * At this point, we move onto executing the step's children.
             * If the chosenOffSpringIdx variable does not equal to 0, we execute the children idx at that index
             * of the array of indexes of the step. So if the index 2 was returnd, we execute virtualTree[step.childrenIndices[2]].
             * Otherwise, we do a full iteration over all children
             */

            // We initiatre this array to a length of 1. If we should execute all children, this is reassigned to.
            uint256[] memory childrenStartingIndices = new uint256[](1);

            // If offspring idx is valid, we assign to index 0 it's index
            if (chosenOffspringIdx > 0)
                childrenStartingIndices[0] = step.children_indexes[
                    // Note we -1 here, since the chosenOffspringIdx would have upped it up by 1 (to retain 0 as the falsy indicator)
                    chosenOffspringIdx - 1
                ];

                // Else it equals to all of the step's children
            else childrenStartingIndices = step.children_indexes;

            /**
             * We now iterate over each children and @recruse the function call
             * Note that the executeStepTree() function accepts an array of steps to execute.
             * You may would have expected us to do an iteration over each child, but in order to be complied with
             * the fact that, an execution tree may emit multiple offchain requests in a single transaction - We accept an array
             * of starting indices, rather than a single starting index. (Offchain actions will be batched per transaction and executed together here,
             * rather than per-event).
             */
            executeStepTree(
                virtualTree,
                childrenStartingIndices,
                new bytes(0),
                context
            );
        }
    }
}
