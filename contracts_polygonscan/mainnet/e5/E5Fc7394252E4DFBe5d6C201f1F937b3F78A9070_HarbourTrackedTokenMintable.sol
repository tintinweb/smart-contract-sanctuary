/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC677 is IERC20 {
  function transferAndCall(
    address recipient,
    uint256 value,
    bytes memory data
  ) external returns (bool);
}

interface IERC677Receiver {
  function onTokenTransfer(
    address sender,
    uint256 value,
    bytes memory data
  ) external;
}

interface ITrackedToken is IERC20 {
  function lastSendBlockOf(address account) external view returns (uint256);
}

abstract contract Context {
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

abstract contract AdminRole is Context {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _admins.add(_msgSender());
    emit AdminAdded(_msgSender());
  }

  modifier onlyAdmin() {
    require(
      _admins.has(_msgSender()),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function addAdmin(address account) public onlyAdmin {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function renounceAdmin() public onlyAdmin {
    _admins.remove(_msgSender());
    emit AdminRemoved(_msgSender());
  }
}

abstract contract CreatorWithdraw is Context, AdminRole {
  address payable private _creator;

  constructor() {
    _creator = payable(_msgSender());
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {
    // thank you
  }

  function withdraw(address erc20, uint256 amount) public onlyAdmin {
    if (erc20 == address(0)) {
      _creator.transfer(amount);
    } else if (erc20 != address(this)) {
      IERC20(erc20).transfer(_creator, amount);
    }
  }
}

abstract contract Owned is Context, AdminRole {
  address private _owner;

  constructor() {
    _owner = _msgSender();
  }

  function getOwner() public view returns (address) {
    return _owner;
  }

  function setOwner(address owner) public onlyAdmin {
    _owner = owner;
  }
}

abstract contract MinterRole is Context {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private _minters;

  constructor() {
    _minters.add(_msgSender());
    emit MinterAdded(_msgSender());
  }

  modifier onlyMinter() {
    require(
      _minters.has(_msgSender()),
      'MinterRole: caller does not have the Minter role'
    );
    _;
  }

  function addMinter(address account) public onlyMinter {
    _minters.add(account);
    emit MinterAdded(account);
  }

  function renounceMinter() public onlyMinter {
    _minters.remove(_msgSender());
    emit MinterRemoved(_msgSender());
  }
}

abstract contract ERC20Detailed {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(
    string memory __name,
    string memory __symbol,
    uint8 __decimals
  ) {
    _name = __name;
    _symbol = __symbol;
    _decimals = __decimals;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }
}

abstract contract ERC20Tracked is Context, ITrackedToken {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => uint256) private _lastSendBlock;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function lastSendBlockOf(address account)
    public
    view
    override
    returns (uint256)
  {
    return _lastSendBlock[account];
  }

  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        'ERC20: transfer amount exceeds allowance'
      )
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _balances[sender] = _balances[sender].sub(
      amount,
      'ERC20: transfer amount exceeds balance'
    );
    _balances[recipient] = _balances[recipient].add(amount);
    _lastSendBlock[sender] = block.number;
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), 'ERC20: mint to the zero address');

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), 'ERC20: burn from the zero address');

    _balances[account] = _balances[account].sub(
      amount,
      'ERC20: burn amount exceeds balance'
    );
    _lastSendBlock[account] = block.number;
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(
      account,
      _msgSender(),
      _allowances[account][_msgSender()].sub(
        amount,
        'ERC20: burn amount exceeds allowance'
      )
    );
  }
}

abstract contract ERC667Tracked is IERC677, ERC20Tracked {
  function transferAndCall(
    address recipient,
    uint256 value,
    bytes memory data
  ) public returns (bool) {
    transfer(recipient, value);
    IERC677Receiver(recipient).onTokenTransfer(_msgSender(), value, data);
    return true;
  }
}

abstract contract ERC20Mintable is ERC20Tracked, MinterRole {
  function mint(address account, uint256 amount)
    public
    onlyMinter
    returns (bool)
  {
    _mint(account, amount);
    return true;
  }
}

contract HarbourTrackedToken is
  ERC667Tracked,
  ERC20Detailed,
  Owned,
  CreatorWithdraw
{
  constructor(
    string memory name,
    string memory symbol,
    uint256 fixedSupply
  ) ERC20Detailed(name, symbol, 18) {
    _mint(_msgSender(), fixedSupply);
  }
}

contract HarbourTrackedTokenMintable is
  ERC667Tracked,
  ERC20Detailed,
  ERC20Mintable,
  Owned,
  CreatorWithdraw
{
  constructor(string memory name, string memory symbol)
    ERC20Detailed(name, symbol, 18)
  {}
}