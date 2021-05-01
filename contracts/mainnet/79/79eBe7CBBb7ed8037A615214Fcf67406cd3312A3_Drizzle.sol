/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

/// Drizzle.sol -- Drip all mcd collateral types

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

pragma solidity ^0.6.12;

interface Chainlog {
    function getAddress(bytes32) external returns (address);
}

interface IlkRegistry {
    function list() external view returns (bytes32[] memory);
}

interface PotLike {
    function drip() external;
}

interface JugLike {
    function drip(bytes32) external;
}

contract Drizzle {

    Chainlog    private constant  _chl = Chainlog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    IlkRegistry private immutable _reg;
    PotLike     private immutable _pot;
    JugLike     private immutable _jug;

    constructor() public {
        _reg = IlkRegistry(_chl.getAddress("ILK_REGISTRY"));
        _pot = PotLike(_chl.getAddress("MCD_POT"));
        _jug = JugLike(_chl.getAddress("MCD_JUG"));
    }

    function drizzle(bytes32[] memory ilks) public {
        _pot.drip();
        for (uint256 i = 0; i < ilks.length; i++) {
            _jug.drip(ilks[i]);
        }
    }

    function drizzle() external {
        bytes32[] memory ilks = _reg.list();
        drizzle(ilks);
    }

    function registry() external view returns (address) {
        return address(_reg);
    }

    function pot() external view returns (address) {
        return address(_pot);
    }

    function jug() external view returns (address) {
        return address(_jug);
    }
}