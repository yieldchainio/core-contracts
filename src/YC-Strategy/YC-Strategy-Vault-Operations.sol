// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./YC-Strategy-Names.sol";
import "../YC-Diamond/interfaces/IERC20.sol";

abstract contract YieldchainStrategyVaultOps is YieldchainStrategyNames {
    // =============================================================
    //                 CONSTRUCTOR SUPER
    // =============================================================
  
    
    constructor(
        bytes[] memory _steps,
        bytes[] memory _base_strategy_steps,
        address[] memory _base_tokens,
        address[] memory _strategy_tokens,
        address[][] memory _tokens_related_addresses,
        uint256 _automation_interval,
        address _deployer
    )
        // Super()
        YieldchainStrategyNames(
            _steps,
            _base_strategy_steps,
            _base_tokens,
            _strategy_tokens,
            _automation_interval,
            _deployer
        )
    {
        // Approve all tokens and their related addresses
        approveAllTokens(_strategy_tokens, _tokens_related_addresses);
    }

    // =============================================================
    //                   VAULT OPERATIONS FUNCTIONS
    // =============================================================
    function deposit(uint256 _amount) public {
        // Require amount to be above zero
        if (_amount <= 0) revert InvalidAmountZero();

        // Transfer tokens from user
        IERC20(tokens[0]).transferFrom(msg.sender, address(this), _amount);

        // Update user's shares
        balances[msg.sender] += _amount;

        // Update total shares
        totalShares += _amount;

        // Send a callback request event to swap the user's deposit token into
        // the strategy's base tokens, and call the depositFullfill function,
        // which will spread them into the base positions

        // If it's one, we can just call depositFullfill on our own w empty calldata

        bytes memory emptyCalldata = "00";
        if (BASE_TOKENS.length == 1)
            depositFullfill(emptyCalldata);

            // Otherwise, there are multiple tokens and we need to multi-swap them using a callback
        else {}
    }

    function depositFullfill(bytes memory _calldata) public view isYieldchain {
        // Empty bytes length for comparison
        bytes memory emptybyte = "00";

        // If we got actual swap calldata
        if (_calldata.length == emptybyte.length) {}
    }

    function withdraw(uint256 amount) public {}

    function _withdrawFullfill(bytes memory _calldata) external isYieldchain {}

    // =============================================================
    //                 ADDITIONAL UTILITY OPERATIONS
    // =============================================================
    function approveAllTokens(
        address[] memory _tokens,
        address[][] memory _related_addresses
    ) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address[] memory relatedAddresses = _related_addresses[i];
            for (uint256 j = 0; j < relatedAddresses.length; j++) {
                IERC20(_tokens[i]).approve(relatedAddresses[j], 2 ** 256 - 1);
            }
        }
    }

    // Internal approve, only called by Yieldchain diamond if ever needed
    function internalApproval(
        address _token,
        address _spender,
        uint256 _amount
    ) external isYieldchain {
        // Either transferred inputted amount, or max uint256 if amount is 0 (implicit max approval)
        IERC20(_token).approve(_spender, _amount > 0 ? _amount : 2 ** 256 - 1);
    }

    // ======================================
    //          AUTOMATION FUNCTIONS
    // ======================================

    // Gets called by upkeep orchestrator to determine whether the strategy should run now
    // TODO: Custom triggers (Not just automations)
    function shouldPerform() external view returns (bool) {
        // If AUTOMATION_INTERVAL has passed since last execution
        if (block.timestamp - lastExecution >= AUTOMATION_INTERVAL) return true;
        return false;
    }

    // User triggers to fund the gas balance - takes in any ERC20 token and transfers it. Then swaps it
    function fundGas(uint256 _amount, address _token) external payable {
        // Initiating data array for callback
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encode(_amount);
        data[1] = abi.encode(_token);

        // Transfering the tokens to us

        // If it's native currency we use msg.value instead of the amount argument
        if (_token == address(0)) {
            require(
                msg.value > 0,
                "ERROR FUNDING GAS: msg.value must be larger than 0 when depositing native currency"
            );
            _amount = msg.value;
        } else {
            // Transfer ERC20 token from msg.sender to us - requires preapproval.
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        }

        // Emiting a callback event requesting the gas deposit
        emit RequestCallback("fundGas", "addGas", 0, data);
    }
}
