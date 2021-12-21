/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hello {
    string greeting = "";

    function udpateGreeting(string[] memory names) public {
        for (uint i = 0; i < names.length; i++) {
            greeting = names[i];
        }
    }
}