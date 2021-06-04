/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: NOLICENSE

pragma solidity 0.8.0;


contract ERC20 {
  mapping(address => uint256) private _balances;
  
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  address private _owner;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  modifier onlyOwner() {
    require(msg.sender == _owner, 'Ownable: caller is not the owner');
    _;
  }

  constructor(string memory name_, string memory symbol_) {
    _owner = msg.sender;
    _name = name_;
    _symbol = symbol_;
    _decimals = 18;
  }
  
  event Tranfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function getOwner() public view returns (address) {
    return _owner;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    uint256 currentAllowance = _allowances[sender][msg.sender];
    require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, currentAllowance - amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 amount) public returns (bool) {
    _approve(msg.sender, spender, _allowances[spender][msg.sender] + amount);
    return true;
  }

  function decreaseAllowance(address spender, uint256 amount) public returns (bool) {
    require(_allowances[msg.sender][spender] - amount >= 0, 'ERC20: decreased allowance below zero');
    _approve(msg.sender, spender, _allowances[msg.sender][spender] - amount);
    return true;
  }

  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(msg.sender, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(_balances[sender] >= amount, 'ERC20: transfer amount exceeds balance');
    _balances[sender] -= amount;
    _balances[recipient] += amount;

    emit Tranfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _mint(address account, uint256 amount) internal {
    _totalSupply += amount;
    _balances[account] += amount;
    emit Tranfer(address(0), account, amount);
  }
}