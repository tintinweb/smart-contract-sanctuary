/**
 *Submitted for verification at polygonscan.com on 2021-11-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TestContract {

    mapping(address => string) public users;
    
    function addUser(string memory userName) public {
        users[msg.sender] = userName;
    }

}