// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;

// import "forge-std/Script.sol";
// import "lib/solidity-stringutils/strings.sol";

// contract SomeScript is Script {
//     using strings for *;

//     function run() external {
//         string[] memory cmd = new string[](4);
//         cmd[0] = "forge";
//         cmd[1] = "inspect";
//         cmd[2] = "FactoryFacet";
//         cmd[3] = "methods";
//         bytes memory res = vm.ffi(cmd);
//         string memory st = string(res);

//         // extract function signatures and take first 4 bytes of keccak
//         strings.slice memory s = st.toSlice();

//         console.log(st);

//         // Skip TRACE lines if any
//         strings.slice memory nl = "\n".toSlice();
//         strings.slice memory trace = "TRACE".toSlice();

//         while (s.contains(trace)) {
//             s.split(nl);
//         }

//         strings.slice memory colon = ":".toSlice();
//         strings.slice memory comma = ",".toSlice();
//         strings.slice memory dbquote = '"'.toSlice();
//         bytes4[] memory selectors = new bytes4[]((s.count(colon)));

//         for (uint i = 0; i < selectors.length; i++) {
//             s.split(dbquote); // advance to next doublequote
//             // split at colon, extract string up to next doublequote for methodname
//             strings.slice memory method = s.split(colon).until(dbquote);
//             console.log(method.toString());
//             selectors[i] = bytes4(method.keccak());
//             s.split(comma).until(dbquote); // advance s to the next comma
//         }
//     }
// }
