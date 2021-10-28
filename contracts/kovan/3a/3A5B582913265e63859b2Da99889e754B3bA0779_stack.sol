/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

contract stack {
    address owner;
    uint startTimestamp;
    
    // historic block.timestamp > qty
    mapping(uint=> uint) whitelist;  
    
    constructor() {
        owner = msg.sender; 
        startTimestamp = block.timestamp;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can withdraw');
        _;
    }
    
    function withdrawAll() public onlyOwner {
        require(block.timestamp > startTimestamp + 90 days, 'Withdraw not allowed');
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function sendfunds() public payable { 
        whitelist[block.timestamp] = msg.value;
    }
}