import {
  AbiCoder,
  Contract,
  JsonRpcProvider,
  Wallet,
  ZeroAddress,
  ZeroHash,
  ethers,
  keccak256,
} from "ethers";
import dotenv from "dotenv";
dotenv.config();

import VaultAbi from "./ABIs/vault.json" assert { type: "json" };
import DiamondABI from "./ABIs/diamond.json" assert { type: "json" };

const FUNCTIONCALL_TUPLE =
  "tuple(address target_address, bytes[] args, string signature)";

const STEP_TUPLE =
  "tuple(bytes func, uint256[] childrenIndices, bytes[] conditions, bool isCallback)";

const LIFI_TUPLE =
  "tuple(address callTo, address approveTo, address sendingAssetId, address receivingAssetId, uint256 fromAmount, bytes callData, bool requiresDeposit)";

const first = AbiCoder.defaultAbiCoder().decode(
  [FUNCTIONCALL_TUPLE],
  "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000009ec36eb173d52cdad980b6422d36d5d163375355000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000002400000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000022000076c8c96ea100a2e748b36505b3ce990c5abc5ff817de3f37c65b9b0c080f226a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000ff970a61a04b1ca14834a43f5de4533ebddb5cc800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000620101000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c686172766573744d61726b6574496e74657265737428627974657333322c616464726573732c6279746573290000000000000000000000000000000000000000"
);

// console.log(first);
// // console.log(second);

const provider = new JsonRpcProvider(process.env.ARBITRUM_RPC_URL);

const signer = new Wallet(process.env.PRIVATE_KEY, provider);

const contract = new Contract(
  "0x7c8bff049A4301205270c2AeB5388245BC8CfA20",
  [
    {
      inputs: [
        {
          internalType: "address",
          name: "sender",
          type: "address",
        },
        {
          internalType: "string[]",
          name: "urls",
          type: "string[]",
        },
        {
          internalType: "bytes",
          name: "callData",
          type: "bytes",
        },
        {
          internalType: "bytes4",
          name: "callbackFunction",
          type: "bytes4",
        },
        {
          internalType: "bytes",
          name: "extraData",
          type: "bytes",
        },
      ],
      name: "OffchainLookup",
      type: "error",
    },
    {
      inputs: [],
      name: "URL",
      outputs: [
        {
          internalType: "string",
          name: "",
          type: "string",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        {
          internalType: "bytes",
          name: "response",
          type: "bytes",
        },
        {
          internalType: "bytes",
          name: "extraData",
          type: "bytes",
        },
      ],
      name: "testCCIPRequest",
      outputs: [
        {
          internalType: "bytes",
          name: "retValue",
          type: "bytes",
        },
      ],
      stateMutability: "view",
      type: "function",
    },
  ],
  signer
);

const res = await contract.testCCIPRequest(
  ZeroHash,
  "0x1111111111111111111111111111111111111111111111111111111111111111",
  {
    enableCcipRead: true,
  }
);

console.log(res);

