// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

/// @title An interface for staking contracts.
interface IStakingContractHandler {
    event StakeChangeNotificationSkipped(address indexed stakeOwner);
    event StakeChangeBatchNotificationSkipped(address[] stakeOwners);
    event StakeMigrationNotificationSkipped(address indexed stakeOwner);

    /*
    * External functions
    */

    /// @dev Returns the stake of the specified stake owner (excluding unstaked tokens).
    /// @param _stakeOwner address The address to check.
    /// @return uint256 The total stake.
    function getStakeBalanceOf(address _stakeOwner) external view returns (uint256);

    /// @dev Returns the total amount staked tokens (excluding unstaked tokens).
    /// @return uint256 The total staked tokens of all stake owners.
    function getTotalStakedTokens() external view returns (uint256);

    /*
    * Governance functions
    */

    event NotifyDelegationsChanged(bool notifyDelegations);

    function setNotifyDelegations(bool notifyDelegations) external; /* onlyMigrationManager */

    function getNotifyDelegations() external returns (bool);
}
