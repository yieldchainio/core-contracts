// SPDX-License-Identifier: SPDX
pragma solidity ^0.8.18;
import "./YC-Strategy-Vault-Operations.sol";
import "./YC-Strategy-Types.sol";

contract YieldchainStrategyExecHelpers is
    YieldchainStrategyVaultOps,
    YieldchainTypes
{
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
        YieldchainStrategyVaultOps(
            _steps,
            _base_strategy_steps,
            _base_tokens,
            _strategy_tokens,
            _tokens_related_addresses,
            _automation_interval,
            _deployer
        )
    {}

    // High-level runFunction function
    function runFunction(
        bytes memory _encodedFunctionCall
    ) internal returns (bytes memory _ret, FunctionCall memory _calledFunc) {
        // Initiallizing
        uint8 typeflag;

        // TODO: Add some r,s,v signature in here to retain pureness of function verification?
        // Preparing the function call.
        (_calledFunc, typeflag) = YC_DIAMOND.prepareFunctionCall(
            _encodedFunctionCall
        );

        // Execute the function
        _ret = _execFunctionCall(_calledFunc, typeflag);
    }

    // Lower-level function for executing a DECODED FunctionCall,
    // Function must be prepared (with actual signature)
    // TODO: Enter the future r,s,v as args here
    function _execFunctionCall(
        FunctionCall memory _func,
        uint8 _typeflag
    ) internal returns (bytes memory _ret) {
        // Initiating an array for the new arguments
        bytes[] memory newArgs = new bytes[](_func.args.length);

        // @notice
        // For each one of the function's arguments, we recruse the function (getArgValue).
        // Since dynamic return values may be used as an argument for this function (a dynamic return value...) as well.
        for (uint256 i = 0; i < newArgs.length; i++) {
            newArgs[i] = _getArgValue(_func.args[i]); // Recrusion
        }

        // Get the calldata
        bytes memory callData = YC_DIAMOND.getCalldata(
            _func.signature,
            newArgs
        );

        // Switch-Case for the call type based on the flag
        if (_typeflag == 0x01)
            (, _ret) = _func.target_address.staticcall(callData);
        else if (_typeflag == 0x02)
            (, _ret) = _func.target_address.delegatecall(callData);
        else if (_typeflag == 0x03)
            (, _ret) = _func.target_address.call(callData);
        else revert InvalidCallFlag();
    }

    /**
     * A recrusive function that accepts a byte argument, attempts to decode it using
     * YC's "Function" struct - if fails, returns the byte as-is. If it goes through, it
     * makes the desired function call, whilst recrusing the same process for each one of the function's
     * arguments.
     * @param _arg A YC Encoded variable - can be either plain (A static variable), or any kind of FunctionCall type.
     * @return _returnArg The result - the actual value of that argument. If static, would just be the argument without
     * the flags (i.e plain). If it's a FunctionCall, it would be the return data of that function call
     */
    function _getArgValue(
        bytes memory _arg
    ) internal returns (bytes memory _returnArg) {
        // Seperating the argument & the flag
        (bytes memory plainArg, uint8 typeflag) = YC_DIAMOND.seperateYCVariable(
            _arg
        );

        // If the flag is 0, it means it is static so we return the plain arg as-is
        if (typeflag == 0x00) return plainArg;

        // @notice
        // If the flag is not 0 (i.e its either 1, 2, 3 - the CALL types), we call prepareFunctionCall.
        // the function will in turn decode the function as needed, recruse back to us for each
        // one of it's arguments, and at the end return the calldata

        // Getting the FunctionCall struct (Since the arg is not static)

        // Execute the function call.
        (_returnArg, ) = runFunction(_arg);
    }
}
