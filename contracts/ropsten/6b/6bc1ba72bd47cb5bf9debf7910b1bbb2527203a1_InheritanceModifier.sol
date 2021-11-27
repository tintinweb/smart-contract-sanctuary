/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

contract Owned {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not allowed");
        _;
    }
}

contract InheritanceModifier is Owned{
    uint tokenPrice =  1 ether;
    mapping(address => uint) public tokenBalance;

    constructor(){
        tokenBalance[owner] = 100;
    }
    
    function balance() public view returns (uint){
        return tokenBalance[owner];
    }

    function balanceOf(address _address) public view returns (uint){
        return tokenBalance[_address];
    }

    function createNewToken() public onlyOwner{
        tokenBalance[owner]++;
    }
    
    function burnToken() public onlyOwner{
        tokenBalance[owner]--;
    }
    
    function puchaseToken() public payable{
        require(tokenBalance[owner] > 1, "Not enough funds available to provide.");
        tokenBalance[owner]--;
        tokenBalance[msg.sender]++;
    }
    function purchaseTokens(uint _amount) public payable{
        require(tokenBalance[owner]-_amount > 0, "Not enough funds available to provide.");
        tokenBalance[owner] -= _amount;
        tokenBalance[msg.sender]+= _amount;
    }

    function sendTokens(address _to, uint _amount) public  {
        require(tokenBalance[msg.sender] >= _amount, "You dont have enough funds to send.");
        tokenBalance[msg.sender] -= _amount;
        tokenBalance[_to] += _amount;
    }
}