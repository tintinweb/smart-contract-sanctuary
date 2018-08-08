pragma solidity ^0.4.0;

// import "./ERC20.sol";

contract ERC20 {
  function totalSupply() view public returns (uint _totalSupply);
  function balanceOf(address _owner) view public returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) view public returns (uint remaining);
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract MyFirstToken is ERC20 {
  string public constant symbol = "SCT";
  string public constant name = "My Second Token";
  uint8 public constant decimals = 10;
  
  uint private constant __totalSupply = 10000;
  mapping (address => uint) private __balanceOf;
  mapping (address => mapping (address => uint)) private __allowances;
  
  constructor () public {
    __balanceOf[msg.sender] = __totalSupply;
  }
  
  function totalSupply() view public returns (uint _totalSupply) {
    _totalSupply = __totalSupply;
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