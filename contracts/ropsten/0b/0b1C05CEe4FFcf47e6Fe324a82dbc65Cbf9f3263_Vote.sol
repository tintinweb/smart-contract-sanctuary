/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: GPL-3.0
// 指定编译器版本
pragma solidity =0.8.7;

// contract 类似于 class 关键字
contract Vote {
  // 成员变量、构造函数、成员方法等概念和其他语言保持一致

  // 可投票的候选人A、B、C
  uint256 public proposal;

  // 构造函数。在合约部署到链上的时候会执行一次
  constructor() {
    proposal=100;
  }

  // 投票函数
  function vote(uint8 _proposal) public {
    // 给对应的被投票人记票
    if (_proposal == 1) {
      proposal++;
    } else {
      proposal--;
    }

  }
}