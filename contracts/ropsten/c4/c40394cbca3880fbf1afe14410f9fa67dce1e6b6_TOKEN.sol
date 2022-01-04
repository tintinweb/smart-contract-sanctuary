/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract TOKEN {
    string internal tokenName;
    string internal tokenSymbol;
    uint8 internal tokenDecimals;
    uint256 internal tokenTotalSupply;

    mapping(address=>uint256) balances;
    mapping(address=>mapping(address=>uint256)) allowed;

    constructor(string memory _name,string memory _symbol,uint8 _decimals, uint256 _totalSupply){
        tokenName=_name;
        tokenSymbol=_symbol;
        tokenDecimals=_decimals;
        tokenTotalSupply= _totalSupply;
        balances[msg.sender]= _totalSupply;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender , uint256 _value);

    function name() external view returns(string memory){
        return tokenName;
    }

    function symbol() external view returns(string memory _symbol){
        _symbol=tokenSymbol;
    }

    function decimals() external view returns(uint8 _decimals){
        _decimals=tokenDecimals;
    }

    function totalSupply() external view returns(uint256 _totalSupply){
        _totalSupply=tokenTotalSupply;
    }

    function balanceOf(address _owner) external view returns(uint256 _balance){
        _balance= balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns(bool _success) {
        require(balances[msg.sender]>=_value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender,_to,_value);
        _success= true;
    }

    function approve(address _spender, uint256 _value) public returns(bool _success){
        allowed[msg.sender][_spender]= _value;
        emit Approval(msg.sender,_spender,_value);
        _success= true;
    }

    function allowance (address _owner, address _spender) external view returns(uint256 _remaining){
        _remaining= allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool _success){
        require(balances[_from]>= _value);
        require(allowed[_from][msg.sender] >= _value);

        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        _success= true;
    }
}