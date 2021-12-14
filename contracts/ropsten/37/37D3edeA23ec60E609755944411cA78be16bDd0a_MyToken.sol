// SPDX-License-Identifier: MIT

pragma solidity  ^0.4.21;

import './EIP20Interface.sol';

contract MyToken is EIP20Interface {

    address owner;
    mapping(address => uint256) balances;
    mapping(address => uint256) approved;
    mapping(address => uint256) remainingLeft;

    constructor(uint256 _totalSupply) public {
        owner = msg.sender;
        totalSupply = _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        if (balances[msg.sender] > _value) {
            return false;
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (owner != msg.sender || approved[_from] > 0 || _value > approved[_from] || balances[_from] > _value) {
            return false;
        }
        
        balances[_from] -= _value;
        balances[_to] += _value;
        remainingLeft[_from] -= _value;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (owner != msg.sender) {
            return false;
        }
        approved[_spender] = _value;
        remainingLeft[_spender] = _value;
        return true;

    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        if (owner == _owner) {
            return 0;
        }
        return remainingLeft[_spender];
    }
}