/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// Copyright (C) 2020 Centrifuge
//
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

pragma solidity >=0.5.15 <0.6.0;

// Copyright (C) 2018 Rain <[email protected]>
//
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

pragma solidity >=0.5.15 <0.6.0;

contract Math {
    uint256 constant ONE = 10 ** 27;

    function safeAdd(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x, "safe-add-failed");
    }

    function safeSub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x, "safe-sub-failed");
    }

    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }

    function safeDiv(uint x, uint y) public pure returns (uint z) {
        z = x / y;
    }

    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }

    function rdiv(uint x, uint y) public pure returns (uint z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }

    function rdivup(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }


}
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
//
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

pragma solidity >=0.5.15 <0.6.0;

/// note.sol -- the `note' modifier, for logging calls as events

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

pragma solidity >=0.4.23;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

contract Auth is DSNote {
    mapping (address => uint) public wards;
    function rely(address usr) public auth note { wards[usr] = 1; }
    function deny(address usr) public auth note { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }
}

contract Memberlist is Math, Auth {

    uint constant minimumDelay = 7 days;

    // -- Members--
    mapping (address => uint) public members;
    function updateMember(address usr, uint validUntil) public auth {
        require((safeAdd(block.timestamp, minimumDelay)) < validUntil);
        members[usr] = validUntil;
     }

    function updateMembers(address[] memory users, uint validUntil) public auth {
        for (uint i = 0; i < users.length; i++) {
            updateMember(users[i], validUntil);
        }
    }

    constructor() public {
        wards[msg.sender] = 1;
    }

    function member(address usr) public view {
        require((members[usr] >= block.timestamp), "not-allowed-to-hold-token");
    }

    function hasMember(address usr) public view returns (bool) {
        if (members[usr] >= block.timestamp) {
            return true;
        } 
        return false;
    }
}