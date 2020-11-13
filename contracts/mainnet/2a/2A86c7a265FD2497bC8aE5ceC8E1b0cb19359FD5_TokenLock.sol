//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract TokenLock is Ownable, AccessControl {
  using SafeMath for uint256;

  bool public transferEnabled = false; // indicates that token is transferable or not
  bool public noTokenLocked = false; // indicates all token is released or not

  struct TokenLockInfo { // token of `amount` cannot be moved before `time`
    uint256 amount; // locked amount
    uint256 time; // unix timestamp
  }

  struct TokenLockState {
    uint256 latestReleaseTime;
    TokenLockInfo[] tokenLocks; // multiple token locks can exist
  }

  mapping(address => TokenLockState) lockingStates;
  event AddTokenLock(address indexed to, uint256 time, uint256 amount);

  function unlockAllTokens() public onlyOwner {
    noTokenLocked = true;
  }

  function enableTransfer(bool _enable) public onlyOwner {
    transferEnabled = _enable;
  }

  // calculate the amount of tokens an address can use
  function getMinLockedAmount(address _addr) view public returns (uint256 locked) {
    uint256 i;
    uint256 a;
    uint256 t;
    uint256 lockSum = 0;

    // if the address has no limitations just return 0
    TokenLockState storage lockState = lockingStates[_addr];
    if (lockState.latestReleaseTime < now) {
      return 0;
    }

    for (i=0; i<lockState.tokenLocks.length; i++) {
      a = lockState.tokenLocks[i].amount;
      t = lockState.tokenLocks[i].time;

      if (t > now) {
        lockSum = lockSum.add(a);
      }
    }

    return lockSum;
  }

  function addTokenLock(address _addr, uint256 _value, uint256 _release_time) onlyOwner public {
    require(_addr != address(0));
    require(_value > 0);
    require(_release_time > now);

    TokenLockState storage lockState = lockingStates[_addr]; // assigns a pointer. change the member value will update struct itself.
    if (_release_time > lockState.latestReleaseTime) {
      lockState.latestReleaseTime = _release_time;
    }
    lockState.tokenLocks.push(TokenLockInfo(_value, _release_time));

    emit AddTokenLock(_addr, _release_time, _value);
  }
}