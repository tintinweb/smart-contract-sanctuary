// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./vlib/Ver2b.sol";

contract Ver2 is Ver2b {
  
  address private immutable _bridge;

  constructor() {
    _bridge = msg.sender;
  }

  function bridge() public view virtual returns (address) {
      return _bridge;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ver2b {
  
  function add2(uint256 num) public pure returns (uint256) {
      return num + num;
  }
}

{
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