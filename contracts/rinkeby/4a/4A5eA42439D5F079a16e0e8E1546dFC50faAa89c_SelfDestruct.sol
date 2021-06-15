// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract SelfDestruct {
  address payable public owner;

  constructor() payable {
    owner = payable(msg.sender);
  }

  receive() external payable {}

  fallback() external payable {}

  function withdraw() public {
    owner.transfer(address(this).balance);
    address payable addr = payable(address(this));
    selfdestruct(addr);
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}