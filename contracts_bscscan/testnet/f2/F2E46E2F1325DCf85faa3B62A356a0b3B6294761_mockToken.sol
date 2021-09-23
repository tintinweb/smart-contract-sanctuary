// SPDX-License-Identifier: NONLICENSED
pragma solidity ^0.8.6;


contract mockToken{
    constructor(){}

    fallback() external payable {
    }
    receive() external payable {
    }

    function sendTo(address _to, uint256 amount) public {
        payable(_to).transfer(amount);
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}