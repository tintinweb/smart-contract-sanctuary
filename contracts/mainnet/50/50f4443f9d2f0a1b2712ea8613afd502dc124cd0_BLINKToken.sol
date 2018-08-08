pragma solidity ^0.4.24;

contract BLINKToken {
  mapping (address => mapping (address => uint256)) allowed;
  mapping(address => uint256) balances;
  uint256 public decimals = 18;
  bool public mintingFinished = false;
  string public name = "BLOCKMASON LINK TOKEN";
  address public owner;
  string public symbol = "BLINK";
  uint256 public totalSupply;

  event Approval(address indexed tokenholder, address indexed spender, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event Transfer(address indexed from, address indexed to, uint256 value);

  constructor() public {
    owner = msg.sender;
  }

  function allowance(address _tokenholder, address _spender) public constant returns (uint256 remaining) {
    return allowed[_tokenholder][_spender];
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
    require(_spender != msg.sender);

    allowed[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);

    return true;
  }

  function balanceOf(address _tokenholder) public constant returns (uint256 balance) {
    return balances[_tokenholder];
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
    require(_spender != address(0));
    require(_spender != msg.sender);

    if (allowed[msg.sender][_spender] <= _subtractedValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender] - _subtractedValue;
    }

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;
  }

  function finishMinting() public returns (bool) {
    require(msg.sender == owner);
    require(!mintingFinished);

    mintingFinished = true;

    emit MintFinished();

    return true;
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
    require(_spender != address(0));
    require(_spender != msg.sender);
    require(allowed[msg.sender][_spender] < allowed[msg.sender][_spender] + _addedValue);

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;
  }

  function mint(address _to, uint256 _amount) public returns (bool) {
    require(msg.sender == owner);
    require(!mintingFinished);
    require(_to != address(0));
    require(totalSupply < totalSupply + _amount);
    require(balances[_to] < balances[_to] + _amount);

    totalSupply = totalSupply + _amount;
    balances[_to] = balances[_to] + _amount;

    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);

    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_to != msg.sender);
    require(balances[msg.sender] - _value < balances[msg.sender]);
    require(balances[_to] < balances[_to] + _value);
    require(_value <= transferableTokens(msg.sender, 0));

    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_from != address(0));
    require(_to != address(0));
    require(_to != _from);
    require(_value <= transferableTokens(_from, 0));
    require(allowed[_from][msg.sender] - _value < allowed[_from][msg.sender]);
    require(balances[_from] - _value < balances[_from]);
    require(balances[_to] < balances[_to] + _value);

    allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
    balances[_from] = balances[_from] - _value;
    balances[_to] = balances[_to] + _value;

    emit Transfer(_from, _to, _value);

    return true;
  }

  function transferOwnership(address _newOwner) public {
    require(msg.sender == owner);
    require(_newOwner != address(0));
    require(_newOwner != owner);

    address previousOwner = owner;
    owner = _newOwner;

    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function transferableTokens(address holder, uint64) public constant returns (uint256) {
    if (mintingFinished) {
      return balanceOf(holder);
    }
    return 0;
  }
}