// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../storage/StrategiesStorage.sol";
import "../../interfaces/ChainlinkAutomationInterface.sol";
import "../../../YC-Strategy/YC-Strategy-Logic.sol";
import "../../YC-Diamond-Interface.sol";
import "./StrategyFactoryFacet.sol";
import "../../interfaces/LinktokenInterface.sol";
import "../../interfaces/AutomationRegistryInterface2_0.sol";
import {ExecutorEnforcment} from "./ExecutorsManagementFacet.sol";
import "../../storage/AutomationStorage.sol";

interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;
}

/**
 * @notice
 * AutomationFacet
 * Is read from / written to by the all of the automation upkeeps, on the YC Diamond.
 */
contract AutomationFacet is AutomationCompatibleInterface, ExecutorEnforcment {
    // =====================================
    //             CONSTRUCTOR
    // =====================================
    constructor(
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryBaseInterface _registry
    ) {
        AutomationStorage storage automationStorage = AutomationStorageLib
            .getAutomationStorage();

        automationStorage.i_link = _link;
        automationStorage.registrar = _registrar;
        automationStorage.i_registry = _registry;
    }

    // =====================================
    //              ERRORS
    // =====================================
    error UpkeepNotSet();

    // =====================================
    //              MODIFIERS
    // =====================================
    // Enforce view-only simulation for checkUpKeep
    modifier cannotExecute() {
        require(tx.origin == address(0), "Only For Simulated Backend");
        _;
    }

    // Enforce execution of performUpKeep to the registry only
    modifier onlyKeeper() {
        // Get storage ref
        AutomationStorage storage automationStorage = AutomationStorageLib
            .getAutomationStorage();

        require(msg.sender == address(automationStorage.i_registry));
        _;
    }

    // ================================================
    //             GAS-RELATED FUNCTIONS
    // ================================================

    /**
     * @notice
     * Used to fund strategies' upkeeps' gas balances.
     * @param _amount The amount of LINK tokens to deposit
     * @param _strategyID - The ID of the strategy to fund.
     * isExecutor - Only called by YC executors.
     * note this is a *fullfill* function - The initial function is called on the strategy
     * contract, and has the deposited token swapped for LINK offchain. After which this function gets executed.
     */

    // TODO: Implement a transferAndCall compatiblity on this, instead of doing approval & transferFrom
    function fundStrategyGas(
        uint96 _amount,
        uint256 _strategyID
    ) external isExecutor {
        // Get storage ref for strategies
        StrategiesStorage storage strategiesStorage = StrategiesStorageLib
            .getStrategiesStorage();

        // Get the current strategy's details
        IStrategy memory currentStrategy = strategiesStorage.strategies[
            _strategyID
        ];

        // Upkeep ID of the strategy
        uint256 upkeepID = currentStrategy.upkeepID;

        // Requiring an upkeep to be set for the strategy.
        if (upkeepID == 0) revert UpkeepNotSet();

        // Get automation storage ref
        AutomationStorage storage automationStorage = AutomationStorageLib
            .getAutomationStorage();

        // Memory ref for i_registry
        AutomationRegistryBaseInterface i_registry = automationStorage
            .i_registry;

        // Transfer amount of I_LINK To us
        automationStorage.i_link.transferFrom(
            currentStrategy.contract_address,
            address(this),
            _amount
        );

        // Finally, fund the Upkeep
        i_registry.addFunds(upkeepID, _amount);
    }

    /**
     * @notice Get a strategy's upkeep's entire details
     * @dev May be consumed by frontends, as well as other helper "Shortcut" functions.
     * @param _strategyID - The ID of the strategy of which we want to get the gas balance of
     * @return upkeep_  the information about the upkeep.
     */
    function getStrategyUpkeepInfo(
        uint256 _strategyID
    ) public view returns (UpkeepInfo memory upkeep_) {
        // Get automation storage ref
        AutomationStorage storage automationStorage = AutomationStorageLib
            .getAutomationStorage();

        // Strategies Storage Ref
        StrategiesStorage storage strategiesStorage = StrategiesStorageLib
            .getStrategiesStorage();

        // Call the retreival function
        upkeep_ = automationStorage.i_registry.getUpkeep(
            strategiesStorage.strategies[_strategyID].upkeepID
        );
    }

    // =====================================
    //          AUTOMATION FUNCTIONS
    // =====================================

    /**
     * @notice
     * @CheckUpkeep
     * Called as a view function to simulate whether performUpkeep should be executed or not
     * @param checkData encoded bytes data inputted by the upkeep. Should equal to encoded strategy ID
     * @return upkeepNeeded a part of the Chainlink Keepers Interface, if this returns true in the simulation - it executes the performUpKeep
     * @return performData encoded bytes data passed from checkUpkeep to performUpKeep - encoded strategy ID again.
     */
    function checkUpkeep(
        bytes calldata checkData
    )
        public
        view
        override
        cannotExecute
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // Getting strategies storage
        StrategiesStorage storage strategiesStorage = StrategiesStorageLib
            .getStrategiesStorage();
        // Decoding checkData into a uint (Current Strategy ID being checked)
        uint256 strategyID = abi.decode(checkData, (uint256));

        // Getting strategy's struct object
        IStrategy memory currentStrategy = strategiesStorage.strategies[
            strategyID
        ];

        // Contract instance
        YCStrategyBase currentStrategyContract = currentStrategy
            .contract_instance;

        // If we should perform the execution (time passed since last execution >= interval...)
        if (currentStrategyContract.shouldPerform()) {
            upkeepNeeded = true;
            performData = checkData;
        }
    }

    /**
     * @notice
     * @performUpkeep
     * Gets called by checkUpkeep, runs the strategy when triggered by the keeper
     */
    function performUpkeep(
        bytes calldata performData
    ) external override onlyKeeper {
        // Re-validate the condition
        (bool isReady, ) = checkUpkeep(performData);
        require(isReady, "Condition Has Not Been Met!");

        // Decoding Strategy ID
        uint256 strategyID = abi.decode(performData, (uint256));

        // Interacting with a different facet
        StrategyFactory(address(this)).runStrategyByID(strategyID);
    }

    // =====================================
    //        REGISTRATION FUNCTIONS
    // =====================================
    /**
     * @notice
     * @registerAutomation
     * Used to initiate an upkeep for a strategy.
     */
    function registerAutomation(
        IStrategy memory _strategy,
        uint256 _amount
    ) external returns (uint256 _upkeepID) {
        // Sufficient check to not re-register upkeeps to strategies
        require(_strategy.upkeepID == 0, "Upkeep Already Initiated");

        // Get storage ref
        AutomationStorage storage automationStorage = AutomationStorageLib
            .getAutomationStorage();

        // Memory ref of i_registry (gas opt)
        AutomationRegistryBaseInterface i_registry = automationStorage
            .i_registry;

        // Getting the state of the registry
        // @notice All variables here except the state one are unused (We want to get the nonce)
        (
            State memory state,
            OnchainConfig memory _c,
            address[] memory _k,
            address[] memory _b,
            uint8 _u
        ) = i_registry.getState();
        uint256 oldNonce = state.nonce;

        // Encoding paylod for registering the upkeep
        bytes memory payload = abi.encode(
            _strategy.title,
            bytes32(0),
            address(this),
            uint256(2 ** 256 - 1), // TODO: Make this some base fee that makes sense. Otherwise gotta do some offchain calc and pass in constructor per strategy.
            address(this),
            _strategy.id,
            _amount,
            0
        );

        // Transfer the LINK amount and call the registry - registering the upkeep
        automationStorage.i_link.transferAndCall(
            automationStorage.registrar,
            _amount,
            bytes.concat(automationStorage.registerSig, payload)
        );

        // Getting the state after calling
        (state, _c, _k, _b, _u) = i_registry.getState();

        // Confirm the nonce has indeed changed
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            // Compute the upkeep ID
            _upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(i_registry),
                        uint32(oldNonce)
                    )
                )
            );
        } else {
            revert("auto-approve disabled");
        }
    }
}
