/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract StartStopUpdateExample {
    
    address public owner;
    bool public paused;
    
    constructor() {
        owner = msg.sender;
    }
    
    function sendMoney() public payable {
        
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    
    function setPaused(bool _paused) public {
        require(msg.sender == owner, "You are not the owner");
        paused = _paused;
    }
    
    function withdrawAllMoney(address payable _to) public {
        require(msg.sender == owner, "You are not the owner");
        require(!paused, "Contract is paused");
        //require(paused == false, ...)
        _to.transfer(address(this).balance);
    }
    
    function destroySmartContract(address payable _to) public {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(_to);
    }
}