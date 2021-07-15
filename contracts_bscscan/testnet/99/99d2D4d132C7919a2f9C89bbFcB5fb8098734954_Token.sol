// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Token {

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    address public owner;
    uint public decimals = 2;
    uint public totalSupply = 1000000 * 10 ** decimals;
    string public name = "My Token";
    string public symbol;
    uint256 private reflectionTotal = totalSupply / 10; // reflectionTotal starts as 10% of total supply

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor (string memory _symbol) {
        owner = msg.sender;
        symbol = _symbol;
        balances[owner] = totalSupply;
        emit Transfer(address(0),owner, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

}