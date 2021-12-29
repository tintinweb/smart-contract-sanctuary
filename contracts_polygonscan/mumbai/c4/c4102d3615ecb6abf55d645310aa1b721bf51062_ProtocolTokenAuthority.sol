/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// Verified using https://dapp.tools

// hevm: flattened sources of /nix/store/ixnp9z85s69jvfxw5dmz7lixp28fkil1-geb-protocol-token-authority/dapp/geb-protocol-token-authority/src/ProtocolTokenAuthority.sol

pragma solidity >=0.6.7 <0.7.0;

////// /nix/store/ixnp9z85s69jvfxw5dmz7lixp28fkil1-geb-protocol-token-authority/dapp/geb-protocol-token-authority/src/ProtocolTokenAuthority.sol
/// ProtocolTokenAuthority -- custom authority for protocol token access control

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

/* pragma solidity ^0.6.7; */

contract ProtocolTokenAuthority {
  address public root;
  address public owner;

  modifier isRootCalling { require(msg.sender == root); _; }
  modifier isRootOrOwnerCalling { require(msg.sender == root || owner == msg.sender); _; }

  event SetRoot(address indexed newRoot);
  event SetOwner(address indexed newOwner);

  function setRoot(address usr) public isRootCalling {
    root = usr;
    emit SetRoot(usr);
  }
  function setOwner(address usr) public isRootOrOwnerCalling {
    owner = usr;
    emit SetOwner(usr);
  }

  mapping (address => uint) public authorizedAccounts;

  event AddAuthorization(address indexed usr);
  function addAuthorization(address usr) public isRootOrOwnerCalling { authorizedAccounts[usr] = 1; emit AddAuthorization(usr); }
  event RemoveAuthorization(address indexed usr);
  function removeAuthorization(address usr) public isRootOrOwnerCalling { authorizedAccounts[usr] = 0; emit RemoveAuthorization(usr); }

  constructor() public {
    root = msg.sender;
    emit SetRoot(msg.sender);
  }

  // bytes4(keccak256(abi.encodePacked('burn(uint256)')))
  bytes4 constant burn = bytes4(0x42966c68);
  // bytes4(keccak256(abi.encodePacked('burn(address,uint256)')))
  bytes4 constant burnFrom = bytes4(0x9dc29fac);
  // bytes4(keccak256(abi.encodePacked('mint(address,uint256)')))
  bytes4 constant mint = bytes4(0x40c10f19);

  function canCall(address src, address, bytes4 sig)
      public view returns (bool)
  {
    if (sig == burn || sig == burnFrom || src == root || src == owner) {
      return true;
    } else if (sig == mint) {
      return (authorizedAccounts[src] == 1);
    } else {
      return false;
    }
  }
}