// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../YC-Diamond/YC-Diamond-Interface.sol";
import "../YC-Types.sol";

library YCDiamondLib {
    // Shorthand for the prepare function call
    function prepFunctionCall(
        IYieldchainDiamond _diamond_instance,
        bytes memory _encodedFunctionCall
    )
        internal
        view
        returns (YieldchainTypes.FunctionCall memory _func, uint8 _typeflag)
    {
        (_func, _typeflag) = _diamond_instance.prepareFunctionCall(
            _encodedFunctionCall
        );
    }

    // Shorthand for the getCalldata function
    function generateCalldata(
        IYieldchainDiamond _diamond_instance,
        string memory _function_sig,
        bytes[] memory _args
    ) internal pure returns (bytes memory _calldata) {
        _calldata = _diamond_instance.getCalldata(_function_sig, _args);
    }
}
