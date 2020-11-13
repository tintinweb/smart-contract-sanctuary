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

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/spec_interfaces/ICommittee.sol

pragma solidity 0.6.12;

/// @title Committee contract interface
interface ICommittee {
	event CommitteeChange(address indexed addr, uint256 weight, bool certification, bool inCommittee);
	event CommitteeSnapshot(address[] addrs, uint256[] weights, bool[] certification);

	// No external functions

	/*
     * External functions
     */

    /// Notifies a weight change of a member
    /// @dev Called only by: Elections contract
    /// @param addr is the committee member address
    /// @param weight is the updated weight of the committee member
	function memberWeightChange(address addr, uint256 weight) external /* onlyElectionsContract onlyWhenActive */;

    /// Notifies a change in the certification of a member
    /// @dev Called only by: Elections contract
    /// @param addr is the committee member address
    /// @param isCertified is the updated certification state of the member
	function memberCertificationChange(address addr, bool isCertified) external /* onlyElectionsContract onlyWhenActive */;

    /// Notifies a member removal for example due to voteOut or voteUnready
    /// @dev Called only by: Elections contract
    /// @param memberRemoved is the removed committee member address
    /// @return memberRemoved indicates whether the member was removed from the committee
    /// @return removedMemberWeight indicates the removed member weight
    /// @return removedMemberCertified indicates whether the member was in the certified committee
	function removeMember(address addr) external returns (bool memberRemoved, uint removedMemberWeight, bool removedMemberCertified)/* onlyElectionContract */;

    /// Notifies a new member applicable for committee (due to registration, unbanning, certification change)
    /// The new member will be added only if it is qualified to join the committee 
    /// @dev Called only by: Elections contract
    /// @param addr is the added committee member address
    /// @param weight is the added member weight
    /// @param isCertified is the added member certification state
    /// @return memberAdded bool indicates whether the member was added
	function addMember(address addr, uint256 weight, bool isCertified) external returns (bool memberAdded)  /* onlyElectionsContract */;

    /// Checks if addMember() would add a the member to the committee (qualified to join)
    /// @param addr is the candidate committee member address
    /// @param weight is the candidate committee member weight
    /// @return wouldAddMember bool indicates whether the member will be added
	function checkAddMember(address addr, uint256 weight) external view returns (bool wouldAddMember);

    /// Returns the committee members and their weights
    /// @return addrs is the committee members list
    /// @return weights is an array of uint, indicating committee members list weight
    /// @return certification is an array of bool, indicating the committee members certification status
	function getCommittee() external view returns (address[] memory addrs, uint256[] memory weights, bool[] memory certification);

    /// Returns the currently appointed committee data
    /// @return generalCommitteeSize is the number of members in the committee
    /// @return certifiedCommitteeSize is the number of certified members in the committee
    /// @return totalWeight is the total effective stake (weight) of the committee
	function getCommitteeStats() external view returns (uint generalCommitteeSize, uint certifiedCommitteeSize, uint totalWeight);

    /// Returns a committee member data
    /// @param addr is the committee member address
    /// @return inCommittee indicates whether the queried address is a member in the committee
    /// @return weight is the committee member weight
    /// @return isCertified indicates whether the committee member is certified
    /// @return totalCommitteeWeight is the total weight of the committee.
	function getMemberInfo(address addr) external view returns (bool inCommittee, uint weight, bool isCertified, uint totalCommitteeWeight);

    /// Emits a CommitteeSnapshot events with current committee info
    /// @dev a CommitteeSnapshot is useful on contract migration or to remove the need to track past events.
	function emitCommitteeSnapshot() external;

	/*
	 * Governance functions
	 */

	event MaxCommitteeSizeChanged(uint8 newValue, uint8 oldValue);

    /// Sets the maximum number of committee members
    /// @dev governance function called only by the functional manager
    /// @dev when reducing the number of members, the bottom ones are removed from the committee
    /// @param _maxCommitteeSize is the maximum number of committee members 
	function setMaxCommitteeSize(uint8 _maxCommitteeSize) external /* onlyFunctionalManager */;

    /// Returns the maximum number of committee members
    /// @return maxCommitteeSize is the maximum number of committee members 
	function getMaxCommitteeSize() external view returns (uint8);
	
    /// Imports the committee members from a previous committee contract during migration
    /// @dev initialization function called only by the initializationManager
    /// @dev does not update the reward contract to avoid incorrect notifications 
    /// @param previousCommitteeContract is the address of the previous committee contract
	function importMembers(ICommittee previousCommitteeContract) external /* onlyInitializationAdmin */;
}

// File: contracts/spec_interfaces/IProtocolWallet.sol

pragma solidity 0.6.12;


/// @title Protocol Wallet interface
interface IProtocolWallet {
    event FundsAddedToPool(uint256 added, uint256 total);

    /*
    * External functions
    */

    /// Returns the address of the underlying staked token
    /// @return balance is the wallet balance
    function getBalance() external view returns (uint256 balance);

    /// Transfers the given amount of orbs tokens form the sender to this contract and updates the pool
    /// @dev assumes the caller approved the amount prior to calling
    /// @param amount is the amount to add to the wallet
    function topUp(uint256 amount) external;

    /// Withdraws from pool to the client address, limited by the pool's MaxRate.
    /// @dev may only be called by the wallet client
    /// @dev no more than MaxRate x time period since the last withdraw may be withdrawn
    /// @dev allocation that wasn't withdrawn can not be withdrawn in the next call
    /// @param amount is the amount to withdraw
    function withdraw(uint256 amount) external; /* onlyClient */


    /*
    * Governance functions
    */

    event ClientSet(address client);
    event MaxAnnualRateSet(uint256 maxAnnualRate);
    event EmergencyWithdrawal(address addr, address token);
    event OutstandingTokensReset(uint256 startTime);

    /// Sets a new annual withdraw rate for the pool
    /// @dev governance function called only by the migration owner
    /// @dev the rate for a duration is duration x annualRate / 1 year 
    /// @param _annualRate is the maximum annual rate that can be withdrawn
    function setMaxAnnualRate(uint256 _annualRate) external; /* onlyMigrationOwner */

    /// Returns the annual withdraw rate of the pool
    /// @return annualRate is the maximum annual rate that can be withdrawn
    function getMaxAnnualRate() external view returns (uint256);

    /// Resets the outstanding tokens to new start time
    /// @dev governance function called only by the migration owner
    /// @dev the next duration will be calculated starting from the given time
    /// @param startTime is the time to set as the last withdrawal time
    function resetOutstandingTokens(uint256 startTime) external; /* onlyMigrationOwner */

    /// Emergency withdraw the wallet funds
    /// @dev governance function called only by the migration owner
    /// @dev used in emergencies, when a migration to a new wallet is needed
    /// @param erc20 is the erc20 address of the token to withdraw
    function emergencyWithdraw(address erc20) external; /* onlyMigrationOwner */

    /// Sets the address of the client that can withdraw funds
    /// @dev governance function called only by the functional owner
    /// @param _client is the address of the new client
    function setClient(address _client) external; /* onlyFunctionalOwner */

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

// File: contracts/IMigratableStakingContract.sol

pragma solidity 0.6.12;


/// @title An interface for staking contracts which support stake migration.
interface IMigratableStakingContract {
    /// @dev Returns the address of the underlying staked token.
    /// @return IERC20 The address of the token.
    function getToken() external view returns (IERC20);

    /// @dev Stakes ORBS tokens on behalf of msg.sender. This method assumes that the user has already approved at least
    /// the required amount using ERC20 approve.
    /// @param _stakeOwner address The specified stake owner.
    /// @param _amount uint256 The number of tokens to stake.
    function acceptMigration(address _stakeOwner, uint256 _amount) external;

    event AcceptedMigration(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
}

// File: contracts/IStakingContract.sol

pragma solidity 0.6.12;


/// @title An interface for staking contracts.
interface IStakingContract {
    /// @dev Stakes ORBS tokens on behalf of msg.sender. This method assumes that the user has already approved at least
    /// the required amount using ERC20 approve.
    /// @param _amount uint256 The amount of tokens to stake.
    function stake(uint256 _amount) external;

    /// @dev Unstakes ORBS tokens from msg.sender. If successful, this will start the cooldown period, after which
    /// msg.sender would be able to withdraw all of his tokens.
    /// @param _amount uint256 The amount of tokens to unstake.
    function unstake(uint256 _amount) external;

    /// @dev Requests to withdraw all of staked ORBS tokens back to msg.sender. Stake owners can withdraw their ORBS
    /// tokens only after previously unstaking them and after the cooldown period has passed (unless the contract was
    /// requested to release all stakes).
    function withdraw() external;

    /// @dev Restakes unstaked ORBS tokens (in or after cooldown) for msg.sender.
    function restake() external;

    /// @dev Distributes staking rewards to a list of addresses by directly adding rewards to their stakes. This method
    /// assumes that the user has already approved at least the required amount using ERC20 approve. Since this is a
    /// convenience method, we aren't concerned about reaching block gas limit by using large lists. We assume that
    /// callers will be able to properly batch/paginate their requests.
    /// @param _totalAmount uint256 The total amount of rewards to distribute.
    /// @param _stakeOwners address[] The addresses of the stake owners.
    /// @param _amounts uint256[] The amounts of the rewards.
    function distributeRewards(uint256 _totalAmount, address[] calldata _stakeOwners, uint256[] calldata _amounts) external;

    /// @dev Returns the stake of the specified stake owner (excluding unstaked tokens).
    /// @param _stakeOwner address The address to check.
    /// @return uint256 The total stake.
    function getStakeBalanceOf(address _stakeOwner) external view returns (uint256);

    /// @dev Returns the total amount staked tokens (excluding unstaked tokens).
    /// @return uint256 The total staked tokens of all stake owners.
    function getTotalStakedTokens() external view returns (uint256);

    /// @dev Returns the time that the cooldown period ends (or ended) and the amount of tokens to be released.
    /// @param _stakeOwner address The address to check.
    /// @return cooldownAmount uint256 The total tokens in cooldown.
    /// @return cooldownEndTime uint256 The time when the cooldown period ends (in seconds).
    function getUnstakeStatus(address _stakeOwner) external view returns (uint256 cooldownAmount,
        uint256 cooldownEndTime);

    /// @dev Migrates the stake of msg.sender from this staking contract to a new approved staking contract.
    /// @param _newStakingContract IMigratableStakingContract The new staking contract which supports stake migration.
    /// @param _amount uint256 The amount of tokens to migrate.
    function migrateStakedTokens(IMigratableStakingContract _newStakingContract, uint256 _amount) external;

    event Staked(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
    event Unstaked(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
    event Withdrew(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
    event Restaked(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
    event MigratedStake(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
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

// File: contracts/StakingRewards.sol

pragma solidity 0.6.12;











contract StakingRewards is IStakingRewards, ManagedContract {
    using SafeMath for uint256;
    using SafeMath96 for uint96;

    uint256 constant PERCENT_MILLIE_BASE = 100000;
    uint256 constant TOKEN_BASE = 1e18;

    struct Settings {
        uint96 annualCap;
        uint32 annualRateInPercentMille;
        uint32 defaultDelegatorsStakingRewardsPercentMille;
        uint32 maxDelegatorsStakingRewardsPercentMille;
        bool rewardAllocationActive;
    }
    Settings settings;

    IERC20 public token;

    struct StakingRewardsState {
        uint96 stakingRewardsPerWeight;
        uint96 unclaimedStakingRewards;
        uint32 lastAssigned;
    }
    StakingRewardsState public stakingRewardsState;

    uint256 public stakingRewardsContractBalance;

    struct GuardianStakingRewards {
        uint96 delegatorRewardsPerToken;
        uint96 lastStakingRewardsPerWeight;
        uint96 balance;
        uint96 claimed;
    }
    mapping(address => GuardianStakingRewards) public guardiansStakingRewards;

    struct GuardianRewardSettings {
        uint32 delegatorsStakingRewardsPercentMille;
        bool overrideDefault;
    }
    mapping(address => GuardianRewardSettings) public guardiansRewardSettings;

    struct DelegatorStakingRewards {
        uint96 balance;
        uint96 lastDelegatorRewardsPerToken;
        uint96 claimed;
    }
    mapping(address => DelegatorStakingRewards) public delegatorsStakingRewards;

    /// Constructor
    /// @dev the constructor does not migrate reward balances from the previous rewards contract
    /// @param _contractRegistry is the contract registry address
    /// @param _registryAdmin is the registry admin address
    /// @param _token is the token used for staking rewards
    /// @param annualRateInPercentMille is the annual rate in percent-mille
    /// @param annualCap is the annual staking rewards cap
    /// @param defaultDelegatorsStakingRewardsPercentMille is the default delegators portion in percent-mille(0 - maxDelegatorsStakingRewardsPercentMille)
    /// @param maxDelegatorsStakingRewardsPercentMille is the maximum delegators portion in percent-mille(0 - 100,000)
    /// @param previousRewardsContract is the previous rewards contract address used for migration of guardians settings. address(0) indicates no guardian settings to migrate
    /// @param guardiansToMigrate is a list of guardian addresses to migrate their rewards settings
    constructor(
        IContractRegistry _contractRegistry,
        address _registryAdmin,
        IERC20 _token,
        uint32 annualRateInPercentMille,
        uint96 annualCap,
        uint32 defaultDelegatorsStakingRewardsPercentMille,
        uint32 maxDelegatorsStakingRewardsPercentMille,
        IStakingRewards previousRewardsContract,
        address[] memory guardiansToMigrate
    ) ManagedContract(_contractRegistry, _registryAdmin) public {
        require(address(_token) != address(0), "token must not be 0");

        _setAnnualStakingRewardsRate(annualRateInPercentMille, annualCap);
        setMaxDelegatorsStakingRewardsPercentMille(maxDelegatorsStakingRewardsPercentMille);
        setDefaultDelegatorsStakingRewardsPercentMille(defaultDelegatorsStakingRewardsPercentMille);

        token = _token;

        if (address(previousRewardsContract) != address(0)) {
            migrateGuardiansSettings(previousRewardsContract, guardiansToMigrate);
        }
    }

    modifier onlyCommitteeContract() {
        require(msg.sender == address(committeeContract), "caller is not the elections contract");

        _;
    }

    modifier onlyDelegationsContract() {
        require(msg.sender == address(delegationsContract), "caller is not the delegations contract");

        _;
    }

    /*
    * External functions
    */

    /// Returns the current reward balance of the given address.
    /// @dev calculates the up to date balances (differ from the state)
    /// @param addr is the address to query
    /// @return delegatorStakingRewardsBalance the rewards awarded to the guardian role
    /// @return guardianStakingRewardsBalance the rewards awarded to the guardian role
    function getStakingRewardsBalance(address addr) external override view returns (uint256 delegatorStakingRewardsBalance, uint256 guardianStakingRewardsBalance) {
        (DelegatorStakingRewards memory delegatorStakingRewards,,) = getDelegatorStakingRewards(addr, block.timestamp);
        (GuardianStakingRewards memory guardianStakingRewards,,) = getGuardianStakingRewards(addr, block.timestamp);
        return (delegatorStakingRewards.balance, guardianStakingRewards.balance);
    }

    /// Claims the staking rewards balance of an addr, staking the rewards
    /// @dev Claimed rewards are staked in the staking contract using the distributeRewards interface
    /// @dev includes the rewards for both the delegator and guardian roles
    /// @dev calculates the up to date rewards prior to distribute them to the staking contract
    /// @param addr is the address to claim rewards for
    function claimStakingRewards(address addr) external override onlyWhenActive {
        (uint256 guardianRewards, uint256 delegatorRewards) = claimStakingRewardsLocally(addr);
        uint256 total = delegatorRewards.add(guardianRewards);
        if (total == 0) {
            return;
        }

        uint96 claimedGuardianRewards = guardiansStakingRewards[addr].claimed.add(guardianRewards);
        guardiansStakingRewards[addr].claimed = claimedGuardianRewards;
        uint96 claimedDelegatorRewards = delegatorsStakingRewards[addr].claimed.add(delegatorRewards);
        delegatorsStakingRewards[addr].claimed = claimedDelegatorRewards;

        require(token.approve(address(stakingContract), total), "claimStakingRewards: approve failed");

        address[] memory addrs = new address[](1);
        addrs[0] = addr;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = total;
        stakingContract.distributeRewards(total, addrs, amounts);

        emit StakingRewardsClaimed(addr, delegatorRewards, guardianRewards, claimedDelegatorRewards, claimedGuardianRewards);
    }

    /// Returns the current global staking rewards state
    /// @dev calculated to the latest block, may differ from the state read
    /// @return stakingRewardsPerWeight is the potential reward per 1E18 (TOKEN_BASE) committee weight assigned to a guardian was in the committee from day zero
    /// @return unclaimedStakingRewards is the of tokens that were assigned to participants and not claimed yet
    function getStakingRewardsState() public override view returns (
        uint96 stakingRewardsPerWeight,
        uint96 unclaimedStakingRewards
    ) {
        (, , uint totalCommitteeWeight) = committeeContract.getCommitteeStats();
        (StakingRewardsState memory _stakingRewardsState,) = _getStakingRewardsState(totalCommitteeWeight, block.timestamp, settings);
        stakingRewardsPerWeight = _stakingRewardsState.stakingRewardsPerWeight;
        unclaimedStakingRewards = _stakingRewardsState.unclaimedStakingRewards;
    }

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
    function getGuardianStakingRewardsData(address guardian) external override view returns (
        uint256 balance,
        uint256 claimed,
        uint256 delegatorRewardsPerToken,
        uint256 delegatorRewardsPerTokenDelta,
        uint256 lastStakingRewardsPerWeight,
        uint256 stakingRewardsPerWeightDelta
    ) {
        (GuardianStakingRewards memory rewards, uint256 _stakingRewardsPerWeightDelta, uint256 _delegatorRewardsPerTokenDelta) = getGuardianStakingRewards(guardian, block.timestamp);
        return (rewards.balance, rewards.claimed, rewards.delegatorRewardsPerToken, _delegatorRewardsPerTokenDelta, rewards.lastStakingRewardsPerWeight, _stakingRewardsPerWeightDelta);
    }

    /// Returns the current delegator staking rewards state
    /// @dev calculated to the latest block, may differ from the state read
    /// @param delegator is the delegator to query
    /// @return balance is the staking rewards balance for the delegator role
    /// @return claimed is the staking rewards for the delegator role that were claimed
    /// @return guardian is the guardian the delegator delegated to receiving a portion of the guardian staking rewards
    /// @return lastDelegatorRewardsPerToken is the up to date delegatorRewardsPerToken used for the delegator state calculation
    /// @return delegatorRewardsPerTokenDelta is the increment in delegatorRewardsPerToken since the last delegator update
    function getDelegatorStakingRewardsData(address delegator) external override view returns (
        uint256 balance,
        uint256 claimed,
        address guardian,
        uint256 lastDelegatorRewardsPerToken,
        uint256 delegatorRewardsPerTokenDelta
    ) {
        (DelegatorStakingRewards memory rewards, address _guardian, uint256 _delegatorRewardsPerTokenDelta) = getDelegatorStakingRewards(delegator, block.timestamp);
        return (rewards.balance, rewards.claimed, _guardian, rewards.lastDelegatorRewardsPerToken, _delegatorRewardsPerTokenDelta);
    }

    /// Returns an estimation for the delegator and guardian staking rewards for a given duration
    /// @dev the returned value is an estimation, assuming no change in the PoS state
    /// @dev the period calculated for start from the current block time until the current time + duration.
    /// @param addr is the address to estimate rewards for
    /// @param duration is the duration to calculate for in seconds
    /// @return estimatedDelegatorStakingRewards is the estimated reward for the delegator role
    /// @return estimatedGuardianStakingRewards is the estimated reward for the guardian role
    function estimateFutureRewards(address addr, uint256 duration) external override view returns (uint256 estimatedDelegatorStakingRewards, uint256 estimatedGuardianStakingRewards) {
        (GuardianStakingRewards memory guardianRewardsNow,,) = getGuardianStakingRewards(addr, block.timestamp);
        (DelegatorStakingRewards memory delegatorRewardsNow,,) = getDelegatorStakingRewards(addr, block.timestamp);
        (GuardianStakingRewards memory guardianRewardsFuture,,) = getGuardianStakingRewards(addr, block.timestamp.add(duration));
        (DelegatorStakingRewards memory delegatorRewardsFuture,,) = getDelegatorStakingRewards(addr, block.timestamp.add(duration));

        estimatedDelegatorStakingRewards = delegatorRewardsFuture.balance.sub(delegatorRewardsNow.balance);
        estimatedGuardianStakingRewards = guardianRewardsFuture.balance.sub(guardianRewardsNow.balance);
    }

    /// Sets the guardian's delegators staking reward portion
    /// @dev by default uses the defaultDelegatorsStakingRewardsPercentMille
    /// @param delegatorRewardsPercentMille is the delegators portion in percent-mille (0 - maxDelegatorsStakingRewardsPercentMille)
    function setGuardianDelegatorsStakingRewardsPercentMille(uint32 delegatorRewardsPercentMille) external override onlyWhenActive {
        require(delegatorRewardsPercentMille <= PERCENT_MILLIE_BASE, "delegatorRewardsPercentMille must be 100000 at most");
        require(delegatorRewardsPercentMille <= settings.maxDelegatorsStakingRewardsPercentMille, "delegatorRewardsPercentMille must not be larger than maxDelegatorsStakingRewardsPercentMille");
        updateDelegatorStakingRewards(msg.sender);
        _setGuardianDelegatorsStakingRewardsPercentMille(msg.sender, delegatorRewardsPercentMille);
    }

    /// Returns a guardian's delegators staking reward portion
    /// @dev If not explicitly set, returns the defaultDelegatorsStakingRewardsPercentMille
    /// @return delegatorRewardsRatioPercentMille is the delegators portion in percent-mille
    function getGuardianDelegatorsStakingRewardsPercentMille(address guardian) external override view returns (uint256 delegatorRewardsRatioPercentMille) {
        return _getGuardianDelegatorsStakingRewardsPercentMille(guardian, settings);
    }

    /// Returns the amount of ORBS tokens in the staking rewards wallet allocated to staking rewards
    /// @dev The staking wallet balance must always larger than the allocated value
    /// @return allocated is the amount of tokens allocated in the staking rewards wallet
    function getStakingRewardsWalletAllocatedTokens() external override view returns (uint256 allocated) {
        (, uint96 unclaimedStakingRewards) = getStakingRewardsState();
        return uint256(unclaimedStakingRewards).sub(stakingRewardsContractBalance);
    }

    /// Returns the current annual staking reward rate
    /// @dev calculated based on the current total committee weight
    /// @return annualRate is the current staking reward rate in percent-mille
    function getCurrentStakingRewardsRatePercentMille() external override view returns (uint256 annualRate) {
        (, , uint totalCommitteeWeight) = committeeContract.getCommitteeStats();
        annualRate = _getAnnualRewardPerWeight(totalCommitteeWeight, settings).mul(PERCENT_MILLIE_BASE).div(TOKEN_BASE);
    }

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
    function committeeMembershipWillChange(address guardian, uint256 weight, uint256 totalCommitteeWeight, bool inCommittee, bool inCommitteeAfter) external override onlyWhenActive onlyCommitteeContract {
        uint256 delegatedStake = delegationsContract.getDelegatedStake(guardian);

        Settings memory _settings = settings;
        StakingRewardsState memory _stakingRewardsState = _updateStakingRewardsState(totalCommitteeWeight, _settings);
        _updateGuardianStakingRewards(guardian, inCommittee, inCommitteeAfter, weight, delegatedStake, _stakingRewardsState, _settings);
    }

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
    function delegationWillChange(address guardian, uint256 guardianDelegatedStake, address delegator, uint256 delegatorStake, address nextGuardian, uint256 nextGuardianDelegatedStake) external override onlyWhenActive onlyDelegationsContract {
        Settings memory _settings = settings;
        (bool inCommittee, uint256 weight, , uint256 totalCommitteeWeight) = committeeContract.getMemberInfo(guardian);

        StakingRewardsState memory _stakingRewardsState = _updateStakingRewardsState(totalCommitteeWeight, _settings);
        GuardianStakingRewards memory guardianStakingRewards = _updateGuardianStakingRewards(guardian, inCommittee, inCommittee, weight, guardianDelegatedStake, _stakingRewardsState, _settings);
        _updateDelegatorStakingRewards(delegator, delegatorStake, guardian, guardianStakingRewards);

        if (nextGuardian != guardian) {
            (inCommittee, weight, , totalCommitteeWeight) = committeeContract.getMemberInfo(nextGuardian);
            GuardianStakingRewards memory nextGuardianStakingRewards = _updateGuardianStakingRewards(nextGuardian, inCommittee, inCommittee, weight, nextGuardianDelegatedStake, _stakingRewardsState, _settings);
            delegatorsStakingRewards[delegator].lastDelegatorRewardsPerToken = nextGuardianStakingRewards.delegatorRewardsPerToken;
        }
    }

    /*
    * Governance functions
    */

    /// Activates staking rewards allocation
    /// @dev governance function called only by the initialization admin
    /// @dev On migrations, startTime should be set to the previous contract deactivation time
    /// @param startTime sets the last assignment time
    function activateRewardDistribution(uint startTime) external override onlyMigrationManager {
        require(!settings.rewardAllocationActive, "reward distribution is already activated");

        stakingRewardsState.lastAssigned = uint32(startTime);
        settings.rewardAllocationActive = true;

        emit RewardDistributionActivated(startTime);
    }

    /// Deactivates fees and bootstrap allocation
    /// @dev governance function called only by the migration manager
    /// @dev guardians updates remain active based on the current perMember value
    function deactivateRewardDistribution() external override onlyMigrationManager {
        require(settings.rewardAllocationActive, "reward distribution is already deactivated");

        StakingRewardsState memory _stakingRewardsState = updateStakingRewardsState();

        settings.rewardAllocationActive = false;

        withdrawRewardsWalletAllocatedTokens(_stakingRewardsState);

        emit RewardDistributionDeactivated();
    }

    /// Sets the default delegators staking reward portion
    /// @dev governance function called only by the functional manager
    /// @param defaultDelegatorsStakingRewardsPercentMille is the default delegators portion in percent-mille(0 - maxDelegatorsStakingRewardsPercentMille)
    function setDefaultDelegatorsStakingRewardsPercentMille(uint32 defaultDelegatorsStakingRewardsPercentMille) public override onlyFunctionalManager {
        require(defaultDelegatorsStakingRewardsPercentMille <= PERCENT_MILLIE_BASE, "defaultDelegatorsStakingRewardsPercentMille must not be larger than 100000");
        require(defaultDelegatorsStakingRewardsPercentMille <= settings.maxDelegatorsStakingRewardsPercentMille, "defaultDelegatorsStakingRewardsPercentMille must not be larger than maxDelegatorsStakingRewardsPercentMille");
        settings.defaultDelegatorsStakingRewardsPercentMille = defaultDelegatorsStakingRewardsPercentMille;
        emit DefaultDelegatorsStakingRewardsChanged(defaultDelegatorsStakingRewardsPercentMille);
    }

    /// Returns the default delegators staking reward portion
    /// @return defaultDelegatorsStakingRewardsPercentMille is the default delegators portion in percent-mille
    function getDefaultDelegatorsStakingRewardsPercentMille() public override view returns (uint32) {
        return settings.defaultDelegatorsStakingRewardsPercentMille;
    }

    /// Sets the maximum delegators staking reward portion
    /// @dev governance function called only by the functional manager
    /// @param maxDelegatorsStakingRewardsPercentMille is the maximum delegators portion in percent-mille(0 - 100,000)
    function setMaxDelegatorsStakingRewardsPercentMille(uint32 maxDelegatorsStakingRewardsPercentMille) public override onlyFunctionalManager {
        require(maxDelegatorsStakingRewardsPercentMille <= PERCENT_MILLIE_BASE, "maxDelegatorsStakingRewardsPercentMille must not be larger than 100000");
        settings.maxDelegatorsStakingRewardsPercentMille = maxDelegatorsStakingRewardsPercentMille;
        emit MaxDelegatorsStakingRewardsChanged(maxDelegatorsStakingRewardsPercentMille);
    }

    /// Returns the default delegators staking reward portion
    /// @return maxDelegatorsStakingRewardsPercentMille is the maximum delegators portion in percent-mille
    function getMaxDelegatorsStakingRewardsPercentMille() public override view returns (uint32) {
        return settings.maxDelegatorsStakingRewardsPercentMille;
    }

    /// Sets the annual rate and cap for the staking reward
    /// @dev governance function called only by the functional manager
    /// @param annualRateInPercentMille is the annual rate in percent-mille
    /// @param annualCap is the annual staking rewards cap
    function setAnnualStakingRewardsRate(uint32 annualRateInPercentMille, uint96 annualCap) external override onlyFunctionalManager {
        updateStakingRewardsState();
        return _setAnnualStakingRewardsRate(annualRateInPercentMille, annualCap);
    }

    /// Returns the annual staking reward rate
    /// @return annualStakingRewardsRatePercentMille is the annual rate in percent-mille
    function getAnnualStakingRewardsRatePercentMille() external override view returns (uint32) {
        return settings.annualRateInPercentMille;
    }

    /// Returns the annual staking rewards cap
    /// @return annualStakingRewardsCap is the annual rate in percent-mille
    function getAnnualStakingRewardsCap() external override view returns (uint256) {
        return settings.annualCap;
    }

    /// Checks if rewards allocation is active
    /// @return rewardAllocationActive is a bool that indicates that rewards allocation is active
    function isRewardAllocationActive() external override view returns (bool) {
        return settings.rewardAllocationActive;
    }

    /// Returns the contract's settings
    /// @return annualStakingRewardsCap is the annual rate in percent-mille
    /// @return annualStakingRewardsRatePercentMille is the annual rate in percent-mille
    /// @return defaultDelegatorsStakingRewardsPercentMille is the default delegators portion in percent-mille
    /// @return maxDelegatorsStakingRewardsPercentMille is the maximum delegators portion in percent-mille
    /// @return rewardAllocationActive is a bool that indicates that rewards allocation is active
    function getSettings() external override view returns (
        uint annualStakingRewardsCap,
        uint32 annualStakingRewardsRatePercentMille,
        uint32 defaultDelegatorsStakingRewardsPercentMille,
        uint32 maxDelegatorsStakingRewardsPercentMille,
        bool rewardAllocationActive
    ) {
        Settings memory _settings = settings;
        annualStakingRewardsCap = _settings.annualCap;
        annualStakingRewardsRatePercentMille = _settings.annualRateInPercentMille;
        defaultDelegatorsStakingRewardsPercentMille = _settings.defaultDelegatorsStakingRewardsPercentMille;
        maxDelegatorsStakingRewardsPercentMille = _settings.maxDelegatorsStakingRewardsPercentMille;
        rewardAllocationActive = _settings.rewardAllocationActive;
    }

    /// Migrates the staking rewards balance of the given addresses to a new staking rewards contract
    /// @dev The new rewards contract is determined according to the contracts registry
    /// @dev No impact of the calling contract if the currently configured contract in the registry
    /// @dev may be called also while the contract is locked
    /// @param addrs is the list of addresses to migrate
    function migrateRewardsBalance(address[] calldata addrs) external override {
        require(!settings.rewardAllocationActive, "Reward distribution must be deactivated for migration");

        IStakingRewards currentRewardsContract = IStakingRewards(getStakingRewardsContract());
        require(address(currentRewardsContract) != address(this), "New rewards contract is not set");

        uint256 totalAmount = 0;
        uint256[] memory guardianRewards = new uint256[](addrs.length);
        uint256[] memory delegatorRewards = new uint256[](addrs.length);
        for (uint i = 0; i < addrs.length; i++) {
            (guardianRewards[i], delegatorRewards[i]) = claimStakingRewardsLocally(addrs[i]);
            totalAmount = totalAmount.add(guardianRewards[i]).add(delegatorRewards[i]);
        }

        require(token.approve(address(currentRewardsContract), totalAmount), "migrateRewardsBalance: approve failed");
        currentRewardsContract.acceptRewardsBalanceMigration(addrs, guardianRewards, delegatorRewards, totalAmount);

        for (uint i = 0; i < addrs.length; i++) {
            emit StakingRewardsBalanceMigrated(addrs[i], guardianRewards[i], delegatorRewards[i], address(currentRewardsContract));
        }
    }

    /// Accepts addresses balance migration from a previous rewards contract
    /// @dev the function may be called by any caller that approves the amounts provided for transfer
    /// @param addrs is the list migrated addresses
    /// @param migratedGuardianStakingRewards is the list of received guardian rewards balance for each address
    /// @param migratedDelegatorStakingRewards is the list of received delegator rewards balance for each address
    /// @param totalAmount is the total amount of staking rewards migrated for all addresses in the list. Must match the sum of migratedGuardianStakingRewards and migratedDelegatorStakingRewards lists.
    function acceptRewardsBalanceMigration(address[] calldata addrs, uint256[] calldata migratedGuardianStakingRewards, uint256[] calldata migratedDelegatorStakingRewards, uint256 totalAmount) external override {
        uint256 _totalAmount = 0;

        for (uint i = 0; i < addrs.length; i++) {
            _totalAmount = _totalAmount.add(migratedGuardianStakingRewards[i]).add(migratedDelegatorStakingRewards[i]);
        }

        require(totalAmount == _totalAmount, "totalAmount does not match sum of rewards");

        if (totalAmount > 0) {
            require(token.transferFrom(msg.sender, address(this), totalAmount), "acceptRewardBalanceMigration: transfer failed");
        }

        for (uint i = 0; i < addrs.length; i++) {
            guardiansStakingRewards[addrs[i]].balance = guardiansStakingRewards[addrs[i]].balance.add(migratedGuardianStakingRewards[i]);
            delegatorsStakingRewards[addrs[i]].balance = delegatorsStakingRewards[addrs[i]].balance.add(migratedDelegatorStakingRewards[i]);
            emit StakingRewardsBalanceMigrationAccepted(msg.sender, addrs[i], migratedGuardianStakingRewards[i], migratedDelegatorStakingRewards[i]);
        }

        stakingRewardsContractBalance = stakingRewardsContractBalance.add(totalAmount);
        stakingRewardsState.unclaimedStakingRewards = stakingRewardsState.unclaimedStakingRewards.add(totalAmount);
    }

    /// Performs emergency withdrawal of the contract balance
    /// @dev called with a token to withdraw, should be called twice with the fees and bootstrap tokens
    /// @dev governance function called only by the migration manager
    /// @param erc20 is the ERC20 token to withdraw
    function emergencyWithdraw(address erc20) external override onlyMigrationManager {
        IERC20 _token = IERC20(erc20);
        emit EmergencyWithdrawal(msg.sender, address(_token));
        require(_token.transfer(msg.sender, _token.balanceOf(address(this))), "StakingRewards::emergencyWithdraw - transfer failed");
    }

    /*
    * Private functions
    */

    // Global state

    /// Returns the annual reward per weight
    /// @dev calculates the current annual rewards per weight based on the annual rate and annual cap
    function _getAnnualRewardPerWeight(uint256 totalCommitteeWeight, Settings memory _settings) private pure returns (uint256) {
        return totalCommitteeWeight == 0 ? 0 : Math.min(uint256(_settings.annualRateInPercentMille).mul(TOKEN_BASE).div(PERCENT_MILLIE_BASE), uint256(_settings.annualCap).mul(TOKEN_BASE).div(totalCommitteeWeight));
    }

    /// Calculates the added rewards per weight for the given duration based on the committee data
    /// @param totalCommitteeWeight is the current committee total weight
    /// @param duration is the duration to calculate for in seconds
    /// @param _settings is the contract settings
    function calcStakingRewardPerWeightDelta(uint256 totalCommitteeWeight, uint duration, Settings memory _settings) private pure returns (uint256 stakingRewardsPerWeightDelta) {
        stakingRewardsPerWeightDelta = 0;

        if (totalCommitteeWeight > 0) {
            uint annualRewardPerWeight = _getAnnualRewardPerWeight(totalCommitteeWeight, _settings);
            stakingRewardsPerWeightDelta = annualRewardPerWeight.mul(duration).div(365 days);
        }
    }

    /// Returns the up global staking rewards state for a specific time
    /// @dev receives the relevant committee data
    /// @dev for future time calculations assumes no change in the committee data
    /// @param totalCommitteeWeight is the current committee total weight
    /// @param currentTime is the time to calculate the rewards for
    /// @param _settings is the contract settings
    function _getStakingRewardsState(uint256 totalCommitteeWeight, uint256 currentTime, Settings memory _settings) private view returns (StakingRewardsState memory _stakingRewardsState, uint256 allocatedRewards) {
        _stakingRewardsState = stakingRewardsState;
        if (_settings.rewardAllocationActive) {
            uint delta = calcStakingRewardPerWeightDelta(totalCommitteeWeight, currentTime.sub(stakingRewardsState.lastAssigned), _settings);
            _stakingRewardsState.stakingRewardsPerWeight = stakingRewardsState.stakingRewardsPerWeight.add(delta);
            _stakingRewardsState.lastAssigned = uint32(currentTime);
            allocatedRewards = delta.mul(totalCommitteeWeight).div(TOKEN_BASE);
            _stakingRewardsState.unclaimedStakingRewards = _stakingRewardsState.unclaimedStakingRewards.add(allocatedRewards);
        }
    }

    /// Updates the global staking rewards
    /// @dev calculated to the latest block, may differ from the state read
    /// @dev uses the _getStakingRewardsState function
    /// @param totalCommitteeWeight is the current committee total weight
    /// @param _settings is the contract settings
    /// @return _stakingRewardsState is the updated global staking rewards struct
    function _updateStakingRewardsState(uint256 totalCommitteeWeight, Settings memory _settings) private returns (StakingRewardsState memory _stakingRewardsState) {
        if (!_settings.rewardAllocationActive) {
            return stakingRewardsState;
        }

        uint allocatedRewards;
        (_stakingRewardsState, allocatedRewards) = _getStakingRewardsState(totalCommitteeWeight, block.timestamp, _settings);
        stakingRewardsState = _stakingRewardsState;
        emit StakingRewardsAllocated(allocatedRewards, _stakingRewardsState.stakingRewardsPerWeight);
    }

    /// Updates the global staking rewards
    /// @dev calculated to the latest block, may differ from the state read
    /// @dev queries the committee state from the committee contract
    /// @dev uses the _updateStakingRewardsState function
    /// @return _stakingRewardsState is the updated global staking rewards struct
    function updateStakingRewardsState() private returns (StakingRewardsState memory _stakingRewardsState) {
        (, , uint totalCommitteeWeight) = committeeContract.getCommitteeStats();
        return _updateStakingRewardsState(totalCommitteeWeight, settings);
    }

    // Guardian state

    /// Returns the current guardian staking rewards state
    /// @dev receives the relevant committee and guardian data along with the global updated global state
    /// @dev calculated to the latest block, may differ from the state read
    /// @param guardian is the guardian to query
    /// @param inCommittee indicates whether the guardian is currently in the committee
    /// @param inCommitteeAfter indicates whether after a potential change the guardian is in the committee
    /// @param guardianWeight is the guardian committee weight
    /// @param guardianDelegatedStake is the guardian delegated stake
    /// @param _stakingRewardsState is the updated global staking rewards state
    /// @param _settings is the contract settings
    /// @return guardianStakingRewards is the updated guardian staking rewards state
    /// @return rewardsAdded is the amount awarded to the guardian since the last update
    /// @return stakingRewardsPerWeightDelta is the delta added to the stakingRewardsPerWeight since the last update
    /// @return delegatorRewardsPerTokenDelta is the delta added to the guardian's delegatorRewardsPerToken since the last update
    function _getGuardianStakingRewards(address guardian, bool inCommittee, bool inCommitteeAfter, uint256 guardianWeight, uint256 guardianDelegatedStake, StakingRewardsState memory _stakingRewardsState, Settings memory _settings) private view returns (GuardianStakingRewards memory guardianStakingRewards, uint256 rewardsAdded, uint256 stakingRewardsPerWeightDelta, uint256 delegatorRewardsPerTokenDelta) {
        guardianStakingRewards = guardiansStakingRewards[guardian];

        if (inCommittee) {
            stakingRewardsPerWeightDelta = uint256(_stakingRewardsState.stakingRewardsPerWeight).sub(guardianStakingRewards.lastStakingRewardsPerWeight);
            uint256 totalRewards = stakingRewardsPerWeightDelta.mul(guardianWeight);

            uint256 delegatorRewardsRatioPercentMille = _getGuardianDelegatorsStakingRewardsPercentMille(guardian, _settings);

            delegatorRewardsPerTokenDelta = guardianDelegatedStake == 0 ? 0 : totalRewards
            .div(guardianDelegatedStake)
            .mul(delegatorRewardsRatioPercentMille)
            .div(PERCENT_MILLIE_BASE);

            uint256 guardianCutPercentMille = PERCENT_MILLIE_BASE.sub(delegatorRewardsRatioPercentMille);

            rewardsAdded = totalRewards
            .mul(guardianCutPercentMille)
            .div(PERCENT_MILLIE_BASE)
            .div(TOKEN_BASE);

            guardianStakingRewards.delegatorRewardsPerToken = guardianStakingRewards.delegatorRewardsPerToken.add(delegatorRewardsPerTokenDelta);
            guardianStakingRewards.balance = guardianStakingRewards.balance.add(rewardsAdded);
        }

        guardianStakingRewards.lastStakingRewardsPerWeight = inCommitteeAfter ? _stakingRewardsState.stakingRewardsPerWeight : 0;
    }

    /// Returns the guardian staking rewards state for a given time
    /// @dev if the time to estimate is in the future, estimates the rewards for the given time
    /// @dev for future time estimation assumes no change in the committee and the guardian state
    /// @param guardian is the guardian to query
    /// @param currentTime is the time to calculate the rewards for
    /// @return guardianStakingRewards is the guardian staking rewards state updated to the give time
    /// @return stakingRewardsPerWeightDelta is the delta added to the stakingRewardsPerWeight since the last update
    /// @return delegatorRewardsPerTokenDelta is the delta added to the guardian's delegatorRewardsPerToken since the last update
    function getGuardianStakingRewards(address guardian, uint256 currentTime) private view returns (GuardianStakingRewards memory guardianStakingRewards, uint256 stakingRewardsPerWeightDelta, uint256 delegatorRewardsPerTokenDelta) {
        Settings memory _settings = settings;

        (bool inCommittee, uint256 guardianWeight, ,uint256 totalCommitteeWeight) = committeeContract.getMemberInfo(guardian);
        uint256 guardianDelegatedStake = delegationsContract.getDelegatedStake(guardian);

        (StakingRewardsState memory _stakingRewardsState,) = _getStakingRewardsState(totalCommitteeWeight, currentTime, _settings);
        (guardianStakingRewards,,stakingRewardsPerWeightDelta,delegatorRewardsPerTokenDelta) = _getGuardianStakingRewards(guardian, inCommittee, inCommittee, guardianWeight, guardianDelegatedStake, _stakingRewardsState, _settings);
    }

    /// Updates a guardian staking rewards state
    /// @dev receives the relevant committee and guardian data along with the global updated global state
    /// @dev updates the global staking rewards state prior to calculating the guardian's
    /// @dev uses _getGuardianStakingRewards
    /// @param guardian is the guardian to update
    /// @param inCommittee indicates whether the guardian was in the committee prior to the change
    /// @param inCommitteeAfter indicates whether the guardian is in the committee after the change
    /// @param guardianWeight is the committee weight of the guardian prior to the change
    /// @param guardianDelegatedStake is the delegated stake of the guardian prior to the change
    /// @param _stakingRewardsState is the updated global staking rewards state
    /// @param _settings is the contract settings
    /// @return guardianStakingRewards is the updated guardian staking rewards state
    function _updateGuardianStakingRewards(address guardian, bool inCommittee, bool inCommitteeAfter, uint256 guardianWeight, uint256 guardianDelegatedStake, StakingRewardsState memory _stakingRewardsState, Settings memory _settings) private returns (GuardianStakingRewards memory guardianStakingRewards) {
        uint256 guardianStakingRewardsAdded;
        uint256 stakingRewardsPerWeightDelta;
        uint256 delegatorRewardsPerTokenDelta;
        (guardianStakingRewards, guardianStakingRewardsAdded, stakingRewardsPerWeightDelta, delegatorRewardsPerTokenDelta) = _getGuardianStakingRewards(guardian, inCommittee, inCommitteeAfter, guardianWeight, guardianDelegatedStake, _stakingRewardsState, _settings);
        guardiansStakingRewards[guardian] = guardianStakingRewards;
        emit GuardianStakingRewardsAssigned(guardian, guardianStakingRewardsAdded, guardianStakingRewards.claimed.add(guardianStakingRewards.balance), guardianStakingRewards.delegatorRewardsPerToken, delegatorRewardsPerTokenDelta, _stakingRewardsState.stakingRewardsPerWeight, stakingRewardsPerWeightDelta);
    }

    /// Updates a guardian staking rewards state
    /// @dev queries the relevant guardian and committee data from the committee contract
    /// @dev uses _updateGuardianStakingRewards
    /// @param guardian is the guardian to update
    /// @param _stakingRewardsState is the updated global staking rewards state
    /// @param _settings is the contract settings
    /// @return guardianStakingRewards is the updated guardian staking rewards state
    function updateGuardianStakingRewards(address guardian, StakingRewardsState memory _stakingRewardsState, Settings memory _settings) private returns (GuardianStakingRewards memory guardianStakingRewards) {
        (bool inCommittee, uint256 guardianWeight,,) = committeeContract.getMemberInfo(guardian);
        return _updateGuardianStakingRewards(guardian, inCommittee, inCommittee, guardianWeight, delegationsContract.getDelegatedStake(guardian), _stakingRewardsState, _settings);
    }

    // Delegator state

    /// Returns the current delegator staking rewards state
    /// @dev receives the relevant delegator data along with the delegator's current guardian updated global state
    /// @dev calculated to the latest block, may differ from the state read
    /// @param delegator is the delegator to query
    /// @param delegatorStake is the stake of the delegator
    /// @param guardianStakingRewards is the updated guardian staking rewards state
    /// @return delegatorStakingRewards is the updated delegator staking rewards state
    /// @return delegatorRewardsAdded is the amount awarded to the delegator since the last update
    /// @return delegatorRewardsPerTokenDelta is the delta added to the delegator's delegatorRewardsPerToken since the last update
    function _getDelegatorStakingRewards(address delegator, uint256 delegatorStake, GuardianStakingRewards memory guardianStakingRewards) private view returns (DelegatorStakingRewards memory delegatorStakingRewards, uint256 delegatorRewardsAdded, uint256 delegatorRewardsPerTokenDelta) {
        delegatorStakingRewards = delegatorsStakingRewards[delegator];

        delegatorRewardsPerTokenDelta = uint256(guardianStakingRewards.delegatorRewardsPerToken)
        .sub(delegatorStakingRewards.lastDelegatorRewardsPerToken);
        delegatorRewardsAdded = delegatorRewardsPerTokenDelta
        .mul(delegatorStake)
        .div(TOKEN_BASE);

        delegatorStakingRewards.balance = delegatorStakingRewards.balance.add(delegatorRewardsAdded);
        delegatorStakingRewards.lastDelegatorRewardsPerToken = guardianStakingRewards.delegatorRewardsPerToken;
    }

    /// Returns the delegator staking rewards state for a given time
    /// @dev if the time to estimate is in the future, estimates the rewards for the given time
    /// @dev for future time estimation assumes no change in the committee, delegation and the delegator state
    /// @param delegator is the delegator to query
    /// @param currentTime is the time to calculate the rewards for
    /// @return delegatorStakingRewards is the updated delegator staking rewards state
    /// @return guardian is the guardian the delegator delegated to
    /// @return delegatorStakingRewardsPerTokenDelta is the delta added to the delegator's delegatorRewardsPerToken since the last update
    function getDelegatorStakingRewards(address delegator, uint256 currentTime) private view returns (DelegatorStakingRewards memory delegatorStakingRewards, address guardian, uint256 delegatorStakingRewardsPerTokenDelta) {
        uint256 delegatorStake;
        (guardian, delegatorStake) = delegationsContract.getDelegationInfo(delegator);
        (GuardianStakingRewards memory guardianStakingRewards,,) = getGuardianStakingRewards(guardian, currentTime);

        (delegatorStakingRewards,,delegatorStakingRewardsPerTokenDelta) = _getDelegatorStakingRewards(delegator, delegatorStake, guardianStakingRewards);
    }

    /// Updates a delegator staking rewards state
    /// @dev receives the relevant delegator data along with the delegator's current guardian updated global state
    /// @dev updates the guardian staking rewards state prior to calculating the delegator's
    /// @dev uses _getDelegatorStakingRewards
    /// @param delegator is the delegator to update
    /// @param delegatorStake is the stake of the delegator
    /// @param guardianStakingRewards is the updated guardian staking rewards state
    function _updateDelegatorStakingRewards(address delegator, uint256 delegatorStake, address guardian, GuardianStakingRewards memory guardianStakingRewards) private {
        uint256 delegatorStakingRewardsAdded;
        uint256 delegatorRewardsPerTokenDelta;
        DelegatorStakingRewards memory delegatorStakingRewards;
        (delegatorStakingRewards, delegatorStakingRewardsAdded, delegatorRewardsPerTokenDelta) = _getDelegatorStakingRewards(delegator, delegatorStake, guardianStakingRewards);
        delegatorsStakingRewards[delegator] = delegatorStakingRewards;

        emit DelegatorStakingRewardsAssigned(delegator, delegatorStakingRewardsAdded, delegatorStakingRewards.claimed.add(delegatorStakingRewards.balance), guardian, guardianStakingRewards.delegatorRewardsPerToken, delegatorRewardsPerTokenDelta);
    }

    /// Updates a delegator staking rewards state
    /// @dev queries the relevant delegator and committee data from the committee contract and delegation contract
    /// @dev uses _updateDelegatorStakingRewards
    /// @param delegator is the delegator to update
    function updateDelegatorStakingRewards(address delegator) private {
        Settings memory _settings = settings;

        (, , uint totalCommitteeWeight) = committeeContract.getCommitteeStats();
        StakingRewardsState memory _stakingRewardsState = _updateStakingRewardsState(totalCommitteeWeight, _settings);

        (address guardian, uint delegatorStake) = delegationsContract.getDelegationInfo(delegator);
        GuardianStakingRewards memory guardianRewards = updateGuardianStakingRewards(guardian, _stakingRewardsState, _settings);

        _updateDelegatorStakingRewards(delegator, delegatorStake, guardian, guardianRewards);
    }

    // Guardian settings

    /// Returns the guardian's delegator portion in percent-mille
    /// @dev if no explicit value was set by the guardian returns the default value
    /// @dev enforces the maximum delegators staking rewards cut
    function _getGuardianDelegatorsStakingRewardsPercentMille(address guardian, Settings memory _settings) private view returns (uint256 delegatorRewardsRatioPercentMille) {
        GuardianRewardSettings memory guardianSettings = guardiansRewardSettings[guardian];
        delegatorRewardsRatioPercentMille =  guardianSettings.overrideDefault ? guardianSettings.delegatorsStakingRewardsPercentMille : _settings.defaultDelegatorsStakingRewardsPercentMille;
        return Math.min(delegatorRewardsRatioPercentMille, _settings.maxDelegatorsStakingRewardsPercentMille);
    }

    /// Migrates a list of guardians' delegators portion setting from a previous staking rewards contract
    /// @dev called by the constructor
    function migrateGuardiansSettings(IStakingRewards previousRewardsContract, address[] memory guardiansToMigrate) private {
        for (uint i = 0; i < guardiansToMigrate.length; i++) {
            _setGuardianDelegatorsStakingRewardsPercentMille(guardiansToMigrate[i], uint32(previousRewardsContract.getGuardianDelegatorsStakingRewardsPercentMille(guardiansToMigrate[i])));
        }
    }

    // Governance and misc.

    /// Sets the annual rate and cap for the staking reward
    /// @param annualRateInPercentMille is the annual rate in percent-mille
    /// @param annualCap is the annual staking rewards cap
    function _setAnnualStakingRewardsRate(uint32 annualRateInPercentMille, uint96 annualCap) private {
        Settings memory _settings = settings;
        _settings.annualRateInPercentMille = annualRateInPercentMille;
        _settings.annualCap = annualCap;
        settings = _settings;

        emit AnnualStakingRewardsRateChanged(annualRateInPercentMille, annualCap);
    }

    /// Sets the guardian's delegators staking reward portion
    /// @param guardian is the guardian to set
    /// @param delegatorRewardsPercentMille is the delegators portion in percent-mille (0 - maxDelegatorsStakingRewardsPercentMille)
    function _setGuardianDelegatorsStakingRewardsPercentMille(address guardian, uint32 delegatorRewardsPercentMille) private {
        guardiansRewardSettings[guardian] = GuardianRewardSettings({
            overrideDefault: true,
            delegatorsStakingRewardsPercentMille: delegatorRewardsPercentMille
            });

        emit GuardianDelegatorsStakingRewardsPercentMilleUpdated(guardian, delegatorRewardsPercentMille);
    }

    /// Claims an addr staking rewards and update its rewards state without transferring the rewards
    /// @dev used by claimStakingRewards and migrateRewardsBalance
    /// @param addr is the address to claim rewards for
    /// @return guardianRewards is the claimed guardian rewards balance
    /// @return delegatorRewards is the claimed delegator rewards balance
    function claimStakingRewardsLocally(address addr) private returns (uint256 guardianRewards, uint256 delegatorRewards) {
        updateDelegatorStakingRewards(addr);

        guardianRewards = guardiansStakingRewards[addr].balance;
        guardiansStakingRewards[addr].balance = 0;

        delegatorRewards = delegatorsStakingRewards[addr].balance;
        delegatorsStakingRewards[addr].balance = 0;

        uint256 total = delegatorRewards.add(guardianRewards);

        StakingRewardsState memory _stakingRewardsState = stakingRewardsState;

        uint256 _stakingRewardsContractBalance = stakingRewardsContractBalance;
        if (total > _stakingRewardsContractBalance) {
            _stakingRewardsContractBalance = withdrawRewardsWalletAllocatedTokens(_stakingRewardsState);
        }

        stakingRewardsContractBalance = _stakingRewardsContractBalance.sub(total);
        stakingRewardsState.unclaimedStakingRewards = _stakingRewardsState.unclaimedStakingRewards.sub(total);
    }

    /// Withdraws the tokens that were allocated to the contract from the staking rewards wallet
    /// @dev used as part of the migration flow to withdraw all the funds allocated for participants before updating the wallet client to a new contract
    /// @param _stakingRewardsState is the updated global staking rewards state
    function withdrawRewardsWalletAllocatedTokens(StakingRewardsState memory _stakingRewardsState) private returns (uint256 _stakingRewardsContractBalance){
        _stakingRewardsContractBalance = stakingRewardsContractBalance;
        uint256 allocated = _stakingRewardsState.unclaimedStakingRewards.sub(_stakingRewardsContractBalance);
        stakingRewardsWallet.withdraw(allocated);
        _stakingRewardsContractBalance = _stakingRewardsContractBalance.add(allocated);
        stakingRewardsContractBalance = _stakingRewardsContractBalance;
    }

    /*
     * Contracts topology / registry interface
     */

    ICommittee committeeContract;
    IDelegations delegationsContract;
    IProtocolWallet stakingRewardsWallet;
    IStakingContract stakingContract;

    /// Refreshes the address of the other contracts the contract interacts with
    /// @dev called by the registry contract upon an update of a contract in the registry
    function refreshContracts() external override {
        committeeContract = ICommittee(getCommitteeContract());
        delegationsContract = IDelegations(getDelegationsContract());
        stakingRewardsWallet = IProtocolWallet(getStakingRewardsWallet());
        stakingContract = IStakingContract(getStakingContract());
    }
}