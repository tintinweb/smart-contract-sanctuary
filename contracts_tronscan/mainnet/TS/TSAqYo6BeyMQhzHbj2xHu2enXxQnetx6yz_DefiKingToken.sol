//SourceUnit: Defiking_TRC20.sol

pragma solidity ^0.4.25;

 /**
 * TRC-20 token DefiKing (DFK)
 * Coded by Defiking.io (2020)
 */

contract DefiKingToken {
  string public name;
  string public symbol;
  uint8 public decimals = 8;
  uint256 public totalSupply;
  address public owner = msg.sender;
  uint256 initialSupply = 100000000;
  string public tokenName = 'DefiKing';
  string public tokenSymbol = 'DFK';
  uint256 public mintCap = 100000000000000000;
  
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Burn(address indexed from, uint256 value);
  
  constructor() public {
    totalSupply = initialSupply * 10 ** uint256(decimals);
    balanceOf[msg.sender] = totalSupply;
    name = tokenName;
    symbol = tokenSymbol;
  }
  
  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != 0x0);
    require(balanceOf[_from] >= _value);
    require(balanceOf[_to] + _value > balanceOf[_to]);
    uint previousBalances = balanceOf[_from] + balanceOf[_to];
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
    assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }
  
  function transferFrom(address _from, address _to, uint256 _value) 
  public returns (bool success) {
    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }
  
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  
  function burn(uint256 _value) public returns (bool) {
    require(_value > 0);
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] -= _value;
    totalSupply -= _value; // Updates totalSupply
    emit Burn(msg.sender, _value);
    return true;
  }
  
  function burnFrom(address _from, uint256 _value) public returns (bool) {
    require(_value > 0);
    require(balanceOf[_from] >= _value);
    require(_value <= allowance[_from][msg.sender]);
    balanceOf[_from] -= _value;
    allowance[_from][msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(_from, _value);
    return true;
  }
  
  function transferOwnership(address newOwner) public returns (bool) {
    require(owner == msg.sender);
    require(newOwner != address(0));
    require(newOwner != address(this));
    owner = newOwner;
  }

  function withdrawTRX() public returns (bool){
    require(owner == msg.sender);
    msg.sender.transfer(address(this).balance);
    return true;
  }

  function withdrawTRC10(trcToken id) payable public {
    require(owner == msg.sender);
    require(id > 1000000);
    uint256 amount = address(this).tokenBalance(id);
    msg.sender.transferToken(amount, id);
  }
  
  function withdrawTRC20(address _tokenContract) public returns (bool){
    require(owner == msg.sender);
    require(_tokenContract != address(0));
    TRC20Token token = TRC20Token(_tokenContract);
    uint256 amount = token.balanceOf(address(this));
    return token.transfer(msg.sender, amount);
  }
  
  function increaseAllowance(address _spender, uint256 addedValue)
  public returns (bool) {
    require(_spender != address(0));
    require(addedValue > 0);
    allowance[msg.sender][_spender] += addedValue;
    emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
    return true;
  }
  
  function decreaseAllowance(address _spender, uint256 subtractedValue)
  public returns (bool) {
    require(_spender != address(0));
    require(subtractedValue > 0);
    allowance[msg.sender][_spender] -= subtractedValue;
    emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
    return true;
  }

  function mint(uint256 amount) public returns (bool) {
    require(owner == msg.sender);
    require(totalSupply + amount > totalSupply);
    require(mintCap >= totalSupply + amount);
    totalSupply += amount;
    balanceOf[msg.sender] += amount;
    emit Transfer(address(0), msg.sender, amount);
    return true;
  }
}

contract TRC20Token {
  function balanceOf(address _owner) constant returns (uint256);
  function transfer(address _to, uint256 _value) returns (bool);
  function approve(address _spender, uint tokens) public returns (bool);
}