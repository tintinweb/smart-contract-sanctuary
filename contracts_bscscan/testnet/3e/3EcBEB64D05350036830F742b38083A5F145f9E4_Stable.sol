/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Stable {
    
    mapping(address => uint256) deposits;
    
    function Deposite() public payable {
        deposits[msg.sender] += msg.value;
    }
    
    function WithDraw() public {
        payable(msg.sender).transfer(deposits[msg.sender]);
        deposits[msg.sender] = 0;
    }
    
    
    
    
}