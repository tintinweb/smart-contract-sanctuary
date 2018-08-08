pragma solidity ^0.4.19;



contract RIPAC {

  mapping(address => uint256) balances;
 
  mapping(address => mapping (address => uint256)) allowed;
  
  
  using SafeMath for uint256;
  
  
  address public owner;
  
  uint256 public _totalSupply = 500000000000;
    uint256 public totalSupply = 500000000000;
    string public constant symbol = "RIPAC";
    string public constant name = " Representative Initiatives PAC ";
    uint8 public constant decimals = 2;
    

    uint256 public constant RATE = 3333;
   
  function RIPAC(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = 50000000000;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                 // Update total supply
       }
        
         function () payable {
        createTokens();
        throw;
    }
        function createTokens() payable {
        require(msg.value > 0);
        
        uint256 tokens = msg.value.add(RATE);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        
        owner.transfer(msg.value);
    }
  
  function totalSupply() constant returns (uint256 theTotalSupply) {
    // Because our function signature
    // states that the returning variable
    // is "theTotalSupply", we&#39;ll just set that variable
    // to the value of the instance variable "_totalSupply"
    // and return it
    theTotalSupply = _totalSupply;
    return theTotalSupply;
  }
  
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
  
  function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    // Fire the event "Approval" to execute any logic
    // that was listening to it
    Approval(msg.sender, _spender, _amount);
    return true;
  }
  
  // Note: This function returns a boolean value
  //       indicating whether the transfer was successful
  function transfer(address _to, uint256 _amount) returns (bool success) {
    // If the sender has sufficient funds to send
    // and the amount is not zero, then send to
    // the given address
    if (balances[msg.sender] >= _amount 
      && _amount > 0
      && balances[_to] + _amount > balances[_to]) {
      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
      // Fire a transfer event for any
      // logic that&#39;s listening
      Transfer(msg.sender, _to, _amount);
        return true;
      } else {
        return false;
      }
   }
   
   function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
    if (balances[_from] >= _amount
      && allowed[_from][msg.sender] >= _amount
      && _amount > 0
      && balances[_to] + _amount > balances[_to]) {
    balances[_from] -= _amount;
    balances[_to] += _amount;
    Transfer(_from, _to, _amount);
      return true;
    } else {
      return false;
    }
  }
  
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  // Triggered whenever approve(address _spender, uint256 _value) is called.
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}