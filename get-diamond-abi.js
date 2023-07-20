import path from "path";
import fs from "fs";
import { exec, execSync } from "child_process";
import oldAbi from "./ABIs/diamond.json" assert { type: "json" };

function extractContractNames(bigString) {
  const regex = /contract\s+(\w+)\b(?:(?!\/\*|\/\/).)*\{/g;
  const contractNames = [];
  let match;

  while ((match = regex.exec(bigString)) !== null) {
    contractNames.push(match[1]);
  }

  return contractNames;
}

function extractArrayFromString(bigString) {
  const arrStartIdx = bigString.indexOf("[");
  const arrEndIdx = bigString.lastIndexOf("]");

  return JSON.parse(bigString.slice(arrStartIdx, arrEndIdx + 1));
}

const basePath = "src/diamond";

const paths = fs
  .readdirSync("src/diamond")
  .map((subpath) => `src/diamond/${subpath}`);

const abi = [];

for (const fileOrDir of paths) {
  if (!fs.statSync(fileOrDir).isFile()) {
    const contents = fs.readdirSync(fileOrDir);
    paths.push(...contents.map((subPath) => fileOrDir + `/${subPath}`));
    continue;
  } else {
  }

  if (
    fileOrDir.length < 4 ||
    fileOrDir.slice(fileOrDir.length - 4, fileOrDir.length) != ".sol"
  )
    continue;

  const contractsInFile = extractContractNames(
    fs.readFileSync(fileOrDir).toString()
  );

  const fileAbi = [];

  for (const contractName of contractsInFile) {
    const contractAbi = extractArrayFromString(
      execSync(`forge inspect ${fileOrDir}:${contractName} abi`).toString()
    );

    fileAbi.push(...contractAbi);
  }

  abi.push(...fileAbi);
}

console.log("New ABi Length, Old ABI Length", abi.length, oldAbi.length);

fs.writeFileSync("./ABIs/diamond.json", JSON.stringify(abi, null, 3), "utf8");
