pragma solidity ^0.6.0;

contract Counter {

    address owner;    // current owner of the contract
    uint256 count;  // persistent contract storage

    constructor(uint256 _count) public { // contract's constructor function
        count = _count;
        owner = msg.sender;
    }

    function increment() public {
        require(owner == msg.sender,'Only owner can be increase this counter!');
        count += 1;
    }

    function getCount() public view returns (uint256) {
        return count;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
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