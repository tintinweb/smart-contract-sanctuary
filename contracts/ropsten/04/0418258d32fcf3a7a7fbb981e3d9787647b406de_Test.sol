/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.11;

contract Test {
    address public owner;
    
    constructor() public {
        owner = msg.sender;    
    }
    
    function() external payable {}
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}