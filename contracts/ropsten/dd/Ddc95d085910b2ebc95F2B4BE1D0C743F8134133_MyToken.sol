// SPDX-License-Identifier: MIT

pragma solidity  ^0.4.21;

import './EIP20Interface.sol';

contract MyToken is EIP20Interface {

    address owner;
    uint256 supplyLeft;
    mapping(address => uint256) balances;
    mapping(address => uint256) approved;
    mapping(address => uint256) remainingLeft;

    event transferFromUser(address _owner, address _from, address _to, uint256 _value);
    constructor(uint256 _totalSupply) public {
        owner = msg.sender;
        totalSupply = _totalSupply;
        supplyLeft = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        if (owner != msg.sender || supplyLeft < _value) {
            return false;
        }
        supplyLeft -= _value;
        balances[_to] += _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_from != msg.sender || approved[_from] == 0 || _value > approved[_from] || _value > balances[_from]) {
            return false;
        }
        
        balances[_from] -= _value;
        balances[_to] += _value;
        remainingLeft[_from] -= _value;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_spender != msg.sender) {
            return false;
        }
        approved[_spender] = _value;
        remainingLeft[_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        if (_owner == _spender) {
            return remainingLeft[_spender];
        }
        return 0;
    }
}