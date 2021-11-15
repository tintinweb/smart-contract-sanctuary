// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// BEP-20 Contract 
contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;

    uint public totalSupply = 1000 * 10 ** 18;
    string public name = 'Dark Energy Crystal';
    string public symbol = 'DLC';
    uint public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    // Public functions
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function approve(address spender, uint value) public returns(bool) {
        _approve(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint value) public returns(bool) {
        _transfer(msg.sender, to, value);
    
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns(bool) {
        require(allowances[from][msg.sender] >= value, 'Transfert amount exceeds allowance');
        _approve(from, msg.sender, value);
        _transfer(from, to, value);

        return true;
    }

    // Private functions

    function _transfer(address from, address to, uint value) internal {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");

        require(balanceOf(from) >= value, 'Insufficient balance');
        balances[from] -= value;
        balances[to] += value;

        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint value) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

