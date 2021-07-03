/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

contract UserDirectory {
    struct Contact {
        string email;
        string phone;
    }
    struct User {
        string name;
        address addr;
        Contact contact;
    }
    address _admin;
    mapping (address => User) _users;
    // User struct in the event
    event UserAdded(address indexed addr, User user);
    constructor() {
        _admin = msg.sender;
    }
    // User struct in the method signature
    function addUser(User calldata _user) public {
        require(msg.sender == _admin);
        _users[_user.addr] = _user;
        emit UserAdded(_user.addr, _user);
    }
    // User struct in the returns
    function user(address addr) external view returns (User memory _user) {
        return _users[addr];
    }
}