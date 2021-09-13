//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

contract MaGo{
    uint256 number;

    function getNum() public view returns (uint256){
        return number;
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