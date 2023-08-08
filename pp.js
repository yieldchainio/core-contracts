import path from "path";
import fs from "fs";
import { exec, execSync } from "child_process";
import oldAbi from "./ABIs/diamond.json" assert { type: "json" };
import axios from "axios";
import { Contract, JsonRpcProvider } from "ethers";

const PROD_READY_COMMENT = "// @production-facet";

function extractContractNames(bigString) {
  const regex =
    /\/\/ @production-facet\s*\ncontract\s+(\w+)\b(?:(?!\/\*|\/\/).)*\{/g;

  const contractNames = [];
  let match;

  while ((match = regex.exec(bigString)) !== null) {
    contractNames.push(match[1]);
  }

  return contractNames;
}

function extractArrayFromString(bigString) {
  const arrStartIdx = bigString.indexOf("{");
  const arrEndIdx = bigString.lastIndexOf("}");

  return JSON.parse(bigString.slice(arrStartIdx, arrEndIdx + 1));
}

const basePath = "src/diamond/facets";

const paths = fs
  .readdirSync(basePath)
  .map((subpath) => `${basePath}/${subpath}`);

const selToContractPath = new Map();

const abi = [];

for (const fileOrDir of paths) {
  if (!fs.statSync(fileOrDir).isFile()) {
    const contents = fs.readdirSync(fileOrDir);
    paths.push(...contents.map((subPath) => fileOrDir + `/${subPath}`));

    continue;
  }
  if (
    fileOrDir.length < 4 ||
    fileOrDir.slice(fileOrDir.length - 4, fileOrDir.length) != ".sol"
  )
    continue;

  const contractsInFile = extractContractNames(
    fs.readFileSync(fileOrDir).toString()
  );

  console.log("Prod Ready Contracts", contractsInFile);

  for (const contractName of contractsInFile) {
    const contracMethods = Object.entries(
      extractArrayFromString(
        execSync(
          `forge inspect ${fileOrDir}:${contractName} methods`
        ).toString()
      )
    );

    for (const method of contracMethods) {
      abi.push(method);
      [selToContractPath.set(`0x${method}`, `${fileOrDir}:${contractName}`)];
    }
  }
}

const missingSelectors = [];

const provider = new JsonRpcProvider(
  "https://arb-mainnet.g.alchemy.com/v2/Bva4kx5jvnUcfxDPwzW_iTO94JAw3ACP"
);

const contract = new Contract(
  "0xbAF45B60F69eCa4616CdE172D3961C156946e831",
  oldAbi,
  provider
);

const onchainFacets = await contract.facets();

const existingSels = Array.from(onchainFacets).flatMap((val) => val[1]);

console.log(existingSels);

for (const [name, sel] of abi) {
  // console.log(
  //   `Iterating over sel 0x${sel}. Is found in existing: ${sels.some(
  //     (_sel) => _sel == `0x${sel}`
  //   )}`
  // );
  if (!existingSels.some((_sel) => _sel == `0x${sel}`)) {
    console.log("Missing Selector:", name);
    missingSelectors.push(`0x${sel}`);
  }
}

console.log("Missing sels", missingSelectors);
