/**
 * Manages vaults' gas balances, and gas fees stuff
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../vault/Vault.sol";
import "../../storage/Strategies.sol";
import "../../storage/Users.sol";
import "../../storage/GasManager.sol";
import "../../AccessControlled.sol";

// @production-facet
contract GasManagerFacet is AccessControlled {
    /**
     * @notice
     * Fund a vault's native gas balance (Used to fund trigger runs)
     * @param strategyAddress - Address of the strategy to fund
     */
    function fundGasBalance(address strategyAddress) public payable {
        /**
         * Shorthand for strategies storage
         */
        StrategiesStorage storage strategiesStorage = StrategiesStorageLib
            .retreive();
        /**
         * Storage ref to our strategy in the mapping
         */
        StrategyState storage strategy = strategiesStorage.strategiesState[
            Vault(strategyAddress)
        ];

        /**
         * Require the strategy to exist
         */
        require(strategy.registered, "Vault Does Not Exist");

        /**
         * Finally, increment the gas balance in the amount provided
         */
        strategy.gasBalanceWei += msg.value;
    }

    /**
     * Set the current hook used to return additional gas costs incurred in the txn
     * (useful for L2s)
     * @param newHook - The new hook to set
     */
    function setGasHook(IGasHook newHook) external onlyOwner {
        GasManagerStorageLib.retreive().gasHook = newHook;
    }
}
