// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// @unsupported: ovm
pragma solidity >=0.7.6;

interface ApproveLike {
  function approve(address, uint256) external;
}

// Escrow funds on L1, manage approval rights

contract L1Escrow {
    
  // --- Auth ---
  mapping (address => uint256) public wards;
  function rely(address usr) external auth {
    wards[usr] = 1;
    emit Rely(usr);
  }
  function deny(address usr) external auth {
    wards[usr] = 0;
    emit Deny(usr);
  }
  modifier auth {
    require(wards[msg.sender] == 1, "L1Escrow/not-authorized");
    _;
  }

  event Rely(address indexed usr);
  event Deny(address indexed usr);
  
  constructor() {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);
  }

  function approve(
    address token,
    address spender,
    uint256 value
  ) public auth {
    ApproveLike(token).approve(spender, value);
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