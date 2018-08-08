pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {
    
    mapping (address => uint256) balances;    
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (_to == 0x0) return false;
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) constant returns (uint256){
        return balances[_owner];
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }
}

contract KairosToken is StandardToken {

  using SafeMath for uint256;
  mapping(address => bool) frozenAccount;
  mapping(address => uint256) bonus; 

  address public kairosOwner;
  string  public constant name         = "KAIROS";
  string  public constant symbol       = "KRX";
  string  public constant version      = "1.0";
  uint256 public constant decimals     = 18;  
  uint256 public initialSupply         = 25 * (10**6) * 10**decimals;
  uint256 public totalSupply;
  uint256 public sellPrice;
  uint256 public buyPrice;

  event CreateNertia(address indexed _to, uint256 _value);
  event Burn(address indexed _from, uint256 _value);
  event FrozenFunds(address indexed _target, bool _frozen );
  event Mint(address indexed _to, uint256 _value);
  
  
  modifier onlyOwner{ 
    if ( msg.sender != kairosOwner) throw; 
    _; 
  }    

  function KairosToken(){
    kairosOwner            = msg.sender;
    balances[kairosOwner]  = initialSupply;
    totalSupply            = initialSupply;
    CreateNertia(kairosOwner, initialSupply);
  }

  function buy() payable returns (uint256 amount) {
    amount = msg.value / buyPrice;
    if(balances[kairosOwner] < amount) throw;
    balances[msg.sender] += amount;
    balances[kairosOwner] -= amount;    
    Transfer(kairosOwner, msg.sender, amount);
    return amount;
  }

  function sell(uint256 amount){
    if(balances[msg.sender] < amount) throw;
    balances[kairosOwner] += amount;
    balances[msg.sender] -= amount;
    if(!msg.sender.send(amount.mul(sellPrice))){
        throw;
    }
    Transfer(msg.sender, kairosOwner, amount);    
  }

  function setPrices(uint256 newSellPrice, uint256 newBuyPrice){
    sellPrice = newSellPrice;
    buyPrice = newBuyPrice;
  }
  

  function transfer(address _to, uint256 _value) returns (bool success) {
      if (_to == 0x0) return false;
      if (!frozenAccount[msg.sender] && balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      }
      return false;      
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if(!frozenAccount[msg.sender] && balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      }
      return false;
      
  }

  function burn(uint256 _value) returns (bool success) {
    if (balances[msg.sender] < _value) throw;            
    balances[msg.sender] -= _value;                      
    totalSupply -= _value;                                
    Burn(msg.sender, _value);
    return true;
  }

  function burnFrom(address _from, uint256 _value) returns (bool success) {
    if (balances[_from] < _value) throw;                
    if (_value > allowed[_from][msg.sender]) throw;    
    balances[_from] -= _value;                          
    totalSupply -= _value;                               
    Burn(_from, _value);
    return true;
  }

  function freezeAccount(address _target, bool frozen){
    frozenAccount[_target] = frozen;
    FrozenFunds(_target, frozen);
  }

  function getDecimals() public returns (uint256){
    return decimals;
  }

  function getOwner() public returns (address){
    return kairosOwner;
  }

}