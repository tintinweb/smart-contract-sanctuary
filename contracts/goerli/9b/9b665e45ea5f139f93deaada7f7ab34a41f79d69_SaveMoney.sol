/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.7;

contract SaveMoney{
    uint goal;
    constructor(uint _goal){
        goal=_goal;
    }
    
    receive() external payable{}
    
    
    
    function getMoney() public view returns (uint x){
        x=address(this).balance;
    }
    
    function withdraw() public{
        if(getMoney() > goal){
            selfdestruct(msg.sender);
        }
    }
    
}