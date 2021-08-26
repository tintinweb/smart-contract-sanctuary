pragma solidity ^0.5.17;

contract AddingTest {
    uint256 public num = 0;

    constructor() public {}

    function add() public {
        num = num + 1;
    }

    function addSpecific(uint256 num_) public {
        num = num + num_;
    }

    function addInternal() public {
        require(msg.sender == address(this), "Just from this contract");
        num = num + 100;
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