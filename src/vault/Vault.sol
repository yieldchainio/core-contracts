// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// ===============
//    IMPORTS
// ===============
import "../vm/VM.sol";
import {SafeERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * The part of the vault contract containing various
 * state (storage) variables and immutables.
 *
 * This is the root contract being inherited
 */

contract State is YCVM {
    // LIBS
    using SafeERC20 for IERC20;

    // =====================
    //        ENUMS
    // =====================
    /**
     * ActionTypes
     * Represents the different type of vault actions that can be queued
     */
    enum ActionTypes {
        DEPOSIT,
        WITHDRAW,
        STRATEGY_RUN
    }

    // =====================
    //       STRUCTS
    // =====================
    /**
     * A struct representing a queue item.
     * Action requests (i.e strategy runs, deposits, withdrawals) are queued in order to avoid clashing,
     * and this struct represents one such request
     * @param action - An ActionType enum representing the action to complete, handled by a switch case in the router
     * @param initiator - The user address that initiated this queue request
     * @param arguments - An arbitrary array of bytes being the arguments, usually would be something like an amount.
     */
    struct QueueItem {
        ActionTypes action;
        address initiator;
        bytes[] arguments;
    }

    // =====================
    //        EVENTS
    // =====================
    /**
     * @notice
     * RequestFullfill event,
     * emitted in order to request an offchain fullfill of computations/actions.
     * @param context - A string showcasing the executor your context. I.e, when running the deposit strategy,
     * context would be "vault_deposit". So the executor will then know to fullfill requests to the array of seed
     * steps, instead of the tree steps
     * @param targetAction - The target "action" or function to execute - It tells the offchain what exactly to do.
     * This would usually be classified as a function in the database, e.g: "lifiswap", "openlong", etc.
     *
     * @param index - If executed within a strategy/seed strategy/whatever run, you would often need to emit the index
     * of the step as well, so that the offchain knows how to reenter the execution with the fullfilment.
     *
     * @param params - Any parameters you may want to pass to the offchain action to complete your execution
     */
    event RequestFullfill(
        ActionTypes indexed context,
        string indexed targetAction,
        uint256 indexed index,
        bytes[] params
    );

    /**
     * Deposit
     * Emitted when a deposit happens into the vault
     * @param sender - The user that deposited
     * @param amount - The amount that was deposited
     */
    event Deposit(address indexed sender, uint256 indexed amount);

    /**
     * Withdraw
     * Emitted when a withdrawal finallizes from the vault
     * @param receiver - The user who made the withdraw
     * @param amount - The amount that was withdrawn
     */
    event Withdraw(address indexed receiver, uint256 indexed amount);

    // =====================
    //        ERRORS
    // =====================
    /**
     * Insufficient allownace is thrown when a user attempts to complete an operation (deposit),
     * but has not approved this vault contract for enough tokens
     */
    error InsufficientAllowance();

    /**
     * Insufficient shares is thrown when a user attempts to withdraw an amount of tokens that they do not own.
     */
    error InsufficientShares();

    // =====================
    //      MODIFIERS
    // =====================
    /**
     * Requires the msg.sender to be the Yieldchain Diamond Contract.
     */
    modifier onlyDiamond() {
        require(msg.sender == YC_DIAMOND, "You Are Not Yieldchain Diamond");
        _;
    }

    /**
     * Requires the msg.sender to be the vault's creator
     */
    modifier onlyCreator() {
        require(msg.sender == CREATOR, "You Are Not Vault Creator");
        _;
    }

    /**
     * Requires the msg.sender to be a moderator of this vault
     */
    modifier onlyMods() {
        require(mods[msg.sender], "You Are Not A Mod");
        _;
    }
    /**
     * Requires the msg.sender to be an admin of this vault
     */
    modifier onlyAdmins() {
        require(admins[msg.sender], "You Are Not An Admin");
        _;
    }

    /**
     * Requires an inputted address to not be another moderator
     * @notice We do allow it if msg.sender is an administrator (higher role)
     */
    modifier peaceAmongstMods(address otherMod) {
        require(
            admins[msg.sender] || !mods[otherMod],
            "Mods Cannot Betray Mods"
        );
        _;
    }

    /**
     * Requires an inputted address to not be another adminstrator
     */
    modifier peaceAmongstAdmins(address otherAdmin) {
        require(
            admins[msg.sender] || !admins[otherAdmin],
            "Admins Cannot Betray Admins"
        );
        _;
    }

    /**
     * Requires the msg.sender to either be whitelisted, or the vault be public
     */
    modifier onlyWhitelistedOrPublicVault() {
        require(
            isPublic || whitelistedUsers[msg.sender],
            "You Are Not Whitelisted"
        );
        _;
    }

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
    ) {
        /**
         * @dev We set the Diamond address to the msg.sender (deployer of this)
         */
        YC_DIAMOND = msg.sender;

        /**
         * @dev We set the creator's address
         */
        CREATOR = creator;

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
    }

    // =====================
    //      IMMUTABLES
    // =====================
    /**
     * @dev The address of the Yieldchain diamond contract
     */
    address immutable YC_DIAMOND;

    /**
     * @dev The address of the creator of this strategy
     */
    address immutable CREATOR;

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

    /**
     * @dev
     * Tracking whether the strategy is private or not,
     * this is not immutable since we would allow to change it from the diamond (deploying) contract,
     * if permmited.
     */
    bool isPublic;

    /**
     * @dev
     * Keeping track of whitelisted users that are allowed to use this vault
     * @notice This is only relevent for private vaults - In public vaults, everyone is allowed in.
     */
    mapping(address => bool) public whitelistedUsers;

    /**
     * @dev
     * Keeping track of all of the admins of the vault,
     * that can whitelist/blacklist users from using it,
     * also only relevent for private vaults
     */
    mapping(address => bool) public mods;

    /**
     * @dev
     * Keeping track of all of the administrators of the vault,
     * Adminstrators have mods permissions but can also add/remove other mods,
     * also only relevent for private vaults
     */
    mapping(address => bool) public admins;

    /**
     * @dev An operation "lock" mechanism,
     * This is set to true when an operation (Strategy run, deposit, withdrawal, etc) begins, and false when it ends -
     * And prevents execution of fullfils in the offchain queue of other operations until this becomes false,
     */
    bool locked;

    // ==============================
    //     VAULT CONFIG METHODS
    // ==============================

    /**
     * @dev
     * changePrivacy()
     * Changes the privacy of this vault.
     * @notice ONLY callable by the Diamond. This is in order to enforce some rules logic, like:
     * 1) A public vault cannot be changed to private in most cases
     * 2) Vaults can only be private for premium users,
     * etc.
     *
     * The logic may change in the future
     *
     * @param shouldBePublic - true: Public, false: private.
     */
    function changePrivacy(bool shouldBePublic) external onlyDiamond {
        isPublic = shouldBePublic;
    }

    /**
     * @dev
     * Whitelist an address
     * @param userAddress - The address to whitelist
     */
    function whitelist(address userAddress) external onlyMods {
        whitelistedUsers[userAddress] = true;
    }

    /**
     * @dev
     * Blacklist an address
     * @param userAddress - The address to whitelist
     */
    function blacklist(
        address userAddress
    ) external onlyMods peaceAmongstMods(userAddress) {
        whitelistedUsers[userAddress] = false;
    }

    /**
     * @dev
     * Add a moderator
     */
    function addModerator(address userAddress) external onlyAdmins {
        mods[userAddress] = true;
    }

    /**
     * @dev
     * Remove a moderator
     */
    function removeModerator(
        address userAddress
    ) external onlyAdmins peaceAmongstAdmins(userAddress) {
        mods[userAddress] = false;
    }

    /**
     * @dev
     * Add an administrator
     */
    function addAdministrator(address userAddress) external onlyCreator {
        mods[userAddress] = true;
        admins[userAddress] = true;
    }

    /**
     * @dev
     * Remove an administrator
     */
    function removeAdministrator(address userAddress) external onlyCreator {
        admins[userAddress] = false;
        mods[userAddress] = false;
    }

    // ==============================
    //      OPERATIONS MANAGER
    // ==============================

    /*********************************************************
     * @notice
     * Since all of our operations (strategy run, deposits, withdrawals...) may include mid-way
     * offchain computations, it is required to keep a queue and a lock in order for them to execute one-by-one
     * in an order, and not clash.
     *********************************************************/

    /**
     * @dev Mapping keeping track of indexes to queued operations
     */
    mapping(uint256 => QueueItem) internal operationsQueue;

    /**
     * @dev We manually keep track of the current "front" and "rear" indexes of the queue
     */
    uint256 front;
    uint256 rear;

    /**
     * routeQueueOperation
     * Dequeues an item from the queue and handles it,
     * depending on the requested operation.
     * Does not take any arguments, just has to be initiated.
     */
    function routeQueueOperation() public {
        // Require the lock state to be unlocked. Otherwise this will be required to be called whne it's unlocked later
        require(!locked, "Lock Is On");
        /**
         * We dequeue & retreive the current operation to handle
         */
        QueueItem memory operation = dequeueOp();

        /**
         * Switch statement for the operation to run
         */
        if (operation.action == ActionTypes.DEPOSIT) handleDeposit(operation);
    }

    /**
     * @dev Enqueue a queue item
     */
    function enqueueOp(QueueItem memory queueItem) internal {
        operationsQueue[rear] = queueItem;
        rear++;

        /**
         * @notice
         * We check to see if the state is currently locked. If it isnt, and we are the first one in the queue,
         * we simply call the routeQueueOperation(), and handle the request immediatly.
         * Otherwise We emit a RequestFullfill event, with the action called "handle_ops_queue", which will, in turn,
         * simply begin handling the queue offchain, taking in mind the lock state.
         * This allows the intervention of the offchain only when required.
         */
        if (!locked && front == rear - 1) routeQueueOperation();
        else
            emit RequestFullfill(
                // Action is just used randomly, does not matter here
                queueItem.action,
                "handle_ops_queue",
                0,
                new bytes[](0)
            );
    }

    /**
     * @dev Dequeue and retreive a queue item
     */
    function dequeueOp() internal returns (QueueItem memory currentItem) {
        require(front < rear, "Queue Is Empty");

        currentItem = operationsQueue[front];

        delete operationsQueue[front];

        front++;

        // We reset front & rear to zero if the queue is empty, to save on future gas
        if (front < rear) {
            front = 0;
            rear = 0;
        }
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
         * @notice Lock the execution of other operations in the meantime
         */
        locked = true;

        /**
         * Decode the first byte argument as an amount
         */
        uint256 amount = abi.decode(withdrawItem.arguments[0], (uint256));

        /**
         * We require the shares of the user to be sufficient
         */
        if (balances[msg.sender] > amount) revert InsufficientShares();

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

    /**
     * @notice
     * decodeAndRequestFullfill()
     * Accepts an encoded FunctionCall struct, and some context, and emits a RequestFullfill event
     * @param encodedFunctionCall - An encoded FunctionCall struct
     * @param context - A string representing some context for the offchain executor, i.e "tree", "seed", "uproot"
     * @param index - An index specifying a step to execute when re-entering onchain, within the provided context
     */
    function _decodeAndRequestFullfill(
        bytes memory encodedFunctionCall,
        ActionTypes context,
        uint256 index
    ) internal {
        // We begin by decoding the function call
        FunctionCall memory func = abi.decode(
            encodedFunctionCall,
            (FunctionCall)
        );

        // And then emitting the event
        emit RequestFullfill(context, func.signature, index, func.args);
    }

    /**
     * @notice
     * _determineConditions()
     * Accepts an array of YCStep's, which are meant to be the conditional step's children.
     * It attempts to execute their YC commands in order - Once one resolves to true, it returns their index + 1.
     * Otherwise, it returns 0 (indiciating none went through). The index is +1'ed so that we can use the 0 index as a nullish indicator,
     * where none of the conditions resolved to true.
     * @param conditions - An array of encoded YC steps, the conditions to execute
     */
    function _determineConditions(
        bytes[] memory conditions
    ) internal returns (uint256) {
        for (uint256 i; i < conditions.length; i++) {
            /**
             * Decode the condition to a YC step
             */
            YCStep memory conditionalStep = abi.decode(conditions[i], (YCStep));

            /**
             * Attempt to execute the condition's complex YC command,
             * if it resolves to true, we return it's index,
             * otherwise, we continue
             */
            if (abi.decode(_runFunction(conditionalStep.func), (bool)))
                return i + 1;
        }

        return 0;
    }
}
