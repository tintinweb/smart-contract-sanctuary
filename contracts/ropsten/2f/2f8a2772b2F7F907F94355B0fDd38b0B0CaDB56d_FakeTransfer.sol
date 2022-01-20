//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

contract FakeTransfer {
  event Transfer(address indexed from, address indexed to, uint256 amount);

  function call() external {
    emit Transfer(address(0),msg.sender,1);
  }

}