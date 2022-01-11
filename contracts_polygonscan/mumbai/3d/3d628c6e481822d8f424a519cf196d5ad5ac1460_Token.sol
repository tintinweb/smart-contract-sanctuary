// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC20.sol";
import "./AccessControlEnumerable.sol";

contract Token is IERC20, AccessControlEnumerable
{
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


  string private _name;
  string private _symbol;
  uint256 private _totalSupply;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;


  constructor (string memory name_, string memory symbol_)
  {
    _name = name_;
    _symbol = symbol_;

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(MINTER_ROLE, msg.sender);
  }

  function name () public view virtual returns (string memory)
  {
    return _name;
  }

  function symbol () public view virtual returns (string memory)
  {
    return _symbol;
  }

  function decimals() public view virtual returns (uint8)
  {
    return 18;
  }

  function totalSupply () public view virtual override returns (uint256)
  {
    return _totalSupply;
  }

  function balanceOf (address account) public view virtual override returns (uint256)
  {
    return _balances[account];
  }

  function allowance (address owner, address spender) public view virtual override returns (uint256)
  {
    return _allowances[owner][spender];
  }


  function _transfer (address sender, address recipient, uint256 amount) internal virtual
  {
    require(sender != address(0), "ERC20: tx from 0 addr");
    require(recipient != address(0), "ERC20: tx to 0 addr");

    uint256 senderBalance = _balances[sender];

    require(senderBalance >= amount, "ERC20: tx amt > balance");

    unchecked
    {
      _balances[sender] = senderBalance - amount;
    }

    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function transfer (address recipient, uint256 amount) public virtual override returns (bool)
  {
    _transfer(msg.sender, recipient, amount);

    return true;
  }

  function transferFrom (address sender, address recipient, uint256 amount) public virtual override returns (bool)
  {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][msg.sender];

    require(currentAllowance >= amount, "ERC20: tx amt > allowance");

    unchecked
    {
      _approve(sender, msg.sender, currentAllowance - amount);
    }

    return true;
  }


  function _approve (address owner, address spender, uint256 amount) internal virtual
  {
    require(owner != address(0), "ERC20: approve from 0 addr");
    require(spender != address(0), "ERC20: approve to 0 addr");

    _allowances[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool)
  {
    _approve(msg.sender, spender, amount);

    return true;
  }

  function increaseAllowance (address spender, uint256 addedValue) public virtual returns (bool)
  {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);

    return true;
  }

  function decreaseAllowance (address spender, uint256 subtractedValue) public virtual returns (bool)
  {
    uint256 currentAllowance = _allowances[msg.sender][spender];

    require(currentAllowance >= subtractedValue, "ERC20: allowance < 0");

    unchecked
    {
      _approve(msg.sender, spender, currentAllowance - subtractedValue);
    }

    return true;
  }


  function _mint (address account, uint256 amount) internal virtual
  {
    require(account != address(0), "ERC20: mint to 0 addr");

    _totalSupply += amount;
    _balances[account] += amount;

    emit Transfer(address(0), account, amount);
  }

  function mint (address to, uint256 amount) public virtual
  {
    require(hasRole(MINTER_ROLE, msg.sender), "ERC20: !minter");

    _mint(to, amount);
  }


  function _burn (address account, uint256 amount) internal virtual
  {
    require(hasRole(MINTER_ROLE, msg.sender), "ERC20: !minter");
    require(account != address(0), "ERC20: burn from 0 addr");

    uint256 accountBalance = _balances[account];

    require(accountBalance >= amount, "ERC20: burn amt > balance");

    unchecked
    {
      _balances[account] = accountBalance - amount;
    }

    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  function burn (uint256 amount) public virtual
  {
    _burn(msg.sender, amount);
  }

  function burnFrom (address account, uint256 amount) public virtual
  {
    uint256 currentAllowance = allowance(account, msg.sender);

    require(currentAllowance >= amount, "ERC20: burn amt > allowance");

    unchecked
    {
      _approve(account, msg.sender, currentAllowance - amount);
    }

    _burn(account, amount);
  }

  function setMinterAddress (address account) public virtual
  {
    require(hasRole(MINTER_ROLE, msg.sender), "ERC20: !minter");

    _setupRole(MINTER_ROLE, account);

  }

  function setAdminAddress (address account) public virtual
  {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ERC20: !admin");

    _setupRole(DEFAULT_ADMIN_ROLE, account);

  }
}