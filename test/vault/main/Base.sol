/**
 * Base contract to inherit from for all strategy test,
 * provides an example strategy
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../../src/vault/Vault.sol";
import "../../../src/vm/Encoders.sol";
import "../utilities/Dex.sol";
import "../utilities/Encoders.sol";
import "../../vm/utilities/ERC20.sol";
import "forge-std/console.sol";

contract BaseStrategy is UtilityEncoder {
    function setUp() public {}

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

    address public constant WETH_TOKEN_CONTRACT =
        0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address public constant DAI_TOKEN_ADDRESS =
        0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    // ==================
    //     CONSTRUCTOR
    // ==================
    constructor() {}

    function getVaultContract() public returns (Vault contractVault) {
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

        /**
         * Seed steps:
         * 1) Stake 50% of deposited GMX into GMX
         */
        bytes[] memory SEED_STEPS = new bytes[](4);

        /**
         * @notice
         * we reuse this variable to avoid stack too deep
         */
        uint256[] memory childrenIndices = new uint256[](0);

        childrenIndices = new uint256[](2);
        childrenIndices[0] = 1;
        childrenIndices[1] = 2;
        SEED_STEPS[0] = abi.encode(
            YCStep(encodeSelfCommand(), childrenIndices, new bytes[](0), false)
        );

        bytes[] memory funcArgs = new bytes[](0);

        // Stake 50% of GMX into GMX Protocol
        funcArgs = new bytes[](1);
        // @notice we encode using getInvestmentAmount() on balanceOf() on GMX, on our address, with a divisor of 2
        funcArgs[0] = encodeGetInvestmentAmount(
            encodeBalanceOf(address(depositToken)),
            200
        );

        SEED_STEPS[1] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            GMX_STAKING_CONTRACT,
                            funcArgs,
                            "stakeGmx(uint256)"
                        )
                    )
                ),
                new uint256[](0),
                new bytes[](0),
                false
            )
        );

        /**
         * Seed Steps:
         * 2) Swap Rest Of GMX Into GNS tokens
         */
        funcArgs = new bytes[](3);

        funcArgs[0] = encodeValueVar(abi.encode(address(GMX_TOKEN_ADDRESS)));
        funcArgs[1] = encodeValueVar(abi.encode(address(GNS_TOKEN_ADDRESS)));
        funcArgs[2] = encodeGetInvestmentAmount(
            encodeBalanceOf(address(depositToken)),
            100
        );

        childrenIndices = new uint256[](1);
        childrenIndices[0] = 3;

        SEED_STEPS[2] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            address(dexContract),
                            funcArgs,
                            "swap(address,address,uint256)"
                        )
                    )
                ),
                childrenIndices,
                new bytes[](0),
                false
            )
        );

        // We now stake the GNS we got from the swap
        funcArgs = new bytes[](1);
        funcArgs[0] = encodeGetInvestmentAmount(
            encodeBalanceOf(GNS_TOKEN_ADDRESS),
            100
        );

        SEED_STEPS[3] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            GNS_STAKING_CONTRACT,
                            funcArgs,
                            "stakeTokens(uint256)"
                        )
                    )
                ),
                new uint256[](0),
                new bytes[](0),
                false
            )
        );

        /**
         * @notice
         * We move onto strategy body,
         * Where we harvest tokens from GMX, swap the WETH from it to other GMX, then restake. And also, swap DAI from GNS to GNS, and restake.
         */
        bytes[] memory STEPS = new bytes[](7);

        childrenIndices = new uint256[](2);
        childrenIndices[0] = 1;
        childrenIndices[1] = 2;
        STEPS[0] = abi.encode(
            YCStep(encodeSelfCommand(), childrenIndices, new bytes[](0), false)
        );

        funcArgs = new bytes[](7);
        funcArgs[0] = encodeValueVar(abi.encode(true));
        funcArgs[1] = encodeValueVar(abi.encode(false));
        funcArgs[2] = encodeValueVar(abi.encode(true));
        funcArgs[3] = encodeValueVar(abi.encode(false));
        funcArgs[4] = encodeValueVar(abi.encode(false));
        funcArgs[5] = encodeValueVar(abi.encode(true));
        funcArgs[6] = encodeValueVar(abi.encode(false));

        childrenIndices = new uint256[](1);
        childrenIndices[0] = 3;

        STEPS[1] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            GMX_STAKING_CONTRACT,
                            funcArgs,
                            "handleRewards(bool,bool,bool,bool,bool,bool,bool)"
                        )
                    )
                ),
                childrenIndices,
                new bytes[](0),
                false
            )
        );

        funcArgs = new bytes[](3);
        funcArgs[0] = encodeValueVar(abi.encode(WETH_TOKEN_CONTRACT));
        funcArgs[1] = encodeValueVar(abi.encode(GMX_TOKEN_ADDRESS));
        funcArgs[2] = encodeGetInvestmentAmount(
            encodeBalanceOf(WETH_TOKEN_CONTRACT),
            100
        );

        childrenIndices = new uint256[](1);
        childrenIndices[0] = 4;

        STEPS[3] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            address(dexContract),
                            funcArgs,
                            "swap(address,address,uint256)"
                        )
                    )
                ),
                childrenIndices,
                new bytes[](0),
                false
            )
        );

        funcArgs = new bytes[](1);
        funcArgs[0] = encodeGetInvestmentAmount(
            encodeBalanceOf(address(depositToken)),
            100
        );

        STEPS[4] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            GMX_STAKING_CONTRACT,
                            funcArgs,
                            "stakeGmx(uint256)"
                        )
                    )
                ),
                new uint256[](0),
                new bytes[](0),
                false
            )
        );

        childrenIndices = new uint256[](1);
        childrenIndices[0] = 5;
        STEPS[2] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            GNS_STAKING_CONTRACT,
                            new bytes[](0),
                            "harvest()"
                        )
                    )
                ),
                childrenIndices,
                new bytes[](0),
                false
            )
        );

        childrenIndices = new uint256[](1);
        childrenIndices[0] = 6;
        funcArgs = new bytes[](3);
        funcArgs[0] = encodeValueVar(abi.encode(DAI_TOKEN_ADDRESS));
        funcArgs[1] = encodeValueVar(abi.encode(GNS_TOKEN_ADDRESS));
        funcArgs[2] = encodeGetInvestmentAmount(
            encodeBalanceOf(DAI_TOKEN_ADDRESS),
            100
        );

        STEPS[5] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            address(dexContract),
                            funcArgs,
                            "swap(address,address,uint256)"
                        )
                    )
                ),
                childrenIndices,
                new bytes[](0),
                false
            )
        );

        // We reuse the one from the seed steps
        STEPS[6] = SEED_STEPS[3];

        /**
         * Create the reverse strategy
         */
        bytes[] memory UPROOT_STEPS = new bytes[](6);

        // We withdraw GNS staking, swap GNS to GMX, Swap DAI to GMX,
        // then withdraw GMX staking, swap WETH to GMX.
        funcArgs = new bytes[](1);
        bytes[] memory amountGetterArgs = new bytes[](1);
        amountGetterArgs[0] = encodeSelfCommand();
        funcArgs[0] = encodeFirstWordExtracter(
            encodeValueStaticCall(
                abi.encode(
                    FunctionCall(
                        GNS_STAKING_CONTRACT,
                        amountGetterArgs,
                        "users(address)"
                    )
                )
            )
        );
        // The root uproot command
        childrenIndices = new uint256[](2);
        childrenIndices[0] = 1;
        childrenIndices[1] = 2;

        UPROOT_STEPS[0] = abi.encode(
            YCStep(encodeSelfCommand(), childrenIndices, new bytes[](0), false)
        );

        childrenIndices = new uint256[](2);
        childrenIndices[0] = 3;
        childrenIndices[1] = 4;
        UPROOT_STEPS[1] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            GNS_STAKING_CONTRACT,
                            funcArgs,
                            "unstakeTokens(uint256)"
                        )
                    )
                ),
                childrenIndices,
                new bytes[](0),
                false
            )
        );

        funcArgs = new bytes[](3);
        funcArgs[0] = encodeValueVar(abi.encode(DAI_TOKEN_ADDRESS));
        funcArgs[1] = encodeValueVar(abi.encode(GMX_TOKEN_ADDRESS));
        funcArgs[2] = encodeGetInvestmentAmount(
            encodeBalanceOf(DAI_TOKEN_ADDRESS),
            100
        );

        UPROOT_STEPS[3] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            address(dexContract),
                            funcArgs,
                            "swap(address,address,uint256)"
                        )
                    )
                ),
                new uint256[](0),
                new bytes[](0),
                false
            )
        );

        funcArgs = new bytes[](3);
        funcArgs[0] = encodeValueVar(abi.encode(GNS_TOKEN_ADDRESS));
        funcArgs[1] = encodeValueVar(abi.encode(GMX_TOKEN_ADDRESS));
        funcArgs[2] = encodeGetInvestmentAmount(
            encodeBalanceOf(GNS_TOKEN_ADDRESS),
            100
        );

        UPROOT_STEPS[4] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            address(dexContract),
                            funcArgs,
                            "swap(address,address,uint256)"
                        )
                    )
                ),
                new uint256[](0),
                new bytes[](0),
                false
            )
        );

        childrenIndices = new uint256[](1);
        childrenIndices[0] = 5;
        funcArgs = new bytes[](1);

        amountGetterArgs = new bytes[](1);
        amountGetterArgs[0] = encodeSelfCommand();

        funcArgs[0] = encodeValueStaticCall(
            abi.encode(
                FunctionCall(
                    GMX_REWARDS_ROUTER,
                    amountGetterArgs,
                    "stakedAmounts(address)"
                )
            )
        );

        UPROOT_STEPS[2] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            GMX_STAKING_CONTRACT,
                            funcArgs,
                            "unstakeGmx(uint256)"
                        )
                    )
                ),
                new uint256[](0),
                new bytes[](0),
                false
            )
        );

        funcArgs = new bytes[](3);
        funcArgs[0] = encodeValueVar(abi.encode(WETH_TOKEN_CONTRACT));
        funcArgs[1] = encodeValueVar(abi.encode(GMX_TOKEN_ADDRESS));
        funcArgs[2] = encodeGetInvestmentAmount(
            encodeBalanceOf(WETH_TOKEN_CONTRACT),
            100
        );

        UPROOT_STEPS[5] = abi.encode(
            YCStep(
                encodeCall(
                    abi.encode(
                        FunctionCall(
                            address(dexContract),
                            funcArgs,
                            "swap(address,address,uint256)"
                        )
                    )
                ),
                new uint256[](0),
                new bytes[](0),
                false
            )
        );

        // Create pairs of approval
        address[2][] memory approvalPairs = new address[2][](6);

        approvalPairs[0] = [GMX_TOKEN_ADDRESS, GMX_STAKING_CONTRACT];

        approvalPairs[1] = [GMX_TOKEN_ADDRESS, GMX_REWARDS_ROUTER];

        approvalPairs[2] = [GNS_TOKEN_ADDRESS, GNS_STAKING_CONTRACT];

        approvalPairs[3] = [GNS_TOKEN_ADDRESS, address(dexContract)];

        approvalPairs[4] = [DAI_TOKEN_ADDRESS, address(dexContract)];

        approvalPairs[5] = [WETH_TOKEN_CONTRACT, address(dexContract)];

        // We deploy the vault contract
        return
            new Vault(
                STEPS,
                SEED_STEPS,
                UPROOT_STEPS,
                approvalPairs,
                IERC20(address(depositToken)),
                isPublic,
                msg.sender
            );
    }
}
