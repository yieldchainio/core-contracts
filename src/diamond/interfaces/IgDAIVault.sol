/**
 * A gDAI-like LP vault interface
 */

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface GTokenVault {
    struct LockedDeposit {
        address someAddress;
        uint256 someUint;
        uint256 someOtherUint;
    }

    function deposit(uint assets, address receiver) external returns (uint);

    function withdraw(
        uint assets,
        address receiver,
        address owner
    ) external returns (uint);

    function redeem(
        uint shares,
        address receiver,
        address owner
    ) external returns (uint);

    function makeWithdrawRequest(uint shares, address owner) external;

    function depositWithDiscountAndLock(
        uint assets,
        uint lockDuration,
        address receiver
    ) external returns (uint);

    function mintWithDiscountAndLock(
        uint shares,
        uint lockDuration,
        address receiver
    ) external returns (uint);

    function unlockDeposit(uint depositId, address receiver) external;

    function sendAssets(uint assets, address receiver) external;

    function receiveAssets(uint assets, address user) external;

    function getLockedDeposit(
        uint depositId
    ) external view returns (LockedDeposit memory);

    function tvl() external view returns (uint);

    function availableAssets() external view returns (uint);

    function currentBalanceDai() external view returns (uint);

    function marketCap() external view returns (uint);
}
