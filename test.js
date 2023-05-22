import { AbiCoder, Contract, JsonRpcProvider, ethers } from "ethers";
import dotenv from "dotenv";
dotenv.config();
import VaultAbi from "./ABIs/vault.json" assert { type: "json" };

const FUNCTIONCALL_TUPLE =
  "tuple(address target_address, bytes[] args, string signature)";

const STEP_TUPLE =
  "tuple(bytes func, uint256[] childrenIndices, bytes[] conditions, bool isCallback)";

const LIFI_TUPLE =
  "tuple(address callTo, address approveTo, address sendingAssetId, address receivingAssetId, uint256 fromAmount, bytes callData, bool requiresDeposit)";

const root = AbiCoder.defaultAbiCoder().decode(
  [STEP_TUPLE],
  "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000"
);

const indexOne = AbiCoder.defaultAbiCoder().decode(
  [STEP_TUPLE],
  "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000920000000000000000000000000000000000000000000000000000000000000094000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000862060000000000000000000000000000000000000000000000000000000000000000200000000000000000000000006b8d3c08072a020ac065c467ce922e3a36d3f9d600000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000722050000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000006a00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000004800000000000000000000000000000000000000000000000000000000000000402050000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000003800000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000002a00000000000000000000000000000000000000000000000000000000000000222050000000000000000000000000000000000000000000000000000000000000000200000000000000000000000006b8d3c08072a020ac065c467ce922e3a36d3f9d6000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000001c00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000e2050000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000673656c6628290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e7573657273286164647265737329000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002165787472616374576f72644174496e6465782862797465732c75696e7432353629000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000162080000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000054d4c4f41440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000024676574496e766573746d656e74416d6f756e742875696e743235362c75696e7432353629000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016756e7374616b65546f6b656e732875696e74323536290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
);

const indexFour = AbiCoder.defaultAbiCoder().decode(
  [FUNCTIONCALL_TUPLE],
  "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000003800000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000002a00000000000000000000000000000000000000000000000000000000000000222050000000000000000000000000000000000000000000000000000000000000000200000000000000000000000006b8d3c08072a020ac065c467ce922e3a36d3f9d6000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000001c00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000e2050000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000673656c6628290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e7573657273286164647265737329000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002165787472616374576f72644174496e6465782862797465732c75696e743235362900000000000000000000000000000000000000000000000000000000000000"
);

console.log("Root", root);
console.log("Idx 1", indexOne);
console.log("idx 4", indexFour);

// const address = "0x9592Cf2951eF6ABd5DfC414dB56770f24470a2A7";

// const provider = new JsonRpcProvider(process.env.ARBITRUM_RPC_URL);
// const strategyContract = new Contract(address, VaultAbi, provider);

// console.log(
//   await strategyContract.extractWordAtIndex.staticCall(
//     "0x00000000000000000000000000000000000000000000000000ba2f0654d6c642000000000000000000000000000000000000000000000000001e7e1194a91b970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f6b7bad5",
//     0
//   ),
//   "Data:",
//   (
//     await strategyContract.extractWordAtIndex.populateTransaction(
//       "0x00000000000000000000000000000000000000000000000000ba2f0654d6c642000000000000000000000000000000000000000000000000001e7e1194a91b970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f6b7bad5",
//       0
//     )
//   ).data
// );
// 0x4c2cd7af
// 00000000000000000000000000000000000000000000000000ba176fa7291347
// 000000000000000000000000000000000000000000000000001e7a4d34cabc8a
// 0000000000000000000000000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000000

// 0x
// 00000000000000000000000000000000000000000000000000ba176fa7291347
// 000000000000000000000000000000000000000000000000001e7a4d34cabc8a
// 0000000000000000000000000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000000
// 0000000000000000000000000000000000000000000000000000000000000000