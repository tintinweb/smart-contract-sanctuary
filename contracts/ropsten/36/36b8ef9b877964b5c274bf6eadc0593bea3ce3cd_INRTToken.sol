/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.0;

// SafeMath Library Definition
library SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}

// ERC20 Token Standard Interface
interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint);
    function allowance(address tokenOwner, address spender) external view returns (uint);
    function transfer(address to, uint tokens) external returns (bool);
    function approve(address spender, uint tokens)  external returns (bool);
    function transferFrom(address from, address to, uint tokens) external returns (bool);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    }


contract INRTToken is ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;
    using SafeMath for uint;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    // Constructor
    constructor() {
        symbol = "INRT";
        name = "Indian Rupee Token";
        decimals = 2;
        _totalSupply = 10000;
        balances[0x4c83493FD2dC9180064A88da5f1B036887902156] = _totalSupply;
        emit Transfer(address(0), 0x4c83493FD2dC9180064A88da5f1B036887902156, _totalSupply);
    }

    // Total supply
    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }

    // Get the token balance for account tokenOwner
    function balanceOf(address tokenOwner) public override view returns (uint) {
        return balances[tokenOwner];
    }


    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    function transfer(address to, uint tokens) public override returns (bool) {
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].safeSub(tokens);
        balances[to] = balances[to].safeAdd(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // Approve function approves that a sender can send some amount to a receiver (in this case, spender)
    // A spender in usual case is an exchange or a swap
    // Once approved, the contract of an exchange or swap can withdraw the amount specified in tokens
    function approve(address spender, uint tokens) public override returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // Transfer tokens from the from account to the to account
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    function transferFrom(address from, address to, uint tokens) public override returns (bool) {
        balances[from] = balances[from].safeSub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].safeSub(tokens);
        balances[to] = balances[to].safeAdd(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // Fallback function, it does not have payable keyword so that nobody can send money
    // Removing payable keyword eliminates the need of a receive function
    fallback() external {
        revert();
    }
}