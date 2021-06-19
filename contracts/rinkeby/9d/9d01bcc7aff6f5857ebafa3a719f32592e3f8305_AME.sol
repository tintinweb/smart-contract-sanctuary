/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

/**
 *Submitted for verification at Etherscan.io on 2020-06-04
*/

pragma solidity ^0.5.0;

//--------------------------------------
//  AME Token contract
//
// Symbol      : AME
// Name        : AME Token
// Total supply: 1500000000
// Decimals    : 18
//--------------------------------------

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint getBalance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
    }

    function safeMul(uint a, uint b) public pure returns (uint c){
    c = a * b; require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract AME is ERC20Interface, SafeMath{
    bytes32 public name;
    bytes32 public symbol;
    uint8 public decimals;
    uint256 private initialSupply;
    uint256 public _totalSupply;
    address private owner;
   
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        name = "AME Token";
        symbol = "AME";
        decimals = 18;
        _totalSupply = 1500000000 * 10 ** uint256(decimals);
	    initialSupply = _totalSupply;
       	balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
 
    function totalSupply() public view returns (uint) {
        return safeSub(_totalSupply, balances[address(0)]);
    }

    function balanceOf(address tokenOwner) public view returns (uint getBalance) {
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
        require(to != address(0));
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
   function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(to != address(0));
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
   }
   
}