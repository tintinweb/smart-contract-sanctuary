/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract eventTest {
    event Hello(uint a, address addressPath);

    function eventTests(uint a) public{
        emit Hello(a, msg.sender);
    }
}