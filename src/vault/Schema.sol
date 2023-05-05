/**
 * Contains all different events, structs, enums, etc of the vault
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract IVault {
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

    // // =====================
    // //      MODIFIERS
    // // =====================
    // /**
    //  * Requires the msg.sender to be the Yieldchain Diamond Contract.
    //  */
    // modifier onlyDiamond() virtual;

    // /**
    //  * Requires the msg.sender to be the vault's creator
    //  */
    // modifier onlyCreator() virtual;

    // /**
    //  * Requires the msg.sender to be a moderator of this vault
    //  */
    // modifier onlyMods() virtual;
    // /**
    //  * Requires the msg.sender to be an admin of this vault
    //  */
    // modifier onlyAdmins() virtual;

    // /**
    //  * Requires an inputted address to not be another moderator
    //  * @notice We do allow it if msg.sender is an administrator (higher role)
    //  */
    // modifier peaceAmongstMods(address otherMod) virtual;

    // /**
    //  * Requires an inputted address to not be another adminstrator
    //  */
    // modifier peaceAmongstAdmins(address otherAdmin) virtual;

    // /**
    //  * Requires the msg.sender to either be whitelisted, or the vault be public
    //  */
    // modifier onlyWhitelistedOrPublicVault() virtual;

    // =====================
    //      FUNCTIONS
    // =====================
    /**
     * routeQueueOperation
     * Dequeues an item from the queue and handles it,
     * depending on the requested operation.
     */
    function routeQueueOperation(
        uint256[] memory startingIndices,
        bytes memory fullfillCommand
    ) public virtual;
}
