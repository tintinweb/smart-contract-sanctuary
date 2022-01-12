// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./TransparentUpgradeableProxy.sol";

contract StakingProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) TransparentUpgradeableProxy(logic, admin, data) {}
}