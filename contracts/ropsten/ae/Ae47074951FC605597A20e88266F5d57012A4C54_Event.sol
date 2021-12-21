/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Event {
    //  Event declaration
    //  up to 3 parameters can be indexed
    //  Indexed parameters helps you filter the logs by the indexed parameter
    event Log(address indexed sender, string message);
    event AnotherLog();

    function test() public {
        //  emit an event
        emit Log(msg.sender, "Hello blockchain");
        emit Log(msg.sender, "Hello EVM");
        emit AnotherLog();
    }
}