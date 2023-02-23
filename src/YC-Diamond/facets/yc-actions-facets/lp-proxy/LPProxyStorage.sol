// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Struct representing the storage of the LP Proxy
struct LPProxyStorage {
    address owner;
    mapping(string => Client) clients;
}

/**
 * @param clientName - Name of the client
 * @param erc20FunctionSig - Signature of ERC20 (or ERC20 & ETH) function used to add liquidity
 * @param ethFunctionSig - Signature of ETH function used to add liquidity
 * @param erc20RemoveFunctionSig - Signature of ERC20 (or ERC20 & ETH) function used to remove liquidity
 * @param ethRemoveFunctionSig - Signature of ETH function used to remove liquidity
 * @param balanceOfSig - Signature of function used to check the balanceOf an address on a liquidity pair
 * @param getAmountsOutSig - Signature of function used to calculate the amount of another token based on an inputted token amount
 * @param getAmountsInSig - Signature of function used to calculate the amount of another token based on an outputted token amount
 * @param factoryFunctionSig - Signature used to retreive the client's factory address
 * @param getReservesSig - Signature of function used to retreive the reserves of a client's pair
 * @param getPairSig - Signature of function used to get a client's pair's address
 * @param isSingleFunction - Boolean indicating whether the client has a single function for both ERC20 & ETH, or seperate ones
 * @param isStandard - Boolean indiciating whether the client is considered "Standard" with the reguler impl (Uniswap V2)
 * @param clientAddress - The client's address (or, if non-standard - our custom impl contract's address)
 */
struct Client {
    string erc20FunctionSig; // Sig being signed when calling AddLiquidity on an ERC20 / Orchestrator function
    string ethFunctionSig; // Sig being signed when calling AddLiquidity on WETH
    string erc20RemoveFunctionSig; // Sig being signed when calling RemoveLiquidity on an ERC20 / Orchestrator function
    string ethRemoveFunctionSig; // Sig being signed when calling RemoveLiquidity on WETH
    string balanceOfSig; // Sig being called when getting the balance of an LP token pair
    string getAmountsOutSig; // Sig being called when getting the amounts out of a swap
    string getAmountsInSig; // Sig being called when getting the amounts in of a swap
    string factoryFunctionSig; // Sig being called when getting the factory address of a client
    string getReservesSig; // Sig being called when getting the reserves of a pair
    string getPairSig; // Sig being called when getting the pair address of a client (on it's factory address)
    bool isSingleFunction; // Boolean, whether the client has one function or two functions (ERC20 & WETH / single one)
    bool isStandard; // Indicating whether the client is a standard UNI-V2 LP or a custom implementation contract.
    address clientAddress; // Address of the client
}

// Library for Strategies-related storage, inherited by all strategy orchestration related facets
library LPProxyStorageLib {
    // Storage slot hash
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("com.yieldchain.lp.proxy");

    // Retreive the storage struct
    function getLPProxyStorage()
        internal
        pure
        returns (LPProxyStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}
