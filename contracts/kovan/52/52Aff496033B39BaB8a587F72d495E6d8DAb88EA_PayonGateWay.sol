/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract PayonGateWay{
    Payoner[] public payonUsers;
    struct Payoner {
        string _ID;
        address _WALLET;
    }
    function Create(string memory _id) public {
        Payoner memory newUser = Payoner(_id, msg.sender);
        payonUsers.push(newUser);
    }
}