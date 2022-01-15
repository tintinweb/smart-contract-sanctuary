/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

pragma solidity ^0.8.2;

// SPDX-License-Identifier: Unlicensed
contract Token {
    mapping(address => uint) public balances;
    uint public totalSupply =100000000 * 10 ** 18; 
    string public name = "MicroDinos";
    string public symbol = "TKN";
    uint public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
        }

        function transfer(address to, uint value) public returns(bool) {
            require(balanceOf(msg.sender) >=value, 'balance too low');
            balances[to] += value;
            balances[msg.sender] -= value;
            emit Transfer(msg.sender, to, value);
            return true;
        }
}