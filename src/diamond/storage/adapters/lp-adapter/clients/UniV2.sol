/**
 * Storage for the UniV2 LP Adapter
 */

/**
 * @notice Struct containing the classification of a UniV2-Compatible LP Client
 * @param erc20FunctionSig String containing the function signature of the ERC20 addLiquidity function
 * @param wethFunctionSig String containing the function signature of the WETH addLiquidity function
 * @param getAmountsOutSig String containing the function signature of the getAmountsOut function
 * @param isSingleFunction Boolean indicating whether the client has a single function or two functions
 * @param isStandard Boolean indicating whether the client is a standard LP or a custom implementation contract
 * @dev If the client is a non-standard LP, then the call with the exact inputted full parameters will be
 * delegated onto the ERC20
 * function sigs, and the logic will be handled by a custom logic contract. If it is standard,
 * then the logic will be handled
 * by the contract itself - It can either be called with the ycSingleFunction
 * (i.e if one function handles addLiquidity), or with
 * the ycTwoFunctions (i.e if two functions handle addLiquidity with a case for ERC20s and ETH).
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
    string totalSupplySig; // Sig being called when getting a pair's total LP token supply
    bool isSingleFunction; // Boolean, whether the client has one function or two functions (ERC20 & WETH / single one)
    bool isStandard; // Indicating whether the client is a standard UNI-V2 LP or a custom implementation contract.
    address clientAddress; // Address of the client
}