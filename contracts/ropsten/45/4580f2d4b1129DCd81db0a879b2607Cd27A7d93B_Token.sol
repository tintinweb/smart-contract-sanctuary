/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Token {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    // Getters automatically generated for public state variables
    string public name = "405104477";
    string public symbol = "CS188";
    uint8 public decimals = 18;

    constructor() {
        uint256 initialAmount = 1337**13;
        _balances[msg.sender] = initialAmount;
        _totalSupply = initialAmount;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_balances[msg.sender] >= _value);

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_balances[_from] >= _value);
        require(_allowances[_from][msg.sender] >= _value);

        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowances[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}