// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC20.sol";

contract SimpleStaking {
    // boolean to prevent reentrancy
    bool internal locked;

    // Contract owner
    address public owner;

    // Timestamp related variables
    uint256 public initialTimestamp;
    bool public timestampSet;
    uint256 public timePeriod;

    // Token amount variables
    mapping(address => uint256) public alreadyWithdrawn;
    mapping(address => uint256) public balances;
    uint256 public contractBalance;

    // ERC20 contract address
    ERC20 public erc20Contract;

    // Events
    event tokensStaked(address from, uint256 amount);
    event TokensUnstaked(address to, uint256 amount);

    /// @dev Deploys contract and links the ERC20 token which we are staking, also sets owner as msg.sender and sets timestampSet bool to false.
    /// @param _erc20_contract_address.
    constructor(ERC20 _erc20_contract_address) {
        // Set contract owner
        owner = msg.sender;
        // Timestamp values not set yet
        timestampSet = false;
        // Set the erc20 contract address which this timelock is deliberately paired to
        require(
            address(_erc20_contract_address) != address(0),
            "_erc20_contract_address address can not be zero"
        );
        erc20Contract = _erc20_contract_address;
        // Initialize the reentrancy variable to not locked
        locked = false;
    }

    // Modifier
    /**
     * @dev Prevents reentrancy
     */
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    // Modifier
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Message sender must be the contract's owner."
        );
        _;
    }

    // Modifier
    /**
     * @dev Throws if timestamp already set.
     */
    modifier timestampNotSet() {
        require(timestampSet == false, "The time stamp has already been set.");
        _;
    }

    // Modifier
    /**
     * @dev Throws if timestamp not set.
     */
    modifier timestampIsSet() {
        require(
            timestampSet == true,
            "Please set the time stamp first, then try again."
        );
        _;
    }

    /// @dev Sets the initial timestamp and calculates minimum staking period in seconds i.e. 3600 = 1 hour
    /// @param _timePeriodInSeconds amount of seconds to add to the initial timestamp i.e. we are essemtially creating the minimum staking period here
    function setTimestamp(
        uint256 _timePeriodInSeconds
    ) public onlyOwner timestampNotSet {
        timestampSet = true;
        initialTimestamp = block.timestamp;
        timePeriod = initialTimestamp + _timePeriodInSeconds;
    }

    /// @dev Allows the contract owner to allocate official ERC20 tokens to each future recipient (only one at a time).
    /// @param token, the official ERC20 token which this contract exclusively accepts.
    /// @param amount to allocate to recipient.
    function stakeTokens(
        ERC20 token,
        uint256 amount
    ) public timestampIsSet noReentrant {
        require(
            token == erc20Contract,
            "You are only allowed to stake the official erc20 token address which was passed into this contract's constructor"
        );
        require(
            amount <= token.balanceOf(msg.sender),
            "Not enough STATE tokens in your wallet, please try lesser amount"
        );
        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] = balances[msg.sender] + amount;
        emit tokensStaked(msg.sender, amount);
    }

    /// @dev Allows user to unstake tokens after the correct time period has elapsed
    /// @param token - address of the official ERC20 token which is being unlocked here.
    /// @param amount - the amount to unlock (in wei)
    function unstakeTokens(
        ERC20 token,
        uint256 amount
    ) public timestampIsSet noReentrant {
        require(
            balances[msg.sender] >= amount,
            "Insufficient token balance, try lesser amount"
        );
        require(
            token == erc20Contract,
            "Token parameter must be the same as the erc20 contract address which was passed into the constructor"
        );
        if (block.timestamp >= timePeriod) {
            alreadyWithdrawn[msg.sender] =
                alreadyWithdrawn[msg.sender] +
                amount;
            balances[msg.sender] = balances[msg.sender] - amount;
            token.transfer(msg.sender, amount);
            emit TokensUnstaked(msg.sender, amount);
        } else {
            revert(
                "Tokens are only available after correct time period has elapsed"
            );
        }
    }

    /// @dev Transfer accidentally locked ERC20 tokens.
    /// @param token - ERC20 token address.
    /// @param amount of ERC20 tokens to remove.
    function transferAccidentallyLockedTokens(
        ERC20 token,
        uint256 amount
    ) public onlyOwner noReentrant {
        require(address(token) != address(0), "Token address can not be zero");
        // This function can not access the official timelocked tokens; just other random ERC20 tokens that may have been accidently sent here
        require(
            token != erc20Contract,
            "Token address can not be ERC20 address which was passed into the constructor"
        );
        // Transfer the amount of the specified ERC20 tokens, to the owner of this contract
        token.transfer(owner, amount);
    }
}
