pragma solidity ^0.7.4;

import './CST.sol';

contract Timelock {
  uint public constant duration = 90 days;
  uint public immutable end;
  address public immutable owner;
  CST public cst;

  constructor() {
    end = block.timestamp + duration;
    owner = msg.sender; 
    cst = CST(0x04d40bEFB0a3DFbF76c1B1157EB23865Abdb6D0B);
  }

  function withdraw() external {
    require(msg.sender == owner, 'only owner');
    require(block.timestamp >= end, 'too early');
    cst.transferOwnership(owner);
  }
}