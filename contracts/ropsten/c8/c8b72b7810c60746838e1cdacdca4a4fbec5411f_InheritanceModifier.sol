/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

contract InheritanceModifier{
    address owner; 
    uint tokenPrice =  1 ether;
    mapping(address => uint) public tokenBalance;
    

    constructor(){
        owner = msg.sender;
        tokenBalance[owner] = 100;
    }

    function createNewToken() public{
        tokenBalance[owner]++;
    }

    function burnToken()public{
        tokenBalance[owner]--;
    }
    
    /*
    check for enough funds, otherwise output error
    remember to deduct from owner and add to new owner
    */
    function purchaseOneToken() public payable{
        require(tokenBalance[owner]*tokenPrice/msg.value > 0, "Not enough funds");
        tokenBalance[owner] --;
        tokenBalance[msg.sender]++;
    }
    /*
    check for enough funds, otherwise output error
    remember to deduct from owner and add to new owner
    */
    function purchaseTokens() public payable{
        require(tokenBalance[owner]*tokenPrice/msg.value > 0, "Not enough funds");
        tokenBalance[owner] -= msg.value/tokenPrice;
        tokenBalance[msg.sender]+= msg.value/tokenPrice;
    }

    function sendTokens(address _to, uint _amount) public payable{
        require(tokenBalance[msg.sender] >= _amount, "You dont have enough funds to send.");
        tokenBalance[msg.sender] -= _amount;
        tokenBalance[_to] += _amount;
    }
}