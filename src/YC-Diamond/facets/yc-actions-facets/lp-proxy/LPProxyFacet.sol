// SPDX-License-Identifier: MIT
import "./LPProxyBase.sol"; // Base functionality (Avoiding boilerplate)
import "../../../interfaces/IERC20.sol"; // IERC20 Interface;
import "./LPProxyStorage.sol";

pragma solidity ^0.8.17;

// TODO: Go over the ERC20 Remove & add Liquidity.
// TODO: Then, implement the ETH ones throughtly.

contract YieldchainLPProxyFacet is YieldchainLPProxyBase {
    /**
     * -------------------------------------------------------------
     * @notice Adds Liquidity to a standard LP Client (UNI-V2 Style) of a function that is either general (ERC20 & ETH) or specific (ERC20 only)
     * -------------------------------------------------------------
     */
    function _addLiquidityYC(
        Client memory client,
        address[] memory fromTokenAddresses,
        address[] memory toTokenAddresses,
        uint256[] memory fromTokenAmounts,
        uint256[] memory toTokenAmounts,
        uint256 slippage
    ) internal returns (uint256) {
        // Address of the current client
        address clientAddress = client.clientAddress;

        // Preparing Success & Result variables
        bool success;
        bytes memory result;

        // Payable sender
        address payable sender = payable(msg.sender);

        // Variable For Token A Balance
        uint256 tokenABalance = getTokenOrEthBalance(
            fromTokenAddresses[0],
            msg.sender
        );

        // Variable For Token B Balance
        uint256 tokenBBalance = getTokenOrEthBalance(
            toTokenAddresses[0],
            msg.sender
        );

        // Variable For Pair Address
        address pairAddress = getPairByClient(
            client,
            fromTokenAddresses[0],
            toTokenAddresses[0]
        );

        uint256 tokenAAmount;
        uint256 tokenBAmount;

        /**
         * Checking to see if one of the tokens is native ETH - assigning msg.value to it's amount variable, if so.
         * Reverting if the msg.value is 0 (No ETH sent)
         * @notice doing additional amount/balance checking as needed
         */
        if (fromTokenAddresses[0] == address(0)) {
            if (msg.value <= 0)
                revert("From Token is native ETH, but msg.value is 0");
            else tokenAAmount = msg.value;
        } else {
            // The amount inputted
            tokenAAmount = fromTokenAmounts[0];

            // If it's bigger than the user's balance, we assign the balance as the amount.
            if (tokenAAmount > tokenABalance) tokenAAmount = tokenABalance;

            // If it's equal to 0, we revert.
            if (tokenAAmount <= 0) revert("Token A Amount is Equal to 0");
        }

        /**
         * If the pair address is 0x0, it means that the pair does not exist yet - So we can use the inputted amounts
         */
        if (pairAddress == address(0)) {
            tokenAAmount = fromTokenAmounts[0];
            tokenBAmount = toTokenAmounts[0];
        } else {
            // Get amount out of the input amount of token A
            tokenBAmount = getAmountOutByClient(
                client,
                tokenAAmount,
                fromTokenAddresses[0],
                toTokenAddresses[0]
            );

            /**
             * @notice doing same native ETH check as before, but for token B.
             */
            if (toTokenAddresses[0] == address(0)) {
                // We revert if we got no msg.value if the address is native ETH
                if (msg.value <= 0)
                    revert("To Token is native ETH, but msg.value is 0");

                // If msg.value is bigger than the token B amount, we will refund the difference
                if (msg.value > tokenBAmount)
                    sender.transfer(msg.value - tokenBAmount);

                // Else, tokenBBalance is equal to msg.value (for next checks)
                tokenBBalance = msg.value;
            }

            // If the token B balance is smaller than the amount needed when adding out desired token A amount, we will decrement the token A amount
            // To be as much as possible when inserting the entire token B balance.
            if (tokenBBalance < tokenBAmount) {
                // Set the token B amount to the token B balance
                tokenBAmount = tokenBBalance;

                // Get the token A amount required to add the token B amount
                tokenAAmount = getAmountOutByClient(
                    client,
                    tokenBAmount,
                    toTokenAddresses[0],
                    fromTokenAddresses[0]
                );
            }
        }

        // Transfer tokenA from caller to us
        IERC20(fromTokenAddresses[0]).transferFrom(
            msg.sender,
            address(this),
            tokenAAmount
        );

        if (fromTokenAddresses[0] != address(0))
            // Transfer tokenB from caller to us
            IERC20(toTokenAddresses[0]).transferFrom(
                msg.sender,
                address(this),
                tokenBAmount
            );

        // Approve the client to spend our tokens
        IERC20(fromTokenAddresses[0]).approve(clientAddress, tokenAAmount);
        IERC20(toTokenAddresses[0]).approve(clientAddress, tokenBAmount);

        if (
            (fromTokenAddresses[0] != address(0) &&
                toTokenAddresses[0] != address(0)) || client.isSingleFunction
        ) {
            // Add the liquidity now, and get the amount of LP tokens received. (We will return this)
            (success, result) = clientAddress.call{value: msg.value}(
                abi.encodeWithSignature(
                    client.erc20FunctionSig,
                    fromTokenAddresses[0],
                    toTokenAddresses[0],
                    tokenAAmount,
                    tokenBAmount,
                    tokenAAmount -
                        (tokenAAmount - tokenAAmount / (100 / slippage)), // slippage
                    tokenBAmount -
                        (tokenBAmount - tokenBAmount / (100 / slippage)), // slippage
                    msg.sender,
                    block.timestamp + block.timestamp
                )
            );
        } else if (fromTokenAddresses[0] == address(0))
            // Add the liquidity now, and get the amount of LP tokens received. (We will return this)
            (success, result) = clientAddress.call{value: msg.value}(
                abi.encodeWithSignature(
                    client.ethFunctionSig,
                    toTokenAddresses[0],
                    tokenBAmount,
                    tokenBAmount - tokenBAmount / (100 / slippage), // slippage
                    msg.value - msg.value / (100 / slippage), // slippage
                    msg.sender,
                    block.timestamp + block.timestamp
                )
            );
        else if (toTokenAddresses[0] == address(0))
            (success, result) = clientAddress.call{value: msg.value}(
                abi.encodeWithSignature(
                    client.ethFunctionSig,
                    fromTokenAddresses[0],
                    tokenAAmount,
                    tokenAAmount - tokenAAmount / (100 / slippage), // slippage
                    msg.value - msg.value / (100 / slippage), // slippage
                    msg.sender,
                    block.timestamp + block.timestamp
                )
            );

        // Return Liquidity Amount

        require(
            success,
            "Transaction Reverted When Adding Liquidity Mister Penis Poop"
        );
        return abi.decode(result, (uint256));
    }

    // -------------------------------------------------------------
    // ---------------------- ADD LIQUIDITY -----------------------
    // -------------------------------------------------------------
    /**
     * @notice Add Liquidity to a Client
     * @param clientName The name of the client
     * @param fromTokenAddresses The addresses of the tokens to add liquidity with
     * @param toTokenAddresses The addresses of the tokens to add liquidity to
     * @param fromTokensAmounts The amounts of the tokens to add liquidity with
     * @param toTokensAmounts The amounts of the tokens to add liquidity to
     * @param slippage The slippage percentage
     * @param customArguments The custom arguments to pass to the client
     * @return lpTokensReceived The amount of LP tokens received
     * @dev if the client is a 'Non-Standard' client, the customArguments will be passed to the client in a delegate call to a custom impl contract.
     * otherwise, we call the standard YC function (tht will handle UNI-V2-style clients)
     */
    function addLiquidityYc(
        string memory clientName,
        address[] memory fromTokenAddresses,
        address[] memory toTokenAddresses,
        uint256[] memory fromTokensAmounts,
        uint256[] memory toTokensAmounts,
        uint256 slippage,
        bytes[] memory customArguments
    ) external payable returns (uint256 lpTokensReceived) {
        // Getting storage ref
        LPProxyStorage storage lpStorage = LPProxyStorageLib
            .getLPProxyStorage();
        // Get the client
        Client memory client = lpStorage.clients[clientName];

        bool success;
        bytes memory result;

        // Sufficient Checks
        require(
            fromTokenAddresses[0] != toTokenAddresses[0],
            "Cannot add liquidity to the same token"
        );

        // If it is a 'Non-Standard' LP Function, we delegate the call to what should be a custom implementation contract
        if (!client.isStandard) {
            (success, result) = client.clientAddress.delegatecall(
                abi.encodeWithSignature(
                    client.erc20FunctionSig,
                    fromTokenAddresses,
                    toTokenAddresses,
                    fromTokensAmounts,
                    toTokensAmounts,
                    slippage,
                    customArguments
                )
            );

            // If it is a 'Standard' LP Function, we call it with the parameters
        } else {
            lpTokensReceived = _addLiquidityYC(
                client,
                fromTokenAddresses,
                toTokenAddresses,
                fromTokensAmounts,
                toTokensAmounts,
                slippage
            );
        }
    }

    /**
     * -------------------------------------------------------------
     * @notice Removes Liquidity from a LP Client that has a single ERC20 Function. Cannot be non-standard (non-standards will handle
     * this on their own within their own implementation contract)
     * -------------------------------------------------------------
     */
    function _removeLiquidityYC(
        Client memory client,
        address[] memory fromTokenAddresses,
        address[] memory toTokenAddresses,
        uint256[] memory lpTokensAmounts
    ) internal returns (bool success) {
        // Address of the current client
        address clientAddress = client.clientAddress;

        // Preparing Success & Result variables
        bytes memory result;

        // Sender
        address payable sender = payable(msg.sender);

        address tokenAAddress = fromTokenAddresses[0];
        address tokenBAddress = toTokenAddresses[0];

        // The pair address
        address pair = getPairByClient(client, tokenAAddress, tokenBAddress);

        // LP Balance of msg.sender
        uint256 balance = getTokenOrEthBalance(pair, sender);

        // Getting the amount of LP to be removed
        uint256 lpAmount = lpTokensAmounts[0];

        if (lpAmount > balance)
            revert("Do not have enough LP tokens to remove");

        uint256 allowance = IERC20(tokenAAddress).allowance(
            sender,
            address(this)
        );

        if (lpAmount > allowance) {
            // Call the vault's internal approve function, to approve us for the max amount of LP tokens
            (success, result) = sender.call(
                abi.encodeWithSignature(
                    "internalApprove(address,address,uint256)",
                    pair,
                    address(this),
                    type(uint256).max - 1
                )
            );
        }

        // Transfer LP tokens to us
        IERC20(pair).transferFrom(sender, address(this), lpAmount);

        // Approve the LP tokens to be removed
        IERC20(pair).approve(client.clientAddress, lpAmount + (lpAmount / 20)); // Adding some upper slippage just in case

        // Call the remove LP function

        // If it's "single function" or none of the addresses are native ETH, call the erc20 function sig.
        if (
            (fromTokenAddresses[0] != address(0) &&
                toTokenAddresses[0] != address(0)) || client.isSingleFunction
        )
            (success, result) = clientAddress.call(
                abi.encodeWithSignature(
                    client.erc20RemoveFunctionSig,
                    fromTokenAddresses[0],
                    toTokenAddresses[0],
                    lpAmount,
                    0,
                    0,
                    sender,
                    block.timestamp + block.timestamp
                )
            );

            // Else if the from token is native ETH
        else if (fromTokenAddresses[0] == address(0))
            (success, result) = clientAddress.call{value: msg.value}(
                abi.encodeWithSignature(
                    client.ethRemoveFunctionSig,
                    toTokenAddresses[0],
                    lpAmount,
                    0,
                    0, // slippage
                    sender,
                    block.timestamp + block.timestamp
                )
            );

            // Else if the to token is native ETH
        else if (toTokenAddresses[0] == address(0))
            (success, result) = clientAddress.call{value: msg.value}(
                abi.encodeWithSignature(
                    client.ethRemoveFunctionSig,
                    fromTokenAddresses[0],
                    lpAmount,
                    0, // slippage
                    0, // slippage
                    sender,
                    block.timestamp + block.timestamp
                )
            );

        // If the call was not successful, revert
        if (!success) revert("Call to remove liquidity failed");
    }

    // -------------------------------------------------------------
    // ---------------------- REMOVE LIQUIDITY ---------------------
    // -------------------------------------------------------------
    /**
     * @notice Removes Liquidity from a LP Client,
     * @param clientName The name of the client
     * @param fromTokenAddresses The addresses of the tokens to be removed
     * @param toTokenAddresses The addresses of the tokens to be received
     * @param lpTokensAmounts The amount of LP tokens to be removed
     * @param customArguments Custom arguments to be passed to the client
     * @return success Whether the call was successful
     * @dev If the client is classfied as non-standard, the call will be delegated to the client's implementation contract.
     * Otherwise, it will be called as a standard UNI-V2 style LP.
     */
    function removeLiquidityYc(
        string memory clientName,
        address[] memory fromTokenAddresses,
        address[] memory toTokenAddresses,
        bytes[] memory customArguments,
        uint256[] memory lpTokensAmounts
    ) public returns (bool) {
        // Prepare call variables for gas saving
        bool success;
        bytes memory result;
        // Getting storage ref
        LPProxyStorage storage lpStorage = LPProxyStorageLib
            .getLPProxyStorage();
        // Get the client
        Client memory client = lpStorage.clients[clientName];

        // If it is a 'Non-Standard' LP Function, we delegate the call to what should be a custom implementation contract
        if (!client.isStandard) {
            (success, result) = client.clientAddress.delegatecall(
                abi.encodeWithSignature(
                    client.erc20FunctionSig,
                    fromTokenAddresses,
                    toTokenAddresses,
                    lpTokensAmounts,
                    customArguments
                )
            );
            return success;
        }

        // Otherwise, call the standard function (UNI-V2 Style)
        return
            _removeLiquidityYC(
                client,
                fromTokenAddresses,
                toTokenAddresses,
                lpTokensAmounts
            );
    }
}
