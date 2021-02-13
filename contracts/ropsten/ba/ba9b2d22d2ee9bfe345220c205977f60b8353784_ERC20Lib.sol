/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20Lib {
  function init(address owner_, string memory name_, string memory symbol_, uint256 totalSupply_) external;
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Lib is IERC20Lib {

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 public totalSupply;

  string public name;
  string public symbol;
  uint8 public decimals;

  bool public initialized = false;

  constructor () {
    initialized = true;
  }

  function init(address owner_, string memory name_, string memory symbol_, uint256 totalSupply_) external override {
    require(initialized == false, "Contract already initialized");
    name = name_;
    symbol = symbol_;
    decimals = 18;
    _balances[owner_] = totalSupply_;
    totalSupply = totalSupply_;

    initialized = true;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    uint256 newAllowance = _allowances[sender][msg.sender] - amount;
    _allowances[sender][msg.sender] = newAllowance;
    emit Approval(sender, msg.sender, newAllowance);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _balances[sender] = _balances[sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;
    emit Transfer(sender, recipient, amount);
  }
}