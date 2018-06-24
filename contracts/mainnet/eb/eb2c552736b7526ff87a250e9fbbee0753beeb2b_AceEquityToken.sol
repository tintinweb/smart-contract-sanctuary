//Compatible Solidity Compiler Version

pragma solidity ^0.4.15;



/*
This Ace Equity Token contract is based on the ERC20 token contract standard. Additional
functionality has been integrated:

*/


contract AceEquityToken  {
    //AceEquityToken
    string public name;
    
    //AceEquityToken Official Symbol
	string public symbol;
	
	//AceEquityToken Decimals
	uint8 public decimals; 
  
  //database to match user Accounts and their respective balances
  mapping(address => uint) _balances;
  mapping(address => mapping( address => uint )) _approvals;
  
  

  address public dev;
  
  //Number of AceEquityToken in existence
  uint public _supply;
  

  event TokenSwapOver();
  
  event Transfer(address indexed from, address indexed to, uint value );
  event Approval(address indexed owner, address indexed spender, uint value );
 
 

  //initialize AceEquityToken
  //pass Ace Configurations to the Constructor
 function AceEquityToken(uint initial_balance, string tokenName, string tokenSymbol, uint8 decimalUnits) {
    
   
    _supply += initial_balance;
    _balances[msg.sender] = initial_balance;
    
    decimals = decimalUnits;
	symbol = tokenSymbol;
	name = tokenName;
	
	dev = msg.sender;
 
    
  }

//retrieve number of all AceEquityToken in existence
function totalSupply() constant returns (uint supply) {
    return _supply;
  }

//check Ace Token balance of an Ethereum account
function balanceOf(address who) constant returns (uint value) {
    return _balances[who];
  }

//check how many Ace Tokens a spender is allowed to spend from an owner
function allowance(address _owner, address spender) constant returns (uint _allowance) {
    return _approvals[_owner][spender];
  }

  // A helper to notify if overflow occurs
function safeToAdd(uint a, uint b) internal returns (bool) {
    return (a + b >= a && a + b >= b);
  }

//transfer an amount of Ace Tokens to an Ethereum address
function transfer(address to, uint value) returns (bool ok) {

    if(_balances[msg.sender] < value) revert();
    
    if(!safeToAdd(_balances[to], value)) revert();
    

    _balances[msg.sender] -= value;
    _balances[to] += value;
    Transfer(msg.sender, to, value);
    return true;
  }

//spend Ace Tokens from another Ethereum account that approves you as spender
function transferFrom(address from, address to, uint value) returns (bool ok) {
    // if you don&#39;t have enough balance, throw
    if(_balances[from] < value) revert();

    // if you don&#39;t have approval, throw
    if(_approvals[from][msg.sender] < value) revert();
    
    if(!safeToAdd(_balances[to], value)) revert();
    
    // transfer and return true
    _approvals[from][msg.sender] -= value;
    _balances[from] -= value;
    _balances[to] += value;
    Transfer(from, to, value);
    return true;
  }
  
  
//allow another Ethereum account to spend Ace Tokens from your Account
function approve(address spender, uint value)
    
    returns (bool ok) {
    _approvals[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
    return true;
  }
}