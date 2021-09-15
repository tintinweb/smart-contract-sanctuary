/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract startStopUpdateExample {
    address public owner;
    bool public paused;
    
    constructor(){
        owner = msg.sender;
        paused = false;
    }
    
    function sendMoney() public payable {
        require(paused == false, "Contract is paused");
        }
    
    
    function setPaused(bool _paused) public view{
        require(msg.sender == owner, "You are not an owner");
        _paused = paused;
    }
    
    function withdrawAllMoney(address payable _to) public  {
        require(msg.sender == owner, "You are not an owner");
        require(paused == false, "Contract is paused");
        _to.transfer(address(this).balance);   
    }
    
    function selfDestruct(address payable _to) public {
         require(msg.sender == owner, "You are not an owner");
       selfDestruct(_to);
    
    }
}