// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/SafeMath96.sol

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath96 {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint96 a, uint256 b) internal pure returns (uint96) {
        require(uint256(uint96(b)) == b, "SafeMath: addition overflow");
        uint96 c = a + uint96(b);
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint96 a, uint256 b) internal pure returns (uint96) {
        require(uint256(uint96(b)) == b, "SafeMath: subtraction overflow");
        return sub(a, uint96(b), "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        uint96 c = a - b;

        return c;
    }

}

// File: contracts/spec_interfaces/IElections.sol

pragma solidity 0.6.12;

/// @title Elections contract interface
interface IElections {
	
	// Election state change events
	event StakeChanged(address indexed addr, uint256 selfDelegatedStake, uint256 delegatedStake, uint256 effectiveStake);
	event GuardianStatusUpdated(address indexed guardian, bool readyToSync, bool readyForCommittee);

	// Vote out / Vote unready
	event GuardianVotedUnready(address indexed guardian);
	event VoteUnreadyCasted(address indexed voter, address indexed subject, uint256 expiration);
	event GuardianVotedOut(address indexed guardian);
	event VoteOutCasted(address indexed voter, address indexed subject);

	/*
	 * External functions
	 */

    /// Notifies that the guardian is ready to sync with other nodes
    /// @dev may be called with either the guardian address or the guardian's orbs address
    /// @dev ready to sync state is not managed in the contract that only emits an event
    /// @dev readyToSync clears the readyForCommittee state
	function readyToSync() external;

    /// Notifies that the guardian is ready to join the committee
    /// @dev may be called with either the guardian address or the guardian's orbs address
    /// @dev a qualified guardian calling readyForCommittee is added to the committee
	function readyForCommittee() external;

    /// Checks if a guardian is qualified to join the committee
    /// @dev when true, calling readyForCommittee() will result in adding the guardian to the committee
    /// @dev called periodically by guardians to check if they are qualified to join the committee
    /// @param guardian is the guardian to check
    /// @return canJoin indicating that the guardian can join the current committee
	function canJoinCommittee(address guardian) external view returns (bool);

    /// Returns an address effective stake
    /// The effective stake is derived from a guardian delegate stake and selfs stake  
    /// @return effectiveStake is the guardian's effective stake
	function getEffectiveStake(address guardian) external view returns (uint effectiveStake);

    /// Returns the current committee along with the guardians' Orbs address and IP
    /// @return committee is a list of the committee members' guardian addresses
    /// @return weights is a list of the committee members' weight (effective stake)
    /// @return orbsAddrs is a list of the committee members' orbs address
    /// @return certification is a list of bool indicating the committee members certification
    /// @return ips is a list of the committee members' ip
	function getCommittee() external view returns (address[] memory committee, uint256[] memory weights, address[] memory orbsAddrs, bool[] memory certification, bytes4[] memory ips);

	// Vote-unready

    /// Casts an unready vote on a subject guardian
    /// @dev Called by a guardian as part of the automatic vote-unready flow
    /// @dev The transaction may be sent from the guardian or orbs address.
    /// @param subject is the subject guardian to vote out
    /// @param voteExpiration is the expiration time of the vote unready to prevent counting of a vote that is already irrelevant.
	function voteUnready(address subject, uint voteExpiration) external;

    /// Returns the current vote unready vote for a voter and a subject pair
    /// @param voter is the voting guardian address
    /// @param subject is the subject guardian address
    /// @return valid indicates whether there is a valid vote
    /// @return expiration returns the votes expiration time
	function getVoteUnreadyVote(address voter, address subject) external view returns (bool valid, uint256 expiration);

    /// Returns the current vote-unready status of a subject guardian.
    /// @dev the committee and certification data is used to check the certified and committee threshold
    /// @param subject is the subject guardian address
    /// @return committee is a list of the current committee members
    /// @return weights is a list of the current committee members weight
    /// @return certification is a list of bool indicating the committee members certification
    /// @return votes is a list of bool indicating the members that votes the subject unready
    /// @return subjectInCommittee indicates that the subject is in the committee
    /// @return subjectInCertifiedCommittee indicates that the subject is in the certified committee
	function getVoteUnreadyStatus(address subject) external view returns (
		address[] memory committee,
		uint256[] memory weights,
		bool[] memory certification,
		bool[] memory votes,
		bool subjectInCommittee,
		bool subjectInCertifiedCommittee
	);

	// Vote-out

    /// Casts a voteOut vote by the sender to the given address
    /// @dev the transaction is sent from the guardian address
    /// @param subject is the subject guardian address
	function voteOut(address subject) external;

    /// Returns the subject address the addr has voted-out against
    /// @param voter is the voting guardian address
    /// @return subject is the subject the voter has voted out
	function getVoteOutVote(address voter) external view returns (address);

    /// Returns the governance voteOut status of a guardian.
    /// @dev A guardian is voted out if votedStake / totalDelegatedStake (in percent mille) > threshold
    /// @param subject is the subject guardian address
    /// @return votedOut indicates whether the subject was voted out
    /// @return votedStake is the total stake voting against the subject
    /// @return totalDelegatedStake is the total delegated stake
	function getVoteOutStatus(address subject) external view returns (bool votedOut, uint votedStake, uint totalDelegatedStake);

	/*
	 * Notification functions from other PoS contracts
	 */

    /// Notifies a delegated stake change event
    /// @dev Called by: delegation contract
    /// @param delegate is the delegate to update
    /// @param selfDelegatedStake is the delegate self stake (0 if not self-delegating)
    /// @param delegatedStake is the delegate delegated stake (0 if not self-delegating)
    /// @param totalDelegatedStake is the total delegated stake
	function delegatedStakeChange(address delegate, uint256 selfDelegatedStake, uint256 delegatedStake, uint256 totalDelegatedStake) external /* onlyDelegationsContract onlyWhenActive */;

    /// Notifies a new guardian was unregistered
    /// @dev Called by: guardian registration contract
    /// @dev when a guardian unregisters its status is updated to not ready to sync and is removed from the committee
    /// @param guardian is the address of the guardian that unregistered
	function guardianUnregistered(address guardian) external /* onlyGuardiansRegistrationContract */;

    /// Notifies on a guardian certification change
    /// @dev Called by: guardian registration contract
    /// @param guardian is the address of the guardian to update
    /// @param isCertified indicates whether the guardian is certified
	function guardianCertificationChanged(address guardian, bool isCertified) external /* onlyCertificationContract */;


	/*
     * Governance functions
	 */

	event VoteUnreadyTimeoutSecondsChanged(uint32 newValue, uint32 oldValue);
	event VoteOutPercentMilleThresholdChanged(uint32 newValue, uint32 oldValue);
	event VoteUnreadyPercentMilleThresholdChanged(uint32 newValue, uint32 oldValue);
	event MinSelfStakePercentMilleChanged(uint32 newValue, uint32 oldValue);

    /// Sets the minimum self stake requirement for the effective stake
    /// @dev governance function called only by the functional manager
    /// @param minSelfStakePercentMille is the minimum self stake in percent-mille (0-100,000) 
	function setMinSelfStakePercentMille(uint32 minSelfStakePercentMille) external /* onlyFunctionalManager */;

    /// Returns the minimum self-stake required for the effective stake
    /// @return minSelfStakePercentMille is the minimum self stake in percent-mille 
	function getMinSelfStakePercentMille() external view returns (uint32);

    /// Sets the vote-out threshold
    /// @dev governance function called only by the functional manager
    /// @param voteOutPercentMilleThreshold is the minimum threshold in percent-mille (0-100,000)
	function setVoteOutPercentMilleThreshold(uint32 voteOutPercentMilleThreshold) external /* onlyFunctionalManager */;

    /// Returns the vote-out threshold
    /// @return voteOutPercentMilleThreshold is the minimum threshold in percent-mille
	function getVoteOutPercentMilleThreshold() external view returns (uint32);

    /// Sets the vote-unready threshold
    /// @dev governance function called only by the functional manager
    /// @param voteUnreadyPercentMilleThreshold is the minimum threshold in percent-mille (0-100,000)
	function setVoteUnreadyPercentMilleThreshold(uint32 voteUnreadyPercentMilleThreshold) external /* onlyFunctionalManager */;

    /// Returns the vote-unready threshold
    /// @return voteUnreadyPercentMilleThreshold is the minimum threshold in percent-mille
	function getVoteUnreadyPercentMilleThreshold() external view returns (uint32);

    /// Returns the contract's settings 
    /// @return minSelfStakePercentMille is the minimum self stake in percent-mille
    /// @return voteUnreadyPercentMilleThreshold is the minimum threshold in percent-mille
    /// @return voteOutPercentMilleThreshold is the minimum threshold in percent-mille
	function getSettings() external view returns (
		uint32 minSelfStakePercentMille,
		uint32 voteUnreadyPercentMilleThreshold,
		uint32 voteOutPercentMilleThreshold
	);

    /// Initializes the ready for committee notification for the committee guardians
    /// @dev governance function called only by the initialization admin during migration 
    /// @dev identical behaviour as if each guardian sent readyForCommittee() 
    /// @param guardians a list of guardians addresses to update
	function initReadyForCommittee(address[] calldata guardians) external /* onlyInitializationAdmin */;

}

// File: contracts/spec_interfaces/IDelegations.sol

pragma solidity 0.6.12;

/// @title Delegations contract interface
interface IDelegations /* is IStakeChangeNotifier */ {

    // Delegation state change events
	event DelegatedStakeChanged(address indexed addr, uint256 selfDelegatedStake, uint256 delegatedStake, address indexed delegator, uint256 delegatorContributedStake);

    // Function calls
	event Delegated(address indexed from, address indexed to);

	/*
     * External functions
     */

    /// Delegate your stake
    /// @dev updates the election contract on the changes in the delegated stake
    /// @dev updates the rewards contract on the upcoming change in the delegator's delegation state
    /// @param to is the address to delegate to
	function delegate(address to) external /* onlyWhenActive */;

    /// Refresh the address stake for delegation power based on the staking contract
    /// @dev Disabled stake change update notifications from the staking contract may create mismatches
    /// @dev refreshStake re-syncs the stake data with the staking contract
    /// @param addr is the address to refresh its stake
	function refreshStake(address addr) external /* onlyWhenActive */;

    /// Refresh the addresses stake for delegation power based on the staking contract
    /// @dev Batched version of refreshStake
    /// @dev Disabled stake change update notifications from the staking contract may create mismatches
    /// @dev refreshStakeBatch re-syncs the stake data with the staking contract
    /// @param addrs is the list of addresses to refresh their stake
	function refreshStakeBatch(address[] calldata addrs) external /* onlyWhenActive */;

    /// Returns the delegate address of the given address
    /// @param addr is the address to query
    /// @return delegation is the address the addr delegated to
	function getDelegation(address addr) external view returns (address);

    /// Returns a delegator info
    /// @param addr is the address to query
    /// @return delegation is the address the addr delegated to
    /// @return delegatorStake is the stake of the delegator as reflected in the delegation contract
	function getDelegationInfo(address addr) external view returns (address delegation, uint256 delegatorStake);
	
    /// Returns the delegated stake of an addr 
    /// @dev an address that is not self delegating has a 0 delegated stake
    /// @param addr is the address to query
    /// @return delegatedStake is the address delegated stake
	function getDelegatedStake(address addr) external view returns (uint256);

    /// Returns the total delegated stake
    /// @dev delegatedStake - the total stake delegated to an address that is self delegating
    /// @dev the delegated stake of a non self-delegated address is 0
    /// @return totalDelegatedStake is the total delegatedStake of all the addresses
	function getTotalDelegatedStake() external view returns (uint256) ;

	/*
	 * Governance functions
	 */

	event DelegationsImported(address[] from, address indexed to);

	event DelegationInitialized(address indexed from, address indexed to);

    /// Imports delegations during initial migration
    /// @dev initialization function called only by the initializationManager
    /// @dev Does not update the Rewards or Election contracts
    /// @dev assumes deactivated Rewards
    /// @param from is a list of delegator addresses
    /// @param to is the address the delegators delegate to
	function importDelegations(address[] calldata from, address to) external /* onlyMigrationManager onlyDuringDelegationImport */;

    /// Initializes the delegation of an address during initial migration 
    /// @dev initialization function called only by the initializationManager
    /// @dev behaves identically to a delegate transaction sent by the delegator
    /// @param from is the delegator addresses
    /// @param to is the delegator delegates to
	function initDelegation(address from, address to) external /* onlyInitializationAdmin */;
}

// File: contracts/IStakeChangeNotifier.sol

pragma solidity 0.6.12;

/// @title An interface for notifying of stake change events (e.g., stake, unstake, partial unstake, restate, etc.).
interface IStakeChangeNotifier {
    /// @dev Notifies of stake change event.
    /// @param _stakeOwner address The address of the subject stake owner.
    /// @param _amount uint256 The difference in the total staked amount.
    /// @param _sign bool The sign of the added (true) or subtracted (false) amount.
    /// @param _updatedStake uint256 The updated total staked amount.
    function stakeChange(address _stakeOwner, uint256 _amount, bool _sign, uint256 _updatedStake) external;

    /// @dev Notifies of multiple stake change events.
    /// @param _stakeOwners address[] The addresses of subject stake owners.
    /// @param _amounts uint256[] The differences in total staked amounts.
    /// @param _signs bool[] The signs of the added (true) or subtracted (false) amounts.
    /// @param _updatedStakes uint256[] The updated total staked amounts.
    function stakeChangeBatch(address[] calldata _stakeOwners, uint256[] calldata _amounts, bool[] calldata _signs,
        uint256[] calldata _updatedStakes) external;

    /// @dev Notifies of stake migration event.
    /// @param _stakeOwner address The address of the subject stake owner.
    /// @param _amount uint256 The migrated amount.
    function stakeMigration(address _stakeOwner, uint256 _amount) external;
}

// File: contracts/spec_interfaces/IStakingContractHandler.sol

pragma solidity 0.6.12;

/// @title Staking contract handler contract interface in addition to IStakeChangeNotifier
interface IStakingContractHandler {
    event StakeChangeNotificationSkipped(address indexed stakeOwner);
    event StakeChangeBatchNotificationSkipped(address[] stakeOwners);
    event StakeMigrationNotificationSkipped(address indexed stakeOwner);

    /*
    * External functions
    */

    /// Returns the stake of the specified stake owner (excluding unstaked tokens).
    /// @param stakeOwner address The address to check.
    /// @return uint256 The total stake.
    function getStakeBalanceOf(address stakeOwner) external view returns (uint256);

    /// Returns the total amount staked tokens (excluding unstaked tokens).
    /// @return uint256 is the total staked tokens of all stake owners.
    function getTotalStakedTokens() external view returns (uint256);

    /*
    * Governance functions
    */

    event NotifyDelegationsChanged(bool notifyDelegations);

    /// Sets notifications to the delegation contract
    /// @dev staking while notifications are disabled may lead to a discrepancy in the delegation data  
    /// @dev governance function called only by the migration manager
    /// @param notifyDelegations is a bool indicating whether to notify the delegation contract
    function setNotifyDelegations(bool notifyDelegations) external; /* onlyMigrationManager */

    /// Returns the notifications to the delegation contract status
    /// @return notifyDelegations is a bool indicating whether notifications are enabled
    function getNotifyDelegations() external view returns (bool);
}

// File: contracts/spec_interfaces/IStakingRewards.sol

pragma solidity 0.6.12;

/// @title Staking rewards contract interface
interface IStakingRewards {

    event DelegatorStakingRewardsAssigned(address indexed delegator, uint256 amount, uint256 totalAwarded, address guardian, uint256 delegatorRewardsPerToken, uint256 delegatorRewardsPerTokenDelta);
    event GuardianStakingRewardsAssigned(address indexed guardian, uint256 amount, uint256 totalAwarded, uint256 delegatorRewardsPerToken, uint256 delegatorRewardsPerTokenDelta, uint256 stakingRewardsPerWeight, uint256 stakingRewardsPerWeightDelta);
    event StakingRewardsClaimed(address indexed addr, uint256 claimedDelegatorRewards, uint256 claimedGuardianRewards, uint256 totalClaimedDelegatorRewards, uint256 totalClaimedGuardianRewards);
    event StakingRewardsAllocated(uint256 allocatedRewards, uint256 stakingRewardsPerWeight);
    event GuardianDelegatorsStakingRewardsPercentMilleUpdated(address indexed guardian, uint256 delegatorsStakingRewardsPercentMille);

    /*
     * External functions
     */

    /// Returns the current reward balance of the given address.
    /// @dev calculates the up to date balances (differ from the state)
    /// @param addr is the address to query
    /// @return delegatorStakingRewardsBalance the rewards awarded to the guardian role
    /// @return guardianStakingRewardsBalance the rewards awarded to the guardian role
    function getStakingRewardsBalance(address addr) external view returns (uint256 delegatorStakingRewardsBalance, uint256 guardianStakingRewardsBalance);

    /// Claims the staking rewards balance of an addr, staking the rewards
    /// @dev Claimed rewards are staked in the staking contract using the distributeRewards interface
    /// @dev includes the rewards for both the delegator and guardian roles
    /// @dev calculates the up to date rewards prior to distribute them to the staking contract
    /// @param addr is the address to claim rewards for
    function claimStakingRewards(address addr) external;

    /// Returns the current global staking rewards state
    /// @dev calculated to the latest block, may differ from the state read
    /// @return stakingRewardsPerWeight is the potential reward per 1E18 (TOKEN_BASE) committee weight assigned to a guardian was in the committee from day zero
    /// @return unclaimedStakingRewards is the of tokens that were assigned to participants and not claimed yet
    function getStakingRewardsState() external view returns (
        uint96 stakingRewardsPerWeight,
        uint96 unclaimedStakingRewards
    );

    /// Returns the current guardian staking rewards state
    /// @dev calculated to the latest block, may differ from the state read
    /// @dev notice that the guardian rewards are the rewards for the guardian role as guardian and do not include delegation rewards
    /// @dev use getDelegatorStakingRewardsData to get the guardian's rewards as delegator
    /// @param guardian is the guardian to query
    /// @return balance is the staking rewards balance for the guardian role
    /// @return claimed is the staking rewards for the guardian role that were claimed
    /// @return delegatorRewardsPerToken is the potential reward per token (1E18 units) assigned to a guardian's delegator that delegated from day zero
    /// @return delegatorRewardsPerTokenDelta is the increment in delegatorRewardsPerToken since the last guardian update
    /// @return lastStakingRewardsPerWeight is the up to date stakingRewardsPerWeight used for the guardian state calculation
    /// @return stakingRewardsPerWeightDelta is the increment in stakingRewardsPerWeight since the last guardian update
    function getGuardianStakingRewardsData(address guardian) external view returns (
        uint256 balance,
        uint256 claimed,
        uint256 delegatorRewardsPerToken,
        uint256 delegatorRewardsPerTokenDelta,
        uint256 lastStakingRewardsPerWeight,
        uint256 stakingRewardsPerWeightDelta
    );

    /// Returns the current delegator staking rewards state
    /// @dev calculated to the latest block, may differ from the state read
    /// @param delegator is the delegator to query
    /// @return balance is the staking rewards balance for the delegator role
    /// @return claimed is the staking rewards for the delegator role that were claimed
    /// @return guardian is the guardian the delegator delegated to receiving a portion of the guardian staking rewards
    /// @return lastDelegatorRewardsPerToken is the up to date delegatorRewardsPerToken used for the delegator state calculation
    /// @return delegatorRewardsPerTokenDelta is the increment in delegatorRewardsPerToken since the last delegator update
    function getDelegatorStakingRewardsData(address delegator) external view returns (
        uint256 balance,
        uint256 claimed,
        address guardian,
        uint256 lastDelegatorRewardsPerToken,
        uint256 delegatorRewardsPerTokenDelta
    );

    /// Returns an estimation for the delegator and guardian staking rewards for a given duration
    /// @dev the returned value is an estimation, assuming no change in the PoS state
    /// @dev the period calculated for start from the current block time until the current time + duration.
    /// @param addr is the address to estimate rewards for
    /// @param duration is the duration to calculate for in seconds
    /// @return estimatedDelegatorStakingRewards is the estimated reward for the delegator role
    /// @return estimatedGuardianStakingRewards is the estimated reward for the guardian role
    function estimateFutureRewards(address addr, uint256 duration) external view returns (
        uint256 estimatedDelegatorStakingRewards,
        uint256 estimatedGuardianStakingRewards
    );

    /// Sets the guardian's delegators staking reward portion
    /// @dev by default uses the defaultDelegatorsStakingRewardsPercentMille
    /// @param delegatorRewardsPercentMille is the delegators portion in percent-mille (0 - maxDelegatorsStakingRewardsPercentMille)
    function setGuardianDelegatorsStakingRewardsPercentMille(uint32 delegatorRewardsPercentMille) external;

    /// Returns a guardian's delegators staking reward portion
    /// @dev If not explicitly set, returns the defaultDelegatorsStakingRewardsPercentMille
    /// @return delegatorRewardsRatioPercentMille is the delegators portion in percent-mille
    function getGuardianDelegatorsStakingRewardsPercentMille(address guardian) external view returns (uint256 delegatorRewardsRatioPercentMille);

    /// Returns the amount of ORBS tokens in the staking rewards wallet allocated to staking rewards
    /// @dev The staking wallet balance must always larger than the allocated value
    /// @return allocated is the amount of tokens allocated in the staking rewards wallet
    function getStakingRewardsWalletAllocatedTokens() external view returns (uint256 allocated);

    /// Returns the current annual staking reward rate
    /// @dev calculated based on the current total committee weight
    /// @return annualRate is the current staking reward rate in percent-mille
    function getCurrentStakingRewardsRatePercentMille() external view returns (uint256 annualRate);

    /// Notifies an expected change in the committee membership of the guardian
    /// @dev Called only by: the Committee contract
    /// @dev called upon expected change in the committee membership of the guardian
    /// @dev triggers update of the global rewards state and the guardian rewards state
    /// @dev updates the rewards state based on the committee state prior to the change
    /// @param guardian is the guardian who's committee membership is updated
    /// @param weight is the weight of the guardian prior to the change
    /// @param totalCommitteeWeight is the total committee weight prior to the change
    /// @param inCommittee indicates whether the guardian was in the committee prior to the change
    /// @param inCommitteeAfter indicates whether the guardian is in the committee after the change
    function committeeMembershipWillChange(address guardian, uint256 weight, uint256 totalCommitteeWeight, bool inCommittee, bool inCommitteeAfter) external /* onlyCommitteeContract */;

    /// Notifies an expected change in a delegator and his guardian delegation state
    /// @dev Called only by: the Delegation contract
    /// @dev called upon expected change in a delegator's delegation state
    /// @dev triggers update of the global rewards state, the guardian rewards state and the delegator rewards state
    /// @dev on delegation change, updates also the new guardian and the delegator's lastDelegatorRewardsPerToken accordingly
    /// @param guardian is the delegator's guardian prior to the change
    /// @param guardianDelegatedStake is the delegated stake of the delegator's guardian prior to the change
    /// @param delegator is the delegator about to change delegation state
    /// @param delegatorStake is the stake of the delegator
    /// @param nextGuardian is the delegator's guardian after to the change
    /// @param nextGuardianDelegatedStake is the delegated stake of the delegator's guardian after to the change
    function delegationWillChange(address guardian, uint256 guardianDelegatedStake, address delegator, uint256 delegatorStake, address nextGuardian, uint256 nextGuardianDelegatedStake) external /* onlyDelegationsContract */;

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
    event EmergencyWithdrawal(address addr, address token);

    /// Activates staking rewards allocation
    /// @dev governance function called only by the initialization admin
    /// @dev On migrations, startTime should be set to the previous contract deactivation time
    /// @param startTime sets the last assignment time
    function activateRewardDistribution(uint startTime) external /* onlyInitializationAdmin */;

    /// Deactivates fees and bootstrap allocation
    /// @dev governance function called only by the migration manager
    /// @dev guardians updates remain active based on the current perMember value
    function deactivateRewardDistribution() external /* onlyMigrationManager */;
    
    /// Sets the default delegators staking reward portion
    /// @dev governance function called only by the functional manager
    /// @param defaultDelegatorsStakingRewardsPercentMille is the default delegators portion in percent-mille(0 - maxDelegatorsStakingRewardsPercentMille)
    function setDefaultDelegatorsStakingRewardsPercentMille(uint32 defaultDelegatorsStakingRewardsPercentMille) external /* onlyFunctionalManager */;

    /// Returns the default delegators staking reward portion
    /// @return defaultDelegatorsStakingRewardsPercentMille is the default delegators portion in percent-mille
    function getDefaultDelegatorsStakingRewardsPercentMille() external view returns (uint32);

    /// Sets the maximum delegators staking reward portion
    /// @dev governance function called only by the functional manager
    /// @param maxDelegatorsStakingRewardsPercentMille is the maximum delegators portion in percent-mille(0 - 100,000)
    function setMaxDelegatorsStakingRewardsPercentMille(uint32 maxDelegatorsStakingRewardsPercentMille) external /* onlyFunctionalManager */;

    /// Returns the default delegators staking reward portion
    /// @return maxDelegatorsStakingRewardsPercentMille is the maximum delegators portion in percent-mille
    function getMaxDelegatorsStakingRewardsPercentMille() external view returns (uint32);

    /// Sets the annual rate and cap for the staking reward
    /// @dev governance function called only by the functional manager
    /// @param annualRateInPercentMille is the annual rate in percent-mille
    /// @param annualCap is the annual staking rewards cap
    function setAnnualStakingRewardsRate(uint32 annualRateInPercentMille, uint96 annualCap) external /* onlyFunctionalManager */;

    /// Returns the annual staking reward rate
    /// @return annualStakingRewardsRatePercentMille is the annual rate in percent-mille
    function getAnnualStakingRewardsRatePercentMille() external view returns (uint32);

    /// Returns the annual staking rewards cap
    /// @return annualStakingRewardsCap is the annual rate in percent-mille
    function getAnnualStakingRewardsCap() external view returns (uint256);

    /// Checks if rewards allocation is active
    /// @return rewardAllocationActive is a bool that indicates that rewards allocation is active
    function isRewardAllocationActive() external view returns (bool);

    /// Returns the contract's settings
    /// @return annualStakingRewardsCap is the annual rate in percent-mille
    /// @return annualStakingRewardsRatePercentMille is the annual rate in percent-mille
    /// @return defaultDelegatorsStakingRewardsPercentMille is the default delegators portion in percent-mille
    /// @return maxDelegatorsStakingRewardsPercentMille is the maximum delegators portion in percent-mille
    /// @return rewardAllocationActive is a bool that indicates that rewards allocation is active
    function getSettings() external view returns (
        uint annualStakingRewardsCap,
        uint32 annualStakingRewardsRatePercentMille,
        uint32 defaultDelegatorsStakingRewardsPercentMille,
        uint32 maxDelegatorsStakingRewardsPercentMille,
        bool rewardAllocationActive
    );

    /// Migrates the staking rewards balance of the given addresses to a new staking rewards contract
    /// @dev The new rewards contract is determined according to the contracts registry
    /// @dev No impact of the calling contract if the currently configured contract in the registry
    /// @dev may be called also while the contract is locked
    /// @param addrs is the list of addresses to migrate
    function migrateRewardsBalance(address[] calldata addrs) external;

    /// Accepts addresses balance migration from a previous rewards contract
    /// @dev the function may be called by any caller that approves the amounts provided for transfer
    /// @param addrs is the list migrated addresses
    /// @param migratedGuardianStakingRewards is the list of received guardian rewards balance for each address
    /// @param migratedDelegatorStakingRewards is the list of received delegator rewards balance for each address
    /// @param totalAmount is the total amount of staking rewards migrated for all addresses in the list. Must match the sum of migratedGuardianStakingRewards and migratedDelegatorStakingRewards lists.
    function acceptRewardsBalanceMigration(address[] calldata addrs, uint256[] calldata migratedGuardianStakingRewards, uint256[] calldata migratedDelegatorStakingRewards, uint256 totalAmount) external;

    /// Performs emergency withdrawal of the contract balance
    /// @dev called with a token to withdraw, should be called twice with the fees and bootstrap tokens
    /// @dev governance function called only by the migration manager
    /// @param erc20 is the ERC20 token to withdraw
    function emergencyWithdraw(address erc20) external /* onlyMigrationManager */;
}

// File: contracts/spec_interfaces/IManagedContract.sol

pragma solidity 0.6.12;

/// @title managed contract interface, used by the contracts registry to notify the contract on updates
interface IManagedContract /* is ILockable, IContractRegistryAccessor, Initializable */ {

    /// Refreshes the address of the other contracts the contract interacts with
    /// @dev called by the registry contract upon an update of a contract in the registry
    function refreshContracts() external;

}

// File: contracts/spec_interfaces/IContractRegistry.sol

pragma solidity 0.6.12;

/// @title Contract registry contract interface
/// @dev The contract registry holds Orbs PoS contracts and managers lists
/// @dev The contract registry updates the managed contracts on changes in the contract list
/// @dev Governance functions restricted to managers access the registry to retrieve the manager address 
/// @dev The contract registry represents the source of truth for Orbs Ethereum contracts 
/// @dev By tracking the registry events or query before interaction, one can access the up to date contracts 
interface IContractRegistry {

	event ContractAddressUpdated(string contractName, address addr, bool managedContract);
	event ManagerChanged(string role, address newManager);
	event ContractRegistryUpdated(address newContractRegistry);

	/*
	* External functions
	*/

    /// Updates the contracts address and emits a corresponding event
    /// @dev governance function called only by the migrationManager or registryAdmin
    /// @param contractName is the contract name, used to identify it
    /// @param addr is the contract updated address
    /// @param managedContract indicates whether the contract is managed by the registry and notified on changes
	function setContract(string calldata contractName, address addr, bool managedContract) external /* onlyAdminOrMigrationManager */;

    /// Returns the current address of the given contracts
    /// @param contractName is the contract name, used to identify it
    /// @return addr is the contract updated address
	function getContract(string calldata contractName) external view returns (address);

    /// Returns the list of contract addresses managed by the registry
    /// @dev Managed contracts are updated on changes in the registry contracts addresses 
    /// @return addrs is the list of managed contracts
	function getManagedContracts() external view returns (address[] memory);

    /// Locks all the managed contracts 
    /// @dev governance function called only by the migrationManager or registryAdmin
    /// @dev When set all onlyWhenActive functions will revert
	function lockContracts() external /* onlyAdminOrMigrationManager */;

    /// Unlocks all the managed contracts 
    /// @dev governance function called only by the migrationManager or registryAdmin
	function unlockContracts() external /* onlyAdminOrMigrationManager */;
	
    /// Updates a manager address and emits a corresponding event
    /// @dev governance function called only by the registryAdmin
    /// @dev the managers list is a flexible list of role to the manager's address
    /// @param role is the managers' role name, for example "functionalManager"
    /// @param manager is the manager updated address
	function setManager(string calldata role, address manager) external /* onlyAdmin */;

    /// Returns the current address of the given manager
    /// @param role is the manager name, used to identify it
    /// @return addr is the manager updated address
	function getManager(string calldata role) external view returns (address);

    /// Sets a new contract registry to migrate to
    /// @dev governance function called only by the registryAdmin
    /// @dev updates the registry address record in all the managed contracts
    /// @dev by tracking the emitted ContractRegistryUpdated, tools can track the up to date contracts
    /// @param newRegistry is the new registry contract 
	function setNewContractRegistry(IContractRegistry newRegistry) external /* onlyAdmin */;

    /// Returns the previous contract registry address 
    /// @dev used when the setting the contract as a new registry to assure a valid registry
    /// @return previousContractRegistry is the previous contract registry
	function getPreviousContractRegistry() external view returns (address);
}

// File: contracts/spec_interfaces/IContractRegistryAccessor.sol

pragma solidity 0.6.12;


interface IContractRegistryAccessor {

    /// Sets the contract registry address
    /// @dev governance function called only by an admin
    /// @param newRegistry is the new registry contract 
    function setContractRegistry(IContractRegistry newRegistry) external /* onlyAdmin */;

    /// Returns the contract registry address
    /// @return contractRegistry is the contract registry address
    function getContractRegistry() external view returns (IContractRegistry contractRegistry);

    function setRegistryAdmin(address _registryAdmin) external /* onlyInitializationAdmin */;

}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/WithClaimableRegistryManagement.sol

pragma solidity 0.6.12;


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract WithClaimableRegistryManagement is Context {
    address private _registryAdmin;
    address private _pendingRegistryAdmin;

    event RegistryManagementTransferred(address indexed previousRegistryAdmin, address indexed newRegistryAdmin);

    /**
     * @dev Initializes the contract setting the deployer as the initial registryRegistryAdmin.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _registryAdmin = msgSender;
        emit RegistryManagementTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current registryAdmin.
     */
    function registryAdmin() public view returns (address) {
        return _registryAdmin;
    }

    /**
     * @dev Throws if called by any account other than the registryAdmin.
     */
    modifier onlyRegistryAdmin() {
        require(isRegistryAdmin(), "WithClaimableRegistryManagement: caller is not the registryAdmin");
        _;
    }

    /**
     * @dev Returns true if the caller is the current registryAdmin.
     */
    function isRegistryAdmin() public view returns (bool) {
        return _msgSender() == _registryAdmin;
    }

    /**
     * @dev Leaves the contract without registryAdmin. It will not be possible to call
     * `onlyManager` functions anymore. Can only be called by the current registryAdmin.
     *
     * NOTE: Renouncing registryManagement will leave the contract without an registryAdmin,
     * thereby removing any functionality that is only available to the registryAdmin.
     */
    function renounceRegistryManagement() public onlyRegistryAdmin {
        emit RegistryManagementTransferred(_registryAdmin, address(0));
        _registryAdmin = address(0);
    }

    /**
     * @dev Transfers registryManagement of the contract to a new account (`newManager`).
     */
    function _transferRegistryManagement(address newRegistryAdmin) internal {
        require(newRegistryAdmin != address(0), "RegistryAdmin: new registryAdmin is the zero address");
        emit RegistryManagementTransferred(_registryAdmin, newRegistryAdmin);
        _registryAdmin = newRegistryAdmin;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingManager.
     */
    modifier onlyPendingRegistryAdmin() {
        require(msg.sender == _pendingRegistryAdmin, "Caller is not the pending registryAdmin");
        _;
    }
    /**
     * @dev Allows the current registryAdmin to set the pendingManager address.
     * @param newRegistryAdmin The address to transfer registryManagement to.
     */
    function transferRegistryManagement(address newRegistryAdmin) public onlyRegistryAdmin {
        _pendingRegistryAdmin = newRegistryAdmin;
    }

    /**
     * @dev Allows the _pendingRegistryAdmin address to finalize the transfer.
     */
    function claimRegistryManagement() external onlyPendingRegistryAdmin {
        _transferRegistryManagement(_pendingRegistryAdmin);
        _pendingRegistryAdmin = address(0);
    }

    /**
     * @dev Returns the current pendingRegistryAdmin
    */
    function pendingRegistryAdmin() public view returns (address) {
       return _pendingRegistryAdmin;  
    }
}

// File: contracts/Initializable.sol

pragma solidity 0.6.12;

contract Initializable {

    address private _initializationAdmin;

    event InitializationComplete();

    /// Constructor
    /// Sets the initializationAdmin to the contract deployer
    /// The initialization admin may call any manager only function until initializationComplete
    constructor() public{
        _initializationAdmin = msg.sender;
    }

    modifier onlyInitializationAdmin() {
        require(msg.sender == initializationAdmin(), "sender is not the initialization admin");

        _;
    }

    /*
    * External functions
    */

    /// Returns the initializationAdmin address
    function initializationAdmin() public view returns (address) {
        return _initializationAdmin;
    }

    /// Finalizes the initialization and revokes the initializationAdmin role 
    function initializationComplete() external onlyInitializationAdmin {
        _initializationAdmin = address(0);
        emit InitializationComplete();
    }

    /// Checks if the initialization was completed
    function isInitializationComplete() public view returns (bool) {
        return _initializationAdmin == address(0);
    }

}

// File: contracts/ContractRegistryAccessor.sol

pragma solidity 0.6.12;





contract ContractRegistryAccessor is IContractRegistryAccessor, WithClaimableRegistryManagement, Initializable {

    IContractRegistry private contractRegistry;

    /// Constructor
    /// @param _contractRegistry is the contract registry address
    /// @param _registryAdmin is the registry admin address
    constructor(IContractRegistry _contractRegistry, address _registryAdmin) public {
        require(address(_contractRegistry) != address(0), "_contractRegistry cannot be 0");
        setContractRegistry(_contractRegistry);
        _transferRegistryManagement(_registryAdmin);
    }

    modifier onlyAdmin {
        require(isAdmin(), "sender is not an admin (registryManger or initializationAdmin)");

        _;
    }

    modifier onlyMigrationManager {
        require(isMigrationManager(), "sender is not the migration manager");

        _;
    }

    modifier onlyFunctionalManager {
        require(isFunctionalManager(), "sender is not the functional manager");

        _;
    }

    /// Checks whether the caller is Admin: either the contract registry, the registry admin, or the initialization admin
    function isAdmin() internal view returns (bool) {
        return msg.sender == address(contractRegistry) || msg.sender == registryAdmin() || msg.sender == initializationAdmin();
    }

    /// Checks whether the caller is a specific manager role or and Admin
    /// @dev queries the registry contract for the up to date manager assignment
    function isManager(string memory role) internal view returns (bool) {
        IContractRegistry _contractRegistry = contractRegistry;
        return isAdmin() || _contractRegistry != IContractRegistry(0) && contractRegistry.getManager(role) == msg.sender;
    }

    /// Checks whether the caller is the migration manager
    function isMigrationManager() internal view returns (bool) {
        return isManager('migrationManager');
    }

    /// Checks whether the caller is the functional manager
    function isFunctionalManager() internal view returns (bool) {
        return isManager('functionalManager');
    }

    /* 
     * Contract getters, return the address of a contract by calling the contract registry 
     */ 

    function getProtocolContract() internal view returns (address) {
        return contractRegistry.getContract("protocol");
    }

    function getStakingRewardsContract() internal view returns (address) {
        return contractRegistry.getContract("stakingRewards");
    }

    function getFeesAndBootstrapRewardsContract() internal view returns (address) {
        return contractRegistry.getContract("feesAndBootstrapRewards");
    }

    function getCommitteeContract() internal view returns (address) {
        return contractRegistry.getContract("committee");
    }

    function getElectionsContract() internal view returns (address) {
        return contractRegistry.getContract("elections");
    }

    function getDelegationsContract() internal view returns (address) {
        return contractRegistry.getContract("delegations");
    }

    function getGuardiansRegistrationContract() internal view returns (address) {
        return contractRegistry.getContract("guardiansRegistration");
    }

    function getCertificationContract() internal view returns (address) {
        return contractRegistry.getContract("certification");
    }

    function getStakingContract() internal view returns (address) {
        return contractRegistry.getContract("staking");
    }

    function getSubscriptionsContract() internal view returns (address) {
        return contractRegistry.getContract("subscriptions");
    }

    function getStakingRewardsWallet() internal view returns (address) {
        return contractRegistry.getContract("stakingRewardsWallet");
    }

    function getBootstrapRewardsWallet() internal view returns (address) {
        return contractRegistry.getContract("bootstrapRewardsWallet");
    }

    function getGeneralFeesWallet() internal view returns (address) {
        return contractRegistry.getContract("generalFeesWallet");
    }

    function getCertifiedFeesWallet() internal view returns (address) {
        return contractRegistry.getContract("certifiedFeesWallet");
    }

    function getStakingContractHandler() internal view returns (address) {
        return contractRegistry.getContract("stakingContractHandler");
    }

    /*
    * Governance functions
    */

    event ContractRegistryAddressUpdated(address addr);

    /// Sets the contract registry address
    /// @dev governance function called only by an admin
    /// @param newContractRegistry is the new registry contract 
    function setContractRegistry(IContractRegistry newContractRegistry) public override onlyAdmin {
        require(newContractRegistry.getPreviousContractRegistry() == address(contractRegistry), "new contract registry must provide the previous contract registry");
        contractRegistry = newContractRegistry;
        emit ContractRegistryAddressUpdated(address(newContractRegistry));
    }

    /// Returns the contract registry that the contract is set to use
    /// @return contractRegistry is the registry contract address
    function getContractRegistry() public override view returns (IContractRegistry) {
        return contractRegistry;
    }

    function setRegistryAdmin(address _registryAdmin) external override onlyInitializationAdmin {
        _transferRegistryManagement(_registryAdmin);
    }

}

// File: contracts/spec_interfaces/ILockable.sol

pragma solidity 0.6.12;

/// @title lockable contract interface, allows to lock a contract
interface ILockable {

    event Locked();
    event Unlocked();

    /// Locks the contract to external non-governance function calls
    /// @dev governance function called only by the migration manager or an admin
    /// @dev typically called by the registry contract upon locking all managed contracts
    /// @dev getters and migration functions remain active also for locked contracts
    /// @dev checked by the onlyWhenActive modifier
    function lock() external /* onlyMigrationManager */;

    /// Unlocks the contract 
    /// @dev governance function called only by the migration manager or an admin
    /// @dev typically called by the registry contract upon unlocking all managed contracts
    function unlock() external /* onlyMigrationManager */;

    /// Returns the contract locking status
    /// @return isLocked is a bool indicating the contract is locked 
    function isLocked() view external returns (bool);

}

// File: contracts/Lockable.sol

pragma solidity 0.6.12;



/// @title lockable contract
contract Lockable is ILockable, ContractRegistryAccessor {

    bool public locked;

    /// Constructor
    /// @param _contractRegistry is the contract registry address
    /// @param _registryAdmin is the registry admin address
    constructor(IContractRegistry _contractRegistry, address _registryAdmin) ContractRegistryAccessor(_contractRegistry, _registryAdmin) public {}

    /// Locks the contract to external non-governance function calls
    /// @dev governance function called only by the migration manager or an admin
    /// @dev typically called by the registry contract upon locking all managed contracts
    /// @dev getters and migration functions remain active also for locked contracts
    /// @dev checked by the onlyWhenActive modifier
    function lock() external override onlyMigrationManager {
        locked = true;
        emit Locked();
    }

    /// Unlocks the contract 
    /// @dev governance function called only by the migration manager or an admin
    /// @dev typically called by the registry contract upon unlocking all managed contracts
    function unlock() external override onlyMigrationManager {
        locked = false;
        emit Unlocked();
    }

    /// Returns the contract locking status
    /// @return isLocked is a bool indicating the contract is locked 
    function isLocked() external override view returns (bool) {
        return locked;
    }

    modifier onlyWhenActive() {
        require(!locked, "contract is locked for this operation");

        _;
    }
}

// File: contracts/ManagedContract.sol

pragma solidity 0.6.12;



/// @title managed contract
contract ManagedContract is IManagedContract, Lockable {

    /// @param _contractRegistry is the contract registry address
    /// @param _registryAdmin is the registry admin address
    constructor(IContractRegistry _contractRegistry, address _registryAdmin) Lockable(_contractRegistry, _registryAdmin) public {}

    /// Refreshes the address of the other contracts the contract interacts with
    /// @dev called by the registry contract upon an update of a contract in the registry
    function refreshContracts() virtual override external {}

}

// File: contracts/Delegations.sol

pragma solidity 0.6.12;









/// @title Delegations contract
contract Delegations is IDelegations, IStakeChangeNotifier, ManagedContract {
	using SafeMath for uint256;
	using SafeMath96 for uint96;

	address constant public VOID_ADDR = address(-1);

	struct StakeOwnerData {
		address delegation;
		uint96 stake;
	}
	mapping(address => StakeOwnerData) public stakeOwnersData;
	mapping(address => uint256) public uncappedDelegatedStake;

	uint256 totalDelegatedStake;

	struct DelegateStatus {
		address addr;
		uint256 uncappedDelegatedStake;
		bool isSelfDelegating;
		uint256 delegatedStake;
		uint96 selfDelegatedStake;
	}

    /// Constructor
    /// @param _contractRegistry is the contract registry address
    /// @param _registryAdmin is the registry admin address
	constructor(IContractRegistry _contractRegistry, address _registryAdmin) ManagedContract(_contractRegistry, _registryAdmin) public {
		address VOID_ADDRESS_DUMMY_DELEGATION = address(-2);
		assert(VOID_ADDR != VOID_ADDRESS_DUMMY_DELEGATION && VOID_ADDR != address(0) && VOID_ADDRESS_DUMMY_DELEGATION != address(0));
		stakeOwnersData[VOID_ADDR].delegation = VOID_ADDRESS_DUMMY_DELEGATION;
	}

	modifier onlyStakingContractHandler() {
		require(msg.sender == address(stakingContractHandler), "caller is not the staking contract handler");

		_;
	}

	/*
	* External functions
	*/

    /// Delegate your stake
    /// @dev updates the election contract on the changes in the delegated stake
    /// @dev updates the rewards contract on the upcoming change in the delegator's delegation state
    /// @param to is the address to delegate to
	function delegate(address to) external override onlyWhenActive {
		delegateFrom(msg.sender, to);
	}

    /// Refresh the address stake for delegation power based on the staking contract
    /// @dev Disabled stake change update notifications from the staking contract may create mismatches
    /// @dev refreshStake re-syncs the stake data with the staking contract
    /// @param addr is the address to refresh its stake
	function refreshStake(address addr) external override onlyWhenActive {
		_stakeChange(addr, stakingContractHandler.getStakeBalanceOf(addr));
	}

    /// Refresh the addresses stake for delegation power based on the staking contract
    /// @dev Batched version of refreshStake
    /// @dev Disabled stake change update notifications from the staking contract may create mismatches
    /// @dev refreshStakeBatch re-syncs the stake data with the staking contract
    /// @param addrs is the list of addresses to refresh their stake
	function refreshStakeBatch(address[] calldata addrs) external override onlyWhenActive {
		for (uint i = 0; i < addrs.length; i++) {
			_stakeChange(addrs[i], stakingContractHandler.getStakeBalanceOf(addrs[i]));
		}
	}

    /// Returns the delegate address of the given address
    /// @param addr is the address to query
    /// @return delegation is the address the addr delegated to
	function getDelegation(address addr) external override view returns (address) {
		return getStakeOwnerData(addr).delegation;
	}

    /// Returns a delegator info
    /// @param addr is the address to query
    /// @return delegation is the address the addr delegated to
    /// @return delegatorStake is the stake of the delegator as reflected in the delegation contract
	function getDelegationInfo(address addr) external override view returns (address delegation, uint256 delegatorStake) {
		StakeOwnerData memory data = getStakeOwnerData(addr);
		return (data.delegation, data.stake);
	}

    /// Returns the delegated stake of an addr 
    /// @dev an address that is not self delegating has a 0 delegated stake
    /// @param addr is the address to query
    /// @return delegatedStake is the address delegated stake
	function getDelegatedStake(address addr) external override view returns (uint256) {
		return getDelegateStatus(addr).delegatedStake;
	}

    /// Returns the total delegated stake
    /// @dev delegatedStake - the total stake delegated to an address that is self delegating
    /// @dev the delegated stake of a non self-delegated address is 0
    /// @return totalDelegatedStake is the total delegatedStake of all the addresses
	function getTotalDelegatedStake() external override view returns (uint256) {
		return totalDelegatedStake;
	}

	/*
	* Notifications from staking contract (IStakeChangeNotifier)
	*/

    /// Notifies of stake change event.
    /// @param _stakeOwner is the address of the subject stake owner.
    /// @param _updatedStake is the updated total staked amount.
	function stakeChange(address _stakeOwner, uint256, bool, uint256 _updatedStake) external override onlyStakingContractHandler onlyWhenActive {
		_stakeChange(_stakeOwner, _updatedStake);
	}

    /// Notifies of multiple stake change events.
    /// @param _stakeOwners is the addresses of subject stake owners.
    /// @param _amounts is the differences in total staked amounts.
    /// @param _signs is the signs of the added (true) or subtracted (false) amounts.
    /// @param _updatedStakes is the updated total staked amounts.
	function stakeChangeBatch(address[] calldata _stakeOwners, uint256[] calldata _amounts, bool[] calldata _signs, uint256[] calldata _updatedStakes) external override onlyStakingContractHandler onlyWhenActive {
		uint batchLength = _stakeOwners.length;
		require(batchLength == _amounts.length, "_stakeOwners, _amounts - array length mismatch");
		require(batchLength == _signs.length, "_stakeOwners, _signs - array length mismatch");
		require(batchLength == _updatedStakes.length, "_stakeOwners, _updatedStakes - array length mismatch");

		for (uint i = 0; i < _stakeOwners.length; i++) {
			_stakeChange(_stakeOwners[i], _updatedStakes[i]);
		}
	}

    /// Notifies of stake migration event.
    /// @dev Empty function. A staking contract migration may be handled in the future in the StakingContractHandler 
    /// @param _stakeOwner address The address of the subject stake owner.
    /// @param _amount uint256 The migrated amount.
	function stakeMigration(address _stakeOwner, uint256 _amount) external override onlyStakingContractHandler onlyWhenActive {}

	/*
	* Governance functions
	*/

    /// Imports delegations during initial migration
    /// @dev initialization function called only by the initializationManager
    /// @dev Does not update the Rewards or Election contracts
    /// @dev assumes deactivated Rewards
    /// @param from is a list of delegator addresses
    /// @param to is the address the delegators delegate to
	function importDelegations(address[] calldata from, address to) external override onlyInitializationAdmin {
		require(to != address(0), "to must be a non zero address");
		require(from.length > 0, "from array must contain at least one address");
		(uint96 stakingRewardsPerWeight, ) = stakingRewardsContract.getStakingRewardsState();
		require(stakingRewardsPerWeight == 0, "no rewards may be allocated prior to importing delegations");

		uint256 uncappedDelegatedStakeDelta = 0;
		StakeOwnerData memory data;
		uint256 newTotalDelegatedStake = totalDelegatedStake;
		DelegateStatus memory delegateStatus = getDelegateStatus(to);
		IStakingContractHandler _stakingContractHandler = stakingContractHandler;
		uint256 delegatorUncapped;
		uint256[] memory delegatorsStakes = new uint256[](from.length);
		for (uint i = 0; i < from.length; i++) {
			data = stakeOwnersData[from[i]];
			require(data.delegation == address(0), "import allowed only for uninitialized accounts. existing delegation detected");
			require(from[i] != to, "import cannot be used for self-delegation (already self delegated)");
			require(data.stake == 0 , "import allowed only for uninitialized accounts. existing stake detected");

			// from[i] stops being self delegating. any uncappedDelegatedStake it has now stops being counted towards totalDelegatedStake
			delegatorUncapped = uncappedDelegatedStake[from[i]];
			if (delegatorUncapped > 0) {
				newTotalDelegatedStake = newTotalDelegatedStake.sub(delegatorUncapped);
				emit DelegatedStakeChanged(
					from[i],
					0,
					0,
					from[i],
					0
				);
			}

			// update state
			data.delegation = to;
			data.stake = uint96(_stakingContractHandler.getStakeBalanceOf(from[i]));
			stakeOwnersData[from[i]] = data;

			uncappedDelegatedStakeDelta = uncappedDelegatedStakeDelta.add(data.stake);

			// store individual stake for event
			delegatorsStakes[i] = data.stake;

			emit Delegated(from[i], to);

			emit DelegatedStakeChanged(
				to,
				delegateStatus.selfDelegatedStake,
				delegateStatus.isSelfDelegating ? delegateStatus.delegatedStake.add(uncappedDelegatedStakeDelta) : 0,
				from[i],
				data.stake
			);
		}

		// update totals
		uncappedDelegatedStake[to] = uncappedDelegatedStake[to].add(uncappedDelegatedStakeDelta);

		if (delegateStatus.isSelfDelegating) {
			newTotalDelegatedStake = newTotalDelegatedStake.add(uncappedDelegatedStakeDelta);
		}
		totalDelegatedStake = newTotalDelegatedStake;

		// emit events
		emit DelegationsImported(from, to);
	}

    /// Initializes the delegation of an address during initial migration 
    /// @dev initialization function called only by the initializationManager
    /// @dev behaves identically to a delegate transaction sent by the delegator
    /// @param from is the delegator addresses
    /// @param to is the delegator delegates to
	function initDelegation(address from, address to) external override onlyInitializationAdmin {
		delegateFrom(from, to);
		emit DelegationInitialized(from, to);
	}

	/*
	* Private functions
	*/

    /// Generates and returns an internal memory structure with a Delegate status
    /// @dev updated based on the up to date state
    /// @dev status.addr is the queried address
    /// @dev status.uncappedDelegatedStake is the amount delegated to address including self-delegated stake
    /// @dev status.isSelfDelegating indicates whether the address is self-delegated
    /// @dev status.selfDelegatedStake if the addr is self-delegated is  the addr self stake. 0 if not self-delegated
    /// @dev status.delegatedStake if the addr is self-delegated is the mount delegated to address. 0 if not self-delegated
	function getDelegateStatus(address addr) private view returns (DelegateStatus memory status) {
		StakeOwnerData memory data = getStakeOwnerData(addr);

		status.addr = addr;
		status.uncappedDelegatedStake = uncappedDelegatedStake[addr];
		status.isSelfDelegating = data.delegation == addr;
		status.selfDelegatedStake = status.isSelfDelegating ? data.stake : 0;
		status.delegatedStake = status.isSelfDelegating ? status.uncappedDelegatedStake : 0;

		return status;
	}

    /// Returns an address stake and delegation data. 
    /// @dev implicitly self-delegated addresses (delegation = 0) return delegation to the address
	function getStakeOwnerData(address addr) private view returns (StakeOwnerData memory data) {
		data = stakeOwnersData[addr];
		data.delegation = (data.delegation == address(0)) ? addr : data.delegation;
		return data;
	}

	struct DelegateFromVars {
		DelegateStatus prevDelegateStatusBefore;
		DelegateStatus newDelegateStatusBefore;
		DelegateStatus prevDelegateStatusAfter;
		DelegateStatus newDelegateStatusAfter;
	}

    /// Handles a delegation change
    /// @dev notifies the rewards contract on the expected change (with data prior to the change)
    /// @dev updates the impacted delegates delegated stake and the total stake
    /// @dev notifies the election contract on changes in the impacted delegates delegated stake
    /// @param from is the delegator address 
    /// @param to is the delegate address
	function delegateFrom(address from, address to) private {
		require(to != address(0), "cannot delegate to a zero address");

		DelegateFromVars memory vars;

		StakeOwnerData memory delegatorData = getStakeOwnerData(from);
		address prevDelegate = delegatorData.delegation;

		if (to == prevDelegate) return; // Delegation hasn't changed

		// Optimization - no need for the full flow in the case of a zero staked delegator with no delegations
		if (delegatorData.stake == 0 && uncappedDelegatedStake[from] == 0) {
			stakeOwnersData[from].delegation = to;
			emit Delegated(from, to);
			return;
		}

		vars.prevDelegateStatusBefore = getDelegateStatus(prevDelegate);
		vars.newDelegateStatusBefore = getDelegateStatus(to);

		stakingRewardsContract.delegationWillChange(prevDelegate, vars.prevDelegateStatusBefore.delegatedStake, from, delegatorData.stake, to, vars.newDelegateStatusBefore.delegatedStake);

		stakeOwnersData[from].delegation = to;

		uint256 delegatorStake = delegatorData.stake;

		uncappedDelegatedStake[prevDelegate] = vars.prevDelegateStatusBefore.uncappedDelegatedStake.sub(delegatorStake);
		uncappedDelegatedStake[to] = vars.newDelegateStatusBefore.uncappedDelegatedStake.add(delegatorStake);

		vars.prevDelegateStatusAfter = getDelegateStatus(prevDelegate);
		vars.newDelegateStatusAfter = getDelegateStatus(to);

		uint256 _totalDelegatedStake = totalDelegatedStake.sub(
			vars.prevDelegateStatusBefore.delegatedStake
		).add(
			vars.prevDelegateStatusAfter.delegatedStake
		).sub(
			vars.newDelegateStatusBefore.delegatedStake
		).add(
			vars.newDelegateStatusAfter.delegatedStake
		);

		totalDelegatedStake = _totalDelegatedStake;

		emit Delegated(from, to);

		IElections _electionsContract = electionsContract;

		if (vars.prevDelegateStatusBefore.delegatedStake != vars.prevDelegateStatusAfter.delegatedStake) {
			_electionsContract.delegatedStakeChange(
				prevDelegate,
				vars.prevDelegateStatusAfter.selfDelegatedStake,
				vars.prevDelegateStatusAfter.delegatedStake,
				_totalDelegatedStake
			);

			emit DelegatedStakeChanged(
				prevDelegate,
				vars.prevDelegateStatusAfter.selfDelegatedStake,
				vars.prevDelegateStatusAfter.delegatedStake,
				from,
				0
			);
		}

		if (vars.newDelegateStatusBefore.delegatedStake != vars.newDelegateStatusAfter.delegatedStake) {
			_electionsContract.delegatedStakeChange(
				to,
				vars.newDelegateStatusAfter.selfDelegatedStake,
				vars.newDelegateStatusAfter.delegatedStake,
				_totalDelegatedStake
			);

			emit DelegatedStakeChanged(
				to,
				vars.newDelegateStatusAfter.selfDelegatedStake,
				vars.newDelegateStatusAfter.delegatedStake,
				from,
				delegatorStake
			);
		}
	}

    /// Handles a change in a stake owner stake
    /// @dev notifies the rewards contract on the expected change (with data prior to the change)
    /// @dev updates the impacted delegate delegated stake and the total stake
    /// @dev notifies the election contract on changes in the impacted delegate delegated stake
    /// @param _stakeOwner is the stake owner
    /// @param _updatedStake is the stake owner stake after the change
	function _stakeChange(address _stakeOwner, uint256 _updatedStake) private {
		StakeOwnerData memory stakeOwnerDataBefore = getStakeOwnerData(_stakeOwner);
		DelegateStatus memory delegateStatusBefore = getDelegateStatus(stakeOwnerDataBefore.delegation);

		uint256 prevUncappedStake = delegateStatusBefore.uncappedDelegatedStake;
		uint256 newUncappedStake = prevUncappedStake.sub(stakeOwnerDataBefore.stake).add(_updatedStake);

		stakingRewardsContract.delegationWillChange(stakeOwnerDataBefore.delegation, delegateStatusBefore.delegatedStake, _stakeOwner, stakeOwnerDataBefore.stake, stakeOwnerDataBefore.delegation, delegateStatusBefore.delegatedStake);

		uncappedDelegatedStake[stakeOwnerDataBefore.delegation] = newUncappedStake;

		require(uint256(uint96(_updatedStake)) == _updatedStake, "Delegations::updatedStakes value too big (>96 bits)");
		stakeOwnersData[_stakeOwner].stake = uint96(_updatedStake);

		uint256 _totalDelegatedStake = totalDelegatedStake;
		if (delegateStatusBefore.isSelfDelegating) {
			_totalDelegatedStake = _totalDelegatedStake.sub(stakeOwnerDataBefore.stake).add(_updatedStake);
			totalDelegatedStake = _totalDelegatedStake;
		}

		DelegateStatus memory delegateStatusAfter = getDelegateStatus(stakeOwnerDataBefore.delegation);

		electionsContract.delegatedStakeChange(
			stakeOwnerDataBefore.delegation,
			delegateStatusAfter.selfDelegatedStake,
			delegateStatusAfter.delegatedStake,
			_totalDelegatedStake
		);

		if (_updatedStake != stakeOwnerDataBefore.stake) {
			emit DelegatedStakeChanged(
				stakeOwnerDataBefore.delegation,
				delegateStatusAfter.selfDelegatedStake,
				delegateStatusAfter.delegatedStake,
				_stakeOwner,
				_updatedStake
			);
		}
	}

	/*
     * Contracts topology / registry interface
     */

	IElections electionsContract;
	IStakingRewards stakingRewardsContract;
	IStakingContractHandler stakingContractHandler;

    /// Refreshes the address of the other contracts the contract interacts with
    /// @dev called by the registry contract upon an update of a contract in the registry
	function refreshContracts() external override {
		electionsContract = IElections(getElectionsContract());
		stakingContractHandler = IStakingContractHandler(getStakingContractHandler());
		stakingRewardsContract = IStakingRewards(getStakingRewardsContract());
	}

}