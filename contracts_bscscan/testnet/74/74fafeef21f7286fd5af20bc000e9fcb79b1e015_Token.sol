pragma solidity ^0.8.0;

import './ERC20Rewards.sol';
import './ERC20.sol';

contract Token is ERC20Rewards {
  constructor(address rewardsToken) 
  ERC20Rewards('STAGEONE', 'STGO', 3, IERC20(rewardsToken)) {
    _mint(msg.sender, 1000000000);
  }
}