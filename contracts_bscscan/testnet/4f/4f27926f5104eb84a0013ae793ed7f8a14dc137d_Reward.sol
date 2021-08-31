pragma solidity ^0.8.0;

import './ERC20.sol';
contract Reward is ERC20 {
  constructor() 
  ERC20('STAGE REWARDS', 'STGR', 18) {
    _mint(msg.sender, 1000000);
  }
}