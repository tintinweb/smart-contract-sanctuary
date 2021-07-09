pragma solidity ^0.8.0;

contract VerifyFail 
{
    uint public data;
    uint256 public createdDate;

    constructor() {
        data = 0;
        createdDate = block.timestamp;
    }

    function set(uint x) public {
        data = x;
    }

    function get() public view returns (uint) {
        return data;    
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