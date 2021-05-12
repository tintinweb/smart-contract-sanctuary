/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity ^0.5.0;

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract simpleMath {
    function simpleAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function simpleSubtract(uint a, uint b) public pure returns (uint c) {
        c = a - b;
        require(b <= a); 
    } 
    function simpleMult(uint a, uint b) public pure returns (uint c) { 
        c = a * b;
        require(a == 0 || c / a == b);
    } 
    function simpleDiv(uint a, uint b) public pure returns (uint c) { 
        c = a / b;
        require(b > 0); 
    }
}

contract Tomorrrow is ERC20, simpleMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "Tomorrow";
        symbol = "TMW";
        decimals = 18;
        _totalSupply = 1000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
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
        balances[msg.sender] = simpleSubtract(balances[msg.sender], tokens);
        balances[to] = simpleAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = simpleSubtract(balances[from], tokens);
        allowed[from][msg.sender] = simpleSubtract(allowed[from][msg.sender], tokens);
        balances[to] = simpleAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}