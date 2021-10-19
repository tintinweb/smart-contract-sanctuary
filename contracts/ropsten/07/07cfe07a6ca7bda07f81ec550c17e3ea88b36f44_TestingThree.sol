/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// File: Testing3.sol

pragma solidity >=0.4.0 <0.9.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract TokenInterface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenHolder) public view returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address tokenHolder, address spender) public view returns (uint256 remaining);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenHolder, address indexed spender, uint256 value);
}

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b;
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

contract TestingThree is TokenInterface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    
    constructor() public {
        name = "TestCoinFGHThree";
        symbol = "FGHTHR";
        decimals = 2;
        _totalSupply = 30000000;
        
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply - balances[address(0)];
    }
    
    function balanceOf(address tokenHolder) public view returns (uint256 balance) {
        return balances[tokenHolder];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        balances[to] = safeAdd(balances[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        balances[from] = safeSub(balances[from], value);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
        balances[to] = safeAdd(balances[to],value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address tokenHolder, address spender) public view returns (uint256 remaining) {
        return allowed[tokenHolder][spender];
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenHolder, address indexed spender, uint256 value);
    
    
}