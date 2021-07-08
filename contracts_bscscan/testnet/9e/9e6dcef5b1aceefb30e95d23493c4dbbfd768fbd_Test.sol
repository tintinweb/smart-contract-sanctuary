/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    
    address owner;
    
    
    constructor() {
        owner=msg.sender;
    }
    function test() public view returns (uint256){
        return owner.balance;
    }
    
    function test2() public view returns (uint256){
        return address(this).balance;
    }
    
    receive () external payable{
        
    }
    
    function test3(uint256 money) public {
        payable(owner).transfer(money);
    }
    
}