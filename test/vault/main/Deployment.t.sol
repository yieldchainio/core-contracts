/**
 * Test the deployment and configurations of the vault contract
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../../src/vault/Vault.sol";
import "../../../src/vm/Encoders.sol";
import "../utilities/Dex.sol";
import "./Base.sol";
import "../../utils/Forks.t.sol";

contract TestVaultDeployment is Test, YieldchainTypes, YCVMEncoders {
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

    address public constant WETH_TOKEN_CONTRACT =
        0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address public constant DAI_TOKEN_ADDRESS =
        0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    // ==================
    //     CONSTRUCTOR
    // ==================

    Vault public vaultContract;
    uint256 networkID;

    function setUp() public {
        networkID = new Forks().ARBITRUM();
        vm.selectFork(networkID);
        vaultContract = new BaseStrategy().getVaultContract();
    }

    /**
     * Test the dry configurations
     */
    function testGenericConfigs() public {
        // Assert that the creator must be us
        assertEq(vaultContract.CREATOR(), address(this), "Creator Incorrect");

        // Assert that the deposit token must be gmx
        assertEq(
            address(vaultContract.DEPOSIT_TOKEN()),
            GMX_TOKEN_ADDRESS,
            "Deposit Token Incorrect"
        );

        // Assert that the publicty should be private
        assertFalse(vaultContract.isPublic(), "Privacy Incorrect");

        // Assert 
    }
}
