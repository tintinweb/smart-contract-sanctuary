// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

/// @title Rewards contract interface
interface IFeesAndBootstrapRewards {
    event FeesAssigned(address indexed guardian, uint256 amount);
    event FeesWithdrawn(address indexed guardian, uint256 amount);
    event BootstrapRewardsAssigned(address indexed guardian, uint256 amount);
    event BootstrapRewardsWithdrawn(address indexed guardian, uint256 amount);

    /*
    * External functions
    */

    /// @dev called by the Committee contract upon expected change in the committee membership of the guardian
    /// Triggers update of the member rewards
    function committeeMembershipWillChange(address guardian, bool inCommittee, bool isCertified, bool nextCertification, uint generalCommitteeSize, uint certifiedCommitteeSize) external /* onlyCommitteeContract */;

    function getFeesAndBootstrapBalance(address guardian) external view returns (
        uint256 feeBalance,
        uint256 bootstrapBalance
    );

    /// @dev Transfer all of msg.sender's outstanding balance to their account
    function withdrawFees(address guardian) external;

    /// @dev Transfer all of msg.sender's outstanding balance to their account
    function withdrawBootstrapFunds(address guardian) external;

    /// @dev Returns the global Fees and Bootstrap rewards state 
    function getFeesAndBootstrapState() external view returns (
        uint256 certifiedFeesPerMember,
        uint256 generalFeesPerMember,
        uint256 certifiedBootstrapPerMember,
        uint256 generalBootstrapPerMember,
        uint256 lastAssigned
    );

    function getFeesAndBootstrapData(address guardian) external view returns (
        uint256 feeBalance,
        uint256 lastFeesPerMember,
        uint256 bootstrapBalance,
        uint256 lastBootstrapPerMember
    );

    /*
     * Governance
     */

    event GeneralCommitteeAnnualBootstrapChanged(uint256 generalCommitteeAnnualBootstrap);
    event CertifiedCommitteeAnnualBootstrapChanged(uint256 certifiedCommitteeAnnualBootstrap);
    event RewardDistributionActivated(uint256 startTime);
    event RewardDistributionDeactivated();
    event FeesAndBootstrapRewardsBalanceMigrated(address indexed guardian, uint256 fees, uint256 bootstrapRewards, address toRewardsContract);
    event FeesAndBootstrapRewardsBalanceMigrationAccepted(address from, address indexed guardian, uint256 fees, uint256 bootstrapRewards);
    event EmergencyWithdrawal(address addr);

    /// @dev deactivates reward distribution, all rewards will be distributed up
    /// deactivate moment.
    function deactivateRewardDistribution() external /* onlyMigrationManager */;

    /// @dev activates reward distribution, all rewards will be distributed up
    /// assuming the last assignment was on startTime (the time the old contarct was deactivated)
    function activateRewardDistribution(uint startTime) external /* onlyInitializationAdmin */;

    /// @dev Returns the contract's settings
    function getSettings() external view returns (
        uint generalCommitteeAnnualBootstrap,
        uint certifiedCommitteeAnnualBootstrap,
        bool rewardAllocationActive
    );

    function getGeneralCommitteeAnnualBootstrap() external view returns (uint256);

    /// @dev Assigns rewards and sets a new monthly rate for the geenral commitee bootstrap.
    function setGeneralCommitteeAnnualBootstrap(uint256 annual_amount) external /* onlyFunctionalManager */;

    function getCertifiedCommitteeAnnualBootstrap() external view returns (uint256);

    /// @dev Assigns rewards and sets a new monthly rate for the certification commitee bootstrap.
    function setCertifiedCommitteeAnnualBootstrap(uint256 annual_amount) external /* onlyFunctionalManager */;

    function isRewardAllocationActive() external view returns (bool);

    /// @dev migrates the staking rewards balance of the guardian to the rewards contract as set in the registry.
    function migrateRewardsBalance(address guardian) external;

    /// @dev accepts guardian's balance migration from a previous rewards contarct.
    function acceptRewardsBalanceMigration(address guardian, uint256 fees, uint256 bootstrapRewards) external;

    /// @dev emergency withdrawal of the rewards contract balances, may eb called only by the EmergencyManager. 
    function emergencyWithdraw() external; /* onlyMigrationManager */
}

