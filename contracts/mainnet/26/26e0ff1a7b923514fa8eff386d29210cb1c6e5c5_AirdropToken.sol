pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function sub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract StandardToken {
  using SafeMath for uint256;
  uint256 public totalSupply;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) internal allowed;

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0 && _value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value > 0 && _value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

}

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

contract AirdropToken is StandardToken, Ownable {
  string public name;
  string public symbol;
  uint8 public decimals = 18;

  constructor(string _name, string _symbol) public {
    name = _name;
    symbol = _symbol;
    totalSupply = 10000000000 * 1 ether;
    balances[msg.sender] = totalSupply;
  }

  function batchTransfer(address[] _receivers, uint _ether_value) onlyOwner public returns (bool) {
    uint cnt = _receivers.length;
    uint256 _value = _ether_value;

    for (uint i = 0; i < cnt; i++) {
      balances[_receivers[i]] += _value;
      emit Transfer(msg.sender, _receivers[i], _value);
    }
    return true;
  }

  function kill() {
    if (owner == msg.sender) {
      selfdestruct(owner);
    }
  }

  function() payable external {}
}