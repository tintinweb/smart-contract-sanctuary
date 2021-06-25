/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract Singularity{
    string public constant name = "Alfred Thaddeus Crane Pennyworth";
    string public constant symbol = "ATCP";
    uint8 public constant decimals = 6;
    
    address immutable owner;
    
    uint public totalSupply = 10000000; // 10 ATCP
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    event Transfer(address sender, address getter, uint count);
    event Approval(address allowed, address toSend, uint count);

    constructor(){
        owner = msg.sender;
    }
    
    modifier OwnersInfo(){
        require(owner == msg.sender);
        _;
    }
    
    modifier HasCoins(uint coinsToSend){
        require(balances[msg.sender] >= coinsToSend);
        _;
    }
    
    modifier TooMuch(address client, uint coinsToSend){
        require(balances[client] + coinsToSend >= balances[client]);
        _;
    }
    
    function mint(address client, uint count) OwnersInfo public payable{
        balances[client] += count;
        totalSupply += count;
    }
    
    function balanceOf(address client) OwnersInfo public view returns(uint){
        return(balances[client]);
    }
    
    function TransferTo(address client, uint count) HasCoins(count) TooMuch(client, count) public payable{
        emit Transfer(msg.sender, client, count);
        balances[msg.sender] -= count;
        balances[client] += count;
    }
    
    function TransferFromTo(address sender, address client, uint count) HasCoins(count) TooMuch(client, count) public payable{
        require(CheckAllowing(client, sender) >= count);
        emit Transfer(sender, client, count);
        balances[sender] -= count;
        balances[client] += count;
        allowed[client][sender] -= count;
    }
    
    function approve(address toAllow, uint count) public payable{
        emit Approval(msg.sender, toAllow, count);
        allowed[msg.sender][toAllow] = count;
    }
    
    function CheckAllowing(address toAllow, address toSpend) public payable returns(uint){
        emit Approval(msg.sender, toAllow, allowed[toAllow][toSpend]);
        return(allowed[toAllow][toSpend]);
    }
}