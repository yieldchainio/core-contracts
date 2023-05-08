// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import "../../../src/Types.sol";
import "../../../src/vm/Constants.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
contract ERC20 is Constants {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    // ======================
    //     YCVM ENCODERS
    // ======================

    function encodeApprovalForYCVM(
        bytes memory ycCommandAddress,
        bytes memory ycCommandAmount
    ) public view returns (bytes memory) {
        // The args for the functioncall
        bytes[] memory args = new bytes[](2);

        // Transform the spender address arg into simple YC command
        args[0] = ycCommandAddress;

        // Transform the amount arg into simple YC command
        args[1] = ycCommandAmount;

        FunctionCall memory approvalCall = FunctionCall(
            address(this),
            args,
            "approve(address,uint256)"
        );

        return
            bytes.concat(
                CALL_COMMAND_FLAG, // Call Command (state-changing)
                VALUE_VAR_FLAG, // No return value (Cheapest flag)
                abi.encode(approvalCall) // Encoded approval call
            );
    }

    function encodeTransferForYCVM(
        bytes memory ycCommandReceiver,
        bytes memory ycCommandAmount
    ) public view returns (bytes memory) {
        // The args for the functioncall
        bytes[] memory args = new bytes[](2);

        args[0] = ycCommandReceiver;
        args[1] = ycCommandAmount;

        FunctionCall memory transferCall = FunctionCall(
            address(this),
            args,
            "transfer(address,uint256)"
        );

        return
            bytes.concat(
                CALL_COMMAND_FLAG, // Call Command (state-changing)
                VALUE_VAR_FLAG, // No return value (Cheapest flag)
                abi.encode(transferCall) // Encoded transfer call
            );
    }

    function encodeTransferFromForYCVM(
        bytes memory ycCommandFrom,
        bytes memory ycCommandTo,
        bytes memory ycCommandAmount
    ) public view returns (bytes memory) {
        // The args for the functioncall
        bytes[] memory args = new bytes[](3);

        args[0] = ycCommandFrom;
        args[1] = ycCommandTo;
        args[2] = ycCommandAmount;

        FunctionCall memory transferFromCall = FunctionCall(
            address(this),
            args,
            "transferFrom(address,address,uint256)"
        );

        return
            bytes.concat(
                CALL_COMMAND_FLAG, // Call Command (state-changing)
                VALUE_VAR_FLAG, // No return value (Cheapest flag)
                abi.encode(transferFromCall) // Encoded transferFrom call
            );
    }

    function encodeBalanceOfForYCVM(
        bytes memory ycCommandAddress
    ) public view returns (bytes memory) {
        // The args for the function call
        bytes[] memory args = new bytes[](1);

        args[0] = ycCommandAddress;

        FunctionCall memory balanceOfStaticCall = FunctionCall(
            address(this),
            args,
            "balanceOf(address)"
        );

        return
            bytes.concat(
                STATICCALL_COMMAND_FLAG, // Static call Command (non state changing)
                VALUE_VAR_FLAG, // Value variable return value (uint)
                abi.encode(balanceOfStaticCall) // Encoded balanceOf staticcall
            );
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mint(msg.sender, initialSupply);

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}
