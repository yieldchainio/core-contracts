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

const LIFI_TUPLE =
  "tuple(address callTo, address approveTo, address sendingAssetId, address receivingAssetId, uint256 fromAmount, bytes callData, bool requiresDeposit)";

const first = AbiCoder.defaultAbiCoder().decode(
  [FUNCTIONCALL_TUPLE],
  "0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000baf45b60f69eca4616cde172d3961c156946e831000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000220000f68545786adf132bfd88a9ef87e4b51e9ffb00e409516ca6a4798d39c66d2b8200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000da10009cbd5d07dd0cecc66161fc93d7c9000da1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002462616c616e63654f664c5028627974657333322c616464726573732c616464726573732900000000000000000000000000000000000000000000000000000000"
);

const second = AbiCoder.defaultAbiCoder().decode(
  [FUNCTIONCALL_TUPLE],
  "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000002c00000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000016205000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000017fc002b466eec40dae837fc4be5c67993ddbd6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001262616c616e63654f6628616464726573732900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000024676574496e766573746d656e74416d6f756e742875696e743235362c75696e743235362900000000000000000000000000000000000000000000000000000000"
);

console.log(first);
// console.log(second);

const provider = new JsonRpcProvider(process.env.ARBITRUM_RPC_URL);
const signer = new Wallet(process.env.PRIVATE_KEY, provider);
const diamond = new Contract(
  "0xbAF45B60F69eCa4616CdE172D3961C156946e831",
  DiamondABI,
  signer
);
const receipt = await provider.getTransactionReceipt(
  "0xa673732cc11578b3f660fdc91ce3fe08c947d6f38ef4d32fbd03ea275c748918"
);

const log = receipt.logs.find(
  (log_) =>
    log_.topics[0] ==
    "0x0d606510f33b5e566ed1ca2b9e88d388ab81cea532909665d725b33134516aff"
);

console.log(AbiCoder.defaultAbiCoder().decode(["bytes"], log.data)[0]);



