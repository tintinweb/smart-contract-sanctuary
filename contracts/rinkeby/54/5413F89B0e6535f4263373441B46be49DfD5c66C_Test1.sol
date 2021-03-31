// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Test {

  uint256 public a;
  constructor(uint256 _a) public {
      a = _a;
  }

  function add(uint256 _b) public {
      a += _b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./Test.sol";

contract Test1 {

  uint256 public a;
  address public test;
  constructor(uint256 _a, address _test) public {
      a = _a;
      test = _test;
  }

  function add(uint256 _b) public {
      a += _b;
  }

  function addTest(uint256 _b) public {
        Test(_b).add(_b);  
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