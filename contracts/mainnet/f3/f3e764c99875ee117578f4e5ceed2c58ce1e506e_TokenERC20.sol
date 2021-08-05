/**
 *Submitted for verification at Etherscan.io on 2020-04-16
*/

pragma solidity ^0.6.4;

contract SafeMath {
  function safeAdd(uint256 _a, uint256 _b) internal returns (uint256) {
    uint256 c = _a + _b;
    assert(c >= _a);
    return c;
  }
  function safeSub(uint256 _a, uint256 _b) internal returns (uint256) {
    assert(_a >= _b);
    return _a - _b;
  }
  function safeMul(uint256 _a, uint256 _b) internal returns (uint256) {
    uint256 c = _a * _b;
    assert(_a == 0 || c / _a == _b);
    return c;
  }
}

contract TokenERC20 is SafeMath{
  string public name;
  string public symbol;
  uint8 public decimals = 18;
  uint256 public totalSupply;
  address public owner;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Burn(address indexed _from, uint256 _value);

  modifier validAddress(address _address){
    require(_address != address(0));
    _;
  }

  constructor (uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
    totalSupply = initialSupply * 10 ** uint256(decimals);
    balanceOf[msg.sender] = totalSupply;
    name = tokenName;
    symbol = tokenSymbol;
    owner = msg.sender;
  }


  function _transfer(address _from, address _to, uint256 _value) internal  {

    require(balanceOf[_from] >= _value);
    require(balanceOf[_to] + _value > balanceOf[_to]);
    balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
    balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
    emit Transfer(_from, _to, _value);

  }
  function transfer(address _to, uint256 _value) public validAddress(_to) returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public
    validAddress(_from)
    validAddress(_to)
    returns (bool success) {
    allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
    _transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public validAddress(_spender) returns (bool success) {
    require(_value == 0 || allowance[msg.sender][_spender] == 0);
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function burn(uint256 _value) public returns (bool success) {
    require(_value >= 0);
    balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
    totalSupply = SafeMath.safeSub(totalSupply, _value);
    emit Burn(msg.sender, _value);
    return true;
  }

}