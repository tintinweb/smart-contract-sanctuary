/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7 .0 < 0.9 .0;

contract Token {

    //Variable
    uint public totalSupply = 10000;
    string public name = "Lunaheal Token";
    string public key = "LHT";
    uint public decimals = 18;

    //Mapping
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    //Event
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    constructor() {
        balances[msg.sender] = totalSupply;
    }
    //Function

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint amount) public returns(bool) {
        require(balanceOf(msg.sender) >= amount, "Balance is not enough");
        balances[to] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // Uy quyen

    function transformFrom(address from, address to, uint amount) public returns (bool) {
        require(balanceOf(from) >= amount, "Balance is not enough");
        require(allowance[from][msg.sender] >= amount, "Balance is not enough");
        balances[to] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // Tao nguoi uy quyen

    function approve(address spender, uint amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}