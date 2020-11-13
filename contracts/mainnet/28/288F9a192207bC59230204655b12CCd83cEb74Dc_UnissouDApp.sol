// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './Stakeable.sol';
import './Roleplay.sol';
import './UnissouToken.sol';

/// @title UnissouDApp
///
/// @notice This contract covers everything related
/// to the DApp of Unissou
///
/// @dev Inehrit {Stakeable} and {UnissouToken}
///
abstract contract UnissouDApp is Roleplay, Stakeable, UnissouToken {

  /// @notice This function allows the sender to stake
  /// an amount (maximum 10) of UnissouToken, when the
  /// token is staked, it is burned from the circulating
  /// supply and placed into the staking pool
  /// 
  /// @dev The function iterate through {stakeholders} to
  /// know if the sender is already a stakeholder. If the
  /// sender is already a stakeholder, then the requested amount
  /// is staked into the pool and then burned from the sender wallet.
  /// If the sender isn't a stakeholer, a new stakeholder is created,
  /// and then the function is recall to stake the requested amount
  ///
  /// Requirements:
  /// See {Stakeable::isAmountValid()}
  ///
  /// @param _amount - Represent the amount of token to be staked
  ///
  function stake(
    uint256 _amount
  ) public virtual isAmountValid(
    _amount,
    balanceOf(msg.sender)
  ) isAmountNotZero(
    _amount
  ) {
    uint256 i = 0;
    bool isStakeholder = false;
    uint256 len = stakeholders.length;
    while (i < len) {
      if (stakeholders[i].owner == msg.sender) {
        isStakeholder = true;
        break;
      }
      i++;
    }

    if (isStakeholder) {
      stakeholders[i].stake += _amount;
      _burn(msg.sender, (_amount * (10**8)));
      _totalStakedSupply += (_amount * (10**8));
      emit Staked(msg.sender, _amount);
    }

    if (!isStakeholder) {
      _createStakeholder(msg.sender);
      stake(_amount);
    }
  }
  
  /// @notice This function unstacks the sender staked
  /// balance depending on the requested {_amount}, if the
  /// {_amount} exceeded the staked supply of the sender,
  /// the whole staked supply of the sender will be unstacked
  /// and withdrawn to the sender wallet without exceeding it.
  ///
  /// @dev Like stake() function do, this function iterate
  /// over the stakeholders to identify if the sender is one 
  /// of them, in the case of the sender is identified as a
  /// stakeholder, then the {_amount} is minted to the sender
  /// wallet and sub from the staked supply.
  ///
  /// Requirements:
  /// See {Stakeable::isAmountNotZero}
  /// See {Stakeable::isAbleToUnstake}
  ///
  /// @param _amount - Represent the amount of token to be unstack
  ///
  function unstake(
    uint256 _amount
  ) public virtual isAmountNotZero(
    _amount
  ) isAbleToUnstake(
    _amount
  ) {
    uint256 i = 0;
    bool isStakeholder = false;
    uint256 len = stakeholders.length;
    while (i < len) {
      if (stakeholders[i].owner == msg.sender) {
        isStakeholder = true;
        break;
      }
      i++;
    }

    require(
      isStakeholder,
      "SC:650"
    );

    if (isStakeholder) {
      if (_amount <= stakeholders[i].stake) {
        stakeholders[i].stake -= _amount;
        _mint(msg.sender, (_amount * (10**8)));
        _totalStakedSupply -= (_amount * (10**8));
        emit Unstaked(msg.sender, _amount);
      }
    }
  }
  
  /// @notice This function allows the sender to compute
  /// his reward earned by staking {UnissouToken}. When you
  /// request a withdraw, the function updates the reward's
  /// value of the sender stakeholding onto the Ethereum
  /// blockchain, allowing him to spend the reward for NFTs.
  ///
  /// @dev The same principe as other functions is applied here,
  /// iteration over stakeholders, when found, execute the action.
  /// See {Stakeable::_computeReward()}
  ///
  function withdraw()
  public virtual {
    uint256 i = 0;
    bool isStakeholder = false;
    uint256 len = stakeholders.length;
    while (i < len) {
      if (stakeholders[i].owner == msg.sender) {
        isStakeholder = true;
        break;
      }
      i++;
    }

    require(
      isStakeholder,
      "SC:650"
    );

    if (isStakeholder) {
      _computeReward(i);
    }
  }

  /// @notice This function allows the owner to spend {_amount} 
  /// of the target rewards gained from his stake.
  ///
  /// @dev To reduce the potential numbers of transaction, the
  /// {_computeReward()} function is also executed into this function.
  ///
  /// @param _amount - Represent the amount of reward to spend
  /// @param _target - Represent the address of the stakeholder owner
  ///
  function spend(
    uint256 _amount,
    address _target
  ) public virtual onlyOwner() {
    uint256 i = 0;
    bool isStakeholder = false;
    uint256 len = stakeholders.length;
    while (i < len) {
      if (stakeholders[i].owner == _target) {
        isStakeholder = true;
        break;
      }
      i++;
    }

    require(
      isStakeholder,
      "SC:650"
    );

    if (isStakeholder) {
      _computeReward(i);
      require(
        _amount <= stakeholders[i].availableReward,
        "SC:660"
      );

      stakeholders[i].availableReward -= _amount;
      stakeholders[i].totalRewardSpent += _amount;
    }
  }
}