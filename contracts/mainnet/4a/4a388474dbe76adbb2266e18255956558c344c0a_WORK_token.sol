/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract WORK_token {
  // The name of the token
  string private _name;

  function name() public view returns (string memory) {
    return _name;
  }

  // The symbol of the token
  string private _symbol;

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  // The number of decimals
  uint8 private _decimals;

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  // The amount of tokens in existence
  uint256 private _totalSupply;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  // The token balance of each account
  mapping (address => uint256) private _balances;

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  // Emitted when tokens are moved from one account to another
  event Transfer(address indexed from, address indexed to, uint256 value);

  // Transfer tokens to another account
  function transfer(address recipient, uint256 amount) public returns (bool) {
    // Prevent transfer to 0x0 address
    require(recipient != address(0), "Transfer to the zero address");
    // Check if the sender has enough tokens
    require(amount <= _balances[msg.sender], "Transfer amount exceeds balance");
    // Subtract tokens from sender's account
    _balances[msg.sender] -= amount;
    // Add tokens to recipient's account
    uint256 newBalance = _balances[recipient] + amount;
    require(newBalance >= _balances[recipient], "Addition overflow");
    _balances[recipient] = newBalance;
    // Notify the listeners
    emit Transfer(msg.sender, recipient, amount);
    return true;
  }

  // The accounts approved to withdraw from a given account with the withdrawal sum allowed for each delegate
  mapping (address => mapping (address => uint256)) private _allowances;

  // Emitted when the allowance of a `spender` for an `owner` is set by a call to `approve` function.
  // `value` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 value);

  // Approve delegate to withdraw tokens
  function approve(address spender, uint256 amount) public returns (bool) {
    // Prevent approval to 0x0 address
    require(spender != address(0), "Approve to the zero address");
    // Change the allowance amount
    _allowances[msg.sender][spender] = amount;
    // Notify the listeners
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  // Get number of tokens approved for withdrawal
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowances[owner][spender];
  }

  // Transfer tokens by delegate
  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    // Prevent transfer to 0x0 address
    require(recipient != address(0), "Transfer to the zero address");
    // Check if the sender has enough tokens
    require(amount <= _balances[sender], "Transfer amount exceeds balance");
    // Subtract tokens from sender's account
    _balances[sender] -= amount;
    // Check if delegate's allowance is big enough
    require(amount <= _allowances[sender][msg.sender], "Transfer amount exceeds allowance");
    // Reduce delegate's allowance amount
    _allowances[sender][msg.sender] -= amount;
    // Add tokens to recipient's account
    uint256 newBalance = _balances[recipient] + amount;
    require(newBalance >= _balances[recipient], "Addition overflow");
    _balances[recipient] = newBalance;
    // Notify the listeners
    emit Transfer(sender, recipient, amount);
    return true;
  }

  // Constructor
  constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals, uint256 total) {
    require(bytes(tokenName).length > 0);
    require(bytes(tokenSymbol).length > 0);
    require(total > 0);

    _name = tokenName;
    _symbol = tokenSymbol;
    _decimals = tokenDecimals;
    _totalSupply = total * 10 ** uint256(_decimals);
    _balances[msg.sender] = _totalSupply;
  }
}