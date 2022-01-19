// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1967Proxy.sol";
import "./TransparentUpgradeableProxy.sol";
import "./ProxyAdmin.sol";

// Kept for backwards compatibility with older versions of Hardhat and Truffle plugins.
contract AdminUpgradeabilityProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) payable TransparentUpgradeableProxy(logic, admin, data) {}
}