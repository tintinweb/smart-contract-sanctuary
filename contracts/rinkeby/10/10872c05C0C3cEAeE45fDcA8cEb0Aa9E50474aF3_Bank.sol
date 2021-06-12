pragma solidity 0.5.16;

contract Bank{
    int bal;

    constructor() public{
        bal = 1;
    }

    function getBalance() view public returns(int) {
        return bal;
    }

    function withdraw(int amt) public {
        bal = bal - amt;
    }

    function deposit(int amt) public {
        bal = bal + amt;
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