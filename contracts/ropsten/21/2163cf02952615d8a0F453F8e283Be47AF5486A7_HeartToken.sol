/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract HeartToken{

    string public constant name = "Heart";
    string public constant symbol = "HEART";
    uint8 public constant decimals = 18;
    
    uint256 totalSupply_;

    event Transfer(address indexed from, address indexed to, uint256 numTokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint numTokens);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor(){
        totalSupply_ = 1000000 * 10 ** decimals;

        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns(uint256){
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns(bool){
        require(numTokens <= balances[msg.sender]);        

        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        
        emit Transfer(msg.sender, receiver, numTokens);

        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool){
        require(delegate != msg.sender);

        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);

        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint){
        return allowed[owner][delegate];
    }

    function transferFrom(address from, address to, uint numTokens) public returns (bool){

        require(numTokens <= balances[from]);
        require(numTokens <= allowed[from][to]);
        
        allowed[from][to] = allowed[from][to] - numTokens;

        balances[from] = balances[from] - numTokens;
        balances[to] = balances[to] + numTokens;

        emit Transfer(from, to, numTokens);

        return true;
    }
}