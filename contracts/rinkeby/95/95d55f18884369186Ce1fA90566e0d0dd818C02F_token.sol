/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;


contract token
{
    string public constant name = "TeaEmpire";
    string public constant symbol = "TeaEmpire";
    uint8 public constant decimals = 3;
    uint public totalSupply = 0;
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    
    event Transfer(address fromAdrs, address toAdrs, uint tokens);
    event Approval(address fromAdrs, address toAdrs, uint tokens);
    
    address private admin;
    address[] private moderators;
    
    constructor(){
        admin = msg.sender;
    }
    
    modifier chekUser(){
        bool flag = false;
        if(msg.sender == admin){
            flag = true;
        }
        for(uint i = 0; i < moderators.length; ++i){
            if(msg.sender == moderators[i]){
                flag = true;
            } 
        }
        require(flag == true);
        _;
    }
    
    modifier chekAdmin(){
        require(msg.sender == admin);
        _;
    }
    
   modifier canTransfer(address _from, address _to, uint tokens){
        require(allowance(_from, _to) >= tokens);
        require(balances[_from] >= tokens);
        require(balances[_to] + tokens > balances[_to]);
        _;
    }
    
    function addUser(address usr) chekAdmin public payable{
        moderators.push(usr);
    }
    
    function mint(address _adrs, uint x) chekUser public payable{
        require(totalSupply + x > totalSupply);
        balances[_adrs] += x;
        totalSupply += x;
    }
    
    function balanceOf(address _adrs) public view returns(uint){
        return balances[_adrs];
    }
    
    function balanceOf() public view returns(uint){
        return balances[msg.sender];
    }
    
    function transfer(address _to, uint tokens) canTransfer(msg.sender, _to, tokens) public payable{
        balances[msg.sender] -= tokens;
        balances[_to] += tokens;
        allowed[msg.sender][_to] -= tokens;
        emit Transfer(msg.sender, _to, tokens);
    }
    
    function transferFrom(address _from, address _to, uint tokens) canTransfer(_from, _to, tokens) public payable{
        balances[_from] -= tokens;
        balances[_to] += tokens;
        allowed[_from][_to] -= tokens;
        emit Transfer(_from, _to, tokens);
    }
    
    function approve(address _adrs, uint tokens) public payable{
        allowed[msg.sender][_adrs] = tokens;
        emit Approval(msg.sender, _adrs, tokens);
    }
    
    function allowance(address _adrs, address _adrs2) public view returns(uint){
        return allowed[_adrs][_adrs2];
    }
}