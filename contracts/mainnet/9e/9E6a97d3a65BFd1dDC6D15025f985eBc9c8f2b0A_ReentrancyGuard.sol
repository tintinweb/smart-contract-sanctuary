// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

abstract contract ReentrancyGuard {
  bool private _entered;

  modifier noReentrancy() {
    require(!_entered);
    _entered = true;
    _;
    _entered = false;
  }
}
