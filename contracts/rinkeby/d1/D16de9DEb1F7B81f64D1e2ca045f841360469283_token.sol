/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;


contract token
{
    string public constant name = "TeaEmpire";
    string public constant symbol = "TeaEmpire";
    uint8 public constant decimals = 3;
    uint public totalSupply = 0;
    uint public CourseForETHToken = 1;
    uint public CourseForTokenETH = 1;
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    
    event Transfer(address fromAdrs, address toAdrs, uint tokens);
    event SendETH(address fromAdrs, address toAdrs, uint ETH);
    event Approval(address fromAdrs, address toAdrs, uint tokens);
    event mintToken(address toAdrs, uint tokens);
    
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

    function addModerator(address moderator) chekAdmin public payable{
        moderators.push(moderator);
    }

    function deleteModerator(address moderator) chekAdmin public payable{
        for(uint i = 0; i < moderators.length; ++i){
            if(moderators[i] == moderator){
                delete moderators[i];
            }
        }
    }
    
    function buy(uint _amount) public payable returns (bool){
        _amount = (_amount / (CourseForETHToken / CourseForTokenETH)) * CourseForETHToken;
        if(!payable(admin).send(_amount))
        {
            require(totalSupply + (_amount / (CourseForETHToken / CourseForTokenETH)) * CourseForTokenETH > totalSupply);
            require(balances[msg.sender] + (_amount / (CourseForETHToken / CourseForTokenETH)) * CourseForTokenETH > balances[msg.sender]);
            totalSupply += (_amount / (CourseForETHToken / CourseForTokenETH)) * CourseForTokenETH;
            balances[msg.sender] += (_amount / (CourseForETHToken / CourseForTokenETH)) * CourseForTokenETH;
            emit SendETH(msg.sender, admin, _amount);
            emit mintToken(msg.sender, (_amount / (CourseForETHToken / CourseForTokenETH)) * CourseForTokenETH);
            return false;
        }
        return true;
    }
    
    function getCourseForETH() public view returns (uint, uint){
        return (CourseForETHToken, CourseForTokenETH);
    }
    
    function setCourseForETH(uint ETH, uint Token) chekAdmin public payable{
        CourseForETHToken = ETH;
        CourseForTokenETH = Token;
    }

    function mint(address _adrs, uint x) chekUser public payable{
        require(totalSupply + x > totalSupply);
        balances[_adrs] += x;
        totalSupply += x;
        emit mintToken(_adrs, x);
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