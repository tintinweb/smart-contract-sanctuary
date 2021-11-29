// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './Ownable.sol';
import './Stakeable.sol';

contract GabrielToken is Ownable, Stakeable {

  uint private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor(
    string memory token_name,
    string memory short_symbol,
    uint8 token_decimals,
    uint256 token_totalSupply
  ) {
    _name = token_name;
    _symbol = short_symbol;
    _decimals = token_decimals;
    _totalSupply = token_totalSupply;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function name() external view returns (string memory) {
    return _name;
  }
  
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function getOwner() external view returns (address) {
    return owner();
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), 'GabrielToken: approve cannot be done from zero address');
    require(spender != address(0), 'GabrielToken: approve cannot be done to zero address');

    _allowances[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }

  function transferFrom(address spender, address recipient, uint256 amount) external returns (bool) {
    require(_allowances[spender][msg.sender] >= amount, 'GabrielToken: not enough allowance');

    _transfer(spender, recipient, amount);
    _approve(spender, msg.sender, _allowances[spender][msg.sender] - amount);

    return true;
  }

  function decreaseAllowance(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] - amount);
    return true;
  }

  function mint(address account, uint256 amount) external onlyOwner returns (bool) {
    _mint(account, amount);
    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), 'GabrielToken: Cannot mint to zero address');

    _totalSupply += amount;
    _balances[account] += amount;

    emit Transfer(address(0), account, amount);
  }

  function burn(address account, uint256 amount) external onlyOwner returns(bool) {
    _burn(account, amount);
    return true;
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), 'GabrielToken: Cannot burn from zero address');
    require(amount <= _balances[account], 'GabrielToken: Cannot burn more than balance');

    _totalSupply -= amount;
    _balances[account] -= amount;

    emit Transfer(account, address(0), amount);
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), 'GabrielToken: Cannot transfer from zero address');
    require(recipient != address(0), 'GabrielToken: Cannot transfer to zero address');
    require(amount <= _balances[sender], 'GabrielToken: Insufficient funds');

    _balances[sender] -= amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function stake(uint256 _amount) external {
    require(_amount <= _balances[msg.sender], 'GabrielToken: Insufficient funds');

    _stake(_amount);
    _burn(msg.sender, _amount);
  }

  function withdrawStake(uint256 amount, uint256 stake_index) external {
    uint256 amount_to_mint = _withdrawStake(amount, stake_index);

    _mint(msg.sender, amount_to_mint);
  }

}