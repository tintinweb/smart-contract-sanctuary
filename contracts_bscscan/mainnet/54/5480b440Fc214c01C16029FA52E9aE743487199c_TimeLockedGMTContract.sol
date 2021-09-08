// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract TimeLockedGMTContract is Ownable {

  uint256 private _totalSupply;
  uint256 private _lockedSupply;

  IERC20 private _token = IERC20(0x7Ddc52c4De30e94Be3A6A0A2b259b2850f421989);

  mapping (address => uint256) private _balances;
  mapping (address => uint256[]) private _timestamps;
  mapping (address => uint256[]) private _purchases;

  event ExtractTokens(address indexed to, uint256 value);
  event PutTokens(address indexed owner, uint256 value);

  function putTokensToTimeLock(address account, uint256 amount, uint256 timestamp) public virtual onlyOwner {
    require(_lockedSupply + amount <= totalSupply(), "Not enought tokens on TimeLockedGMTContract");
    _balances[account] += amount;
    _timestamps[account].push(timestamp);
    _purchases[account].push(amount);
    _lockedSupply += amount;
    emit PutTokens(account, amount);
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

  function extractTokens() public virtual returns (uint256) {
    uint256 valueToExtract = _extractTokensByAddress(msg.sender);
    return valueToExtract;
  }

  function extractTokensByAddress(address account) public virtual onlyOwner returns (uint256) {
    uint256 valueToExtract = _extractTokensByAddress(account);
    return valueToExtract;
  }

  function totalSupply() public view virtual returns (uint256) {
    return _token.balanceOf(address(this));
  }
  function lockedSupply() public view virtual returns (uint256) {
    return _lockedSupply;
  }

  function _extractTokensByAddress(address account) internal virtual returns (uint256) {
    require(_balances[account] > 0, "Balance equals or less then zero");
    uint256 valueToExtract = 0;
    for (uint256 i = 0; i < _timestamps[account].length; i++) {
      if (_timestamps[account][i] < block.timestamp) {
        valueToExtract += _purchases[account][i];
        _balances[account] -= _purchases[account][i];
        _lockedSupply -= _purchases[account][i];
        _purchases[account][i] = 0;
      }
    }
    require(valueToExtract > 0, "Value to extract equals or less then zero");
    _token.transfer(account, valueToExtract);
    emit ExtractTokens(account, valueToExtract);
    return valueToExtract;
  }
}