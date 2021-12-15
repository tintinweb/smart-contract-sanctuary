/**
 *Submitted for verification at snowtrace.io on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ITres {
  function excessReserves() external view returns ( uint );
}

contract CallFunc {
  address public addr;
  address public owner;

  constructor(address _addr) {
    owner = msg.sender;
    addr = _addr;
  }

  function setAddr(address _addr) external {
    require(msg.sender == owner);
    addr = _addr;
  }

  function call() external returns (uint _a) {
    require(msg.sender == owner);
    _a = ITres(addr).excessReserves();
  }
}