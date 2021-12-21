/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hello {
    struct Todo {
        string text;
        bool completed;
    }

    string public greeting = "";

    function udpateGreeting(Todo memory item) public {
        greeting = item.text;
    }
}