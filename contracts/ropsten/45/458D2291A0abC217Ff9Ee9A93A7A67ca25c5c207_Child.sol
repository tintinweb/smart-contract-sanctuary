pragma solidity >=0.7.0;

contract Child {
    uint256 public data;

    // use this function instead of the constructor
    // since creation will be done using createClone() function
    function init(uint256 _data) external {
        data = _data;
    }
}

{
  "optimizer": {
    "enabled": true,
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