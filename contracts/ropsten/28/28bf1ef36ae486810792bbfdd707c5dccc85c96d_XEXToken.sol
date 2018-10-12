pragma solidity ^0.4.25;

library SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }
    uint256 c = _a * _b;
    require(c / _a == _b);
    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);
    uint256 c = _a / _b;
    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;
    return c;
  }

  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);
    return c;
  }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  function add(Role storage _role, address _account) internal {
    require(_account != address(0));
    _role.bearer[_account] = true;
  }

  function remove(Role storage _role, address _account) internal {
    require(_account != address(0));
    _role.bearer[_account] = false;
  }

  function has(Role storage _role, address _account) internal view returns (bool)
  {
    require(_account != address(0));
    return _role.bearer[_account];
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _who) external view returns (uint256);

  function allowance(address _owner, address _spender) external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function approve(address _spender, uint256 _value) external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) private balances;

  mapping(address => mapping (address => uint256)) private allowed;

  uint256 private totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
    
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    require(_spender != address(0));

    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
    require(_spender != address(0));

    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].sub(_subtractedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);

    totalSupply_ = totalSupply_.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

  function _burn(address _account, uint256 _amount) internal {
    require(_account != 0);
    require(_amount <= balances[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances[_account] = balances[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }
}

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed _account);
  event PauserRemoved(address indexed _account);

  Roles.Role private pausers;

  constructor() public {
    addPauser_(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address _account) public view returns (bool) {
    return pausers.has(_account);
  }

  function addPauser(address _account) public onlyPauser {
    addPauser_(_account);
  }

  function renouncePauser() public {
    removePauser_(msg.sender);
  }

  function addPauser_(address _account) internal {
    pausers.add(_account);
    emit PauserAdded(_account);
  }

  function removePauser_(address _account) internal {
    pausers.remove(_account);
    emit PauserRemoved(_account);
  }
}

contract Pausable is PauserRole {
  event Pause();
  event Unpause();

  bool private paused_ = false;

  function paused() public view returns(bool) {
    return paused_;
  }

  modifier whenNotPaused() {
    require(!paused_);
    _;
  }

  modifier whenPaused() {
    require(paused_);
    _;
  }

  function pause() public onlyPauser whenNotPaused {
    paused_ = true;
    emit Pause();
  }

  function unpause() public onlyPauser whenPaused {
    paused_ = false;
    emit Unpause();
  }
}

contract ERC20Pausable is ERC20, Pausable {
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseAllowance(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseAllowance(_spender, _addedValue);
  }

  function decreaseAllowance(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseAllowance(_spender, _subtractedValue);
  }
}

contract ERC20Burnable is ERC20 {
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }
}

contract XEXToken is ERC20Pausable, ERC20Burnable {
  string public constant name = "CROSS exchange token";
  string public constant symbol = "XEX";
  uint8 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(decimals));

  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
  }
}