import {
  AbiCoder,
  Contract,
  Interface,
  JsonRpcProvider,
  Wallet,
  ZeroAddress,
  ZeroHash,
  ethers,
} from "ethers";
import dotenv from "dotenv";
import axios from "axios";
dotenv.config();

import VaultAbi from "./ABIs/vault.json" assert { type: "json" };
import DiamondABI from "./ABIs/diamond.json" assert { type: "json" };

const FUNCTIONCALL_TUPLE =
  "tuple(address target_address, bytes[] args, string signature)";

const STEP_TUPLE =
  "tuple(bytes func, uint256[] childrenIndices, bytes[] conditions, bool isCallback, bytes mvc)";

const first = AbiCoder.defaultAbiCoder().decode(
  [STEP_TUPLE],
  "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000066000000000000000000000000000000000000000000000000000000000000006a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000006c00000000000000000000000000000000000000000000000000000000000000582060000000000000000000000000000000000000000000000000000000000000000200000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000005200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000018c11fd286c5ec11c3b683caa813b77f5163a1220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000342050000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000002c00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000162050000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001262616c616e63654f6628616464726573732900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000c80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000024676574496e766573746d656e74416d6f756e742875696e743235362c75696e74323536290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000086c6966695377617000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e205000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000baf45b60f69eca4616cde172d3961c156946e831000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f76616c69646174654c6966697377617043616c6c646174612862797465732900000000000000000000000000000000000000000000000000000000000000"
);

// console.log(first);

const provider = new JsonRpcProvider(process.env.ARBITRUM_RPC_URL);
const signer = new Wallet(process.env.PRIVATE_KEY, provider);
const diamond = new Contract(
  "0xbAF45B60F69eCa4616CdE172D3961C156946e831",
  DiamondABI,
  signer
);
const vaultAddress = "0x36828b6ED78857A7e1C0eFDd4c008e73A79af307";

const vaultContract = new Contract(vaultAddress, VaultAbi, signer);

const encoded =
  "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000620000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000028000000000000000000000000000000000000000000000000000000000000002e0000000000000000000000000000000000000000000000000000000000000034000000000000000000000000000000000000000000000000000000000000000220000b96eefb601afd3f517c09658ba6194b5a8d3b090b56794b6d7e6921f69845636000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006201010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000d7969656c64636861696e2e696f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008201010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002a3078303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000a34dd6731b097280e1263cecccd095f5c07a7bd80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000002c2fe9e475a4a62000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022201010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001111111254eeb25477b68fb85ed929f73a9605820000000000000000000000001111111254eeb25477b68fb85ed929f73a960582000000000000000000000000ff970a61a04b1ca14834a43f5de4533ebddb5cc8000000000000000000000000da10009cbd5d07dd0cecc66161fc93d7c9000da10000000000000000000000000000000000000000000000000000000000030d4000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a8e449022e0000000000000000000000000000000000000000000000000000000000030d4000000000000000000000000000000000000000000000000002c2fe9e475a4a6200000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001800000000000000000000000f0428617433652c9dc6d1093a42adfbf30d29f742e9b3012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006f73776170546f6b656e7347656e6572696328627974657333322c737472696e672c737472696e672c616464726573732c75696e743235362c28616464726573732c616464726573732c616464726573732c616464726573732c75696e743235362c62797465732c626f6f6c295b5d290000000000000000000000000000000000";

// const sendTransaction = async (data, address) => {
//   const res = await signer.sendTransaction({
//     to: address,
//     data: data,
//     gasLimit: 12000000,
//   });

//   const receipt = await res.wait();

//   console.log(`Done: https://arbiscan.io/tx/${receipt.hash}`);
// };

// await sendTransaction(
//   "0xa9fabe3b00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000002f969e00000000000000000000000000000000000000000000000000000000000000000",
//   "0xbAF45B60F69eCa4616CdE172D3961C156946e831"
// );

const iface = new Interface(DiamondABI);

console.log(
  iface.parseError(
    "0x4e487b710000000000000000000000000000000000000000000000000000000000000011"
  )
);
