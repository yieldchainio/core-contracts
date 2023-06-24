// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IPool} from "lib/aave-v3-core/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "lib/aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";

interface IRadiantV2PoolAddressesProvider is IPoolAddressesProvider {
    function getLendingPool() external view returns (IPool pool);
}
