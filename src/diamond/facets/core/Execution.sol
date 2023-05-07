/**
 * Facet to handle execution of strategies.
 * Acts as a bridge between executors and the strategies
 */

// SPDX-License-Identifier: MITs
pragma solidity ^0.8.18;
import "../../Modifiers.sol";
import "../../storage/Strategies.sol";
import "./Factory.sol";

contract Execution is Modifiers {
    // ===================
    //     CONSTANTS
    // ===================
    // Cost of making an ether transfer
    uint256 internal constant ETHER_TRANSFER_COST = 28925;

    // Cost of storing a gas approximation on the vault contract
    uint256 internal constant GAS_APPROXIMATION_STORAGE_COST = 30000;

    /**
     * @notice
     * hydrateAndExecuteRun()
     * Hydrates w offchain-computed commands & executes a strategy's operation run
     * @param strategy - Address of the strategy
     * @param operationIndex - The index of the operation within the strategy's Operations state
     * @param commandCalldatas - The offchain pre-computed YC Commands that should be used for the offchain-related steps, if any.
     */
    function hydrateAndExecuteRun(
        Vault strategy,
        uint256 operationIndex,
        bytes[] memory commandCalldatas
    ) external onlyExecutors {
        /**
         * @notice
         * @dev
         * We Save a variable for the initial gas on the transaction, to keep track later
         * on of how much it costs, and update balances/compensate accordingly
         */
        uint256 initialGas = gasleft() * tx.gasprice;

        // Storage ref shorthand
        StrategiesStorage storage strategiesStorage = StrategiesStorageLib
            .getStrategiesStorage();

        // Make sure the strategy is registered
        require(
            strategiesStorage.strategiesState[strategy].registered,
            "Strategy Does Not Exist"
        );

        // Request the operation execution on the vault contract, and receive it executed
        OperationItem memory operation = strategy.hydrateAndExecuteRun(
            operationIndex,
            commandCalldatas
        );

        /**
         * @dev
         * We have a switch case regarding what type of operation this was - Each case should do the following:
         * 1) Get the gas used by this execution by deducing the initialGas variable by the gasLeft()
         * 2) Compensate the executor for the gas used, withdraw the ether from the vault
         * 3) Deduct the vault's gas balance for any gas not provided in the request
         * 4) Update the gas approximation state variables on the vault for that operation (+ 5000 GWEI (in WEI!!), to account for the storage update)
         */

        // If it a deposit/withdrawal, the gas should have been sponsored by the inititaor
        if (
            operation.action == ExecutionTypes.SEED ||
            operation.action == ExecutionTypes.UPROOT
        ) {
            // We send all of the sponsored gas to us
            strategy.claimOperationGas(
                operationIndex,
                payable(address(this)),
                operation.gas
            );

            // Store the gas used (+ the cost of storing it) in the vault contract for future approximations
            strategy.storeGasApproximation(
                operation.action,
                gasleft() +
                    ETHER_TRANSFER_COST +
                    GAS_APPROXIMATION_STORAGE_COST *
                    tx.gasprice
            );

            // The gas that was spent up until now (+ the cost of an ether transfer)
            uint256 gasSpent = initialGas -
                gasleft() +
                ETHER_TRANSFER_COST *
                tx.gasprice;

            // We send gas cost to executor
            payable(msg.sender).transfer(gasSpent);
        }
        // Else if it's a strategy run, we deduct the gas from the vault's gas balance
        else {
            // The amount of gas we should transfer
            uint256 gasSpent = initialGas -
                gasleft() +
                ETHER_TRANSFER_COST *
                tx.gasprice;

            // Deduct it from the vault's gas balance and send to the executor
            VaultFactory(address(this)).deductAndTransferVaultGas(
                strategy,
                payable(msg.sender),
                gasSpent
            );
        }

        // We reimbruse remaining gas to initiator if there's any left for a transfer
        // Note 1000 is just some safety delta
        if (gasleft() * tx.gasprice > ETHER_TRANSFER_COST + 1000 * tx.gasprice)
            payable(operation.initiator).transfer(
                gasleft() - ETHER_TRANSFER_COST * tx.gasprice
            );
    }
}
