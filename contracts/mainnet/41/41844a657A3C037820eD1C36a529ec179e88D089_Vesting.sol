// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity 0.8.6;

import "IERC20.sol";

import "SafeOwnable.sol";

contract Vesting is SafeOwnable {

  IERC20 public asset;

  uint public startTime;
  uint public durationTime;
  uint public released;

  constructor(
    IERC20 _asset,
    uint _startTime,
    uint _durationTime
  ) {

    require(_asset != IERC20(address(0)), "Vesting: _asset is zero address");
    require(_startTime + _durationTime > block.timestamp, "Vesting: final time is before current time");
    require(_durationTime > 0, "Vesting: _duration == 0");

    asset = _asset;
    startTime = _startTime;
    durationTime = _durationTime;
  }

  function release(uint _amount) external onlyOwner {

    require(block.timestamp > startTime, "Vesting: not started yet");
    uint unreleased = releasableAmount();

    require(unreleased > 0, "Vesting: no assets are due");
    require(unreleased >= _amount, "Vesting: _amount too high");

    released += _amount;
    asset.transfer(owner, _amount);
  }

  function releasableAmount() public view returns (uint) {
    return vestedAmount() - released;
  }

  function vestedAmount() public view returns (uint) {
    uint currentBalance = asset.balanceOf(address(this));
    uint totalBalance = currentBalance + released;

    if (block.timestamp >= startTime + durationTime) {
      return totalBalance;
    } else {
      return totalBalance * (block.timestamp - startTime) / durationTime;
    }
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns(uint);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function allowance(address owner, address spender) external view returns(uint);
  function decimals() external view returns(uint8);
  function approve(address spender, uint amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint amount) external returns(bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IOwnable.sol";

contract SafeOwnable is IOwnable {

  uint public constant RENOUNCE_TIMEOUT = 1 hours;

  address public override owner;
  address public pendingOwner;
  uint public renouncedAt;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), msg.sender);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external override onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external override {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(msg.sender, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }

  function initiateRenounceOwnership() external onlyOwner {
    require(renouncedAt == 0, "Ownable: already initiated");
    renouncedAt = block.timestamp;
  }

  function acceptRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    require(block.timestamp - renouncedAt > RENOUNCE_TIMEOUT, "Ownable: too early");
    owner = address(0);
    pendingOwner = address(0);
    renouncedAt = 0;
  }

  function cancelRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    renouncedAt = 0;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IOwnable {
  function owner() external view returns(address);
  function transferOwnership(address _newOwner) external;
  function acceptOwnership() external;
}