// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


contract FaucetTest {
    mapping (address => bool) public whitelist;

    function setWhitelist(address account, bool whitelisted) external {
        whitelist[account] = whitelisted;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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