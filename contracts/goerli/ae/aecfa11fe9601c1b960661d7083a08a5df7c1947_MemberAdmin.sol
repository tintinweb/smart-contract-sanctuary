/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/lender/admin/member.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15 >=0.6.12;

////// lib/tinlake-auth/src/auth.sol
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
/* pragma solidity >=0.5.15; */

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

////// src/lender/admin/member.sol
/* pragma solidity >=0.6.12; */

/* import "tinlake-auth/auth.sol"; */

interface MemberlistLike_2 {
    function updateMember(address usr, uint validUntil) external;
    function updateMembers(address[] calldata users, uint validUntil) external;
}

// Wrapper contract for permission restriction on the memberlists.
contract MemberAdmin is Auth {
    constructor() {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // Admins can manipulate memberlists, but have to be added and can be removed by any ward on the MemberAdmin contract
    mapping (address => uint) public admins;

    event RelyAdmin(address indexed usr);
    event DenyAdmin(address indexed usr);

    modifier admin { require(admins[msg.sender] == 1); _; }

    function relyAdmin(address usr) public auth {
        admins[usr] = 1;
        emit RelyAdmin(usr);
    }

    function denyAdmin(address usr) public auth {
        admins[usr] = 0;
        emit DenyAdmin(usr);
    }

    function updateMember(address list, address usr, uint validUntil) public admin {
        MemberlistLike_2(list).updateMember(usr, validUntil);
    }

    function updateMembers(address list, address[] memory users, uint validUntil) public admin {
        MemberlistLike_2(list).updateMembers(users, validUntil);
    }
}