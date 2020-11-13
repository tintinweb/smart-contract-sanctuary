// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './Roleplay.sol';

/// @title Stakeable
///
/// @notice This contract covers most functions about
/// staking and rewards
///
abstract contract Stakeable is Roleplay {
  /// @dev Declare an internal variable of type uint256
  ///
  uint256 internal _totalStakedSupply;

  /// @dev Declare an internal variable of type uint256
  ///
  uint256 internal _maxRewardRatio;
  
  /// @dev Structure declaration of {Stakeholder} data model
  ///
  struct Stakeholder {
    address owner;
    uint256 stake;
    uint256 availableReward;
    uint256 totalRewardEarned;
    uint256 totalRewardSpent;
    uint256 createdAt;
    uint256 lastRewardCalculatedAt;
  }

  /// @dev Declare two events to expose when stake
  /// or unstake is requested, take the event's
  /// sender as argument and the requested amount
  ///
  event Staked(address indexed _from, uint256 _amount);
  event Unstaked(address indexed _from, uint256 _amount);

  /// @dev Declare an array of {Stakeholder}
  ///
  Stakeholder[] stakeholders;
  
  /// @dev Verify if the amount is superior to 0
  /// 
  /// Requirements:
  /// {_amount} should be superior to 0
  ///
  /// @param _amount - Represent the requested amount
  ///
  modifier isAmountNotZero(uint256 _amount) {
    require(
      _amount > 0,
      "SC:630"
    );
    _;
  }

  /// @dev Verify if the amount is a valid amount
  /// 
  /// Requirements:
  /// {_amount} should be inferior or equal to 10
  ///
  /// @param _amount - Represent the requested amount
  /// @param _balance - Represent the sender balance
  ///
  modifier isAmountValid(uint256 _amount, uint256 _balance) {
    require(
      (_amount * (10**8)) <= _balance,
      "SC:640"
    );
    _;
  }

  /// @dev Verify if the amount is a valid amount to unstake
  /// 
  /// Requirements:
  /// {_amount} should be inferior or equal to staked value
  ///
  /// @param _amount - Represent the requested amount
  ///
  modifier isAbleToUnstake(uint256 _amount) {
    Stakeholder memory stakeholder = exposeStakeholder(msg.sender); 
    require(
      _amount <= stakeholder.stake,
      "SC:640"
    );
    _;
  }

  constructor() public {
    _maxRewardRatio = 10;
  }

  /// @notice Expose the total staked supply
  ///
  /// @return The uint256 value of {_totalStakedSupply}
  ///
  function totalStakedSupply()
  public view returns (uint256) {
    return _totalStakedSupply;
  }

  /// @notice Expose the max reward ratio
  ///
  /// @return The uint256 value of {_maxRewardRatio}
  ///
  function maxRewardRatio()
  public view returns (uint256) {
    return _maxRewardRatio;
  }

  /// @notice Expose every Stakeholders
  ///
  /// @return A tuple of Stakeholders
  ///
  function exposeStakeholders()
  public view returns (Stakeholder[] memory) {
    return stakeholders;
  }

  /// @notice Expose a Stakeholder from the Owner address
  ///
  /// @param _owner - Represent the address of the stakeholder owner
  ///
  /// @return A tuple of Stakeholder
  ///
  function exposeStakeholder(
    address _owner
  ) public view returns (Stakeholder memory) {
    uint256 i = 0;
    uint256 len = stakeholders.length;
    while (i < len) {
      if (stakeholders[i].owner == _owner) {
        return stakeholders[i];
      }
      i++;
    }
  }

  /// @notice Set the {_maxRewardRatio}
  ///
  /// @dev Only owner can use this function
  ///
  /// @param _amount - Represent the requested ratio
  ///
  function setMaxRewardRatio(
    uint256 _amount
  ) public virtual onlyOwner() {
    _maxRewardRatio = _amount;
  }

  /// @notice Create a new {Stakeholder}
  ///
  /// @dev Owner is the sender
  ///
  /// @param _owner - Represent the owner of the Stakeholder
  ///
  function _createStakeholder(
    address _owner
  ) internal virtual {
    stakeholders.push(Stakeholder({
      owner: _owner,
      stake: 0,
      createdAt: now,
      availableReward: 0,
      totalRewardEarned: 0,
      totalRewardSpent: 0,
      lastRewardCalculatedAt: 0
    }));
  }

  /// @notice This function compute the reward gained from staking
  /// CreationEngineToken
  ///
  /// @dev The calculation is pretty simple, a {Stakeholder}
  /// holds the date of the {Stakeholder}'s creation. If the
  /// reward hasn't been computed since the creation, the
  /// algorithm will calculate them based on the number of
  /// days passed since the creation of the stakeholding.
  /// Then the calculation's date will be saved onto the
  /// {Stakeholder} and when {_computeReward} will be called
  /// again, the reward calculation will take this date in 
  /// consideration to compute the reward.
  /// 
  /// The actual ratio is 1 Stake = 1 Reward.
  /// With a maximum of 10 tokens per stake,
  /// you can obtain a total of 10 rewards per day
  ///
  /// @param _id - Represent the Stakeholder index
  ///
  function _computeReward(
    uint256 _id
  ) internal virtual {
    uint256 stake = stakeholders[_id].stake;
    uint256 lastCalculatedReward = stakeholders[_id].lastRewardCalculatedAt;
    uint256 createdAt = stakeholders[_id].createdAt;

    if (lastCalculatedReward == 0) {
      if (createdAt < now) {
        if ((now - createdAt) >= 1 days) {
          stakeholders[_id].availableReward += (((now - createdAt) / 1 days) * (
            stake <= _maxRewardRatio ?
            stake : _maxRewardRatio
          ));
          stakeholders[_id].totalRewardEarned += (((now - createdAt) / 1 days) * (
            stake <= _maxRewardRatio ?
            stake : _maxRewardRatio
          ));
          stakeholders[_id].lastRewardCalculatedAt = now;
          return;
        }
      }
    }

    if (lastCalculatedReward != 0) {
      if (lastCalculatedReward < now) {
        if ((now - lastCalculatedReward) >= 1 days) {
          stakeholders[_id].availableReward += (((now - lastCalculatedReward) / 1 days) * (
            stake <= _maxRewardRatio ?
            stake : _maxRewardRatio
          ));
          stakeholders[_id].totalRewardEarned += (((now - lastCalculatedReward) / 1 days) * (
            stake <= _maxRewardRatio ?
            stake : _maxRewardRatio
          ));
          stakeholders[_id].lastRewardCalculatedAt = now;
          return;
        }
      }
    }
  }
}