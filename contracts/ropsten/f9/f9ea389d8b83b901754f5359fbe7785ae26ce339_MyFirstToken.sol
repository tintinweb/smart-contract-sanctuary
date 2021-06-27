/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract MyFirstToken
{
    string constant public name = "LloydikCoin";
    string constant public symbol = "LLC";
    uint8 constant public decimals = 8;
    
    uint public totalSupply = 0;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address immutable creator;
    constructor()
    {
        creator = msg.sender;
    }
    
    function mint(address toAddress, uint count) payable public isAuthor
    {
        require(count + totalSupply > totalSupply && balances[toAddress] + count >= balances[toAddress]);
        totalSupply += count;
        balances[toAddress] += count;
    }
    
    function balanceOf(address _address) public view returns(uint)
    {
        return balances[_address];
    }
    
    modifier CanTransfer(address FromAddress, address toAddress, uint count)
    {
        require(balances[toAddress] + count > balances[toAddress] && balances[FromAddress] >= count);
        _;
    }
    
    modifier isAuthor()
    {
        require(msg.sender == creator);
        _;
    }
    event Transfer(address FromAddress, address ToAddress, uint tokens);
    event Approval(address FromAddress, address ToAddress, uint CanTransferTokens);
    
    function transfer(address toAddress, uint count) payable public CanTransfer(msg.sender, toAddress, count)
    {
        balances[msg.sender] -= count;
        balances[toAddress] += count;
        emit Transfer(msg.sender, toAddress, count);
        allowed[msg.sender][toAddress] -= count;
    }
    
    function transferFrom(address FromAddress, address toAddress, uint count) payable public CanTransfer(FromAddress, toAddress, count) 
    {
        balances[FromAddress] -= count;
        balances[toAddress] += count;
        emit Transfer(FromAddress, toAddress, count);
        allowed[FromAddress][toAddress] -= count;
        emit Approval(FromAddress, toAddress, count);
    }
    
    function approve(address toAddress, uint value) payable public
    {
        allowed[msg.sender][toAddress] = value;
        emit Approval(msg.sender, toAddress, value);
    }
    
    function allowance(address FromAddress, address toAddress) view public returns(uint)
    {
        return allowed[FromAddress][toAddress];
    }
}