/**
 *Submitted for verification at polygonscan.com on 2021-11-23
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Faucet.sol
// SPDX-License-Identifier: GNU-3
pragma solidity >=0.4.23 >=0.8.6 <0.9.0;

////// lib/ds-auth/src/auth.sol
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity >=0.4.23; */

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

////// src/Faucet.sol
/* pragma solidity ^0.8.6; */

/* import "ds-auth/auth.sol"; */

interface TokenLike {
  function transfer(address dest, uint amt) external;
}

contract Faucet is DSAuth() {

  uint public maxpull;
  TokenLike public token;


  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x > y ? y : x;
  }

  function _pullTo(address dest, uint amt) internal {
    token.transfer(dest,min(amt,maxpull));
  }

  constructor(address _token, uint _maxpull) { 
    token = TokenLike(_token);
    maxpull = _maxpull;
  }

  function pull(uint amt) external {
    _pullTo(msg.sender,amt);
  }

  function pullTo(address dest, uint amt) external {
    _pullTo(dest,amt);
  }

  function drainTo(address dest, uint amt) external auth {
    token.transfer(dest, amt);
  }

  function setMaxpull(uint _maxpull) external auth {
    maxpull = _maxpull;
  }

  function setToken(address _token) external auth {
    token = TokenLike(_token);
  }

}