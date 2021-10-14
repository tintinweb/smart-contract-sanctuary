// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

contract FakePancakePair {

  address public token0;
  address public token1;

  constructor(address _token0, address _token1) public {
      token0 = _token0;
      token1 = _token1;
  }

  function decimals() public returns(uint8) {

    return 10;
  }

  function approve(address spender, uint256 amount) public returns(bool) {

    return true;
  }

  function balanceOf(address owner) public returns(uint) {

    return 10;
  }

  function getReserves() public returns(uint112, uint112, uint32) {

    return (10, 10, 10);
  }

  function totalSupply() public returns(uint) {

    return 10;
  }
  
}