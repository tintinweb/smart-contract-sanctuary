/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    mapping (address => uint256) public numbers;
    
    function sendNumber(uint256 number) public {
        numbers[msg.sender] = number;
    }
}