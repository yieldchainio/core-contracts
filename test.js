import {
  AbiCoder,
  Contract,
  JsonRpcProvider,
  Wallet,
  ZeroAddress,
  ethers,
} from "ethers";
import dotenv from "dotenv";
dotenv.config();

import VaultAbi from "./ABIs/vault.json" assert { type: "json" };
import DiamondABI from "./ABIs/diamond.json" assert { type: "json" };

const FUNCTIONCALL_TUPLE =
  "tuple(address target_address, bytes[] args, string signature)";

const STEP_TUPLE =
  "tuple(bytes func, uint256[] childrenIndices, bytes[] conditions, bool isCallback)";

const first = AbiCoder.defaultAbiCoder().decode(
  [FUNCTIONCALL_TUPLE],
  "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000006c0000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000028000000000000000000000000000000000000000000000000000000000000002e0000000000000000000000000000000000000000000000000000000000000034000000000000000000000000000000000000000000000000000000000000000220000c4c78ff9617ac5cfc537390c0a1eca93887dcf10fcec2a2edc42e42b7843c9c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006201010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000d7969656c64636861696e2e696f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008201010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002a3078303030303030303030303030303030303030303030303030303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000a34dd6731b097280e1263cecccd095f5c07a7bd80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000002cac32d6850b1ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c201010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000001b02da8cb0d097eb8d57a175b88c7d8b479975060000000000000000000000001b02da8cb0d097eb8d57a175b88c7d8b47997506000000000000000000000000ff970a61a04b1ca14834a43f5de4533ebddb5cc8000000000000000000000000da10009cbd5d07dd0cecc66161fc93d7c9000da10000000000000000000000000000000000000000000000000000000000030d4000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000014438ed17390000000000000000000000000000000000000000000000000000000000030d4000000000000000000000000000000000000000000000000002cac32d6850b1ff00000000000000000000000000000000000000000000000000000000000000a00000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae00000000000000000000000000000000000000000000000000000000649a79d10000000000000000000000000000000000000000000000000000000000000004000000000000000000000000ff970a61a04b1ca14834a43f5de4533ebddb5cc8000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9000000000000000000000000d4d42f0b6def4ce0383636770ef773390d85c61a000000000000000000000000da10009cbd5d07dd0cecc66161fc93d7c9000da100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006f73776170546f6b656e7347656e6572696328627974657333322c737472696e672c737472696e672c616464726573732c75696e743235362c28616464726573732c616464726573732c616464726573732c616464726573732c75696e743235362c62797465732c626f6f6c295b5d290000000000000000000000000000000000"
);

// console.log(first);

const provider = new JsonRpcProvider(process.env.ARBITRUM_RPC_URL);
const signer = new Wallet(process.env.PRIVATE_KEY, provider);
const diamond = new Contract(
  "0xbAF45B60F69eCa4616CdE172D3961C156946e831",
  DiamondABI,
  signer
);
const vaultAddress = "0xA34dD6731B097280E1263CecCCD095f5c07a7BD8";

const vaultContract = new Contract(vaultAddress, VaultAbi, signer);

const deposit = await vaultContract.deposit(200000n, {
  enableCcipRead: true,
});

const depositReceipt = await deposit.wait();

console.log(`Done:`, `https://arbiscan.io/tx/${depositReceipt.hash}`);

// const res = await diamond.fundGasBalance(vaultAddress, {
//   value: 2 * 10 ** 15,
// });

// const receipt = await res.wait();

// if (receipt.status) console.log("Funded Vault's Gas Balance...");
// else throw "Funding Vault Gas Balance Failed On Hash " + receipt.hash;

// const runTxn = await diamond.executeStrategiesTriggers.populateTransaction(
//   [10],
//   [[true]]
// );

// const gasLimit = await diamond.executeStrategiesTriggers.estimateGas(
//   [10],
//   [[true]]
// );

// runTxn.gasLimit = gasLimit * 4n;

// const runRes = await signer.sendTransaction(runTxn);

// const runReceipt = await runRes.wait();

// if (runReceipt.status)
//   console.log(
//     "Run Strategy At Hash",
//     `https://arbiscan.io/tx/${runReceipt.hash}`
//   );
// else throw "Couldnt run strategy";

// const ddd = await vaultContract.getVirtualStepsTree(1);
const offchainLookupEncoded =
  "0x000000000000000000000000a34dd6731b097280e1263cecccd095f5c07a7bd800000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000140fbcdbabf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002d687474703a2f2f6c6f63616c686f73743a383038302f6f6666636861696e2d616374696f6e732f7b646174617d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000a34dd6731b097280e1263cecccd095f5c07a7bd8000000000000000000000000000000000000000000000000000000000000a4b1000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000e00000000000000000000000001231deb6f5749ef6ce6943a275a1d3e7486f4eae00000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000086c696669537761700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000ff970a61a04b1ca14834a43f5de4533ebddb5cc8000000000000000000000000da10009cbd5d07dd0cecc66161fc93d7c9000da10000000000000000000000000000000000000000000000000000000000030d4000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000030d40";
const offchainLookup = AbiCoder.defaultAbiCoder().decode(
  ["address", "string[]", "bytes", "bytes4", "bytes"],
  offchainLookupEncoded
);

// console.log(offchainLookup)

const offchainRequestEncoded = offchainLookup[2];
const offchainRequest = AbiCoder.defaultAbiCoder().decode(
  [
    "tuple(address initiator, uint256 chainId, uint256 stepIndex, bytes[] cachedOffchainCommands, address callTargetAddress, string signature, bytes args)",
  ],
  offchainRequestEncoded
);
// console.log("Res", offchainRequestEncoded);
