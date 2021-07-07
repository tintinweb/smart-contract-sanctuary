/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    function test() public returns (uint256){
        return msg.sender.balance;
    }
    
    function test2() public returns (uint256){
        return address(this).balance;
    }
}