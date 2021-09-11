/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.4.0 <0.8.7;

contract Money{
    uint public goal;
    constructor(uint _goal){
        goal=_goal;
    }
    receive() external payable {}
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    
    function withdrwa() public {
        if(getBalance() > goal){
            selfdestruct(msg.sender);
        }
    }
    
    
    
}