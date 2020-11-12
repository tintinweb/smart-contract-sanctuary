// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./IStakingContractHandler.sol";
import "./IStakeChangeNotifier.sol";
import "./IStakingContract.sol";
import "./ManagedContract.sol";

contract StakingContractHandler is IStakingContractHandler, IStakeChangeNotifier, ManagedContract {

    bool notifyDelegations = true;

    constructor(IContractRegistry _contractRegistry, address _registryAdmin) public ManagedContract(_contractRegistry, _registryAdmin) {}

    modifier onlyStakingContract() {
        require(msg.sender == address(getStakingContract()), "caller is not the staking contract");

        _;
    }

    /*
    * External functions
    */

    function stakeChange(address stakeOwner, uint256 amount, bool sign, uint256 updatedStake) external override onlyStakingContract {
        if (!notifyDelegations) {
            emit StakeChangeNotificationSkipped(stakeOwner);
            return;
        }

        delegationsContract.stakeChange(stakeOwner, amount, sign, updatedStake);
    }

    /// @dev Notifies of multiple stake change events.
    /// @param stakeOwners address[] The addresses of subject stake owners.
    /// @param amounts uint256[] The differences in total staked amounts.
    /// @param signs bool[] The signs of the added (true) or subtracted (false) amounts.
    /// @param updatedStakes uint256[] The updated total staked amounts.
    function stakeChangeBatch(address[] calldata stakeOwners, uint256[] calldata amounts, bool[] calldata signs, uint256[] calldata updatedStakes) external override onlyStakingContract {
        if (!notifyDelegations) {
            emit StakeChangeBatchNotificationSkipped(stakeOwners);
            return;
        }

        delegationsContract.stakeChangeBatch(stakeOwners, amounts, signs, updatedStakes);
    }

    /// @dev Notifies of stake migration event.
    /// @param stakeOwner address The address of the subject stake owner.
    /// @param amount uint256 The migrated amount.
    function stakeMigration(address stakeOwner, uint256 amount) external override onlyStakingContract {
        if (!notifyDelegations) {
            emit StakeMigrationNotificationSkipped(stakeOwner);
            return;
        }

        delegationsContract.stakeMigration(stakeOwner, amount);
    }

    /// @dev Returns the stake of the specified stake owner (excluding unstaked tokens).
    /// @param stakeOwner address The address to check.
    /// @return uint256 The total stake.
    function getStakeBalanceOf(address stakeOwner) external override view returns (uint256) {
        return stakingContract.getStakeBalanceOf(stakeOwner);
    }

    /// @dev Returns the total amount staked tokens (excluding unstaked tokens).
    /// @return uint256 The total staked tokens of all stake owners.
    function getTotalStakedTokens() external override view returns (uint256) {
        return stakingContract.getTotalStakedTokens();
    }

    /*
    * Governance functions
    */

    function setNotifyDelegations(bool _notifyDelegations) external override onlyMigrationManager {
        notifyDelegations = _notifyDelegations;
        emit NotifyDelegationsChanged(_notifyDelegations);
    }

    function getNotifyDelegations() external override returns (bool) {
        return notifyDelegations;
    }

    /*
     * Contracts topology / registry interface
     */

    IStakeChangeNotifier delegationsContract;
    IStakingContract stakingContract;
    function refreshContracts() external override {
        delegationsContract = IStakeChangeNotifier(getDelegationsContract());
        stakingContract = IStakingContract(getStakingContract());
    }
}