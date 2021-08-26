//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract Box {
    uint256 private value;
    event ValueChanged(uint256 newValue);

    

    function init(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }


    function retrieve() public view returns (uint256) {
        return value;
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