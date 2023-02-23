// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./LPProxyStorage.sol";
import "../../base-diamond-facets/OwnershipFacet.sol";

contract YieldchainLPProxyBase is OwnershipFacet {
    // ===================
    //     CONSTRUCTOR
    // ===================
    constructor() {
        LPProxyStorage storage lpProxyStorage = LPProxyStorageLib
            .getLPProxyStorage();
        lpProxyStorage.owner = msg.sender;
    }

    /**
     * @notice
     * Used to add an LP client,
     * Accessible only by the owner
     * @param clientDetails - A struct object representing a client's configuration
     */
    function addClient(
        string memory clientName,
        Client memory clientDetails
    ) public isOwner {
        // Getting storage ref
        LPProxyStorage storage lpProxyStorage = LPProxyStorageLib
            .getLPProxyStorage();

        // Adding the client
        lpProxyStorage.clients[clientName] = clientDetails;
    }

    // Get a client by it's name
    function getClient(
        string memory clientName
    ) public view returns (Client memory) {
        LPProxyStorage storage lpProxyStorage = LPProxyStorageLib
            .getLPProxyStorage();

        return lpProxyStorage.clients[clientName];
    }

    /**
     *  -------------------------------------------------------------
     * @notice Gets a token balance for a token address and user address
     *  -------------------------------------------------------------
     */
    function getTokenOrEthBalance(
        address tokenAddress,
        address userAddress
    ) public view returns (uint256) {
        bool success;
        bytes memory result;

        // Return native currency balance in the case of the 0 address being provided
        if (tokenAddress == address(0)) {
            return userAddress.balance;
        }

        // Call the ERC20 balanceOf function, return that
        (success, result) = tokenAddress.staticcall(
            abi.encodeWithSignature("balanceOf(address)", userAddress)
        );

        require(success, "Failed to get token balance");

        return abi.decode(result, (uint256));
    }

    /**
     *  -------------------------------------------------------------
     * @notice gets the address of a pair from the inputted token addresses, and the client's name
     * -------------------------------------------------------------
     */
    function getPairByClient(
        Client memory client,
        address tokenAAddress,
        address tokenBAddress
    ) internal view returns (address) {
        bool success;
        bytes memory result;
        (success, result) = client.clientAddress.staticcall(
            abi.encodeWithSignature(client.factoryFunctionSig)
        );

        require(success, "Failed To Get Factory Address For Client");

        address factoryAddress = abi.decode(result, (address));

        (success, result) = factoryAddress.staticcall(
            abi.encodeWithSignature(
                client.getPairSig,
                tokenAAddress,
                tokenBAddress
            )
        );

        require(success, "Failed To Get Pair Address For Client");

        return abi.decode(result, (address));
    }

    /**
     * -------------------------------------------------------------
     * @notice Takes in an amount, token A & B addresses - returns the amount needed for
     * token B when adding liquidity with the token A amount, on any supported client
     * -------------------------------------------------------------
     */
    function getAmountOutByClient(
        Client memory client,
        uint256 amountIn,
        address tokenInAddress,
        address tokenOutAddress
    ) internal returns (uint256) {
        // Get amount out from the client
        address[] memory path = new address[](2);

        path[0] = tokenInAddress;
        path[1] = tokenOutAddress;
        (bool success, bytes memory result) = client.clientAddress.call(
            abi.encodeWithSignature(client.getAmountsOutSig, amountIn, path)
        );

        require(success, "Failed To Get Amount Out For Client");

        // Return the amount out (we get an array where the first element is the amount
        // we entered and the second one is what we're looking for)
        return abi.decode(result, (uint256[]))[1];
    }

    /**
     * @notice Gets the reserves of a pair on a client
     */
    function getReservesByClient(
        address pair,
        Client memory client
    ) internal view returns (uint256, uint256) {
        (bool success, bytes memory result) = pair.staticcall(
            abi.encodeWithSignature(client.getReservesSig)
        );

        require(success, "Failed To Get Reserves For Client");

        return abi.decode(result, (uint256, uint256));
    }
}
