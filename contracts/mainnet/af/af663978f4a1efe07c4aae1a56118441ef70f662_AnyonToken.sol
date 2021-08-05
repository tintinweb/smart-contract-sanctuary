/**
 *Submitted for verification at Etherscan.io on 2020-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;

//--------------------------------------
//  ANYON contract
//
// Symbol      : AYTO 
// Name        : Anyon Token
// Total supply: 21000000
// Decimals    : 10
//--------------------------------------

abstract contract ERC20Interface {
    function totalSupply() virtual external view returns (uint256);
    function balanceOf(address tokenOwner) virtual external view returns (uint);
    function allowance(address tokenOwner, address spender) virtual external view returns (uint);
    function transfer(address to, uint tokens) virtual external returns (bool);
    function approve(address spender, uint tokens) virtual external returns (bool);
    function transferFrom(address from, address to, uint tokens) virtual external returns (bool);
    function mint(uint256 tokens)virtual external returns(bool);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Mint(address from, address, uint256 tokens);

    }

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "SafeMath: subtraction overflow"); 
        c = a - b; 
        return c;
    }

}

contract AnyonToken is ERC20Interface, SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public _totalSupply;
    address public owner;
    
   
    mapping(address => uint) internal balances;
    mapping(address => mapping(address => uint)) internal allowed;
    mapping(uint256 => uint256) internal token;
    
    
    constructor() public {
        name = "Anyon Token";
        symbol = "AYTO";
        decimals = 10;
        _totalSupply = 21000000 * 10 ** uint256(decimals);
	    initialSupply = _totalSupply;
	    balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
   
 
    function totalSupply() external view override returns (uint256) {
        return safeSub(_totalSupply, balances[address(0)]);
    }

    function balanceOf(address tokenOwner) external view override returns (uint getBalance) {
        return balances[tokenOwner];
    }
 
    function allowance(address tokenOwner, address spender) external view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approve(address spender, uint tokens) external override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) external override returns (bool success) {
        require(to != address(0));
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
   function transferFrom(address from, address to, uint tokens) external override returns (bool success) {
        require(to != address(0));
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
   }
   
   function mint(uint256 tokens) external override returns(bool success){
       require(owner == msg.sender, 'This is not owner');
       balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
       _totalSupply = safeAdd(tokens, _totalSupply);
       emit Mint( msg.sender, address(0), tokens);
       return true;
   }
   
   
}