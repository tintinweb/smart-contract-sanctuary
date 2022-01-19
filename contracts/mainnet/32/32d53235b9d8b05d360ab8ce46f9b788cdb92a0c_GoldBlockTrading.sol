/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.25;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);

  function balanceOf(address who) public view returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  mapping(address => uint256) freezeOf;
  uint256 _totalSupply;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0) && _value > 0 && _value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

contract ERC20Token is BasicToken, ERC20 {
  using SafeMath for uint256;
  mapping(address => mapping(address => uint256)) allowed;
  mapping(address => uint256) freezeOf;

  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_value == 0 || allowed[msg.sender][_spender] == 0);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);

    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool success) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;
  }
}

contract Ownable {

  address public owner;
  mapping(address => bool) admin;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyOwnerOrAdmin() {
    require(msg.sender != address(0) || msg.sender == owner || admin[msg.sender] == true);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0) && newOwner != owner && admin[newOwner] == true);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  function setAdmin(address newAdmin) onlyOwner public {
    require(admin[newAdmin] != true && owner != newAdmin);
    admin[newAdmin] = true;
  }

  function unsetAdmin(address Admin) onlyOwner public {
    require(admin[Admin] != false && owner != Admin);
    admin[Admin] = false;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  function has(Role storage role, address account) internal view returns (bool){
    require(account != address(0));
    return role.bearer[account];
  }
}

contract BurnableToken is BasicToken, Ownable {
  event Burn(address indexed burner, uint256 amount);

  function burn(uint256 _value) onlyOwner public {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    _totalSupply = _totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0), _value);
  }
}

contract GoldBlockTrading is BurnableToken, DetailedERC20, ERC20Token, Pausable {
  using SafeMath for uint256;

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event LockerChanged(address indexed _address, uint256 amount);
  event Recall(address indexed from, uint256 amount);

  mapping(address => uint) public locker;

  string public constant symbol = "GBT";
  string public constant name = "GoldBlockTrading";
  uint8 public constant decimals = 18;

  uint256 public constant TOTAL_SUPPLY = 100 * (10 ** 8) * (10 ** uint256(decimals));

  constructor() DetailedERC20(name, symbol, decimals) public {
    _totalSupply = TOTAL_SUPPLY;
    balances[owner] = _totalSupply;
    emit Transfer(address(0x0), msg.sender, _totalSupply);
  }

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(balances[msg.sender].sub(_value) >= locker[msg.sender]);

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(balances[_from].sub(_value) >= locker[_from]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    emit Transfer(_from, _to, _value);

    return true;
  }

  function lockOf(address _address) public view returns (uint256 _locker) {
    return locker[_address];
  }

  function setLock(address _address, uint256 _value) public onlyOwnerOrAdmin {
    require(_value <= _totalSupply && _address != address(0));
    locker[_address] = _value;
    emit LockerChanged(_address, _value);
  }

  function recall(address _from, uint256 _amount) public onlyOwnerOrAdmin {

    require(_amount > 0);

    uint256 currentLocker = locker[_from];
    uint256 currentBalance = balances[_from];

    require(currentLocker >= _amount && currentBalance >= _amount);

    uint256 newLock = currentLocker.sub(_amount);
    locker[_from] = newLock;
    emit LockerChanged(_from, newLock);

    balances[_from] = balances[_from].sub(_amount);
    balances[owner] = balances[owner].add(_amount);
    emit Transfer(_from, owner, _amount);
    emit Recall(_from, _amount);
  }

  function transferList(address[] _recipients, uint256[] _balances) public onlyOwnerOrAdmin {
    require(_recipients.length == _balances.length);

    for (uint i = 0; i < _recipients.length; i++) {
      balances[msg.sender] = balances[msg.sender].sub(_balances[i]);
      balances[_recipients[i]] = balances[_recipients[i]].add(_balances[i]);
      emit Transfer(msg.sender, _recipients[i], _balances[i]);
    }
  }

  function setLockList(address[] _recipients, uint256[] _balances) public onlyOwnerOrAdmin {
    require(_recipients.length == _balances.length);

    for (uint i = 0; i < _recipients.length; i++) {
      locker[_recipients[i]] = _balances[i];
      emit LockerChanged(_recipients[i], _balances[i]);
    }
  }

  function destroy() public onlyOwner {
    selfdestruct(msg.sender);
  }
}