contract FCOIN0939Token {
  address public owner;
  string public name;
  string public symbol;
  uint public decimals;
  uint256 public totalSupply;
  event Transfer(address indexed from, address indexed to, uint256 value);
  mapping (address => uint256) public balanceOf;
  
  function FCOIN0939Token(uint256 initialSupply, string tokenName, string tokenSymbol, uint decimalUnits) public {
    owner = msg.sender;
    totalSupply = initialSupply;
    balanceOf[msg.sender] = totalSupply;
    name = tokenName;
    symbol = tokenSymbol;
    decimals = decimalUnits;
  }

  function transfer(address _to, uint256 _value) public {
    require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
  }
}