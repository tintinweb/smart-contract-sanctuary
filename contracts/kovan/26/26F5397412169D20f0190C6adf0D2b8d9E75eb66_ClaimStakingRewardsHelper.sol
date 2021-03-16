// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import {IClaimStakingRewardsHelper} from '../interfaces/IClaimStakingRewardsHelper.sol';
import {IStakedTokenV3} from '../interfaces/IStakedTokenV3.sol';

contract ClaimStakingRewardsHelper is IClaimStakingRewardsHelper {
  address public immutable aaveStakeToken;
  address public immutable bptStakeToken;

  constructor(address _aaveStakeToken, address _bptStakeToken) {
    aaveStakeToken = _aaveStakeToken;
    bptStakeToken = _bptStakeToken;
  }

  function claimAllRewards(address to, uint256 amount) external override {
    IStakedTokenV3(aaveStakeToken).claimRewardsOnBehalf(msg.sender, to, amount);
    IStakedTokenV3(bptStakeToken).claimRewardsOnBehalf(msg.sender, to, amount);
  }

  function claimAllRewardsAndStake(address to, uint256 amount) external override {
    IStakedTokenV3(aaveStakeToken).claimRewardsAndStakeOnBehalf(msg.sender, to, amount);

    uint256 rewardsClaimed =
      IStakedTokenV3(bptStakeToken).claimRewardsOnBehalf(msg.sender, address(this), amount);
    IStakedTokenV3(aaveStakeToken).stake(to, rewardsClaimed);
  }
}

pragma solidity ^0.7.5;

interface IClaimStakingRewardsHelper {
  function claimAllRewards(address to, uint256 amount) external;

  function claimAllRewardsAndStake(address to, uint256 amount) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import {IStakedToken} from './IStakedToken.sol';

interface IStakedTokenV3 is IStakedToken {
  function exchangeRate() external view returns (uint256);

  function getCooldownPaused() external view returns (bool);

  function setCooldownPause(bool paused) external;

  function slash(address destination, uint256 amount) external;

  function getMaxSlashablePercentage() external view returns (uint256);

  function setMaxSlashablePercentage(uint256 percentage) external;

  function stakeWithPermit(
    address from,
    address to,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function claimRewardsOnBehalf(
    address from,
    address to,
    uint256 amount
  ) external returns (uint256);

  function redeemOnBehalf(
    address from,
    address to,
    uint256 amount
  ) external;

  function claimRewardsAndStake(address to, uint256 amount) external returns (uint256);

  function claimRewardsAndRedeem(
    address to,
    uint256 claimAmount,
    uint256 redeemAmount
  ) external;

  function claimRewardsAndStakeOnBehalf(
    address from,
    address to,
    uint256 amount
  ) external returns (uint256);

  function claimRewardsAndRedeemOnBehalf(
    address from,
    address to,
    uint256 claimAmount,
    uint256 redeemAmount
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

interface IStakedToken {
  
  function stake(address to, uint256 amount) external;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;
}