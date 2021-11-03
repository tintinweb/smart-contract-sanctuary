/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract StartStopUpdate {
    
    address public owner;
    bool public paused;
    
    constructor() {
        owner = msg.sender;
    }
    
    function sendMoney() public payable {
        
    }
    
    function setPaused(bool _paused) public {
        require (msg.sender == owner, "Du bist nicht der Besitzer" );
        paused = _paused;
    }
    
    function withdrawAllMoney(address payable _to) public {
        require(owner == msg.sender, "Du bist nicht der Besitzer");
        require(paused == false, "Vertrag anhalten");
        _to.transfer(address(this).balance);
    }
    
    function destroySmartContract(address payable _to) public {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(_to);
    }
    
    function getBalance () public view returns(uint){
        return address(this).balance;
    }
    
    function withdrawMoney() public {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
    
    function withdrawMoneyTo(address payable _to) public {
        _to.transfer(getBalance());
    }
}