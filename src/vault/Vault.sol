// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// ===============
//    IMPORTS
// ===============
import "../interfaces/IERC20.sol";
import "../vm/VM.sol";

/**
 * The part of the vault contract containing various
 * state (storage) variables and immutables.
 *
 * This is the root contract being inherited
 */

contract State is YCVM {
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
        string indexed context,
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
        require(
            msg.sender == YC_DIAMOND,
            "Only The Yieldchain Diamond Is Permitted To Do This"
        );
        _;
    }

    /**
     * Requires the msg.sender to be the vault's creator
     */
    modifier onlyCreator() {
        require(
            msg.sender == CREATOR,
            "Only The Vault Creator Is Permitted To Do This"
        );
        _;
    }

    /**
     * Requires the msg.sender to be a moderator of this vault
     */
    modifier onlyMods() {
        require(mods[msg.sender], "Only Moderators Are Permitted To Do This");
        _;
    }
    /**
     * Requires the msg.sender to be an admin of this vault
     */
    modifier onlyAdmins() {
        require(
            admins[msg.sender],
            "Only Administrators Are Permitted To Do This"
        );
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
    }

    /**
     * @dev
     * Remove an administrator
     */
    function removeAdministrator(address userAddress) external onlyCreator {
        admins[userAddress] = false;
    }


    // ==============================
    //      OPERATIONS MANAGER
    // ==============================

    /**
     * @notice
     * Since all of our operations (strategy run, deposits, withdrawals...) may include mid-way
     * offchain computations, it is required to keep a queue and a lock in order for them to execute one-by-one 
     * in an order, and not clash.
     * 
     */

    // ==============================
    //     VAULT OPS METHODS
    // ==============================

    /**
     * @notice
     * Request A Deposit Into The Vault
     * @param amount - The amount of the deposit token to deposit
     */
    function deposit(uint256 amount) external {
        /**
         * We assert that the user must have given us appropriate allowance.
         * This will be checked offchain as well of course and on the deposit fullfil call,
         * but is done in order to ensure easy spamming
         */
        if (DEPOSIT_TOKEN.allowance(msg.sender, address(this)) >= amount)
            revert InsufficientAllowance();

        /**
         * We then call safeTransferFrom() in order to transfer the requested tokens into the vault,
         * and begin with the execution of their funds
         */

        /**
         * @notice
         * We emit a RequestFullfil event, requesting a deposit fullfill run.
         * This is done in order to "queue" all of the deposits, withdrawals & strategy runs, to avoid
         * mid-execution clashes of logic (i.e mixing up balances), since we allow offchain logic to be included
         * in strategies.
         */
        emit RequestFullfill("vault_deposit", "vault_deposit", 0, )
    }

    // ==============================
    //     STRATEGY EXECUTION
    // ==============================

    /**
     * @notice
     * executeStepTree()
     * Receives an index of a step in the linked-list array of steps,
     * executes it & it's children.
     *
     * @param stepIndex - the index of the step within the STEPS linked list to execute
     * @param
     */
}
