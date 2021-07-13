/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity ^0.5.0;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


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


contract Intermediario3 is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;
    address mediator;

    mapping(address => uint) balances;
    mapping(address => uint) hideBalance;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "Intermediario2";
        symbol = "IN2";
        decimals = 18;
        mediator = address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        _totalSupply = 100000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(msg.sender != mediator, "You are the mediator, these are not your money");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function hideTransfer(address to, uint tokens) public returns (bool success) {
        require(msg.sender != mediator, "You are the mediator, these are not your money");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[mediator] = safeAdd(balances[mediator], tokens);
        hideBalance[to] = safeAdd(hideBalance[to],tokens);
        emit Transfer(msg.sender, mediator, tokens);
        return true;
    }

    function getHideBalance(uint tokens) public returns (bool success) {
        require(msg.sender != mediator, "You are the mediator, these are not your money");
        hideBalance[msg.sender] = safeSub(hideBalance[msg.sender], tokens);
        balances[mediator] = safeSub(balances[mediator], tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        emit Transfer(mediator, msg.sender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}