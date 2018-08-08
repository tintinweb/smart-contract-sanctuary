pragma solidity ^0.4.2;

// Safe maths
library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract ApproveAndCallFallBack {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _data) public;
}

// Owned contract
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
contract ERC20Interface {
  function totalSupply() public constant returns (uint _supply);
  function balanceOf(address _owner) public constant returns (uint balance);
  function allowance(address _owner, address _spender) public constant returns (uint remaining);
  function transfer(address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract VouchCoin is Ownable, ERC20Interface {
  using SafeMath for uint;

  uint public _totalSupply = 10000000000000000;
  string public constant name = "VouchCoin";
  string public constant symbol = "VHC";
  uint public constant decimals = 8;
  string public standard = "VouchCoin token v2.0";

  mapping (address => uint) balances;
  mapping (address => mapping (address => uint)) allowances;

  event Burn(address indexed _from, uint _value);

  // Constructor
  function VouchCoin() public {
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }

  // Total supply
  function totalSupply() public constant returns (uint _supply) {
    return _totalSupply;
  }

  // Get the token balance of address
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  // Transfer tokens from owner address
  function transfer(address _to, uint _value) public returns (bool success) {
    require(_to != 0x0);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) public returns(bool success) {
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function approveAndCall(address _spender, uint _value, bytes _data) public returns (bool success) {
    approve(_spender, _value);
    emit Approval(msg.sender, _spender, _value);
    ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, this, _data);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    balances[_from] = balances[_from].sub(_value);
    allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowances[_owner][_spender];
  }

  function burnTokens(uint _amount) public onlyOwner {
    _totalSupply = _totalSupply.sub(_amount);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    emit Burn(msg.sender, _amount);
    emit Transfer(msg.sender, 0x0, _amount);
  }
}