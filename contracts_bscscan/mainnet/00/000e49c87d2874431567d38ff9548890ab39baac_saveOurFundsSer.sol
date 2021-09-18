/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract saveOurFundsSer {
    
    address owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function withdraw() external {
        require(msg.sender == owner);
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
}