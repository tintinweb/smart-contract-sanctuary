/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance (address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// Safe Math Library wrappers over Solidity’s arithmetic operations with added overflow checks.
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract PunkToadToken is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "PunkToadToken";
        symbol = "PNKT";
        decimals = 18;

        _totalSupply = 100000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // Returns the number of tokens that a particular address, in this case, the contract owner, has in their account.
    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    // Identifies the total number of ERC-20 tokens created.
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    // If the user doesn't have the minimum required number of tokens, this function cancels the transaction.
    function allowance (address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // If the balance-check succeeds, the contract owner can give approval to the user to collect the required number of tokens from the contract's address.
    function approve(address spender, uint tokens) public override returns (bool success) {
        // msg.sender is the creator of the contract
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // Issue a given amount of tokens from the owner of a contract to another address.
    function transfer(address to, uint tokens) public override returns (bool success) {
        // msg.sender is the creator of the contract
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // Transfer a given amount of tokens from one user to another user.
    function transferFrom (address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        // msg.sender is the creator of the contract
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}