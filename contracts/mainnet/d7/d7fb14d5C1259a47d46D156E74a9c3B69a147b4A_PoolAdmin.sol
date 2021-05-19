/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// Copyright (C) 2020 Centrifuge
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

interface AssessorLike {
    function file(bytes32 name, uint256 value) external;
}

interface LendingAdapterLike {
    function raise(uint256 amount) external;
    function sink(uint256 amount) external;
    function heal() external;
}

interface MemberlistLike {
    function updateMember(address usr, uint256 validUntil) external;
    function updateMembers(address[] calldata users, uint256 validUntil) external;
}

// Wrapper contract for various pool management tasks.
contract PoolAdmin is Auth {
  
    AssessorLike public assessor;
    LendingAdapterLike public lending;
    MemberlistLike public seniorMemberlist;
    MemberlistLike public juniorMemberlist;

    bool public live = true;

    // Admins can manage pools, but have to be added and can be removed by any ward on the PoolAdmin contract
    mapping(address => uint256) public admins;

    // Events
    event File(bytes32 indexed what, bool indexed data);
    event RelyAdmin(address indexed usr);
    event DenyAdmin(address indexed usr);
    event SetMaxReserve(uint256 value);
    event RaiseCreditline(uint256 amount);
    event SinkCreditline(uint256 amount);
    event HealCreditline();
    event UpdateSeniorMember(address indexed usr, uint256 validUntil);
    event UpdateSeniorMembers(address[] indexed users, uint256 validUntil);
    event UpdateJuniorMember(address indexed usr, uint256 validUntil);
    event UpdateJuniorMembers(address[] indexed users, uint256 validUntil);

    constructor() public {
        wards[msg.sender] = 1;
    }

    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "assessor") {
            assessor = AssessorLike(addr);
        } else if (contractName == "lending") {
            lending = LendingAdapterLike(addr);
        } else if (contractName == "seniorMemberlist") {
            seniorMemberlist = MemberlistLike(addr);
        } else if (contractName == "juniorMemberlist") {
            juniorMemberlist = MemberlistLike(addr);
        } else revert();
    }

    function file(bytes32 what, bool data) public auth {
        live = data;
        emit File(what, data);
    }

    modifier admin { require(admins[msg.sender] == 1 && live); _; }

    function relyAdmin(address usr) public auth {
        admins[usr] = 1;
        emit RelyAdmin(usr);
    }

    function denyAdmin(address usr) public auth {
        admins[usr] = 0;
        emit DenyAdmin(usr);
    }

    // Manage max reserve
    function setMaxReserve(uint256 value) public admin {
        assessor.file("maxReserve", value);
        emit SetMaxReserve(value);
    }

    // Manage creditline
    function raiseCreditline(uint256 amount) public admin {
        lending.raise(amount);
        emit RaiseCreditline(amount);
    }

    function sinkCreditline(uint256 amount) public admin {
        lending.sink(amount);
        emit SinkCreditline(amount);
    }

    function healCreditline() public admin {
        lending.heal();
        emit HealCreditline();
    }

    // Manage memberlists
    function updateSeniorMember(address usr, uint256 validUntil) public admin {
        seniorMemberlist.updateMember(usr, validUntil);
        emit UpdateSeniorMember(usr, validUntil);
    }

    function updateSeniorMembers(address[] memory users, uint256 validUntil) public admin {
        seniorMemberlist.updateMembers(users, validUntil);
        emit UpdateSeniorMembers(users, validUntil);
    }

    function updateJuniorMember(address usr, uint256 validUntil) public admin {
        juniorMemberlist.updateMember(usr, validUntil);
        emit UpdateJuniorMember(usr, validUntil);
    }

    function updateJuniorMembers(address[] memory users, uint256 validUntil) public admin {
        juniorMemberlist.updateMembers(users, validUntil);
        emit UpdateJuniorMembers(users, validUntil);
    }
    
}