// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract TimeLockedGMTContract is Ownable {

  uint256 private _totalSupply;
  uint256 private _lockedSupply;

  IERC20 private _token = IERC20(0x2cb1b32fA5742fD30EFb8c9eA24FA0d1254bfb9E);

  mapping (address => uint256) private _balances;
  mapping (address => uint256[]) private _timestamps;
  mapping (address => uint256[]) private _purchases;

  event ExactTokens(address indexed to, uint256 value);
  event PutTokens(address indexed owner, uint256 value);

  function putTokensToTimeLock(address user, uint256 amount, uint256 timestamp) public virtual onlyOwner {
    require(_lockedSupply + amount <= totalSupply(), "Not enought tokens on TimeLockedGMTContract");
    _balances[user] += amount;
    _timestamps[user].push(timestamp);
    _purchases[user].push(amount);
    _lockedSupply += amount;
    emit PutTokens(user, amount);
  }

  function balanceOf(address account) public view virtual returns (uint256) {
    return _balances[account];
  }

  function timestampsOf(address account) public view virtual returns (uint256[] memory) {
    return _timestamps[account];
  }
  function purchasesOf(address account) public view virtual returns (uint256[] memory) {
    return _purchases[account];
  }

  function exactTokens() public virtual returns (uint256) {
    require(_balances[msg.sender] > 0, "Balance equals or less then zero");
    uint256 valueToExact = 0;
    for (uint256 i = 0; i < _timestamps[msg.sender].length; i++) {
      if (_timestamps[msg.sender][i] < block.timestamp) {
        valueToExact += _purchases[msg.sender][i];
        _balances[msg.sender] -= _purchases[msg.sender][i];
        _lockedSupply -= _purchases[msg.sender][i];
        _purchases[msg.sender][i] = 0;
      }
    }
    require(valueToExact > 0, "Value to exact equals or less then zero");
    _token.transfer(msg.sender, valueToExact);
    emit ExactTokens(msg.sender, valueToExact);
    return valueToExact;
  }

  function totalSupply() public view virtual returns (uint256) {
    return _token.balanceOf(address(this));
  }
  function lockedSupply() public view virtual returns (uint256) {
    return _lockedSupply;
  }
}