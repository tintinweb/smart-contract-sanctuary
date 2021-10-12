/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Pr0xyVault {
  address public _t1 = 0x8b88130e3B6d99aC05e382C17bD28dcaD2F86D41;
  address public _t2 = 0xd230f390AbB50470fa265a022d673c6147BDc396;
  address public _t3 = 0xD854526EA2E285666C9d35D2Da3C07D514DB90a7;
  address public _t4 = 0xf224DF0BF1FCCFb119320e10C0AcD3bB93210DCA;

  uint public _s1 = 33;
  uint public _s2 = 33;
  uint public _s3 = 33;
  uint public _s4 = 1;
  uint public _shares = 100;

  bool internal _lock;

  constructor() {}

  receive() external payable {}

  fallback() external payable {}

  function withdraw() public nonReentrant {
    uint _p1 = address(this).balance * _s1 / _shares;
    uint _p2 = address(this).balance * _s2 / _shares;
    uint _p3 = address(this).balance * _s3 / _shares;
    uint _p4 = address(this).balance * _s4 / _shares;

    require(payable(_t1).send(_p1));
    require(payable(_t2).send(_p2));
    require(payable(_t3).send(_p3));
    require(payable(_t4).send(_p4));
  }

  modifier nonReentrant() {
    require(!_lock, "Reentrant Call!");
    _lock = true;
    _;
    _lock = false;
  }
}