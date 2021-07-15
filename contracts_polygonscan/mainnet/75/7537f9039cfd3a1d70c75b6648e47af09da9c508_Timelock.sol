pragma solidity ^0.7.4;

import './MasterChefv2.sol';

contract Timelock {
  uint public constant duration = 15 days;
  uint public immutable end;
  address public immutable owner;
  MasterChef public masterChef;

  constructor() {
    end = block.timestamp + duration;
    owner = msg.sender; 
    masterChef = MasterChef(0x7518167AACa8E7Ede78015D19Ed02169E62796F9);
  }

  function withdraw() external {
    require(msg.sender == owner, 'only owner');
    require(block.timestamp >= end, 'too early');
    masterChef.transferOwnership(owner);
  }
}