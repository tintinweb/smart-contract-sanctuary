/**
 *Submitted for verification at Etherscan.io on 2019-11-26
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/MkrAuthority.sol
pragma solidity >=0.4.23 >=0.5.10 >=0.5.10 <0.6.0;

////// src/MkrAuthority.sol
/// MkrAuthority -- custom authority for MKR token access control

// Copyright (C) 2019 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity ^0.5.10; */

contract MkrAuthority {
  address public root;
  modifier sudo { require(msg.sender == root); _; }
  event LogSetRoot(address indexed newRoot);
  function setRoot(address usr) public sudo {
    root = usr;
    emit LogSetRoot(usr);
  }

  mapping (address => uint) public wards;
  event LogRely(address indexed usr);
  function rely(address usr) public sudo { wards[usr] = 1; emit LogRely(usr); }
  event LogDeny(address indexed usr);
  function deny(address usr) public sudo { wards[usr] = 0; emit LogDeny(usr); }

  constructor() public {
    root = msg.sender;
  }

  // bytes4(keccak256(abi.encodePacked('burn(address,uint256)')))
  bytes4 constant burn = bytes4(0x9dc29fac);
  // bytes4(keccak256(abi.encodePacked('mint(address,uint256)')))
  bytes4 constant mint = bytes4(0x40c10f19);

  function canCall(address src, address dst, bytes4 sig)
      public view returns (bool)
  {
    if (sig == burn || src == root) {
      return true;
    } else if (sig == mint) {
      return (wards[src] == 1);
    } else {
      return false;
    }
  }
}