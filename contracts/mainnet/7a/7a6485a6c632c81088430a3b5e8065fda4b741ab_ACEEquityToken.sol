//Compatible Solidity Compiler Version

pragma solidity ^0.4.15;



/*
This ACE Equity Token contract is based on the ERC20 token contract standard. Additional
functionality has been integrated:

*/


contract ACEEquityToken  {
    //ACE Equity Official Token Name
    string public name;
    
    //ACE Equity Token Official Symbol
	string public symbol;
	
	//ACE Equity Token Decimals
	uint8 public decimals; 
  
  //database to match user Accounts and their respective balances
  mapping(address => uint) _balances;
  mapping(address => mapping( address => uint )) _approvals;
  
  //ACE Equity Token Hard cap 
  uint public cap_ACE;
  
  //Number of ACE Equity Tokens in existence
  uint public _supply;
  
  
  event Transfer(address indexed from, address indexed to, uint value );
  event Approval(address indexed owner, address indexed spender, uint value );
  
address public dev;


  //pass ACE Equity Token Configurations to the Constructor
 function ACEEquityToken(uint initial_balance, string tokenName, string tokenSymbol, uint8 decimalUnits) public {
    
    cap_ACE = initial_balance;
    _supply += initial_balance;
    _balances[msg.sender] = initial_balance;
    
    decimals = decimalUnits;
	symbol = tokenSymbol;
	name = tokenName;
    dev = msg.sender;
    
  }

//retrieve number of all ACE Equity Tokens in existence
function totalSupply() public constant returns (uint supply) {
    return _supply;
  }

//check ACE Equity Tokens balance of an Ethereum account
function balanceOf(address who) public constant returns (uint value) {
    return _balances[who];
  }

//check how many ACE Equity Tokens a spender is allowed to spend from an owner
function allowance(address _owner, address spender) public constant returns (uint _allowance) {
    return _approvals[_owner][spender];
  }

  // A helper to notify if overflow occurs
function safeToAdd(uint a, uint b) internal returns (bool) {
    return (a + b >= a && a + b >= b);
  }

//transfer an amount of ACE Equity Tokens to an Ethereum address
function transfer(address to, uint value) public returns (bool ok) {

    if(_balances[msg.sender] < value) revert();
    
    if(!safeToAdd(_balances[to], value)) revert();
    

    _balances[msg.sender] -= value;
    _balances[to] += value;
    Transfer(msg.sender, to, value);
    return true;
  }

//spend ACE Equity Tokens from another Ethereum account that approves you as spender
function transferFrom(address from, address to, uint value) public returns (bool ok) {
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
  
  
//allow another Ethereum account to spend TMX Equity Tokens from your Account
function approve(address spender, uint value)
    public
    returns (bool ok) {
    _approvals[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
    return true;
  }

}