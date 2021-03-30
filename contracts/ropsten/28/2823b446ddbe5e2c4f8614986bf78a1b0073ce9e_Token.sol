/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        assert(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        assert(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        assert(b > 0);
        c = a / b;
    }
}

    
contract Token is SafeMath{
    
    string constant name_ = "token";
    string constant  symbol_ = "XFC";
    uint8  constant decimals_ = 18;
    uint192 constant totalSupply_ = 10000000000000000000000;
    address owner_;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowance;
    
    
     event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );


    
    constructor () {
        owner_ = msg.sender;
        balances[owner_] = totalSupply();
    }
    
    function name() public pure returns(string memory){
        return name_;
    }
    
    
    function symbol() public pure returns(string memory){
        return symbol_;
    }
    
    
    function decimals() public pure returns (uint8){
        return decimals_;
    }
    
    
    function totalSupply() public pure returns (uint192){
        return totalSupply_;
    }
    
    function balanceOf(address _owner) public view returns (uint256){
        return balances[_owner];   
    }
    
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf(msg.sender) >= _value,"No enough XFC");
        balances[_to] = safeAdd(balanceOf(_to),_value);
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        emit Transfer(msg.sender,_to,_value);
        return true;
        
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(allowance[_from][msg.sender] >= _value, "Tokens not approved");
        require(balanceOf(_from) >= _value, "No enough XFC");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        
    }
    
}