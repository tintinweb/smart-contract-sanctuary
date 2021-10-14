// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

contract FakeIBEP20 {

  function decimals() public returns(uint8) {

    return 10;
  }

  function approve(address spender, uint256 amount) public returns(bool) {

    return true;
  }

  function balanceOf(address account) public returns(uint256) {

    return 10;
  }

  function symbol() public returns(string memory) {

    return "symbol";
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {

    return true;
  }
  
}