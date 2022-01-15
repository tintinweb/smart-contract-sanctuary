// SPDX-License-Identifier: test

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Token is ERC20 {

  uint256 public total = 1000000000 * 10 ** 18;

  // 构造函数
  constructor(address addr) ERC20("USDT","USDT"){
    // 调用父类函数,传入合约所有者地址和发币总额
      super._mint(addr, total);
  }

}