/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.11;

contract spoodr {
    address private yash = 0xb23a62978a7EcAA57Ff6fd0b7F5b6A190dEfC3B4;
    address private varun = 0x36A11601fcFc864D4F3ad41167f1Ab9c83D0cCe2;

    uint public totalSupply = 1000000000000 * 10 ** 18;
    string public name;
    string public symbol;
    uint public decimals = 18;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        name = "Spooderman";
        symbol = "SPOODR";

        balances[msg.sender] = totalSupply;
        balances[varun] += 50000000000 * 10 ** 18;
        balances[yash] += 50000000000 * 10 ** 18;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value);
        require(value > 0);
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value);
        require(allowance[from][msg.sender] >= value);
        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}