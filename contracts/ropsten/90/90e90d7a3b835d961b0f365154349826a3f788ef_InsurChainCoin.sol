pragma solidity ^0.4.24;

library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function batchTransfer(address[] receivers, uint256[] values) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;
  uint256 internal totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function batchTransfer(address[] _receivers, uint256[] _values) public returns (bool) {
    require(_receivers.length > 0);
    require(_receivers.length < 100000);
    require(_receivers.length == _values.length);

    uint256 sum;
    for(uint i = 0; i < _values.length; i++) {
      sum = sum.add(_values[i]);
    }
    require(sum <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(sum);
    for(uint j = 0; j < _receivers.length; j++) {
      balances[_receivers[j]] = balances[_receivers[j]].add(_values[j]);
      emit Transfer(msg.sender, _receivers[j], _values[j]);
    }
    return true;
  }
}

contract InsurChainCoin is BasicToken {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor() public {
    name = "InsurChain2.0";
    symbol = "INSUR";
    decimals = 18;
    totalSupply_ = 2e28;
    balances[msg.sender]=totalSupply_;
    emit Transfer(address(0), msg.sender, totalSupply_);
  }
}