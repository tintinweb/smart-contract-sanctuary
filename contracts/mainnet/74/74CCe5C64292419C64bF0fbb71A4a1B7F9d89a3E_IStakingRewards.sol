// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

/// @title Staking rewards contract interface
interface IStakingRewards {

    event DelegatorStakingRewardsAssigned(address indexed delegator, uint256 amount, uint256 totalAwarded, address guardian, uint256 delegatorRewardsPerToken);
    event GuardianStakingRewardsAssigned(address indexed guardian, uint256 amount, uint256 totalAwarded, uint256 delegatorRewardsPerToken, uint256 stakingRewardsPerWeight);
    event StakingRewardsClaimed(address indexed addr, uint256 claimedDelegatorRewards, uint256 claimedGuardianRewards, uint256 totalClaimedDelegatorRewards, uint256 totalClaimedGuardianRewards);
    event StakingRewardsAllocated(uint256 allocatedRewards, uint256 stakingRewardsPerWeight);
    event GuardianDelegatorsStakingRewardsPercentMilleUpdated(address indexed guardian, uint256 delegatorsStakingRewardsPercentMille);

    /*
     * External functions
     */

    /// @dev Returns the currently unclaimed orbs token reward balance of the given address.
    function getStakingRewardsBalance(address addr) external view returns (uint256 balance);

    /// @dev Allows Guardian to set a different delegator staking reward cut than the default
    /// delegatorRewardsPercentMille accepts values between 0 - maxDelegatorsStakingRewardsPercentMille
    function setGuardianDelegatorsStakingRewardsPercentMille(uint32 delegatorRewardsPercentMille) external;

    /// @dev Returns the guardian's delegatorRewardsPercentMille
    function getGuardianDelegatorsStakingRewardsPercentMille(address guardian) external view returns (uint256 delegatorRewardsRatioPercentMille);

    /// @dev Claims the staking rewards balance of addr by staking
    function claimStakingRewards(address addr) external;

    /// @dev Returns the amount of ORBS tokens in the staking wallet that were allocated
    /// but not yet claimed. The staking wallet balance must always larger than the allocated value.
    function getStakingRewardsWalletAllocatedTokens() external view returns (uint256 allocated);

    function getGuardianStakingRewardsData(address guardian) external view returns (
        uint256 balance,
        uint256 claimed,
        uint256 delegatorRewardsPerToken,
        uint256 lastStakingRewardsPerWeight
    );

    function getDelegatorStakingRewardsData(address delegator) external view returns (
        uint256 balance,
        uint256 claimed,
        uint256 lastDelegatorRewardsPerToken
    );

    function getStakingRewardsState() external view returns (
        uint96 stakingRewardsPerWeight,
        uint96 unclaimedStakingRewards
    );

    function getCurrentStakingRewardsRatePercentMille() external returns (uint256);

    /// @dev called by the Committee contract upon expected change in the committee membership of the guardian
    /// Triggers update of the member rewards
    function committeeMembershipWillChange(address guardian, uint256 weight, uint256 totalCommitteeWeight, bool inCommittee, bool inCommitteeAfter) external /* onlyCommitteeContract */;

    /// @dev called by the Delegation contract upon expected change in a committee member delegator stake
    /// Triggers update of the delegator and guardian staking rewards
    function delegationWillChange(address guardian, uint256 delegatedStake, address delegator, uint256 delegatorStake, address nextGuardian, uint256 nextGuardianDelegatedStake) external /* onlyDelegationsContract */;

    /*
     * Governance functions
     */

    event AnnualStakingRewardsRateChanged(uint256 annualRateInPercentMille, uint256 annualCap);
    event DefaultDelegatorsStakingRewardsChanged(uint32 defaultDelegatorsStakingRewardsPercentMille);
    event MaxDelegatorsStakingRewardsChanged(uint32 maxDelegatorsStakingRewardsPercentMille);
    event RewardDistributionActivated(uint256 startTime);
    event RewardDistributionDeactivated();
    event StakingRewardsBalanceMigrated(address indexed addr, uint256 guardianStakingRewards, uint256 delegatorStakingRewards, address toRewardsContract);
    event StakingRewardsBalanceMigrationAccepted(address from, address indexed addr, uint256 guardianStakingRewards, uint256 delegatorStakingRewards);
    event EmergencyWithdrawal(address addr);

    /// @dev activates reward distribution, all rewards will be distributed up
    /// assuming the last assignment was on startTime (the time the old contarct was deactivated)
    function activateRewardDistribution(uint startTime) external /* onlyInitializationAdmin */;

    /// @dev deactivates reward distribution, all rewards will be distributed up
    /// deactivate moment.
    function deactivateRewardDistribution() external /* onlyMigrationManager */;

    /// @dev Sets the default cut of the delegators staking reward.
    function setDefaultDelegatorsStakingRewardsPercentMille(uint32 defaultDelegatorsStakingRewardsPercentMille) external /* onlyFunctionalManager onlyWhenActive */;

    function getDefaultDelegatorsStakingRewardsPercentMille() external view returns (uint32);

    /// @dev Sets the maximum cut of the delegators staking reward.
    function setMaxDelegatorsStakingRewardsPercentMille(uint32 maxDelegatorsStakingRewardsPercentMille) external /* onlyFunctionalManager onlyWhenActive */;

    function getMaxDelegatorsStakingRewardsPercentMille() external view returns (uint32);

    /// @dev Sets a new annual rate and cap for the staking reward.
    function setAnnualStakingRewardsRate(uint256 annualRateInPercentMille, uint256 annualCap) external /* onlyFunctionalManager */;

    function getAnnualStakingRewardsRatePercentMille() external view returns (uint32);

    function getAnnualStakingRewardsCap() external view returns (uint256);

    function isRewardAllocationActive() external view returns (bool);

    /// @dev Returns the contract's settings
    function getSettings() external view returns (
        uint annualStakingRewardsCap,
        uint32 annualStakingRewardsRatePercentMille,
        uint32 defaultDelegatorsStakingRewardsPercentMille,
        uint32 maxDelegatorsStakingRewardsPercentMille,
        bool rewardAllocationActive
    );

    /// @dev migrates the staking rewards balance of the guardian to the rewards contract as set in the registry.
    function migrateRewardsBalance(address guardian) external;

    /// @dev accepts guardian's balance migration from a previous rewards contarct.
    function acceptRewardsBalanceMigration(address guardian, uint256 guardianStakingRewards, uint256 delegatorStakingRewards) external;

    /// @dev emergency withdrawal of the rewards contract balances, may eb called only by the EmergencyManager. 
    function emergencyWithdraw() external /* onlyMigrationManager */;
}

