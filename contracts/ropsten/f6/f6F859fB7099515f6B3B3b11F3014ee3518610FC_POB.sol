pragma solidity ^0.5.15;

/*
POB contract handles all the proof of burn related functionality
*/
contract POB {
    address public coordinator;

    constructor() public {
        coordinator = msg.sender;
    }

    function getCoordinator() public view returns (address) {
        return coordinator;
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