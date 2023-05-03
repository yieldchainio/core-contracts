// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../../src/vault/Vault.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../../src/vm/Encoders.sol";
import "../utilities/Dex.sol";

/**
 * Testing the access control of the vault contract,
 * i.e adding admins/moderators, etc
 */

contract AccessControlTest is Test, YieldchainTypes, YCVMEncoders {
    // ==================
    //     CONSTANTS
    // ==================

    Dex public dexContract;
    Vault public vaultContract;

    address public constant GMX_TOKEN_ADDRESS =
        0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;

    address public constant GMX_STAKING_CONTRACT =
        0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;

    address public constant GMX_REWARDS_ROUTER =
        0x908C4D94D34924765f1eDc22A1DD098397c59dD4;

    address public constant GNS_TOKEN_ADDRESS =
        0x18c11FD286C5EC11c3b683Caa813B77f5163A122;

    address public constant GNS_STAKING_CONTRACT =
        0x6B8D3C08072a020aC065c467ce922e3A36D3F9d6;

    // ==================
    //     CONSTRUCTOR
    // ==================
    constructor() {
        dexContract = new Dex();
        /**
         * @notice
         * Our example strategy will not be complex since we want this test ot be fully onchain.
         *
         * It will consist of the GMX and GNS protocols, and a dummy "DEX" contract that will be responsible
         * for returning a 1:1 rate of our tokens, and manually manipulating the balances
         */
        ERC20 depositToken = ERC20(GMX_TOKEN_ADDRESS);

        bool isPublic = false;

        address creator = msg.sender;

        /**
         * Seed steps:
         * 1) Stake 50% of deposited GMX into GMX
         */
        bytes[] memory SEED_STEPS = new bytes[](3);

        // Stake 50% of GMX into GMX Protocol
        bytes[] memory stakeGMXArgs = new bytes[](1);
        stakeGMXArgs[0] = encodeValueVar(new bytes(0));
        bytes memory stakeGMXCall = abi.encode(
            FunctionCall(
                GMX_STAKING_CONTRACT,
                stakeGMXArgs,
                "stakeGmx(uint256)"
            )
        );
        YCStep memory stakeGMX = YCStep(
            stakeGMXCall,
            new uint256[](0),
            new bytes[](0),
            false
        );

        SEED_STEPS[0] = abi.encode(stakeGMX);

        /**
         * Seed Steps:
         * 2) Swap Rest Of GMX Into GNS tokens
         * // TODO: How did we decide to do the token splitting onchain? completely forgot.
         */
        bytes[] memory swapToGNSArgs = new bytes[](3);

        swapToGNSArgs[0] = encodeRefValueVar(
            abi.encode(address(GMX_TOKEN_ADDRESS))
        );
        swapToGNSArgs[1] = encodeRefValueVar(
            abi.encode(address(GNS_TOKEN_ADDRESS))
        );
        swapToGNSArgs[2] = encodeRefValueVar(new bytes(0));

        // vaultContract = new Vault();
    }
}
