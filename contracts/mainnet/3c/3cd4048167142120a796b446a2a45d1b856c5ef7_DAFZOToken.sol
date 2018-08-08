pragma solidity ^0.4.13;

contract Token {
 
  /// total amount of tokens
  uint256 public totalSupply;

  function balanceOf(address _owner) constant returns (uint256 balance);

  
  function transfer(address _to, uint256 _value) returns (bool success);

 
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

  
  function approve(address _spender, uint256 _value) returns (bool success);

  
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

  function transfer(address _to, uint256 _value) returns (bool success) {
    
    //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
   
    //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
}

contract DAFZOToken is StandardToken {

  string public constant name = "DAFZO";
  string public constant symbol = "DFZ";
  uint8 public constant decimals = 18;

  function DAFZOToken(address _icoAddress,
                         address _preIcoAddress,
                         address _dafzoWalletAddress,
                         address _bountyWalletAddress) {
    require(_icoAddress != 0x0);
    require(_preIcoAddress != 0x0);
    require(_dafzoWalletAddress != 0x0);
    require(_bountyWalletAddress != 0x0);

    totalSupply = 70000000 * 10**18;                     // 70000000 DFZ

    uint256 icoTokens = 18956000  * 10**18;               

    uint256 preIcoTokens = 28434000 * 10**18;
    
     uint256 bountyTokens = 1610000 * 10**18;

    uint256 DAFZOTokens = 21000000 * 10**18;            // Dafzo Funds        
                                                                      

    assert(icoTokens + preIcoTokens + DAFZOTokens + bountyTokens == totalSupply);

    balances[_icoAddress] = icoTokens;
    Transfer(0, _icoAddress, icoTokens);

    balances[_preIcoAddress] = preIcoTokens;
    Transfer(0, _preIcoAddress, preIcoTokens);

    balances[_dafzoWalletAddress] = DAFZOTokens;
    Transfer(0, _dafzoWalletAddress, DAFZOTokens);

    balances[_bountyWalletAddress] = bountyTokens;
    Transfer(0, _bountyWalletAddress, bountyTokens);
  }

  function burn(uint256 _value) returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      totalSupply -= _value;
      Transfer(msg.sender, 0x0, _value);
      return true;
    } else {
      return false;
    }
  }
}