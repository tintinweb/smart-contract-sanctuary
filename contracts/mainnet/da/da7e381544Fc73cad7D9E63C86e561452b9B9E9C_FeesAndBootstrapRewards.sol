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

// File: contracts/spec_interfaces/IMigratableFeesWallet.sol

pragma solidity 0.6.12;

/// @title An interface for Fee wallets that support bucket migration.
interface IMigratableFeesWallet {

    /// Accepts a bucket fees from a old fees wallet as part of a migration
    /// @dev Called by the old FeesWallet contract.
    /// @dev Part of the IMigratableFeesWallet interface.
    /// @dev assumes the caller approved the transfer of the amount prior to calling
    /// @param bucketStartTime is the start time of the bucket to migration, must be a bucket's valid start time
    /// @param amount is the amount to migrate (transfer) to the bucket
    function acceptBucketMigration(uint256 bucketStartTime, uint256 amount) external;
}

// File: contracts/spec_interfaces/IFeesWallet.sol

pragma solidity 0.6.12;


/// @title Fees Wallet contract interface, manages the fee buckets
interface IFeesWallet {

    event FeesWithdrawnFromBucket(uint256 bucketId, uint256 withdrawn, uint256 total);
    event FeesAddedToBucket(uint256 bucketId, uint256 added, uint256 total);

    /*
     *   External methods
     */

    /// Top-ups the fee pool with the given amount at the given rate
    /// @dev Called by: subscriptions contract. (not enforced)
    /// @dev fills the rewards in 30 days buckets based on the monthlyRate
    /// @param amount is the amount to fill
    /// @param monthlyRate is the monthly rate
    /// @param fromTimestamp is the to start fill the buckets, determines the first bucket to fill and the amount filled in the first bucket.
    function fillFeeBuckets(uint256 amount, uint256 monthlyRate, uint256 fromTimestamp) external;

    /// Collect fees from the buckets since the last call and transfers the amount back.
    /// @dev Called by: only FeesAndBootstrapRewards contract
    /// @dev The amount to collect may be queried before collect by calling getOutstandingFees
    /// @return collectedFees the amount of fees collected and transferred
    function collectFees() external returns (uint256 collectedFees) /* onlyRewardsContract */;

    /// Returns the amount of fees that are currently available for withdrawal
    /// @param currentTime is the time to check the pending fees for
    /// @return outstandingFees is the amount of pending fees to collect at time currentTime
    function getOutstandingFees(uint256 currentTime) external view returns (uint256 outstandingFees);

    /*
     * General governance
     */

    event EmergencyWithdrawal(address addr, address token);

    /// Migrates the fees of a bucket starting at startTimestamp.
    /// @dev governance function called only by the migration manager
    /// @dev Calls acceptBucketMigration in the destination contract.
    /// @param destination is the address of the new FeesWallet contract
    /// @param bucketStartTime is the start time of the bucket to migration, must be a bucket's valid start time
    function migrateBucket(IMigratableFeesWallet destination, uint256 bucketStartTime) external /* onlyMigrationManager */;

    /// Accepts a fees bucket balance from a old fees wallet as part of the fees wallet migration
    /// @dev Called by the old FeesWallet contract.
    /// @dev Part of the IMigratableFeesWallet interface.
    /// @dev assumes the caller approved the amount prior to calling
    /// @param bucketStartTime is the start time of the bucket to migration, must be a bucket's valid start time
    /// @param amount is the amount to migrate (transfer) to the bucket
    function acceptBucketMigration(uint256 bucketStartTime, uint256 amount) external;

    /// Emergency withdraw the contract funds
    /// @dev governance function called only by the migration manager
    /// @dev used in emergencies only, where migrateBucket is not a suitable solution
    /// @param erc20 is the erc20 address of the token to withdraw
    function emergencyWithdraw(address erc20) external /* onlyMigrationManager */;

}

// File: contracts/spec_interfaces/IFeesAndBootstrapRewards.sol

pragma solidity 0.6.12;

/// @title Rewards contract interface
interface IFeesAndBootstrapRewards {
    event FeesAllocated(uint256 allocatedGeneralFees, uint256 generalFeesPerMember, uint256 allocatedCertifiedFees, uint256 certifiedFeesPerMember);
    event FeesAssigned(address indexed guardian, uint256 amount, uint256 totalAwarded, bool certification, uint256 feesPerMember);
    event FeesWithdrawn(address indexed guardian, uint256 amount, uint256 totalWithdrawn);
    event BootstrapRewardsAllocated(uint256 allocatedGeneralBootstrapRewards, uint256 generalBootstrapRewardsPerMember, uint256 allocatedCertifiedBootstrapRewards, uint256 certifiedBootstrapRewardsPerMember);
    event BootstrapRewardsAssigned(address indexed guardian, uint256 amount, uint256 totalAwarded, bool certification, uint256 bootstrapPerMember);
    event BootstrapRewardsWithdrawn(address indexed guardian, uint256 amount, uint256 totalWithdrawn);

    /*
    * External functions
    */

    /// Triggers update of the guardian rewards
    /// @dev Called by: the Committee contract
    /// @dev called upon expected change in the committee membership of the guardian
    /// @param guardian is the guardian who's committee membership is updated
    /// @param inCommittee indicates whether the guardian is in the committee prior to the change
    /// @param isCertified indicates whether the guardian is certified prior to the change
    /// @param nextCertification indicates whether after the change, the guardian is certified
    /// @param generalCommitteeSize indicates the general committee size prior to the change
    /// @param certifiedCommitteeSize indicates the certified committee size prior to the change
    function committeeMembershipWillChange(address guardian, bool inCommittee, bool isCertified, bool nextCertification, uint generalCommitteeSize, uint certifiedCommitteeSize) external /* onlyCommitteeContract */;

    /// Returns the fees and bootstrap balances of a guardian
    /// @dev calculates the up to date balances (differ from the state)
    /// @param guardian is the guardian address
    /// @return feeBalance the guardian's fees balance
    /// @return bootstrapBalance the guardian's bootstrap balance
    function getFeesAndBootstrapBalance(address guardian) external view returns (
        uint256 feeBalance,
        uint256 bootstrapBalance
    );

    /// Returns an estimation of the fees and bootstrap a guardian will be entitled to for a duration of time
    /// The estimation is based on the current system state and there for only provides an estimation
    /// @param guardian is the guardian address
    /// @param duration is the amount of time in seconds for which the estimation is calculated
    /// @return estimatedFees is the estimated received fees for the duration
    /// @return estimatedBootstrapRewards is the estimated received bootstrap for the duration
    function estimateFutureFeesAndBootstrapRewards(address guardian, uint256 duration) external view returns (
        uint256 estimatedFees,
        uint256 estimatedBootstrapRewards
    );

    /// Transfers the guardian Fees balance to their account
    /// @dev One may withdraw for another guardian
    /// @param guardian is the guardian address
    function withdrawFees(address guardian) external;

    /// Transfers the guardian bootstrap balance to their account
    /// @dev One may withdraw for another guardian
    /// @param guardian is the guardian address
    function withdrawBootstrapFunds(address guardian) external;

    /// Returns the current global Fees and Bootstrap rewards state 
    /// @dev calculated to the latest block, may differ from the state read
    /// @return certifiedFeesPerMember represents the fees a certified committee member from day 0 would have receive
    /// @return generalFeesPerMember represents the fees a non-certified committee member from day 0 would have receive
    /// @return certifiedBootstrapPerMember represents the bootstrap fund a certified committee member from day 0 would have receive
    /// @return generalBootstrapPerMember represents the bootstrap fund a non-certified committee member from day 0 would have receive
    /// @return lastAssigned is the time the calculation was done to (typically the latest block time)
    function getFeesAndBootstrapState() external view returns (
        uint256 certifiedFeesPerMember,
        uint256 generalFeesPerMember,
        uint256 certifiedBootstrapPerMember,
        uint256 generalBootstrapPerMember,
        uint256 lastAssigned
    );

    /// Returns the current guardian Fees and Bootstrap rewards state 
    /// @dev calculated to the latest block, may differ from the state read
    /// @param guardian is the guardian to query
    /// @return feeBalance is the guardian fees balance 
    /// @return lastFeesPerMember is the FeesPerMember on the last update based on the guardian certification state
    /// @return bootstrapBalance is the guardian bootstrap balance 
    /// @return lastBootstrapPerMember is the FeesPerMember on the last BootstrapPerMember based on the guardian certification state
    /// @return withdrawnFees is the amount of fees withdrawn by the guardian
    /// @return withdrawnBootstrap is the amount of bootstrap reward withdrawn by the guardian
    /// @return certified is the current guardian certification state 
    function getFeesAndBootstrapData(address guardian) external view returns (
        uint256 feeBalance,
        uint256 lastFeesPerMember,
        uint256 bootstrapBalance,
        uint256 lastBootstrapPerMember,
        uint256 withdrawnFees,
        uint256 withdrawnBootstrap,
        bool certified
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
    event EmergencyWithdrawal(address addr, address token);

    /// Activates fees and bootstrap allocation
    /// @dev governance function called only by the initialization admin
    /// @dev On migrations, startTime should be set as the previous contract deactivation time.
    /// @param startTime sets the last assignment time
    function activateRewardDistribution(uint startTime) external /* onlyInitializationAdmin */;
    
    /// Deactivates fees and bootstrap allocation
    /// @dev governance function called only by the migration manager
    /// @dev guardians updates remain active based on the current perMember value
    function deactivateRewardDistribution() external /* onlyMigrationManager */;

    /// Returns the rewards allocation activation status
    /// @return rewardAllocationActive is the activation status
    function isRewardAllocationActive() external view returns (bool);

    /// Sets the annual rate for the general committee bootstrap
    /// @dev governance function called only by the functional manager
    /// @dev updates the global bootstrap and fees state before updating  
    /// @param annualAmount is the annual general committee bootstrap award
    function setGeneralCommitteeAnnualBootstrap(uint256 annualAmount) external /* onlyFunctionalManager */;

    /// Returns the general committee annual bootstrap award
    /// @return generalCommitteeAnnualBootstrap is the general committee annual bootstrap
    function getGeneralCommitteeAnnualBootstrap() external view returns (uint256);

    /// Sets the annual rate for the certified committee bootstrap
    /// @dev governance function called only by the functional manager
    /// @dev updates the global bootstrap and fees state before updating  
    /// @param annualAmount is the annual certified committee bootstrap award
    function setCertifiedCommitteeAnnualBootstrap(uint256 annualAmount) external /* onlyFunctionalManager */;

    /// Returns the certified committee annual bootstrap reward
    /// @return certifiedCommitteeAnnualBootstrap is the certified committee additional annual bootstrap
    function getCertifiedCommitteeAnnualBootstrap() external view returns (uint256);

    /// Migrates the rewards balance to a new FeesAndBootstrap contract
    /// @dev The new rewards contract is determined according to the contracts registry
    /// @dev No impact of the calling contract if the currently configured contract in the registry
    /// @dev may be called also while the contract is locked
    /// @param guardians is the list of guardians to migrate
    function migrateRewardsBalance(address[] calldata guardians) external;

    /// Accepts guardian's balance migration from a previous rewards contract
    /// @dev the function may be called by any caller that approves the amounts provided for transfer
    /// @param guardians is the list of migrated guardians
    /// @param fees is the list of received guardian fees balance
    /// @param totalFees is the total amount of fees migrated for all guardians in the list. Must match the sum of the fees list.
    /// @param bootstrap is the list of received guardian bootstrap balance.
    /// @param totalBootstrap is the total amount of bootstrap rewards migrated for all guardians in the list. Must match the sum of the bootstrap list.
    function acceptRewardsBalanceMigration(address[] memory guardians, uint256[] memory fees, uint256 totalFees, uint256[] memory bootstrap, uint256 totalBootstrap) external;

    /// Performs emergency withdrawal of the contract balance
    /// @dev called with a token to withdraw, should be called twice with the fees and bootstrap tokens
    /// @dev governance function called only by the migration manager
    /// @param erc20 is the ERC20 token to withdraw
    function emergencyWithdraw(address erc20) external; /* onlyMigrationManager */

    /// Returns the contract's settings
    /// @return generalCommitteeAnnualBootstrap is the general committee annual bootstrap
    /// @return certifiedCommitteeAnnualBootstrap is the certified committee additional annual bootstrap
    /// @return rewardAllocationActive indicates the rewards allocation activation state 
    function getSettings() external view returns (
        uint generalCommitteeAnnualBootstrap,
        uint certifiedCommitteeAnnualBootstrap,
        bool rewardAllocationActive
    );
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

// File: contracts/FeesAndBootstrapRewards.sol

pragma solidity 0.6.12;










contract FeesAndBootstrapRewards is IFeesAndBootstrapRewards, ManagedContract {
    using SafeMath for uint256;
    using SafeMath96 for uint96;

    uint256 constant PERCENT_MILLIE_BASE = 100000;
    uint256 constant TOKEN_BASE = 1e18;

    struct Settings {
        uint96 generalCommitteeAnnualBootstrap;
        uint96 certifiedCommitteeAnnualBootstrap;
        bool rewardAllocationActive;
    }
    Settings settings;

    IERC20 public bootstrapToken;
    IERC20 public feesToken;

    struct FeesAndBootstrapState {
        uint96 certifiedFeesPerMember;
        uint96 generalFeesPerMember;
        uint96 certifiedBootstrapPerMember;
        uint96 generalBootstrapPerMember;
        uint32 lastAssigned;
    }
    FeesAndBootstrapState public feesAndBootstrapState;

    struct FeesAndBootstrap {
        uint96 feeBalance;
        uint96 bootstrapBalance;
        uint96 lastFeesPerMember;
        uint96 lastBootstrapPerMember;
        uint96 withdrawnFees;
        uint96 withdrawnBootstrap;
    }
    mapping(address => FeesAndBootstrap) public feesAndBootstrap;

    /// Constructor
    /// @param _contractRegistry is the contract registry address
    /// @param _registryAdmin is the registry admin address
    /// @param _feesToken is the token used for virtual chains fees 
    /// @param _bootstrapToken is the token used for the bootstrap reward
    /// @param generalCommitteeAnnualBootstrap is the general committee annual bootstrap reward
    /// @param certifiedCommitteeAnnualBootstrap is the certified committee additional annual bootstrap reward
    constructor(
        IContractRegistry _contractRegistry,
        address _registryAdmin,
        IERC20 _feesToken,
        IERC20 _bootstrapToken,
        uint generalCommitteeAnnualBootstrap,
        uint certifiedCommitteeAnnualBootstrap
    ) ManagedContract(_contractRegistry, _registryAdmin) public {
        require(address(_bootstrapToken) != address(0), "bootstrapToken must not be 0");
        require(address(_feesToken) != address(0), "feeToken must not be 0");

        _setGeneralCommitteeAnnualBootstrap(generalCommitteeAnnualBootstrap);
        _setCertifiedCommitteeAnnualBootstrap(certifiedCommitteeAnnualBootstrap);

        feesToken = _feesToken;
        bootstrapToken = _bootstrapToken;
    }

    modifier onlyCommitteeContract() {
        require(msg.sender == address(committeeContract), "caller is not the elections contract");

        _;
    }

    /*
    * External functions
    */

    /// Triggers update of the guardian rewards
    /// @dev Called by: the Committee contract
    /// @dev called upon expected change in the committee membership of the guardian
    /// @param guardian is the guardian who's committee membership is updated
    /// @param inCommittee indicates whether the guardian is in the committee prior to the change
    /// @param isCertified indicates whether the guardian is certified prior to the change
    /// @param nextCertification indicates whether after the change, the guardian is certified
    /// @param generalCommitteeSize indicates the general committee size prior to the change
    /// @param certifiedCommitteeSize indicates the certified committee size prior to the change
    function committeeMembershipWillChange(address guardian, bool inCommittee, bool isCertified, bool nextCertification, uint generalCommitteeSize, uint certifiedCommitteeSize) external override onlyWhenActive onlyCommitteeContract {
        _updateGuardianFeesAndBootstrap(guardian, inCommittee, isCertified, nextCertification, generalCommitteeSize, certifiedCommitteeSize);
    }

    /// Returns the fees and bootstrap balances of a guardian
    /// @dev calculates the up to date balances (differ from the state)
    /// @return feeBalance the guardian's fees balance
    /// @return bootstrapBalance the guardian's bootstrap balance
    function getFeesAndBootstrapBalance(address guardian) external override view returns (uint256 feeBalance, uint256 bootstrapBalance) {
        (FeesAndBootstrap memory guardianFeesAndBootstrap,) = getGuardianFeesAndBootstrap(guardian, block.timestamp);
        return (guardianFeesAndBootstrap.feeBalance, guardianFeesAndBootstrap.bootstrapBalance);
    }

    /// Returns an estimation of the fees and bootstrap a guardian will be entitled to for a duration of time
    /// The estimation is based on the current system state and there for only provides an estimation
    /// @param guardian is the guardian address
    /// @param duration is the amount of time in seconds for which the estimation is calculated
    /// @return estimatedFees is the estimated received fees for the duration
    /// @return estimatedBootstrapRewards is the estimated received bootstrap for the duration
    function estimateFutureFeesAndBootstrapRewards(address guardian, uint256 duration) external override view returns (uint256 estimatedFees, uint256 estimatedBootstrapRewards) {
        (FeesAndBootstrap memory guardianFeesAndBootstrapNow,) = getGuardianFeesAndBootstrap(guardian, block.timestamp);
        (FeesAndBootstrap memory guardianFeesAndBootstrapFuture,) = getGuardianFeesAndBootstrap(guardian, block.timestamp.add(duration));
        estimatedFees = guardianFeesAndBootstrapFuture.feeBalance.sub(guardianFeesAndBootstrapNow.feeBalance);
        estimatedBootstrapRewards = guardianFeesAndBootstrapFuture.bootstrapBalance.sub(guardianFeesAndBootstrapNow.bootstrapBalance);
    }

    /// Transfers the guardian Fees balance to their account
    /// @dev One may withdraw for another guardian
    /// @param guardian is the guardian address
    function withdrawFees(address guardian) external override onlyWhenActive {
        updateGuardianFeesAndBootstrap(guardian);

        uint256 amount = feesAndBootstrap[guardian].feeBalance;
        feesAndBootstrap[guardian].feeBalance = 0;
        uint96 withdrawnFees = feesAndBootstrap[guardian].withdrawnFees.add(amount);
        feesAndBootstrap[guardian].withdrawnFees = withdrawnFees;

        emit FeesWithdrawn(guardian, amount, withdrawnFees);
        require(feesToken.transfer(guardian, amount), "Rewards::withdrawFees - insufficient funds");
    }

    /// Transfers the guardian bootstrap balance to their account
    /// @dev One may withdraw for another guardian
    /// @param guardian is the guardian address
    function withdrawBootstrapFunds(address guardian) external override onlyWhenActive {
        updateGuardianFeesAndBootstrap(guardian);
        uint256 amount = feesAndBootstrap[guardian].bootstrapBalance;
        feesAndBootstrap[guardian].bootstrapBalance = 0;
        uint96 withdrawnBootstrap = feesAndBootstrap[guardian].withdrawnBootstrap.add(amount);
        feesAndBootstrap[guardian].withdrawnBootstrap = withdrawnBootstrap;
        emit BootstrapRewardsWithdrawn(guardian, amount, withdrawnBootstrap);

        require(bootstrapToken.transfer(guardian, amount), "Rewards::withdrawBootstrapFunds - insufficient funds");
    }

    /// Returns the current global Fees and Bootstrap rewards state 
    /// @dev calculated to the latest block, may differ from the state read
    /// @return certifiedFeesPerMember represents the fees a certified committee member from day 0 would have receive
    /// @return generalFeesPerMember represents the fees a non-certified committee member from day 0 would have receive
    /// @return certifiedBootstrapPerMember represents the bootstrap fund a certified committee member from day 0 would have receive
    /// @return generalBootstrapPerMember represents the bootstrap fund a non-certified committee member from day 0 would have receive
    /// @return lastAssigned is the time the calculation was done to (typically the latest block time)
    function getFeesAndBootstrapState() external override view returns (
        uint256 certifiedFeesPerMember,
        uint256 generalFeesPerMember,
        uint256 certifiedBootstrapPerMember,
        uint256 generalBootstrapPerMember,
        uint256 lastAssigned
    ) {
        (uint generalCommitteeSize, uint certifiedCommitteeSize, ) = committeeContract.getCommitteeStats();
        (FeesAndBootstrapState memory _feesAndBootstrapState,,) = _getFeesAndBootstrapState(generalCommitteeSize, certifiedCommitteeSize, generalFeesWallet.getOutstandingFees(block.timestamp), certifiedFeesWallet.getOutstandingFees(block.timestamp), block.timestamp, settings);
        certifiedFeesPerMember = _feesAndBootstrapState.certifiedFeesPerMember;
        generalFeesPerMember = _feesAndBootstrapState.generalFeesPerMember;
        certifiedBootstrapPerMember = _feesAndBootstrapState.certifiedBootstrapPerMember;
        generalBootstrapPerMember = _feesAndBootstrapState.generalBootstrapPerMember;
        lastAssigned = _feesAndBootstrapState.lastAssigned;
    }

    /// Returns the current guardian Fees and Bootstrap rewards state 
    /// @dev calculated to the latest block, may differ from the state read
    /// @return feeBalance is the guardian fees balance 
    /// @return lastFeesPerMember is the FeesPerMember on the last update based on the guardian certification state
    /// @return bootstrapBalance is the guardian bootstrap balance 
    /// @return lastBootstrapPerMember is the FeesPerMember on the last BootstrapPerMember based on the guardian certification state
    function getFeesAndBootstrapData(address guardian) external override view returns (
        uint256 feeBalance,
        uint256 lastFeesPerMember,
        uint256 bootstrapBalance,
        uint256 lastBootstrapPerMember,
        uint256 withdrawnFees,
        uint256 withdrawnBootstrap,
        bool certified
    ) {
        FeesAndBootstrap memory guardianFeesAndBootstrap;
        (guardianFeesAndBootstrap, certified) = getGuardianFeesAndBootstrap(guardian, block.timestamp);
        return (
            guardianFeesAndBootstrap.feeBalance,
            guardianFeesAndBootstrap.lastFeesPerMember,
            guardianFeesAndBootstrap.bootstrapBalance,
            guardianFeesAndBootstrap.lastBootstrapPerMember,
            guardianFeesAndBootstrap.withdrawnFees,
            guardianFeesAndBootstrap.withdrawnBootstrap,
            certified
        );
    }

    /*
     * Governance functions
     */

    /// Activates fees and bootstrap allocation
    /// @dev governance function called only by the initialization admin
    /// @dev On migrations, startTime should be set as the previous contract deactivation time.
    /// @param startTime sets the last assignment time
    function activateRewardDistribution(uint startTime) external override onlyMigrationManager {
        require(!settings.rewardAllocationActive, "reward distribution is already activated");

        feesAndBootstrapState.lastAssigned = uint32(startTime);
        settings.rewardAllocationActive = true;

        emit RewardDistributionActivated(startTime);
    }

    /// Deactivates fees and bootstrap allocation
    /// @dev governance function called only by the migration manager
    /// @dev guardians updates remain active based on the current perMember value
    function deactivateRewardDistribution() external override onlyMigrationManager {
        require(settings.rewardAllocationActive, "reward distribution is already deactivated");

        updateFeesAndBootstrapState();

        settings.rewardAllocationActive = false;

        emit RewardDistributionDeactivated();
    }

    /// Returns the rewards allocation activation status
    /// @return rewardAllocationActive is the activation status
    function isRewardAllocationActive() external override view returns (bool) {
        return settings.rewardAllocationActive;
    }

    /// Sets the annual rate for the general committee bootstrap
    /// @dev governance function called only by the functional manager
    /// @dev updates the global bootstrap and fees state before updating  
    /// @param annualAmount is the annual general committee bootstrap award
    function setGeneralCommitteeAnnualBootstrap(uint256 annualAmount) external override onlyFunctionalManager {
        updateFeesAndBootstrapState();
        _setGeneralCommitteeAnnualBootstrap(annualAmount);
    }

    /// Returns the general committee annual bootstrap award
    /// @return generalCommitteeAnnualBootstrap is the general committee annual bootstrap
    function getGeneralCommitteeAnnualBootstrap() external override view returns (uint256) {
        return settings.generalCommitteeAnnualBootstrap;
    }

    /// Sets the annual rate for the certified committee bootstrap
    /// @dev governance function called only by the functional manager
    /// @dev updates the global bootstrap and fees state before updating  
    /// @param annualAmount is the annual certified committee bootstrap award
    function setCertifiedCommitteeAnnualBootstrap(uint256 annualAmount) external override onlyFunctionalManager {
        updateFeesAndBootstrapState();
        _setCertifiedCommitteeAnnualBootstrap(annualAmount);
    }

    /// Returns the certified committee annual bootstrap reward
    /// @return certifiedCommitteeAnnualBootstrap is the certified committee additional annual bootstrap
    function getCertifiedCommitteeAnnualBootstrap() external override view returns (uint256) {
        return settings.certifiedCommitteeAnnualBootstrap;
    }

    /// Migrates the rewards balance to a new FeesAndBootstrap contract
    /// @dev The new rewards contract is determined according to the contracts registry
    /// @dev No impact of the calling contract if the currently configured contract in the registry
    /// @dev may be called also while the contract is locked
    /// @param guardians is the list of guardians to migrate
    function migrateRewardsBalance(address[] calldata guardians) external override {
        require(!settings.rewardAllocationActive, "Reward distribution must be deactivated for migration");

        IFeesAndBootstrapRewards currentRewardsContract = IFeesAndBootstrapRewards(getFeesAndBootstrapRewardsContract());
        require(address(currentRewardsContract) != address(this), "New rewards contract is not set");

        uint256 totalFees = 0;
        uint256 totalBootstrap = 0;
        uint256[] memory fees = new uint256[](guardians.length);
        uint256[] memory bootstrap = new uint256[](guardians.length);

        for (uint i = 0; i < guardians.length; i++) {
            updateGuardianFeesAndBootstrap(guardians[i]);

            FeesAndBootstrap memory guardianFeesAndBootstrap = feesAndBootstrap[guardians[i]];
            fees[i] = guardianFeesAndBootstrap.feeBalance;
            totalFees = totalFees.add(fees[i]);
            bootstrap[i] = guardianFeesAndBootstrap.bootstrapBalance;
            totalBootstrap = totalBootstrap.add(bootstrap[i]);

            guardianFeesAndBootstrap.feeBalance = 0;
            guardianFeesAndBootstrap.bootstrapBalance = 0;
            feesAndBootstrap[guardians[i]] = guardianFeesAndBootstrap;
        }

        require(feesToken.approve(address(currentRewardsContract), totalFees), "migrateRewardsBalance: approve failed");
        require(bootstrapToken.approve(address(currentRewardsContract), totalBootstrap), "migrateRewardsBalance: approve failed");
        currentRewardsContract.acceptRewardsBalanceMigration(guardians, fees, totalFees, bootstrap, totalBootstrap);

        for (uint i = 0; i < guardians.length; i++) {
            emit FeesAndBootstrapRewardsBalanceMigrated(guardians[i], fees[i], bootstrap[i], address(currentRewardsContract));
        }
    }

    /// Accepts guardian's balance migration from a previous rewards contract
    /// @dev the function may be called by any caller that approves the amounts provided for transfer
    /// @param guardians is the list of migrated guardians
    /// @param fees is the list of received guardian fees balance
    /// @param totalFees is the total amount of fees migrated for all guardians in the list. Must match the sum of the fees list.
    /// @param bootstrap is the list of received guardian bootstrap balance.
    /// @param totalBootstrap is the total amount of bootstrap rewards migrated for all guardians in the list. Must match the sum of the bootstrap list.
    function acceptRewardsBalanceMigration(address[] memory guardians, uint256[] memory fees, uint256 totalFees, uint256[] memory bootstrap, uint256 totalBootstrap) external override {
        uint256 _totalFees = 0;
        uint256 _totalBootstrap = 0;

        for (uint i = 0; i < guardians.length; i++) {
            _totalFees = _totalFees.add(fees[i]);
            _totalBootstrap = _totalBootstrap.add(bootstrap[i]);
        }

        require(totalFees == _totalFees, "totalFees does not match fees sum");
        require(totalBootstrap == _totalBootstrap, "totalBootstrap does not match bootstrap sum");

        if (totalFees > 0) {
            require(feesToken.transferFrom(msg.sender, address(this), totalFees), "acceptRewardBalanceMigration: transfer failed");
        }
        if (totalBootstrap > 0) {
            require(bootstrapToken.transferFrom(msg.sender, address(this), totalBootstrap), "acceptRewardBalanceMigration: transfer failed");
        }

        FeesAndBootstrap memory guardianFeesAndBootstrap;
        for (uint i = 0; i < guardians.length; i++) {
            guardianFeesAndBootstrap = feesAndBootstrap[guardians[i]];
            guardianFeesAndBootstrap.feeBalance = guardianFeesAndBootstrap.feeBalance.add(fees[i]);
            guardianFeesAndBootstrap.bootstrapBalance = guardianFeesAndBootstrap.bootstrapBalance.add(bootstrap[i]);
            feesAndBootstrap[guardians[i]] = guardianFeesAndBootstrap;

            emit FeesAndBootstrapRewardsBalanceMigrationAccepted(msg.sender, guardians[i], fees[i], bootstrap[i]);
        }
    }

    /// Performs emergency withdrawal of the contract balance
    /// @dev called with a token to withdraw, should be called twice with the fees and bootstrap tokens
    /// @dev governance function called only by the migration manager
    /// @param erc20 is the ERC20 token to withdraw
    function emergencyWithdraw(address erc20) external override onlyMigrationManager {
        IERC20 _token = IERC20(erc20);
        emit EmergencyWithdrawal(msg.sender, address(_token));
        require(_token.transfer(msg.sender, _token.balanceOf(address(this))), "Rewards::emergencyWithdraw - transfer failed");
    }

    /// Returns the contract's settings
    /// @return generalCommitteeAnnualBootstrap is the general committee annual bootstrap
    /// @return certifiedCommitteeAnnualBootstrap is the certified committee additional annual bootstrap
    /// @return rewardAllocationActive indicates the rewards allocation activation state 
    function getSettings() external override view returns (
        uint generalCommitteeAnnualBootstrap,
        uint certifiedCommitteeAnnualBootstrap,
        bool rewardAllocationActive
    ) {
        Settings memory _settings = settings;
        generalCommitteeAnnualBootstrap = _settings.generalCommitteeAnnualBootstrap;
        certifiedCommitteeAnnualBootstrap = _settings.certifiedCommitteeAnnualBootstrap;
        rewardAllocationActive = _settings.rewardAllocationActive;
    }

    /*
    * Private functions
    */

    // Global state

    /// Returns the current global Fees and Bootstrap rewards state 
    /// @dev receives the relevant committee and general state data
    /// @param generalCommitteeSize is the current number of members in the certified committee
    /// @param certifiedCommitteeSize is the current number of members in the general committee
    /// @param collectedGeneralFees is the amount of fees collected from general virtual chains for the calculated period
    /// @param collectedCertifiedFees is the amount of fees collected from general virtual chains for the calculated period
    /// @param currentTime is the time to calculate the fees and bootstrap for
    /// @param _settings is the contract settings
    function _getFeesAndBootstrapState(uint generalCommitteeSize, uint certifiedCommitteeSize, uint256 collectedGeneralFees, uint256 collectedCertifiedFees, uint256 currentTime, Settings memory _settings) private view returns (FeesAndBootstrapState memory _feesAndBootstrapState, uint256 allocatedGeneralBootstrap, uint256 allocatedCertifiedBootstrap) {
        _feesAndBootstrapState = feesAndBootstrapState;

        if (_settings.rewardAllocationActive) {
            uint256 generalFeesDelta = generalCommitteeSize == 0 ? 0 : collectedGeneralFees.div(generalCommitteeSize);
            uint256 certifiedFeesDelta = certifiedCommitteeSize == 0 ? 0 : generalFeesDelta.add(collectedCertifiedFees.div(certifiedCommitteeSize));

            _feesAndBootstrapState.generalFeesPerMember = _feesAndBootstrapState.generalFeesPerMember.add(generalFeesDelta);
            _feesAndBootstrapState.certifiedFeesPerMember = _feesAndBootstrapState.certifiedFeesPerMember.add(certifiedFeesDelta);

            uint duration = currentTime.sub(_feesAndBootstrapState.lastAssigned);
            uint256 generalBootstrapDelta = uint256(_settings.generalCommitteeAnnualBootstrap).mul(duration).div(365 days);
            uint256 certifiedBootstrapDelta = generalBootstrapDelta.add(uint256(_settings.certifiedCommitteeAnnualBootstrap).mul(duration).div(365 days));

            _feesAndBootstrapState.generalBootstrapPerMember = _feesAndBootstrapState.generalBootstrapPerMember.add(generalBootstrapDelta);
            _feesAndBootstrapState.certifiedBootstrapPerMember = _feesAndBootstrapState.certifiedBootstrapPerMember.add(certifiedBootstrapDelta);
            _feesAndBootstrapState.lastAssigned = uint32(currentTime);

            allocatedGeneralBootstrap = generalBootstrapDelta.mul(generalCommitteeSize);
            allocatedCertifiedBootstrap = certifiedBootstrapDelta.mul(certifiedCommitteeSize);
        }
    }

    /// Updates the global Fees and Bootstrap rewards state
    /// @dev utilizes _getFeesAndBootstrapState to calculate the global state 
    /// @param generalCommitteeSize is the current number of members in the certified committee
    /// @param certifiedCommitteeSize is the current number of members in the general committee
    /// @return _feesAndBootstrapState is a FeesAndBootstrapState struct with the updated state
    function _updateFeesAndBootstrapState(uint generalCommitteeSize, uint certifiedCommitteeSize) private returns (FeesAndBootstrapState memory _feesAndBootstrapState) {
        Settings memory _settings = settings;
        if (!_settings.rewardAllocationActive) {
            return feesAndBootstrapState;
        }

        uint256 collectedGeneralFees = generalFeesWallet.collectFees();
        uint256 collectedCertifiedFees = certifiedFeesWallet.collectFees();
        uint256 allocatedGeneralBootstrap;
        uint256 allocatedCertifiedBootstrap;

        (_feesAndBootstrapState, allocatedGeneralBootstrap, allocatedCertifiedBootstrap) = _getFeesAndBootstrapState(generalCommitteeSize, certifiedCommitteeSize, collectedGeneralFees, collectedCertifiedFees, block.timestamp, _settings);
        bootstrapRewardsWallet.withdraw(allocatedGeneralBootstrap.add(allocatedCertifiedBootstrap));

        feesAndBootstrapState = _feesAndBootstrapState;

        emit FeesAllocated(collectedGeneralFees, _feesAndBootstrapState.generalFeesPerMember, collectedCertifiedFees, _feesAndBootstrapState.certifiedFeesPerMember);
        emit BootstrapRewardsAllocated(allocatedGeneralBootstrap, _feesAndBootstrapState.generalBootstrapPerMember, allocatedCertifiedBootstrap, _feesAndBootstrapState.certifiedBootstrapPerMember);
    }

    /// Updates the global Fees and Bootstrap rewards state
    /// @dev utilizes _updateFeesAndBootstrapState
    /// @return _feesAndBootstrapState is a FeesAndBootstrapState struct with the updated state
    function updateFeesAndBootstrapState() private returns (FeesAndBootstrapState memory _feesAndBootstrapState) {
        (uint generalCommitteeSize, uint certifiedCommitteeSize, ) = committeeContract.getCommitteeStats();
        return _updateFeesAndBootstrapState(generalCommitteeSize, certifiedCommitteeSize);
    }

    // Guardian state

    /// Returns the current guardian Fees and Bootstrap rewards state 
    /// @dev receives the relevant guardian committee membership data and the global state
    /// @param guardian is the guardian to query
    /// @param inCommittee indicates whether the guardian is currently in the committee
    /// @param isCertified indicates whether the guardian is currently certified
    /// @param nextCertification indicates whether after the change, the guardian is certified
    /// @param _feesAndBootstrapState is the current updated global fees and bootstrap state
    /// @return guardianFeesAndBootstrap is a struct with the guardian updated fees and bootstrap state
    /// @return addedBootstrapAmount is the amount added to the guardian bootstrap balance
    /// @return addedFeesAmount is the amount added to the guardian fees balance
    function _getGuardianFeesAndBootstrap(address guardian, bool inCommittee, bool isCertified, bool nextCertification, FeesAndBootstrapState memory _feesAndBootstrapState) private view returns (FeesAndBootstrap memory guardianFeesAndBootstrap, uint256 addedBootstrapAmount, uint256 addedFeesAmount) {
        guardianFeesAndBootstrap = feesAndBootstrap[guardian];

        if (inCommittee) {
            addedBootstrapAmount = (isCertified ? _feesAndBootstrapState.certifiedBootstrapPerMember : _feesAndBootstrapState.generalBootstrapPerMember).sub(guardianFeesAndBootstrap.lastBootstrapPerMember);
            guardianFeesAndBootstrap.bootstrapBalance = guardianFeesAndBootstrap.bootstrapBalance.add(addedBootstrapAmount);

            addedFeesAmount = (isCertified ? _feesAndBootstrapState.certifiedFeesPerMember : _feesAndBootstrapState.generalFeesPerMember).sub(guardianFeesAndBootstrap.lastFeesPerMember);
            guardianFeesAndBootstrap.feeBalance = guardianFeesAndBootstrap.feeBalance.add(addedFeesAmount);
        }

        guardianFeesAndBootstrap.lastBootstrapPerMember = nextCertification ?  _feesAndBootstrapState.certifiedBootstrapPerMember : _feesAndBootstrapState.generalBootstrapPerMember;
        guardianFeesAndBootstrap.lastFeesPerMember = nextCertification ?  _feesAndBootstrapState.certifiedFeesPerMember : _feesAndBootstrapState.generalFeesPerMember;
    }

    /// Updates a guardian Fees and Bootstrap rewards state
    /// @dev receives the relevant guardian committee membership data
    /// @dev updates the global Fees and Bootstrap state prior to calculating the guardian's
    /// @dev utilizes _getGuardianFeesAndBootstrap
    /// @param guardian is the guardian to update
    /// @param inCommittee indicates whether the guardian is currently in the committee
    /// @param isCertified indicates whether the guardian is currently certified
    /// @param nextCertification indicates whether after the change, the guardian is certified
    /// @param generalCommitteeSize indicates the general committee size prior to the change
    /// @param certifiedCommitteeSize indicates the certified committee size prior to the change
    function _updateGuardianFeesAndBootstrap(address guardian, bool inCommittee, bool isCertified, bool nextCertification, uint generalCommitteeSize, uint certifiedCommitteeSize) private {
        uint256 addedBootstrapAmount;
        uint256 addedFeesAmount;

        FeesAndBootstrapState memory _feesAndBootstrapState = _updateFeesAndBootstrapState(generalCommitteeSize, certifiedCommitteeSize);
        FeesAndBootstrap memory guardianFeesAndBootstrap;
        (guardianFeesAndBootstrap, addedBootstrapAmount, addedFeesAmount) = _getGuardianFeesAndBootstrap(guardian, inCommittee, isCertified, nextCertification, _feesAndBootstrapState);
        feesAndBootstrap[guardian] = guardianFeesAndBootstrap;

        emit BootstrapRewardsAssigned(guardian, addedBootstrapAmount, guardianFeesAndBootstrap.withdrawnBootstrap.add(guardianFeesAndBootstrap.bootstrapBalance), isCertified, guardianFeesAndBootstrap.lastBootstrapPerMember);
        emit FeesAssigned(guardian, addedFeesAmount, guardianFeesAndBootstrap.withdrawnFees.add(guardianFeesAndBootstrap.feeBalance), isCertified, guardianFeesAndBootstrap.lastFeesPerMember);
    }

    /// Returns the guardian Fees and Bootstrap rewards state for a given time
    /// @dev if the time to estimate is in the future, estimates the fees and rewards for the given time
    /// @dev for future time estimation assumes no change in the guardian committee membership and certification
    /// @param guardian is the guardian to query
    /// @param currentTime is the time to calculate the fees and bootstrap for
    /// @return guardianFeesAndBootstrap is a struct with the guardian updated fees and bootstrap state
    /// @return certified is the guardian certification status
    function getGuardianFeesAndBootstrap(address guardian, uint256 currentTime) private view returns (FeesAndBootstrap memory guardianFeesAndBootstrap, bool certified) {
        ICommittee _committeeContract = committeeContract;
        (uint generalCommitteeSize, uint certifiedCommitteeSize, ) = _committeeContract.getCommitteeStats();
        (FeesAndBootstrapState memory _feesAndBootstrapState,,) = _getFeesAndBootstrapState(generalCommitteeSize, certifiedCommitteeSize, generalFeesWallet.getOutstandingFees(currentTime), certifiedFeesWallet.getOutstandingFees(currentTime), currentTime, settings);
        bool inCommittee;
        (inCommittee, , certified,) = _committeeContract.getMemberInfo(guardian);
        (guardianFeesAndBootstrap, ,) = _getGuardianFeesAndBootstrap(guardian, inCommittee, certified, certified, _feesAndBootstrapState);
    }

    /// Updates a guardian Fees and Bootstrap rewards state
    /// @dev query the relevant guardian and committee data from the committee contract
    /// @dev utilizes _updateGuardianFeesAndBootstrap
    /// @param guardian is the guardian to update
    function updateGuardianFeesAndBootstrap(address guardian) private {
        ICommittee _committeeContract = committeeContract;
        (uint generalCommitteeSize, uint certifiedCommitteeSize, ) = _committeeContract.getCommitteeStats();
        (bool inCommittee, , bool isCertified,) = _committeeContract.getMemberInfo(guardian);
        _updateGuardianFeesAndBootstrap(guardian, inCommittee, isCertified, isCertified, generalCommitteeSize, certifiedCommitteeSize);
    }

    // Governance and misc.

    /// Sets the annual rate for the general committee bootstrap
    /// @param annualAmount is the annual general committee bootstrap award
    function _setGeneralCommitteeAnnualBootstrap(uint256 annualAmount) private {
        require(uint256(uint96(annualAmount)) == annualAmount, "annualAmount must fit in uint96");

        settings.generalCommitteeAnnualBootstrap = uint96(annualAmount);
        emit GeneralCommitteeAnnualBootstrapChanged(annualAmount);
    }

    /// Sets the annual rate for the certified committee bootstrap
    /// @param annualAmount is the annual certified committee bootstrap award
    function _setCertifiedCommitteeAnnualBootstrap(uint256 annualAmount) private {
        require(uint256(uint96(annualAmount)) == annualAmount, "annualAmount must fit in uint96");

        settings.certifiedCommitteeAnnualBootstrap = uint96(annualAmount);
        emit CertifiedCommitteeAnnualBootstrapChanged(annualAmount);
    }

    /*
     * Contracts topology / registry interface
     */

    ICommittee committeeContract;
    IFeesWallet generalFeesWallet;
    IFeesWallet certifiedFeesWallet;
    IProtocolWallet bootstrapRewardsWallet;

    /// Refreshes the address of the other contracts the contract interacts with
    /// @dev called by the registry contract upon an update of a contract in the registry
    function refreshContracts() external override {
        committeeContract = ICommittee(getCommitteeContract());
        generalFeesWallet = IFeesWallet(getGeneralFeesWallet());
        certifiedFeesWallet = IFeesWallet(getCertifiedFeesWallet());
        bootstrapRewardsWallet = IProtocolWallet(getBootstrapRewardsWallet());
    }
}