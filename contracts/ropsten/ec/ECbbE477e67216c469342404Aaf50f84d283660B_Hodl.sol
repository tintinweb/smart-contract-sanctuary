/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodl{
    string creator;
    address payable creator_address;
    
    address[] all_address;
    mapping(address=>string) address_name;
    
    constructor(string memory name){
        creator = name;
        creator_address = payable(msg.sender);
    }
    
    fallback() external payable {
    }
    
    receive() external payable {
    }
     
    function f(uint start, uint daysAfter) public 
    {
        if (  block.timestamp >= start + daysAfter * 365 days) {
                selfdestruct(creator_address); 
            }
    }
}