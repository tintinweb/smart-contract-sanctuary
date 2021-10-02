pragma solidity ^0.8.0;

contract counter {

    uint256 public counter  = 0;

    constructor(){
    }

    function increaseCounter() public {
        counter++;
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