// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    uint amount;

    constructor (uint _startAmount) {
        amount = _startAmount;
    }

    function getAmount() public view returns(uint) {
        return amount;
    }

    function setAmount(uint _amount) public {
        amount = _amount;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
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