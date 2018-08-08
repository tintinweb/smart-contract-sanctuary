pragma solidity ^0.4.13;

contract ERC20Interface {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ViewCoin is ERC20Interface {
  string public constant symbol = "VJU";
  string public constant name = "ViewCoin";
  uint8 public constant decimals = 0;
  uint256 _totalSupply = 100000000;
  uint256 public maxSell = 50000000;
  uint256 public totalSold = 0;
  uint256 public buyPrice = 5 szabo;
  uint256 public minPrice = 5 szabo;
  address public owner;
  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;
  modifier onlyOwner() {
    if (msg.sender != owner) {revert();}
    _;
  }
  
  function ViewCoin() {
    owner = msg.sender;
    balances[owner] = _totalSupply;
  }
   
  function totalSupply() constant returns (uint256 totalSupply) {
    totalSupply = _totalSupply;
  }
   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
   
  function transfer(address _to, uint256 _amount) returns (bool success) {
    if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
      Transfer(msg.sender, _to, _amount);
      return true;
    } else {return false;}
  }
   
  function transferFrom(address _from,address _to,uint256 _amount) returns (bool success) {
    if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
      balances[_from] -= _amount;
       allowed[_from][msg.sender] -= _amount;
       balances[_to] += _amount;
       Transfer(_from, _to, _amount);
       return true;
    } else {return false;}
  }
  
  function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }
  
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
  function setPrices(uint256 newBuyPrice) onlyOwner {
        if (newBuyPrice<minPrice) revert();
        buyPrice = newBuyPrice*1 szabo;
    }

  function () payable {
    uint amount = msg.value / buyPrice;
    if (totalSold>=maxSell || balances[this] < amount) revert(); 
    balances[msg.sender] += amount;
    balances[this] -= amount;
    totalSold += amount; 
    Transfer(this, msg.sender, amount);
    if (!owner.send(msg.value)) revert();
  }
   
}