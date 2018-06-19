pragma solidity ^0.4.4;

contract EtownCoinTest {
  string public standard = &#39;ERC20&#39;;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function EtownCoinTest(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol
    ) {
    balanceOf[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    name = tokenName;
    symbol = tokenSymbol;
    decimals = decimalUnits;
  }

  function transfer(address _to, uint256 _value) {
    if (_to == 0x0) revert();
    if (balanceOf[msg.sender] < _value) revert();
    if (balanceOf[_to] + _value < balanceOf[_to]) revert();
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    Transfer(msg.sender, _to, _value);
  }

  function approve(address _spender, uint256 _value)
    returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    success = true;
  }    

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    if (_to == 0x0) revert();
    if (balanceOf[_from] < _value) revert();
    if (balanceOf[_to] + _value < balanceOf[_to]) revert();
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    success = true;
  }
}