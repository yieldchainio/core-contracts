import { AbiCoder } from "ethers";

const deploymentCalldata = process.argv[2];

let noFuncSel = deploymentCalldata.slice(10, deploymentCalldata.length);

const iterationAmtsToChangePtr = 4;

let currentPtr = 0;

let newChunck = "";

for (let i = 0; i < iterationAmtsToChangePtr; i++) {
  const prevPtr = noFuncSel.slice(currentPtr, currentPtr + 64);

  const decodedNum = AbiCoder.defaultAbiCoder().decode(
    ["uint256"],
    "0x" + prevPtr
  )[0];
  console.log(decodedNum);

  console.log(decodedNum + 32n);

  const newPtr = AbiCoder.defaultAbiCoder().encode(
    ["uint256"],
    [decodedNum + 32n]
  );

  newChunck += newPtr.slice(2, newPtr.length);
  currentPtr += 64;
}

newChunck += noFuncSel.slice(64 * 4, 64 * 6);

newChunck += "000000000000000000000000634176ecc95d326cae16829d923c1373df6ece95";

newChunck += noFuncSel.slice(64 * 6, noFuncSel.length);


console.log("0x" + newChunck);


