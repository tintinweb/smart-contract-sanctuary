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

// File: contracts/spec_interfaces/IGuardiansRegistration.sol

pragma solidity 0.6.12;

/// @title Guardian registration contract interface
interface IGuardiansRegistration {
	event GuardianRegistered(address indexed guardian);
	event GuardianUnregistered(address indexed guardian);
	event GuardianDataUpdated(address indexed guardian, bool isRegistered, bytes4 ip, address orbsAddr, string name, string website, uint256 registrationTime);
	event GuardianMetadataChanged(address indexed guardian, string key, string newValue, string oldValue);

	/*
     * External methods
     */

    /// Registers a new guardian
    /// @dev called using the guardian's address that holds the guardian self-stake and used for delegation
    /// @param ip is the guardian's node ipv4 address as a 32b number 
    /// @param orbsAddr is the guardian's Orbs node address 
    /// @param name is the guardian's name as a string
    /// @param website is the guardian's website as a string, publishing a name and website provide information for delegators
	function registerGuardian(bytes4 ip, address orbsAddr, string calldata name, string calldata website) external;

    /// Updates a registered guardian data
    /// @dev may be called only by a registered guardian
    /// @param ip is the guardian's node ipv4 address as a 32b number 
    /// @param orbsAddr is the guardian's Orbs node address 
    /// @param name is the guardian's name as a string
    /// @param website is the guardian's website as a string, publishing a name and website provide information for delegators
	function updateGuardian(bytes4 ip, address orbsAddr, string calldata name, string calldata website) external;

    /// Updates a registered guardian ip address
    /// @dev may be called only by a registered guardian
    /// @dev may be called with either the guardian address or the guardian's orbs address
    /// @param ip is the guardian's node ipv4 address as a 32b number 
	function updateGuardianIp(bytes4 ip) external /* onlyWhenActive */;

    /// Updates a guardian's metadata property
    /// @dev called using the guardian's address
    /// @dev any key may be updated to be used by Orbs platform and tools
    /// @param key is the name of the property to update
    /// @param value is the value of the property to update in a string format
    function setMetadata(string calldata key, string calldata value) external;

    /// Returns a guardian's metadata property
    /// @dev a property that wasn't set returns an empty string
    /// @param guardian is the guardian to query
    /// @param key is the name of the metadata property to query
    /// @return value is the value of the queried property in a string format
    function getMetadata(address guardian, string calldata key) external view returns (string memory);

    /// Unregisters a guardian
    /// @dev may be called only by a registered guardian
    /// @dev unregistering does not clear the guardian's metadata properties
	function unregisterGuardian() external;

    /// Returns a guardian's data
    /// @param guardian is the guardian to query
    /// @param ip is the guardian's node ipv4 address as a 32b number 
    /// @param orbsAddr is the guardian's Orbs node address 
    /// @param name is the guardian's name as a string
    /// @param website is the guardian's website as a string
    /// @param registrationTime is the timestamp of the guardian's registration
    /// @param lastUpdateTime is the timestamp of the guardian's last update
	function getGuardianData(address guardian) external view returns (bytes4 ip, address orbsAddr, string memory name, string memory website, uint registrationTime, uint lastUpdateTime);

    /// Returns the Orbs addresses of a list of guardians
    /// @dev an unregistered guardian returns address(0) Orbs address
    /// @param guardianAddrs is a list of guardians' addresses to query
    /// @return orbsAddrs is a list of the guardians' Orbs addresses 
	function getGuardiansOrbsAddress(address[] calldata guardianAddrs) external view returns (address[] memory orbsAddrs);

    /// Returns a guardian's ip
    /// @dev an unregistered guardian returns 0 ip address
    /// @param guardian is the guardian to query
    /// @return ip is the guardian's node ipv4 address as a 32b number 
	function getGuardianIp(address guardian) external view returns (bytes4 ip);

    /// Returns the ip of a list of guardians
    /// @dev an unregistered guardian returns 0 ip address
    /// @param guardianAddrs is a list of guardians' addresses to query
    /// @param ips is a list of the guardians' node ipv4 addresses as a 32b numbers
	function getGuardianIps(address[] calldata guardianAddrs) external view returns (bytes4[] memory ips);

    /// Checks if a guardian is registered
    /// @param guardian is the guardian to query
    /// @return registered is a bool indicating a guardian address is registered
	function isRegistered(address guardian) external view returns (bool);

    /// Translates a list guardians Orbs addresses to guardian addresses
    /// @dev an Orbs address that does not correspond to any registered guardian returns address(0)
    /// @param orbsAddrs is a list of the guardians' Orbs addresses to query
    /// @return guardianAddrs is a list of guardians' addresses that matches the Orbs addresses
	function getGuardianAddresses(address[] calldata orbsAddrs) external view returns (address[] memory guardianAddrs);

    /// Resolves the guardian address for a guardian, given a Guardian/Orbs address
    /// @dev revert if the address does not correspond to a registered guardian address or Orbs address
    /// @dev designed to be used for contracts calls, validating a registered guardian
    /// @dev should be used with caution when called by tools as the call may revert
    /// @dev in case of a conflict matching both guardian and Orbs address, the Guardian address takes precedence
    /// @param guardianOrOrbsAddress is the address to query representing a guardian address or Orbs address
    /// @return guardianAddress is the guardian address that matches the queried address
	function resolveGuardianAddress(address guardianOrOrbsAddress) external view returns (address guardianAddress);

	/*
	 * Governance functions
	 */

    /// Migrates a list of guardians from a previous guardians registration contract
    /// @dev governance function called only by the initialization admin
    /// @dev reads the migrated guardians data by calling getGuardianData in the previous contract
    /// @dev imports also the guardians' registration time and last update
    /// @dev emits a GuardianDataUpdated for each guardian to allow tracking by tools
    /// @param guardiansToMigrate is a list of guardians' addresses to migrate
    /// @param previousContract is the previous registration contract address
	function migrateGuardians(address[] calldata guardiansToMigrate, IGuardiansRegistration previousContract) external /* onlyInitializationAdmin */;

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

// File: contracts/spec_interfaces/ICertification.sol

pragma solidity 0.6.12;

/// @title Certification contract interface
interface ICertification /* is Ownable */ {
	event GuardianCertificationUpdate(address indexed guardian, bool isCertified);

	/*
     * External methods
     */

    /// Returns the certification status of a guardian
    /// @param guardian is the guardian to query
	function isGuardianCertified(address guardian) external view returns (bool isCertified);

    /// Sets the guardian certification status
    /// @dev governance function called only by the certification manager
    /// @param guardian is the guardian to update
    /// @param isCertified bool indication whether the guardian is certified
	function setGuardianCertification(address guardian, bool isCertified) external /* onlyCertificationManager */ ;
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

// File: contracts/Elections.sol

pragma solidity 0.6.12;








/// @title Elections contract
contract Elections is IElections, ManagedContract {
	using SafeMath for uint256;

	uint32 constant PERCENT_MILLIE_BASE = 100000;

	mapping(address => mapping(address => uint256)) voteUnreadyVotes; // by => to => expiration
	mapping(address => uint256) public votersStake;
	mapping(address => address) voteOutVotes; // by => to
	mapping(address => uint256) accumulatedStakesForVoteOut; // addr => total stake
	mapping(address => bool) votedOutGuardians;

	struct Settings {
		uint32 minSelfStakePercentMille;
		uint32 voteUnreadyPercentMilleThreshold;
		uint32 voteOutPercentMilleThreshold;
	}
	Settings settings;

    /// Constructor
    /// @param _contractRegistry is the contract registry address
    /// @param _registryAdmin is the registry admin address
    /// @param minSelfStakePercentMille is the minimum self stake in percent-mille (0-100,000) 
    /// @param voteUnreadyPercentMilleThreshold is the minimum vote-unready threshold in percent-mille (0-100,000)
    /// @param voteOutPercentMilleThreshold is the minimum vote-out threshold in percent-mille (0-100,000)
	constructor(IContractRegistry _contractRegistry, address _registryAdmin, uint32 minSelfStakePercentMille, uint32 voteUnreadyPercentMilleThreshold, uint32 voteOutPercentMilleThreshold) ManagedContract(_contractRegistry, _registryAdmin) public {
		setMinSelfStakePercentMille(minSelfStakePercentMille);
		setVoteOutPercentMilleThreshold(voteOutPercentMilleThreshold);
		setVoteUnreadyPercentMilleThreshold(voteUnreadyPercentMilleThreshold);
	}

	modifier onlyDelegationsContract() {
		require(msg.sender == address(delegationsContract), "caller is not the delegations contract");

		_;
	}

	modifier onlyGuardiansRegistrationContract() {
		require(msg.sender == address(guardianRegistrationContract), "caller is not the guardian registrations contract");

		_;
	}

	modifier onlyCertificationContract() {
		require(msg.sender == address(certificationContract), "caller is not the certification contract");

		_;
	}

	/*
	 * External functions
	 */

    /// Notifies that the guardian is ready to sync with other nodes
    /// @dev ready to sync state is not managed in the contract that only emits an event
    /// @dev readyToSync clears the readyForCommittee state
	function readyToSync() external override onlyWhenActive {
		address guardian = guardianRegistrationContract.resolveGuardianAddress(msg.sender); // this validates registration
		require(!isVotedOut(guardian), "caller is voted-out");

		emit GuardianStatusUpdated(guardian, true, false);

		committeeContract.removeMember(guardian);
	}

    /// Notifies that the guardian is ready to join the committee
    /// @dev a qualified guardian calling readyForCommittee is added to the committee
	function readyForCommittee() external override onlyWhenActive {
		_readyForCommittee(msg.sender);
	}

    /// Checks if a guardian is qualified to join the committee
    /// @dev when true, calling readyForCommittee() will result in adding the guardian to the committee
    /// @dev called periodically by guardians to check if they are qualified to join the committee
    /// @param guardian is the guardian to check
    /// @return canJoin indicating that the guardian can join the current committee
	function canJoinCommittee(address guardian) external view override returns (bool) {
		guardian = guardianRegistrationContract.resolveGuardianAddress(guardian); // this validates registration

		if (isVotedOut(guardian)) {
			return false;
		}

		uint256 effectiveStake = getGuardianEffectiveStake(guardian, settings);
		return committeeContract.checkAddMember(guardian, effectiveStake);
	}

    /// Returns an address effective stake
    /// The effective stake is derived from a guardian delegate stake and selfs stake  
    /// @return effectiveStake is the guardian's effective stake
	function getEffectiveStake(address guardian) external override view returns (uint effectiveStake) {
		return getGuardianEffectiveStake(guardian, settings);
	}

    /// Returns the current committee along with the guardians' Orbs address and IP
    /// @return committee is a list of the committee members' guardian addresses
    /// @return weights is a list of the committee members' weight (effective stake)
    /// @return orbsAddrs is a list of the committee members' orbs address
    /// @return certification is a list of bool indicating the committee members certification
    /// @return ips is a list of the committee members' ip
	function getCommittee() external override view returns (address[] memory committee, uint256[] memory weights, address[] memory orbsAddrs, bool[] memory certification, bytes4[] memory ips) {
		IGuardiansRegistration _guardianRegistrationContract = guardianRegistrationContract;
		(committee, weights, certification) = committeeContract.getCommittee();
		orbsAddrs = _guardianRegistrationContract.getGuardiansOrbsAddress(committee);
		ips = _guardianRegistrationContract.getGuardianIps(committee);
	}

	// Vote-unready

    /// Casts an unready vote on a subject guardian
    /// @dev Called by a guardian as part of the automatic vote-unready flow
    /// @dev The transaction may be sent from the guardian or orbs address.
    /// @param subject is the subject guardian to vote out
    /// @param voteExpiration is the expiration time of the vote unready to prevent counting of a vote that is already irrelevant.
	function voteUnready(address subject, uint voteExpiration) external override onlyWhenActive {
		require(voteExpiration >= block.timestamp, "vote expiration time must not be in the past");

		address voter = guardianRegistrationContract.resolveGuardianAddress(msg.sender);
		voteUnreadyVotes[voter][subject] = voteExpiration;
		emit VoteUnreadyCasted(voter, subject, voteExpiration);

		(address[] memory generalCommittee, uint256[] memory generalWeights, bool[] memory certification) = committeeContract.getCommittee();

		bool votedUnready = isCommitteeVoteUnreadyThresholdReached(generalCommittee, generalWeights, certification, subject);
		if (votedUnready) {
			clearCommitteeUnreadyVotes(generalCommittee, subject);
			emit GuardianVotedUnready(subject);

			emit GuardianStatusUpdated(subject, false, false);
			committeeContract.removeMember(subject);
		}
	}

    /// Returns the current vote unready vote for a voter and a subject pair
    /// @param voter is the voting guardian address
    /// @param subject is the subject guardian address
    /// @return valid indicates whether there is a valid vote
    /// @return expiration returns the votes expiration time
	function getVoteUnreadyVote(address voter, address subject) public override view returns (bool valid, uint256 expiration) {
		expiration = voteUnreadyVotes[voter][subject];
		valid = expiration != 0 && block.timestamp < expiration;
	}

    /// Returns the current vote-unready status of a subject guardian.
    /// @dev the committee and certification data is used to check the certified and committee threshold
    /// @param subject is the subject guardian address
    /// @return committee is a list of the current committee members
    /// @return weights is a list of the current committee members weight
    /// @return certification is a list of bool indicating the committee members certification
    /// @return votes is a list of bool indicating the members that votes the subject unready
    /// @return subjectInCommittee indicates that the subject is in the committee
    /// @return subjectInCertifiedCommittee indicates that the subject is in the certified committee
	function getVoteUnreadyStatus(address subject) external override view returns (address[] memory committee, uint256[] memory weights, bool[] memory certification, bool[] memory votes, bool subjectInCommittee, bool subjectInCertifiedCommittee) {
		(committee, weights, certification) = committeeContract.getCommittee();

		votes = new bool[](committee.length);
		for (uint i = 0; i < committee.length; i++) {
			address memberAddr = committee[i];
			if (block.timestamp < voteUnreadyVotes[memberAddr][subject]) {
				votes[i] = true;
			}

			if (memberAddr == subject) {
				subjectInCommittee = true;
				subjectInCertifiedCommittee = certification[i];
			}
		}
	}

	// Vote-out

    /// Casts a voteOut vote by the sender to the given address
    /// @dev the transaction is sent from the guardian address
    /// @param subject is the subject guardian address
	function voteOut(address subject) external override onlyWhenActive {
		Settings memory _settings = settings;

		address voter = msg.sender;
		address prevSubject = voteOutVotes[voter];

		voteOutVotes[voter] = subject;
		emit VoteOutCasted(voter, subject);

		uint256 voterStake = delegationsContract.getDelegatedStake(voter);

		if (prevSubject == address(0)) {
			votersStake[voter] = voterStake;
		}

		if (subject == address(0)) {
			delete votersStake[voter];
		}

		uint totalStake = delegationsContract.getTotalDelegatedStake();

		if (prevSubject != address(0) && prevSubject != subject) {
			applyVoteOutVotesFor(prevSubject, 0, voterStake, totalStake, _settings);
		}

		if (subject != address(0)) {
			uint voteStakeAdded = prevSubject != subject ? voterStake : 0;
			applyVoteOutVotesFor(subject, voteStakeAdded, 0, totalStake, _settings); // recheck also if not new
		}
	}

    /// Returns the subject address the addr has voted-out against
    /// @param voter is the voting guardian address
    /// @return subject is the subject the voter has voted out
	function getVoteOutVote(address voter) external override view returns (address) {
		return voteOutVotes[voter];
	}

    /// Returns the governance voteOut status of a guardian.
    /// @dev A guardian is voted out if votedStake / totalDelegatedStake (in percent mille) > threshold
    /// @param subject is the subject guardian address
    /// @return votedOut indicates whether the subject was voted out
    /// @return votedStake is the total stake voting against the subject
    /// @return totalDelegatedStake is the total delegated stake
	function getVoteOutStatus(address subject) external override view returns (bool votedOut, uint votedStake, uint totalDelegatedStake) {
		votedOut = isVotedOut(subject);
		votedStake = accumulatedStakesForVoteOut[subject];
		totalDelegatedStake = delegationsContract.getTotalDelegatedStake();
	}

	/*
	 * Notification functions from other PoS contracts
	 */

    /// Notifies a delegated stake change event
    /// @dev Called by: delegation contract
    /// @param delegate is the delegate to update
    /// @param selfDelegatedStake is the delegate self stake (0 if not self-delegating)
    /// @param delegatedStake is the delegate delegated stake (0 if not self-delegating)
    /// @param totalDelegatedStake is the total delegated stake
	function delegatedStakeChange(address delegate, uint256 selfDelegatedStake, uint256 delegatedStake, uint256 totalDelegatedStake) external override onlyDelegationsContract onlyWhenActive {
		Settings memory _settings = settings;

		uint effectiveStake = calcEffectiveStake(selfDelegatedStake, delegatedStake, _settings);
		emit StakeChanged(delegate, selfDelegatedStake, delegatedStake, effectiveStake);

		committeeContract.memberWeightChange(delegate, effectiveStake);

		applyStakesToVoteOutBy(delegate, delegatedStake, totalDelegatedStake, _settings);
	}

    /// Notifies a new guardian was unregistered
    /// @dev Called by: guardian registration contract
    /// @dev when a guardian unregisters its status is updated to not ready to sync and is removed from the committee
    /// @param guardian is the address of the guardian that unregistered
	function guardianUnregistered(address guardian) external override onlyGuardiansRegistrationContract onlyWhenActive {
		emit GuardianStatusUpdated(guardian, false, false);
		committeeContract.removeMember(guardian);
	}

    /// Notifies on a guardian certification change
    /// @dev Called by: guardian registration contract
    /// @param guardian is the address of the guardian to update
    /// @param isCertified indicates whether the guardian is certified
	function guardianCertificationChanged(address guardian, bool isCertified) external override onlyCertificationContract onlyWhenActive {
		committeeContract.memberCertificationChange(guardian, isCertified);
	}

	/*
     * Governance functions
	 */

    /// Sets the minimum self stake requirement for the effective stake
    /// @dev governance function called only by the functional manager
    /// @param minSelfStakePercentMille is the minimum self stake in percent-mille (0-100,000) 
	function setMinSelfStakePercentMille(uint32 minSelfStakePercentMille) public override onlyFunctionalManager {
		require(minSelfStakePercentMille <= PERCENT_MILLIE_BASE, "minSelfStakePercentMille must be 100000 at most");
		emit MinSelfStakePercentMilleChanged(minSelfStakePercentMille, settings.minSelfStakePercentMille);
		settings.minSelfStakePercentMille = minSelfStakePercentMille;
	}

    /// Returns the minimum self-stake required for the effective stake
    /// @return minSelfStakePercentMille is the minimum self stake in percent-mille 
	function getMinSelfStakePercentMille() external override view returns (uint32) {
		return settings.minSelfStakePercentMille;
	}

    /// Sets the vote-out threshold
    /// @dev governance function called only by the functional manager
    /// @param voteOutPercentMilleThreshold is the minimum threshold in percent-mille (0-100,000)
	function setVoteOutPercentMilleThreshold(uint32 voteOutPercentMilleThreshold) public override onlyFunctionalManager {
		require(voteOutPercentMilleThreshold <= PERCENT_MILLIE_BASE, "voteOutPercentMilleThreshold must not be larger than 100000");
		emit VoteOutPercentMilleThresholdChanged(voteOutPercentMilleThreshold, settings.voteOutPercentMilleThreshold);
		settings.voteOutPercentMilleThreshold = voteOutPercentMilleThreshold;
	}

    /// Returns the vote-out threshold
    /// @return voteOutPercentMilleThreshold is the minimum threshold in percent-mille
	function getVoteOutPercentMilleThreshold() external override view returns (uint32) {
		return settings.voteOutPercentMilleThreshold;
	}

    /// Sets the vote-unready threshold
    /// @dev governance function called only by the functional manager
    /// @param voteUnreadyPercentMilleThreshold is the minimum threshold in percent-mille (0-100,000)
	function setVoteUnreadyPercentMilleThreshold(uint32 voteUnreadyPercentMilleThreshold) public override onlyFunctionalManager {
		require(voteUnreadyPercentMilleThreshold <= PERCENT_MILLIE_BASE, "voteUnreadyPercentMilleThreshold must not be larger than 100000");
		emit VoteUnreadyPercentMilleThresholdChanged(voteUnreadyPercentMilleThreshold, settings.voteUnreadyPercentMilleThreshold);
		settings.voteUnreadyPercentMilleThreshold = voteUnreadyPercentMilleThreshold;
	}

    /// Returns the vote-unready threshold
    /// @return voteUnreadyPercentMilleThreshold is the minimum threshold in percent-mille
	function getVoteUnreadyPercentMilleThreshold() external override view returns (uint32) {
		return settings.voteUnreadyPercentMilleThreshold;
	}

    /// Returns the contract's settings 
    /// @return minSelfStakePercentMille is the minimum self stake in percent-mille
    /// @return voteUnreadyPercentMilleThreshold is the minimum threshold in percent-mille
    /// @return voteOutPercentMilleThreshold is the minimum threshold in percent-mille
	function getSettings() external override view returns (
		uint32 minSelfStakePercentMille,
		uint32 voteUnreadyPercentMilleThreshold,
		uint32 voteOutPercentMilleThreshold
	) {
		Settings memory _settings = settings;
		minSelfStakePercentMille = _settings.minSelfStakePercentMille;
		voteUnreadyPercentMilleThreshold = _settings.voteUnreadyPercentMilleThreshold;
		voteOutPercentMilleThreshold = _settings.voteOutPercentMilleThreshold;
	}

    /// Initializes the ready for committee notification for the committee guardians
    /// @dev governance function called only by the initialization admin during migration 
    /// @dev identical behaviour as if each guardian sent readyForCommittee() 
    /// @param guardians a list of guardians addresses to update
	function initReadyForCommittee(address[] calldata guardians) external override onlyInitializationAdmin {
		for (uint i = 0; i < guardians.length; i++) {
			_readyForCommittee(guardians[i]);
		}
	}

	/*
     * Private functions
	 */


    /// Handles a readyForCommittee notification
    /// @dev may be called with either the guardian address or the guardian's orbs address
    /// @dev notifies the committee contract that will add the guardian if qualified
    /// @param guardian is the guardian ready for committee
	function _readyForCommittee(address guardian) private {
		guardian = guardianRegistrationContract.resolveGuardianAddress(guardian); // this validates registration
		require(!isVotedOut(guardian), "caller is voted-out");

		emit GuardianStatusUpdated(guardian, true, true);

		uint256 effectiveStake = getGuardianEffectiveStake(guardian, settings);
		committeeContract.addMember(guardian, effectiveStake, certificationContract.isGuardianCertified(guardian));
	}

    /// Calculates a guardian effective stake based on its self-stake and delegated stake
	function calcEffectiveStake(uint256 selfStake, uint256 delegatedStake, Settings memory _settings) private pure returns (uint256) {
		if (selfStake.mul(PERCENT_MILLIE_BASE) >= delegatedStake.mul(_settings.minSelfStakePercentMille)) {
			return delegatedStake;
		}
		return selfStake.mul(PERCENT_MILLIE_BASE).div(_settings.minSelfStakePercentMille); // never overflows or divides by zero
	}

    /// Returns the effective state of a guardian 
    /// @dev calls the delegation contract to retrieve the guardian current stake and delegated stake
    /// @param guardian is the guardian to query
    /// @param _settings is the contract settings struct
    /// @return effectiveStake is the guardian's effective stake
	function getGuardianEffectiveStake(address guardian, Settings memory _settings) private view returns (uint256 effectiveStake) {
		IDelegations _delegationsContract = delegationsContract;
		(,uint256 selfStake) = _delegationsContract.getDelegationInfo(guardian);
		uint256 delegatedStake = _delegationsContract.getDelegatedStake(guardian);
		return calcEffectiveStake(selfStake, delegatedStake, _settings);
	}

	// Vote-unready

    /// Checks if the vote unready threshold was reached for a given subject
    /// @dev a subject is voted-unready if either it reaches the threshold in the general committee or a certified subject reaches the threshold in the certified committee
    /// @param committee is a list of the current committee members
    /// @param weights is a list of the current committee members weight
    /// @param certification is a list of bool indicating the committee members certification
    /// @param subject is the subject guardian address
    /// @return thresholdReached is a bool indicating that the threshold was reached
	function isCommitteeVoteUnreadyThresholdReached(address[] memory committee, uint256[] memory weights, bool[] memory certification, address subject) private returns (bool) {
		Settings memory _settings = settings;

		uint256 totalCommitteeStake = 0;
		uint256 totalVoteUnreadyStake = 0;
		uint256 totalCertifiedStake = 0;
		uint256 totalCertifiedVoteUnreadyStake = 0;

		address member;
		uint256 memberStake;
		bool isSubjectCertified;
		for (uint i = 0; i < committee.length; i++) {
			member = committee[i];
			memberStake = weights[i];

			if (member == subject && certification[i]) {
				isSubjectCertified = true;
			}

			totalCommitteeStake = totalCommitteeStake.add(memberStake);
			if (certification[i]) {
				totalCertifiedStake = totalCertifiedStake.add(memberStake);
			}

			(bool valid, uint256 expiration) = getVoteUnreadyVote(member, subject);
			if (valid) {
				totalVoteUnreadyStake = totalVoteUnreadyStake.add(memberStake);
				if (certification[i]) {
					totalCertifiedVoteUnreadyStake = totalCertifiedVoteUnreadyStake.add(memberStake);
				}
			} else if (expiration != 0) {
				// Vote is stale, delete from state
				delete voteUnreadyVotes[member][subject];
			}
		}

		return (
			totalCommitteeStake > 0 &&
			totalVoteUnreadyStake.mul(PERCENT_MILLIE_BASE) >= uint256(_settings.voteUnreadyPercentMilleThreshold).mul(totalCommitteeStake)
		) || (
			isSubjectCertified &&
			totalCertifiedStake > 0 &&
			totalCertifiedVoteUnreadyStake.mul(PERCENT_MILLIE_BASE) >= uint256(_settings.voteUnreadyPercentMilleThreshold).mul(totalCertifiedStake)
		);
	}

    /// Clears the committee members vote-unready state upon declaring a guardian unready
    /// @param committee is a list of the current committee members
    /// @param subject is the subject guardian address
	function clearCommitteeUnreadyVotes(address[] memory committee, address subject) private {
		for (uint i = 0; i < committee.length; i++) {
			voteUnreadyVotes[committee[i]][subject] = 0; // clear vote-outs
		}
	}

	// Vote-out

    /// Updates the vote-out state upon a stake change notification
    /// @param voter is the voter address
    /// @param currentVoterStake is the voter delegated stake
    /// @param totalDelegatedStake is the total delegated stake
    /// @param _settings is the contract settings struct
	function applyStakesToVoteOutBy(address voter, uint256 currentVoterStake, uint256 totalDelegatedStake, Settings memory _settings) private {
		address subject = voteOutVotes[voter];
		if (subject == address(0)) return;

		uint256 prevVoterStake = votersStake[voter];
		votersStake[voter] = currentVoterStake;

		applyVoteOutVotesFor(subject, currentVoterStake, prevVoterStake, totalDelegatedStake, _settings);
	}

    /// Applies updates in a vote-out subject state and checks whether its threshold was reached
    /// @param subject is the vote-out subject
    /// @param voteOutStakeAdded is the added votes against the subject
    /// @param voteOutStakeRemoved is the removed votes against the subject
    /// @param totalDelegatedStake is the total delegated stake used to check the vote-out threshold
    /// @param _settings is the contract settings struct
    function applyVoteOutVotesFor(address subject, uint256 voteOutStakeAdded, uint256 voteOutStakeRemoved, uint256 totalDelegatedStake, Settings memory _settings) private {
		if (isVotedOut(subject)) {
			return;
		}

		uint256 accumulated = accumulatedStakesForVoteOut[subject].
			sub(voteOutStakeRemoved).
			add(voteOutStakeAdded);

		bool shouldBeVotedOut = totalDelegatedStake > 0 && accumulated.mul(PERCENT_MILLIE_BASE) >= uint256(_settings.voteOutPercentMilleThreshold).mul(totalDelegatedStake);
		if (shouldBeVotedOut) {
			votedOutGuardians[subject] = true;
			emit GuardianVotedOut(subject);

			emit GuardianStatusUpdated(subject, false, false);
			committeeContract.removeMember(subject);
		}

		accumulatedStakesForVoteOut[subject] = accumulated;
	}

    /// Checks whether a guardian was voted out
	function isVotedOut(address guardian) private view returns (bool) {
		return votedOutGuardians[guardian];
	}

	/*
     * Contracts topology / registry interface
     */

	ICommittee committeeContract;
	IDelegations delegationsContract;
	IGuardiansRegistration guardianRegistrationContract;
	ICertification certificationContract;

    /// Refreshes the address of the other contracts the contract interacts with
    /// @dev called by the registry contract upon an update of a contract in the registry
	function refreshContracts() external override {
		committeeContract = ICommittee(getCommitteeContract());
		delegationsContract = IDelegations(getDelegationsContract());
		guardianRegistrationContract = IGuardiansRegistration(getGuardiansRegistrationContract());
		certificationContract = ICertification(getCertificationContract());
	}

}