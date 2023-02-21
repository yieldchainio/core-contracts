// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract YieldchainOnpcodes {
    function _execute_opcode(bytes1 _opcode, bytes[] memory _args)
        external
        returns (bytes memory _ret)
    {
        if (_opcode == 0x00) _ret = STOP(_args);
        else if (_opcode == 0x01) _ret = ADD(_args);
        else if (_opcode == 0x02) _ret = MUL(_args);
        else if (_opcode == 0x03) _ret = SUB(_args);
        else if (_opcode == 0x04) _ret = DIV(_args);
        else if (_opcode == 0x05) _ret = SDIV(_args);
        else if (_opcode == 0x06) _ret = MOD(_args);
        else if (_opcode == 0x07) _ret = SMOD(_args);
        else if (_opcode == 0x08) _ret = ADDMOD(_args);
        else if (_opcode == 0x09) _ret = MULMOD(_args);
        else if (_opcode == 0x0a) _ret = EXP(_args);
        else if (_opcode == 0x0b) _ret = SIGNEXTEND(_args);
        else if (_opcode == 0x10) _ret = LT(_args);
        else if (_opcode == 0x11) _ret = GT(_args);
        else if (_opcode == 0x12) _ret = SLT(_args);
        else if (_opcode == 0x13) _ret = SGT(_args);
        else if (_opcode == 0x14) _ret = EQ(_args);
        else if (_opcode == 0x15) _ret = ISZERO(_args);
        else if (_opcode == 0x16) _ret = AND(_args);
        else if (_opcode == 0x17) _ret = OR(_args);
        else if (_opcode == 0x18) _ret = XOR(_args);
        else if (_opcode == 0x19) _ret = NOT(_args);
        else if (_opcode == 0x1a) _ret = BYTE(_args);
        else if (_opcode == 0x1b) _ret = SHL(_args);
        else if (_opcode == 0x1c) _ret = SHR(_args);
        else if (_opcode == 0x1d) _ret = SAR(_args);
        else if (_opcode == 0x20) _ret = KECCAK256(_args);
        else if (_opcode == 0x30) _ret = ADDRESS(_args);
        else if (_opcode == 0x31) _ret = BALANCE(_args);
        else if (_opcode == 0x32) _ret = ORIGIN(_args);
        else if (_opcode == 0x33) _ret = CALLER(_args);
        else if (_opcode == 0x34) _ret = CALLVALUE(_args);
        else if (_opcode == 0x35) _ret = CALLDATALOAD(_args);
        else if (_opcode == 0x36) _ret = CALLDATASIZE(_args);
        else if (_opcode == 0x37) _ret = CALLDATACOPY(_args);
        else if (_opcode == 0x38) _ret = CODESIZE(_args);
        else if (_opcode == 0x39) _ret = CODECOPY(_args);
        else if (_opcode == 0x3a) _ret = GASPRICE(_args);
        else if (_opcode == 0x3b) _ret = EXTCODESIZE(_args);
        else if (_opcode == 0x3c) _ret = EXTCODECOPY(_args);
        else if (_opcode == 0x3d) _ret = RETURNDATASIZE(_args);
        else if (_opcode == 0x3e) _ret = RETURNDATACOPY(_args);
        else if (_opcode == 0x3f) _ret = EXTCODEHASH(_args);
        else if (_opcode == 0x40) _ret = BLOCKHASH(_args);
        else if (_opcode == 0x41) _ret = COINBASE(_args);
        else if (_opcode == 0x42) _ret = TIMESTAMP(_args);
        else if (_opcode == 0x43) _ret = NUMBER(_args);
        else if (_opcode == 0x44) _ret = PREVRANDAO(_args);
        else if (_opcode == 0x45) _ret = GASLIMIT(_args);
        else if (_opcode == 0x46) _ret = CHAINID(_args);
        else if (_opcode == 0x47) _ret = SELFBALANCE(_args);
        else if (_opcode == 0x48) _ret = BASEFEE(_args);
        else if (_opcode == 0x50) _ret = POP(_args);
        else if (_opcode == 0x51) _ret = MLOAD(_args);
        else if (_opcode == 0x52) _ret = MSTORE(_args);
        else if (_opcode == 0x53) _ret = MSTORE8(_args);
        else if (_opcode == 0x54) _ret = SLOAD(_args);
        else if (_opcode == 0x55) _ret = SSTORE(_args);
        else if (_opcode == 0x56) _ret = JUMP(_args);
        else if (_opcode == 0x57) _ret = JUMPI(_args);
        else if (_opcode == 0x59) _ret = MSIZE(_args);
        else if (_opcode == 0x5a) _ret = GAS(_args);
        else if (_opcode == 0xa0) _ret = LOG0(_args);
        else if (_opcode == 0xa1) _ret = LOG1(_args);
        else if (_opcode == 0xa2) _ret = LOG2(_args);
        else if (_opcode == 0xa3) _ret = LOG3(_args);
        else if (_opcode == 0xa4) _ret = LOG4(_args);
        else if (_opcode == 0xf0) _ret = CREATE(_args);
        else if (_opcode == 0xf3) _ret = RETURN(_args);
        else if (_opcode == 0xf5) _ret = CREATE2(_args);
        else if (_opcode == 0xfd) _ret = REVERT(_args);
    }

    function STOP(bytes[] memory _args) internal returns (bytes memory _ret) {}

    function ADD(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := add(a, b)
        }
    }

    function MUL(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := mul(a, b)
        }
    }

    function SUB(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := sub(a, b)
        }
    }

    function DIV(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := div(a, b)
        }
    }

    function SDIV(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := sdiv(a, b)
        }
    }

    function MOD(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := mod(a, b)
        }
    }

    function SMOD(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := smod(a, b)
        }
    }

    function ADDMOD(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))
            let c := mload(add(_args, 0x60))

            _ret := addmod(a, b, c)
        }
    }

    function MULMOD(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))
            let c := mload(add(_args, 0x60))

            _ret := mulmod(a, b, c)
        }
    }

    function EXP(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := exp(a, b)
        }
    }

    function SIGNEXTEND(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := signextend(a, b)
        }
    }

    function LT(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := lt(a, b)
        }
    }

    function GT(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := gt(a, b)
        }
    }

    function SLT(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := slt(a, b)
        }
    }

    function SGT(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := sgt(a, b)
        }
    }

    function EQ(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := eq(a, b)
        }
    }

    function ISZERO(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))

            _ret := iszero(a)
        }
    }

    function AND(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := and(a, b)
        }
    }

    function OR(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := or(a, b)
        }
    }

    function XOR(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := xor(a, b)
        }
    }

    function NOT(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := not(a)
        }
    }

    function BYTE(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := byte(a, b)
        }
    }

    function SHL(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := shl(a, b)
        }
    }

    function SHR(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := shr(a, b)
        }
    }

    function SAR(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := sar(a, b)
        }
    }

    function KECCAK256(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))

            _ret := keccak256(a, b)
        }
    }

    function ADDRESS(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := address()
        }
    }

    function BALANCE(bytes[] memory _args)
        internal
        view
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            _ret := balance(a)
        }
    }

    function ORIGIN(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := origin()
        }
    }

    function CALLER(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := caller()
        }
    }

    function CALLVALUE(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := callvalue()
        }
    }

    function CALLDATALOAD(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))

            _ret := calldataload(a)
        }
    }

    function CALLDATASIZE(
        bytes[] memory /*_args*/
    ) internal pure returns (bytes memory _ret) {
        assembly {
            _ret := calldatasize()
        }
    }

    function CALLDATACOPY(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let b := mload(add(_args, 0x40))
            let c := mload(add(_args, 0x60))
            calldatacopy(a, b, c) // TODO: Needed?
            _ret := 1
        }
    }

    function CODESIZE(
        bytes[] memory /*_args*/
    ) internal pure returns (bytes memory _ret) {
        assembly {
            _ret := codesize()
        }
    }

    function CODECOPY(bytes[] memory _args)
        internal
        view
        returns (bytes memory _ret)
    {
        // TODO: Needed?
    }

    function GASPRICE(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := gasprice()
        }
    }

    function EXTCODESIZE(bytes[] memory _args)
        internal
        view
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            _ret := extcodesize(a)
        }
    }

    function EXTCODECOPY(bytes[] memory _args)
        internal
        view
        returns (bytes memory _ret)
    {
        // TODO: needed?
    }

    function RETURNDATASIZE(
        bytes[] memory /*_args*/
    ) internal pure returns (bytes memory _ret) {
        assembly {
            _ret := returndatasize()
        }
    }

    function RETURNDATACOPY(bytes[] memory _args)
        internal
        view
        returns (bytes memory _ret)
    {
        // TODO: Needed?
    }

    function EXTCODEHASH(bytes[] memory _args)
        internal
        view
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            _ret := extcodehash(a)
        }
    }

    function BLOCKHASH(bytes[] memory _args)
        internal
        view
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            _ret := blockhash(a)
        }
    }

    function COINBASE(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := coinbase()
        }
    }

    function TIMESTAMP(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := timestamp()
        }
    }

    function NUMBER(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := number()
        }
    }

    function PREVRANDAO(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := prevrandao()
        }
    }

    function GASLIMIT(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := gaslimit()
        }
    }

    function CHAINID(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := chainid()
        }
    }

    function SELFBALANCE(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := selfbalance()
        }
    }

    function BASEFEE(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := basefee()
        }
    }

    function POP(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let a := mload(add(_args, 0x20))
            let pre_size := msize()
            pop(a)
            if eq(msize(), sub(pre_size, a)) {
                _ret := 1
            }
            if iszero(eq(msize(), sub(pre_size, a))) {
                _ret := 0
            }
        }
    }

    function MLOAD(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let offset := mload(add(_args, 0x20))
            _ret := mload(offset)
        }
    }

    function MSTORE(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let offset := mload(add(_args, 0x20))
            let val := mload(add(_args, 0x40))
            mstore(offset, val)
            if eq(mload(offset), val) {
                _ret := 1
            }
            if iszero(eq(mload(offset), val)) {
                _ret := 0
            }
        }
    }

    function MSTORE8(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            // TODO: do i need to load the values differently  since size is different?
            let offset := mload(add(_args, 0x20))
            let val := mload(add(_args, 0x40))
            mstore8(offset, val)
            if eq(mload(offset), val) {
                _ret := 1
            }
            if iszero(eq(mload(offset), val)) {
                _ret := 0
            }
        }
    }

    function SLOAD(bytes[] memory _args)
        internal
        view
        returns (bytes memory _ret)
    {
        assembly {
            let key := mload(add(_args, 0x20))
            _ret := sload(key)
        }
    }

    function SSTORE(bytes[] memory _args) internal returns (bytes memory _ret) {
        assembly {
            let key := mload(add(_args, 0x20))
            let val := mload(add(_args, 0x40))
            sstore(key, val)
            if eq(sload(key), val) {
                _ret := 1
            }
            if iszero(eq(sload(key), val)) {
                _ret := 0
            }
        }
    }

    function JUMP(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let dest := mload(add(_args, 0x20))
            _ret := dest
        }
    }

    function JUMPI(bytes[] memory _args)
        internal
        pure
        returns (bytes memory _ret)
    {
        assembly {
            let dest := mload(add(_args, 0x20))
            let condition := mload(add(_args, 0x40))
            // TODO: jumpi non existant?
            _ret := condition
        }
    }

    function MSIZE(
        bytes[] memory /*_args*/
    ) internal pure returns (bytes memory _ret) {
        assembly {
            _ret := msize()
        }
    }

    function GAS(
        bytes[] memory /*_args*/
    ) internal view returns (bytes memory _ret) {
        assembly {
            _ret := gas()
        }
    }

    function LOG0(bytes[] memory _args) internal returns (bytes memory _ret) {
        assembly {
            let offset := mload(add(_args, 0x20))
            let length := mload(add(_args, 0x40))
            log0(offset, length)
            _ret := 1
        }
    }

    function LOG1(bytes[] memory _args) internal returns (bytes memory _ret) {
        assembly {
            let offset := mload(add(_args, 0x20))
            let length := mload(add(_args, 0x40))
            let topic0 := mload(add(_args, 0x60))
            log1(offset, length, topic0)
            _ret := 1
        }
    }

    function LOG2(bytes[] memory _args) internal returns (bytes memory _ret) {
        assembly {
            let offset := mload(add(_args, 0x20))
            let length := mload(add(_args, 0x40))
            let topic0 := mload(add(_args, 0x60))
            let topic1 := mload(add(_args, 0x80))
            log2(offset, length, topic0, topic1)
            _ret := 1
        }
    }

    function LOG3(bytes[] memory _args) internal returns (bytes memory _ret) {
        assembly {
            let offset := mload(add(_args, 0x20))
            let length := mload(add(_args, 0x40))
            let topic0 := mload(add(_args, 0x60))
            let topic1 := mload(add(_args, 0x80))
            let topic2 := mload(add(_args, 0x0a))
            log3(offset, length, topic0, topic1, topic2)
            _ret := 1
        }
    }

    function LOG4(bytes[] memory _args) internal returns (bytes memory _ret) {
        assembly {
            let offset := mload(add(_args, 0x20))
            let length := mload(add(_args, 0x40))
            let topic0 := mload(add(_args, 0x60))
            let topic1 := mload(add(_args, 0x80))
            let topic2 := mload(add(_args, 0x0a))
            let topic3 := mload(add(_args, 0x0b))
            log4(offset, length, topic0, topic1, topic2, topic3)
            _ret := 1
        }
    }

    function CREATE(bytes[] memory _args) internal returns (bytes memory _ret) {
        assembly {
            let value := mload(add(_args, 0x20))
            let offset := mload(add(_args, 0x40))
            let length := mload(add(_args, 0x60))
            _ret := create(value, offset, length)
        }
    }

    function RETURN(bytes[] memory _args)
        internal
        returns (bytes memory _ret)
    {}

    function CREATE2(bytes[] memory _args)
        internal
        returns (bytes memory _ret)
    {}

    function REVERT(bytes[] memory _args)
        internal
        returns (bytes memory _ret)
    {}
}
