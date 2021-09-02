/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

pragma solidity ^0.4.15;


contract MyCoin {
    mapping (address => uint) public balances;

    function TestToken() payable {
        balances[msg.sender] = 1000;
    }

    function transfer(address _to, uint _value) returns (bool success) {
        if (balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            return true;
        }
        return false;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
}