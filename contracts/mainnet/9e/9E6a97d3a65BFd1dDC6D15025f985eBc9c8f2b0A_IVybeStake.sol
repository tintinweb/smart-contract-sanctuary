// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IOwnershipTransferrable.sol";

interface IVybeStake is IOwnershipTransferrable {
  event StakeIncreased(address indexed staker, uint256 amount);
  event StakeDecreased(address indexed staker, uint256 amount);
  event Rewards(address indexed staker, uint256 mintage, uint256 developerFund);
  event MelodyAdded(address indexed melody);
  event MelodyRemoved(address indexed melody);

  function vybe() external returns (address);
  function totalStaked() external returns (uint256);
  function staked(address staker) external returns (uint256);
  function lastClaim(address staker) external returns (uint256);

  function addMelody(address melody) external;
  function removeMelody(address melody) external;
  function upgrade(address owned, address upgraded) external;
}
