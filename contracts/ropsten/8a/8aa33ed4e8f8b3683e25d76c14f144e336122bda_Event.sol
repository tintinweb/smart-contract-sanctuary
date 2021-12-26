/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity  >=0.7.0 <0.9.0;

contract Event {
    event Log(address indexed sender,uint amount);


    function fn() external {
        emit Log(msg.sender, 200);
    }
}