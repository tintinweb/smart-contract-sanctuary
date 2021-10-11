/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract BellRinger {
    uint public bellCounter;
    event BellRung(uint count, address ringer);
    
    function ringBell () public {
        bellCounter = bellCounter + 1;
        emit BellRung(bellCounter, msg.sender);
    }
}