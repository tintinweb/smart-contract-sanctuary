//Compatible Solidity Compiler Version

pragma solidity ^0.4.15;



/*
This TMX Global Token contract is based on the ERC20 token contract standard. Additional
functionality has been integrated:

*/


contract TMXGlobalToken  {
    //TMX Global Official Token Name
    string public name;
    
    //TMX Global Token Official Symbol
	string public symbol;
	
	//TMX Global Token Decimals
	uint8 public decimals; 
  
  //database to match user Accounts and their respective balances
  mapping(address => uint) _balances;
  mapping(address => mapping( address => uint )) _approvals;
  
  //TMX Global Token Hard cap 
  uint public cap_tmx;
  
  //Number of TMX Global Tokens in existence
  uint public _supply;
  

  event TokenMint(address newTokenHolder, uint amountOfTokens);
  event TokenSwapOver();
  
  event Transfer(address indexed from, address indexed to, uint value );
  event Approval(address indexed owner, address indexed spender, uint value );
  event mintting(address indexed to, uint value );
  event minterTransfered(address indexed prevCommand, address indexed nextCommand);
 
 //Ethereum address of Authorized Nuru Token Minter
address public dev;

//check if hard cap reached before mintting new Tokens
modifier cap_reached(uint amount) {
    
    if((_supply + amount) > cap_tmx) revert();
    _;
}

//check if Account is the Authorized Minter
modifier onlyMinter {
    
      if (msg.sender != dev) revert();
      _;
  }
  
  //initialize Nuru Token
  //pass TMX Global Token Configurations to the Constructor
 function TMXGlobalToken(uint cap_token, uint initial_balance, string tokenName, string tokenSymbol, uint8 decimalUnits) public {
    
    cap_tmx = cap_token;
    _supply += initial_balance;
    _balances[msg.sender] = initial_balance;
    
    decimals = decimalUnits;
	symbol = tokenSymbol;
	name = tokenName;
    dev = msg.sender;
    
  }

//retrieve number of all TMX Global Tokens in existence
function totalSupply() public constant returns (uint supply) {
    return _supply;
  }

//check TMX Global Tokens balance of an Ethereum account
function balanceOf(address who) public constant returns (uint value) {
    return _balances[who];
  }

//check how many TMX Global Tokens a spender is allowed to spend from an owner
function allowance(address _owner, address spender) public constant returns (uint _allowance) {
    return _approvals[_owner][spender];
  }

  // A helper to notify if overflow occurs
function safeToAdd(uint a, uint b) internal returns (bool) {
    return (a + b >= a && a + b >= b);
  }

//transfer an amount of TMX Global Tokens to an Ethereum address
function transfer(address to, uint value) public returns (bool ok) {

    if(_balances[msg.sender] < value) revert();
    
    if(!safeToAdd(_balances[to], value)) revert();
    

    _balances[msg.sender] -= value;
    _balances[to] += value;
    Transfer(msg.sender, to, value);
    return true;
  }

//spend TMX Global Tokens from another Ethereum account that approves you as spender
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
  
  
//allow another Ethereum account to spend TMX Global Tokens from your Account
function approve(address spender, uint value)
    public
    returns (bool ok) {
    _approvals[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
    return true;
  }

//mechanism for TMX Global Tokens Creation
//only minter can create new TMX Global Tokens
//check if TMX Global Token Hard Cap is reached before proceedig - revert if true
function mint(address recipient, uint amount) onlyMinter cap_reached(amount) public
  {
        
   _balances[recipient] += amount;  
   _supply += amount;
    
   
    mintting(recipient, amount);
  }
  
 //transfer the priviledge of creating new TMX Global Tokens to anothe Ethereum account
function transferMintership(address newMinter) public onlyMinter returns(bool)
  {
    dev = newMinter;
    
    minterTransfered(dev, newMinter);
  }
  
}