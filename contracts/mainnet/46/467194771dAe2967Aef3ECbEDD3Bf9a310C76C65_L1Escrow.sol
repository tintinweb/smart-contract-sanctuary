// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// @unsupported: ovm
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

  event Approve(address indexed token, address indexed spender, uint256 value);
  
  constructor() {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);
  }

  function approve(
    address token,
    address spender,
    uint256 value
  ) external auth {
    emit Approve(token, spender, value);

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