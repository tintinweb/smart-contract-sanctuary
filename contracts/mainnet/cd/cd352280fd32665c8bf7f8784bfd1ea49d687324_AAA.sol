pragma solidity ^0.4.24;

library CCC {
  function addCCC(uint256 a, uint256 b) pure returns (uint256) {
    uint256 c = a - b;
    return c;
  }
}

contract AAA {
    function aa() constant returns (uint256) {
        uint256 x = 50;
        return CCC.addCCC(50, x);
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 0
  },
  "metadata": {
    "bytecodeHash": "none"
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
  "libraries": {
    "CCC.sol": {
      "CCC": "0x7560aF28d77e1B0a452bD3D7D4dc96FF86815379"
    }
  }
}