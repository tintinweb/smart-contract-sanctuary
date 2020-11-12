// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/// Know more: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

abstract contract ERC20 is IERC20 {
  using SafeMath for uint256;
  using Address for address;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _initialSupply;
  uint256 private _totalSupply;
  uint256 private _totalSupplyCap;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor (
    string memory name,
    string memory symbol,
    uint256 totalSupplyCap,
    uint256 initialSupply
  ) public {
    _decimals = 8;

    _name = name;
    _symbol = symbol;
    _totalSupplyCap = totalSupplyCap;
    _initialSupply = initialSupply;
  }

  function name()
  public view returns (string memory) {
    return _name;
  }

  function symbol()
  public view returns (string memory) {
    return _symbol;
  }

  function decimals()
  public view returns (uint8) {
    return _decimals;
  }

  function initialSupply()
  public view override returns (uint256) {
    return _initialSupply;
  }

  function totalSupply()
  public view override returns (uint256) {
    return _totalSupply;
  }

  function totalSupplyCap()
  public view override returns (uint256) {
    return _totalSupplyCap;
  }

  function balanceOf(
    address account
  ) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(
    address owner,
    address spender
  ) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  ) public virtual override returns (bool) {
    _approve(msg.sender, spender, (amount * (10**8)));
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, _allowances[sender][msg.sender].sub((amount * (10**8)), "ERC20:490"));
    return true;
  }

  function increaseAllowance(
    address spender,
    uint256 addedValue
  ) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].add((addedValue * (10**8))));
    return true;
  }

  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  ) public virtual returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender].sub((subtractedValue * (10**8)), "ERC20:495"));
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(
      sender != address(0),
      "ERC20:410"
    );

    require(
      recipient != address(0),
      "ERC20:420"
    );

    require(
      amount > 0,
      "ERC20:480"
    );

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20:470");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(
    address account,
    uint256 amount
  ) internal virtual {
    require(
      account != address(0),
      "ERC20:120"
    );

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(
    address account,
    uint256 amount
  ) internal virtual {
    require(
      account != address(0),
      "ERC20:220"
    );

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20:230");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(
      owner != address(0),
      "ERC20:450"
    );
    require(
      spender != address(0),
      "ERC20:460"
    );

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setupDecimals(
    uint8 decimals_
  ) internal {
    _decimals = decimals_;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}