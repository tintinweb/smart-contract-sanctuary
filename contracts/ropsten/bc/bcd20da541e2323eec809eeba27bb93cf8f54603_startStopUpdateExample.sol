/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.24;

contract startStopUpdateExample {
    address public owner;
    bool public paused;
    uint256 amount = 1 ether;
    mapping (address => uint256) private userbalance;
    constructor() public {
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
    
    function withdrawAllMoney(address  _to) public payable  {
        require(msg.sender == owner, "You are not an owner");
        require(paused == false, "Contract is paused");
        _to.transfer(address(this).balance);   
    }
    
    function destroySmartContract(address  to) public  payable {
         require(msg.sender == owner, "You are not an owner");
       selfdestruct(to);
    
    }
    
    function sendBackEther(address to)   external payable{
        require(msg.sender==to);
       if(userbalance[to]>=amount) {
            to.transfer(0.1 ether);
       }
    }
}