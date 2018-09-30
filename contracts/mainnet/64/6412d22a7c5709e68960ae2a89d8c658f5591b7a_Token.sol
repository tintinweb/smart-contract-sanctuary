pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract AbstractERC20 {

  uint256 public totalSupply;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
}

/*
Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/
contract StandardToken is AbstractERC20 {
    
  using SafeMath for uint256;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  function transfer(address _to, uint256 _value) public returns (bool success) {

    require(balances[msg.sender] >= _value);
    require(_to != 0x0);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

    require(balances[_from] >= _value);
    require(allowed[_from][msg.sender] >= _value);
    require(_to != 0x0);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {

    require(_spender != 0x0);
    require(_value == 0 || allowed[msg.sender][_spender] == 0);

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract Owned {

  address public owner;
  address public newOwner;

  event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier ownerOnly {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public ownerOnly {
    require(_newOwner != owner);
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnerUpdate(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract Mintable is StandardToken {

  event Emission(uint256 _amount);

  function _mint(address _to, uint256 _amount) internal {

    require(_amount > 0);
    require(_to != 0x0);
    balances[_to] = balances[_to].add(_amount);
    totalSupply = totalSupply.add(_amount);
    emit Emission(_amount);
    emit Transfer(this, _to, _amount);
  }
}

contract Destroyable is StandardToken {

  event Destruction(uint256 _amount);

  function _destroy(address _from, uint256 _amount) internal {

    require(balances[_from] >= _amount);
    balances[_from] = balances[_from].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    emit Destruction(_amount);
    emit Transfer(_from, this, _amount);
  }
}

contract Token is StandardToken, Owned, Destroyable, Mintable {

  address owner;
  string constant public name = "GoldSecure";
  string constant public symbol = "GOLD";
  uint8 constant public decimals = 8;
  
  event Burn(address indexed _burner, uint256 _value);
  
  constructor(uint256 _initialSupply) public {
  
    owner = msg.sender;
    balances[owner] = _initialSupply;
    totalSupply = _initialSupply;
  }
  
  function issue(address _to, uint256 _amount) external ownerOnly {

    _mint(_to, _amount);
  }
  
  function destroy(address _from, uint256 _amount) external ownerOnly {

    _destroy(_from, _amount);
  }
  
  function burn(uint256 _amount) external {

    _destroy(msg.sender, _amount);
    emit Burn(msg.sender, _amount);
  }
}