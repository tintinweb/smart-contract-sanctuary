// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

contract FakePancakeFactory {

  address public pair;

  constructor(address _pair) public {
      pair = _pair;
  }

  function getPair(address tokenA, address tokenB) public returns(address) {

    return pair;
  }
  
}