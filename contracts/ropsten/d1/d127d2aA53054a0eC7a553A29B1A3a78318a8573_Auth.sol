/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Auth {

    // THESE EVENTS ARE EMITTED WHEN AUTH IS GRANTED / REVOKED
    event Granted(address user, uint8 role);
    event Revoked(address user);

    // CONTRACT STORAGE MAPPING ADDRESSES TO ROLES (0=revoked, 1=client, 2=cluster)
    mapping(address => uint8) private users;

    // GRANT CERTAIN ROLE TO AN ADDRESS
    function grant (address user, uint8 role) external {
        require(role > 0 && role <= 2);
        users[user] = role;
        emit Granted(user, role);
    }

    // REVOKE ANY ROLE OF AN ADDRESS
    function revoke (address user) external {
        users[user] = 0;
        emit Revoked(user);
    }

    // FUNCTION TO CHECK ANY ADDRESS ROLE
    function check (address user) external view returns (uint8) {
        return users[user];
    }
}