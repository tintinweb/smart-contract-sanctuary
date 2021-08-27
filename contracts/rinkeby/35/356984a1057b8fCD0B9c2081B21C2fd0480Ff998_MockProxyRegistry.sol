// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title MockProxyRegistry
 * @author MirrorXYZ
 */
contract MockProxyRegistry {
    /// @notice Authenticated proxies by user.
    mapping(address => address) public proxies;

    function registerProxy(address proxy) external {
        proxies[msg.sender] = proxy;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 2000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}