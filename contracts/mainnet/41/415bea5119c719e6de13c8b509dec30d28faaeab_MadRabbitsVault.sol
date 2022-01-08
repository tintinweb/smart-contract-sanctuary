/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract MadRabbitsVault {
  address public _t1 = 0x9704e7f9445509c740CAafB4c6cD62cEa03c3fa5;
  address public _t2 = 0x060B103D088e3f5C8381c20Cf2c5e675dda28D59;
  address public _t3 = 0x5453D123EDdC36f2C05E1FCcBD0AA9fAC579BC2A;
  address public _t4 = 0x5404980C4e40310073f4c959E91bA94c4C47Ca03;
  address public _t5 = 0x1EdC92cF7447A8FeCa279ea48d60D05100F03694;
  address public _t6 = 0x01a5Ade4eB79999a941D887Ace9B2710c2578c5F;
  address public _t7 = 0x17842c31D82C05FA5baD798A44B496B470265777;
  address public _t8 = 0x8353cAcfcfFA3F7111CBcdE6e49f720e14fda06e;
  address public _t9 = 0xec7146921ee4aB15375BC01673e6d9Dd4375Eff8;
  address public _t10 = 0xE1bBf31a6c7447d80179422F6D0D8B46B2821383;
  address public _t11 = 0xE36dF7A5050C1f319b71313072929802920E5E6C;

  bool internal _lock;

  constructor() {}

  receive() external payable {}

  fallback() external payable {}

  function withdraw() public nonReentrant {
    uint _p1 = address(this).balance * 97 / 200;
    uint _p2 = address(this).balance / 10;
    uint _p3 = address(this).balance / 10;
    uint _p4 = address(this).balance / 20;
    uint _p5 = address(this).balance / 40;
    uint _p6 = address(this).balance * 9 / 100;
    uint _p7 = address(this).balance * 3 / 100;
    uint _p8 = address(this).balance * 3 / 100;
    uint _p9 = address(this).balance * 3 / 100;
    uint _p10 = address(this).balance * 3 / 100;
    uint _p11 = address(this).balance * 3 / 100;

    require(payable(_t1).send(_p1));
    require(payable(_t2).send(_p2));
    require(payable(_t3).send(_p3));
    require(payable(_t4).send(_p4));
    require(payable(_t5).send(_p5));
    require(payable(_t6).send(_p6));
    require(payable(_t7).send(_p7));
    require(payable(_t8).send(_p8));
    require(payable(_t9).send(_p9));
    require(payable(_t10).send(_p10));
    require(payable(_t11).send(_p11));
  }

  modifier nonReentrant() {
    require(!_lock, "Reentrant Call!");
    _lock = true;
    _;
    _lock = false;
  }
}