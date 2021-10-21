/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// Verified using https://dapp.tools

// hevm: flattened sources of /nix/store/3ivni8dlkyh85w9c3b7lbq7m8s47qyxs-geb-pit/dapp/geb-pit/src/TokenBurner.sol
pragma solidity >=0.6.7 <0.7.0;

////// /nix/store/3ivni8dlkyh85w9c3b7lbq7m8s47qyxs-geb-pit/dapp/geb-pit/src/TokenBurner.sol
/// TokenBurner.sol -- a simple token burner

// Copyright (C) 2017  Rain Break <[email protected]>

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

/* pragma solidity ^0.6.7; */

abstract contract BurntToken {
    function burn(uint) virtual public;
    function balanceOf(address) virtual public view returns (uint);
}

contract TokenBurner {
    function burn(address token) public {
        BurntToken(token).burn(BurntToken(token).balanceOf(address(this)));
    }
}