pragma solidity ^0.4.0;

// import &quot;./ERC20.sol&quot;;

contract ERC20 {
  address public owner;
  string public name;
  string public symbol;
  uint256 public decimals;
  string public icon;
  uint256 public totalSupply;
  function balanceOf(address _owner) view public returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) view public returns (uint remaining);
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract MyThirdToken is ERC20 {
  mapping (address => uint) private __balanceOf;
  mapping (address => mapping (address => uint)) private __allowances;
  
  constructor (string _name, string _symbol, uint256 _decimals, string _icon, uint256 _totalSupply) public {
    owner = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    icon = _icon;
    totalSupply = _totalSupply;
    __balanceOf[owner] = totalSupply;
  }
  
  function balanceOf(address _addr) view public returns (uint balance) {
    return __balanceOf[_addr];
  }
    
  function transfer(address _to, uint _value) public returns (bool success) {
    if (_value > 0 && _value <= balanceOf(msg.sender)) {
      __balanceOf[msg.sender] -= _value;
      __balanceOf[_to] += _value;
      emit Transfer(msg.sender, _to, _value);
      emit Approval(msg.sender, _to, _value);
      return true;
    }
    return false;
  }
  
  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    if (__allowances[_from][msg.sender] > 0 &&
        _value > 0 &&
        __allowances[_from][msg.sender] >= _value && 
        __balanceOf[_from] >= _value) {
      __balanceOf[_from] -= _value;
      __balanceOf[_to] += _value;
      // Missed from the video
      __allowances[_from][msg.sender] -= _value;
      return true;
      }
    return false;
  }
    
  function approve(address _spender, uint _value) public returns (bool success) {
    __allowances[msg.sender][_spender] = _value;
    return true;
  }
    
  function allowance(address _owner, address _spender) view public returns (uint remaining) {
    return __allowances[_owner][_spender];
  }
}