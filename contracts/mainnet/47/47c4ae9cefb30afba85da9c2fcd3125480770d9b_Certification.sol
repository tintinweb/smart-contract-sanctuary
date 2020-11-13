// File: contracts/spec_interfaces/IContractRegistry.sol

pragma solidity 0.5.16;

interface IContractRegistry {

	event ContractAddressUpdated(string contractName, address addr);

	/// @dev updates the contracts address and emits a corresponding event
	function set(string calldata contractName, address addr) external /* onlyGovernor */;

	/// @dev returns the current address of the
	function get(string calldata contractName) external view returns (address);
}

// File: contracts/spec_interfaces/ICertification.sol

pragma solidity 0.5.16;



/// @title Elections contract interface
interface ICertification /* is Ownable */ {
	event GuardianCertificationUpdate(address guardian, bool isCertified);

	/*
     * External methods
     */

    /// @dev Called by a guardian as part of the automatic vote unready flow
    /// Used by the Election contract
	function isGuardianCertified(address addr) external view returns (bool isCertified);

    /// @dev Called by a guardian as part of the automatic vote unready flow
    /// Used by the Election contract
	function setGuardianCertification(address addr, bool isCertified) external /* Owner only */ ;

	/*
	 * Governance
	 */

    /// @dev Updates the address calldata of the contract registry
	function setContractRegistry(IContractRegistry _contractRegistry) external /* onlyMigrationOwner */;

}

// File: contracts/spec_interfaces/IProtocol.sol

pragma solidity 0.5.16;

interface IProtocol {
    event ProtocolVersionChanged(string deploymentSubset, uint256 currentVersion, uint256 nextVersion, uint256 fromTimestamp);

    /*
     *   External methods
     */

    /// @dev returns true if the given deployment subset exists (i.e - is registered with a protocol version)
    function deploymentSubsetExists(string calldata deploymentSubset) external view returns (bool);

    /// @dev returns the current protocol version for the given deployment subset.
    function getProtocolVersion(string calldata deploymentSubset) external view returns (uint256);

    /*
     *   Governor methods
     */

    /// @dev create a new deployment subset.
    function createDeploymentSubset(string calldata deploymentSubset, uint256 initialProtocolVersion) external /* onlyFunctionalOwner */;

    /// @dev schedules a protocol version upgrade for the given deployment subset.
    function setProtocolVersion(string calldata deploymentSubset, uint256 nextVersion, uint256 fromTimestamp) external /* onlyFunctionalOwner */;
}

// File: contracts/spec_interfaces/ICommittee.sol

pragma solidity 0.5.16;


/// @title Elections contract interface
interface ICommittee {
	event GuardianCommitteeChange(address addr, uint256 weight, bool certification, bool inCommittee);
	event CommitteeSnapshot(address[] addrs, uint256[] weights, bool[] certification);

	// No external functions

	/*
     * Methods restricted to other Orbs contracts
     */

	/// @dev Called by: Elections contract
	/// Notifies a weight change for sorting to a relevant committee member.
    /// weight = 0 indicates removal of the member from the committee (for exmaple on unregister, voteUnready, voteOut)
	function memberWeightChange(address addr, uint256 weight) external returns (bool committeeChanged) /* onlyElectionContract */;

	/// @dev Called by: Elections contract
	/// Notifies a guardian certification change
	function memberCertificationChange(address addr, bool isCertified) external returns (bool committeeChanged) /* onlyElectionsContract */;

	/// @dev Called by: Elections contract
	/// Notifies a a member removal for exampl	e due to voteOut / voteUnready
	function removeMember(address addr) external returns (bool committeeChanged) /* onlyElectionContract */;

	/// @dev Called by: Elections contract
	/// Notifies a new member applicable for committee (due to registration, unbanning, certification change)
	function addMember(address addr, uint256 weight, bool isCertified) external returns (bool committeeChanged) /* onlyElectionsContract */;

	/// @dev Called by: Elections contract
	/// Returns the committee members and their weights
	function getCommittee() external view returns (address[] memory addrs, uint256[] memory weights, bool[] memory certification);

	/*
	 * Governance
	 */

	function setMaxTimeBetweenRewardAssignments(uint32 maxTimeBetweenRewardAssignments) external /* onlyFunctionalOwner onlyWhenActive */;
	function setMaxCommittee(uint8 maxCommitteeSize) external /* onlyFunctionalOwner onlyWhenActive */;

	event MaxTimeBetweenRewardAssignmentsChanged(uint32 newValue, uint32 oldValue);
	event MaxCommitteeSizeChanged(uint8 newValue, uint8 oldValue);

    /// @dev Updates the address calldata of the contract registry
	function setContractRegistry(IContractRegistry _contractRegistry) external /* onlyMigrationOwner */;

    /*
     * Getters
     */

    /// @dev returns the current committee
    /// used also by the rewards and fees contracts
	function getCommitteeInfo() external view returns (address[] memory addrs, uint256[] memory weights, address[] memory orbsAddrs, bool[] memory certification, bytes4[] memory ips);

	/// @dev returns the current settings of the committee contract
	function getSettings() external view returns (uint32 maxTimeBetweenRewardAssignments, uint8 maxCommitteeSize);
}

// File: contracts/IStakeChangeNotifier.sol

pragma solidity 0.5.16;

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

// File: contracts/interfaces/IElections.sol

pragma solidity 0.5.16;



/// @title Elections contract interface
interface IElections /* is IStakeChangeNotifier */ {
	// Election state change events
	event GuardianVotedUnready(address guardian);
	event GuardianVotedOut(address guardian);

	// Function calls
	event VoteUnreadyCasted(address voter, address subject);
	event VoteOutCasted(address voter, address subject);
	event StakeChanged(address addr, uint256 selfStake, uint256 delegated_stake, uint256 effective_stake);

	event GuardianStatusUpdated(address addr, bool readyToSync, bool readyForCommittee);

	// Governance
	event VoteUnreadyTimeoutSecondsChanged(uint32 newValue, uint32 oldValue);
	event MinSelfStakePercentMilleChanged(uint32 newValue, uint32 oldValue);
	event VoteOutPercentageThresholdChanged(uint8 newValue, uint8 oldValue);
	event VoteUnreadyPercentageThresholdChanged(uint8 newValue, uint8 oldValue);

	/*
	 * External methods
	 */

	/// @dev Called by a guardian as part of the automatic vote-out flow
	function voteUnready(address subject_addr) external;

	/// @dev casts a voteOut vote by the sender to the given address
	function voteOut(address subjectAddr) external;

	/// @dev Called by a guardian when ready to start syncing with other nodes
	function readyToSync() external;

	/// @dev Called by a guardian when ready to join the committee, typically after syncing is complete or after being voted out
	function readyForCommittee() external;

	/*
	 * Methods restricted to other Orbs contracts
	 */

	/// @dev Called by: delegation contract
	/// Notifies a delegated stake change event
	/// total_delegated_stake = 0 if addr delegates to another guardian
	function delegatedStakeChange(address addr, uint256 selfStake, uint256 delegatedStake, uint256 totalDelegatedStake) external /* onlyDelegationContract */;

	/// @dev Called by: guardian registration contract
	/// Notifies a new guardian was registered
	function guardianRegistered(address addr) external /* onlyGuardiansRegistrationContract */;

	/// @dev Called by: guardian registration contract
	/// Notifies a new guardian was unregistered
	function guardianUnregistered(address addr) external /* onlyGuardiansRegistrationContract */;

	/// @dev Called by: guardian registration contract
	/// Notifies on a guardian certification change
	function guardianCertificationChanged(address addr, bool isCertified) external /* onlyCertificationContract */;

	/*
     * Governance
	 */

	/// @dev Updates the address of the contract registry
	function setContractRegistry(IContractRegistry _contractRegistry) external /* onlyMigrationOwner */;

	function setVoteUnreadyTimeoutSeconds(uint32 voteUnreadyTimeoutSeconds) external /* onlyFunctionalOwner onlyWhenActive */;
	function setMinSelfStakePercentMille(uint32 minSelfStakePercentMille) external /* onlyFunctionalOwner onlyWhenActive */;
	function setVoteOutPercentageThreshold(uint8 voteUnreadyPercentageThreshold) external /* onlyFunctionalOwner onlyWhenActive */;
	function setVoteUnreadyPercentageThreshold(uint8 voteUnreadyPercentageThreshold) external /* onlyFunctionalOwner onlyWhenActive */;
	function getSettings() external view returns (
		uint32 voteUnreadyTimeoutSeconds,
		uint32 minSelfStakePercentMille,
		uint8 voteUnreadyPercentageThreshold,
		uint8 voteOutPercentageThreshold
	);
}

// File: contracts/spec_interfaces/IGuardiansRegistration.sol

pragma solidity 0.5.16;


/// @title Elections contract interface
interface IGuardiansRegistration {
	event GuardianRegistered(address addr);
	event GuardianDataUpdated(address addr, bytes4 ip, address orbsAddr, string name, string website, string contact);
	event GuardianUnregistered(address addr);
	event GuardianMetadataChanged(address addr, string key, string newValue, string oldValue);

	/*
     * External methods
     */

    /// @dev Called by a participant who wishes to register as a guardian
	function registerGuardian(bytes4 ip, address orbsAddr, string calldata name, string calldata website, string calldata contact) external;

    /// @dev Called by a participant who wishes to update its propertires
	function updateGuardian(bytes4 ip, address orbsAddr, string calldata name, string calldata website, string calldata contact) external;

	/// @dev Called by a participant who wishes to update its IP address (can be call by both main and Orbs addresses)
	function updateGuardianIp(bytes4 ip) external /* onlyWhenActive */;

    /// @dev Called by a participant to update additional guardian metadata properties.
    function setMetadata(string calldata key, string calldata value) external;

    /// @dev Called by a participant to get additional guardian metadata properties.
    function getMetadata(address addr, string calldata key) external view returns (string memory);

    /// @dev Called by a participant who wishes to unregister
	function unregisterGuardian() external;

    /// @dev Returns a guardian's data
    /// Used also by the Election contract
	function getGuardianData(address addr) external view returns (bytes4 ip, address orbsAddr, string memory name, string memory website, string memory contact, uint registration_time, uint last_update_time);

	/// @dev Returns the Orbs addresses of a list of guardians
	/// Used also by the committee contract
	function getGuardiansOrbsAddress(address[] calldata addrs) external view returns (address[] memory orbsAddrs);

	/// @dev Returns a guardian's ip
	/// Used also by the Election contract
	function getGuardianIp(address addr) external view returns (bytes4 ip);

	/// @dev Returns guardian ips
	function getGuardianIps(address[] calldata addr) external view returns (bytes4[] memory ips);


	/// @dev Returns true if the given address is of a registered guardian
	/// Used also by the Election contract
	function isRegistered(address addr) external view returns (bool);

	/*
     * Methods restricted to other Orbs contracts
     */

    /// @dev Translates a list guardians Ethereum addresses to Orbs addresses
    /// Used by the Election contract
	function getOrbsAddresses(address[] calldata ethereumAddrs) external view returns (address[] memory orbsAddr);

	/// @dev Translates a list guardians Orbs addresses to Ethereum addresses
	/// Used by the Election contract
	function getEthereumAddresses(address[] calldata orbsAddrs) external view returns (address[] memory ethereumAddr);

	/// @dev Resolves the ethereum address for a guardian, given an Ethereum/Orbs address
	function resolveGuardianAddress(address ethereumOrOrbsAddress) external view returns (address mainAddress);

}

// File: contracts/spec_interfaces/ISubscriptions.sol

pragma solidity 0.5.16;


/// @title Subscriptions contract interface
interface ISubscriptions {
    event SubscriptionChanged(uint256 vcid, uint256 genRefTime, uint256 expiresAt, string tier, string deploymentSubset);
    event Payment(uint256 vcid, address by, uint256 amount, string tier, uint256 rate);
    event VcConfigRecordChanged(uint256 vcid, string key, string value);
    event SubscriberAdded(address subscriber);
    event VcCreated(uint256 vcid, address owner); // TODO what about isCertified, deploymentSubset?
    event VcOwnerChanged(uint256 vcid, address previousOwner, address newOwner);

    /*
     *   Methods restricted to other Orbs contracts
     */

    /// @dev Called by: authorized subscriber (plan) contracts
    /// Creates a new VC
    function createVC(string calldata tier, uint256 rate, uint256 amount, address owner, bool isCertified, string calldata deploymentSubset) external returns (uint, uint);

    /// @dev Called by: authorized subscriber (plan) contracts
    /// Extends the subscription of an existing VC.
    function extendSubscription(uint256 vcid, uint256 amount, address payer) external;

    /// @dev called by VC owner to set a VC config record. Emits a VcConfigRecordChanged event.
    function setVcConfigRecord(uint256 vcid, string calldata key, string calldata value) external /* onlyVcOwner */;

    /// @dev returns the value of a VC config record
    function getVcConfigRecord(uint256 vcid, string calldata key) external view returns (string memory);

    /// @dev Transfers VC ownership to a new owner (can only be called by the current owner)
    function setVcOwner(uint256 vcid, address owner) external /* onlyVcOwner */;

    /// @dev Returns the genesis ref time delay
    function getGenesisRefTimeDelay() external view returns (uint256);

    /*
     *   Governance methods
     */

    /// @dev Called by the owner to authorize a subscriber (plan)
    function addSubscriber(address addr) external /* onlyFunctionalOwner */;

    /// @dev Called by the owner to set the genesis ref time delay
    function setGenesisRefTimeDelay(uint256 newGenesisRefTimeDelay) external /* onlyFunctionalOwner */;

    /// @dev Updates the address of the contract registry
    function setContractRegistry(IContractRegistry _contractRegistry) external /* onlyMigrationOwner */;

}

// File: contracts/spec_interfaces/IDelegation.sol

pragma solidity 0.5.16;


/// @title Elections contract interface
interface IDelegations /* is IStakeChangeNotifier */ {
    // Delegation state change events
	event DelegatedStakeChanged(address indexed addr, uint256 selfDelegatedStake, uint256 delegatedStake, address[] delegators, uint256[] delegatorTotalStakes);

    // Function calls
	event Delegated(address indexed from, address indexed to);

	/*
     * External methods
     */

	/// @dev Stake delegation
	function delegate(address to) external /* onlyWhenActive */;

	function refreshStakeNotification(address addr) external /* onlyWhenActive */;

	/*
	 * Governance
	 */

    /// @dev Updates the address calldata of the contract registry
	function setContractRegistry(IContractRegistry _contractRegistry) external /* onlyMigrationOwner */;

	function importDelegations(address[] calldata from, address[] calldata to, bool notifyElections) external /* onlyMigrationOwner onlyDuringDelegationImport */;
	function finalizeDelegationImport() external /* onlyMigrationOwner onlyDuringDelegationImport */;

	event DelegationsImported(address[] from, address[] to, bool notifiedElections);
	event DelegationImportFinalized();

	/*
	 * Getters
	 */

	function getDelegatedStakes(address addr) external view returns (uint256);
	function getSelfDelegatedStake(address addr) external view returns (uint256);
	function getDelegation(address addr) external view returns (address);
	function getTotalDelegatedStake() external view returns (uint256) ;


}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts/IMigratableStakingContract.sol

pragma solidity 0.5.16;


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

pragma solidity 0.5.16;


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
    /// @param _totalAmount uint256 The total amount of rewards to distributes.
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

// File: contracts/interfaces/IRewards.sol

pragma solidity 0.5.16;



/// @title Rewards contract interface
interface IRewards {

    function assignRewards() external;
    function assignRewardsToCommittee(address[] calldata generalCommittee, uint256[] calldata generalCommitteeWeights, bool[] calldata certification) external /* onlyCommitteeContract */;

    // staking

    event StakingRewardsDistributed(address indexed distributer, uint256 fromBlock, uint256 toBlock, uint split, uint txIndex, address[] to, uint256[] amounts);
    event StakingRewardsAssigned(address[] assignees, uint256[] amounts); // todo balance?
    event StakingRewardsAddedToPool(uint256 added, uint256 total);
    event MaxDelegatorsStakingRewardsChanged(uint32 maxDelegatorsStakingRewardsPercentMille);

    /// @return Returns the currently unclaimed orbs token reward balance of the given address.
    function getStakingRewardBalance(address addr) external view returns (uint256 balance);

    /// @dev Distributes msg.sender's orbs token rewards to a list of addresses, by transferring directly into the staking contract.
    /// @dev `to[0]` must be the sender's main address
    /// @dev Total delegators reward (`to[1:n]`) must be less then maxDelegatorsStakingRewardsPercentMille of total amount
    function distributeOrbsTokenStakingRewards(uint256 totalAmount, uint256 fromBlock, uint256 toBlock, uint split, uint txIndex, address[] calldata to, uint256[] calldata amounts) external;

    /// @dev Transfers the given amount of orbs tokens form the sender to this contract an update the pool.
    function topUpStakingRewardsPool(uint256 amount) external;

    /*
    *   Reward-governor methods
    */

    /// @dev Assigns rewards and sets a new monthly rate for the pro-rata pool.
    function setAnnualStakingRewardsRate(uint256 annual_rate_in_percent_mille, uint256 annual_cap) external /* onlyFunctionalOwner */;


    // fees

    event FeesAssigned(uint256 generalGuardianAmount, uint256 certifiedGuardianAmount);
    event FeesWithdrawn(address guardian, uint256 amount);
    event FeesWithdrawnFromBucket(uint256 bucketId, uint256 withdrawn, uint256 total, bool isCertified);
    event FeesAddedToBucket(uint256 bucketId, uint256 added, uint256 total, bool isCertified);

    /*
     *   External methods
     */

    /// @return Returns the currently unclaimed orbs token reward balance of the given address.
    function getFeeBalance(address addr) external view returns (uint256 balance);

    /// @dev Transfer all of msg.sender's outstanding balance to their account
    function withdrawFeeFunds() external;

    /// @dev Called by: subscriptions contract
    /// Top-ups the certification fee pool with the given amount at the given rate (typically called by the subscriptions contract)
    function fillCertificationFeeBuckets(uint256 amount, uint256 monthlyRate, uint256 fromTimestamp) external;

    /// @dev Called by: subscriptions contract
    /// Top-ups the general fee pool with the given amount at the given rate (typically called by the subscriptions contract)
    function fillGeneralFeeBuckets(uint256 amount, uint256 monthlyRate, uint256 fromTimestamp) external;

    function getTotalBalances() external view returns (uint256 feesTotalBalance, uint256 stakingRewardsTotalBalance, uint256 bootstrapRewardsTotalBalance);

    // bootstrap

    event BootstrapRewardsAssigned(uint256 generalGuardianAmount, uint256 certifiedGuardianAmount);
    event BootstrapAddedToPool(uint256 added, uint256 total);
    event BootstrapRewardsWithdrawn(address guardian, uint256 amount);

    /*
     *   External methods
     */

    /// @return Returns the currently unclaimed bootstrap balance of the given address.
    function getBootstrapBalance(address addr) external view returns (uint256 balance);

    /// @dev Transfer all of msg.sender's outstanding balance to their account
    function withdrawBootstrapFunds() external;

    /// @return The timestamp of the last reward assignment.
    function getLastRewardAssignmentTime() external view returns (uint256 time);

    /// @dev Transfers the given amount of bootstrap tokens form the sender to this contract and update the pool.
    /// Assumes the tokens were approved for transfer
    function topUpBootstrapPool(uint256 amount) external;

    /*
     * Reward-governor methods
     */

    /// @dev Assigns rewards and sets a new monthly rate for the geenral commitee bootstrap.
    function setGeneralCommitteeAnnualBootstrap(uint256 annual_amount) external /* onlyFunctionalOwner */;

    /// @dev Assigns rewards and sets a new monthly rate for the certification commitee bootstrap.
    function setCertificationCommitteeAnnualBootstrap(uint256 annual_amount) external /* onlyFunctionalOwner */;

    event EmergencyWithdrawal(address addr);

    function emergencyWithdraw() external /* onlyMigrationManager */;

    /*
     * General governance
     */

    /// @dev Updates the address of the contract registry
    function setContractRegistry(IContractRegistry _contractRegistry) external /* onlyMigrationOwner */;


}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/WithClaimableMigrationOwnership.sol

pragma solidity 0.5.16;


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract WithClaimableMigrationOwnership is Context{
    address private _migrationOwner;
    address pendingMigrationOwner;

    event MigrationOwnershipTransferred(address indexed previousMigrationOwner, address indexed newMigrationOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial migrationMigrationOwner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _migrationOwner = msgSender;
        emit MigrationOwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current migrationOwner.
     */
    function migrationOwner() public view returns (address) {
        return _migrationOwner;
    }

    /**
     * @dev Throws if called by any account other than the migrationOwner.
     */
    modifier onlyMigrationOwner() {
        require(isMigrationOwner(), "WithClaimableMigrationOwnership: caller is not the migrationOwner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current migrationOwner.
     */
    function isMigrationOwner() public view returns (bool) {
        return _msgSender() == _migrationOwner;
    }

    /**
     * @dev Leaves the contract without migrationOwner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current migrationOwner.
     *
     * NOTE: Renouncing migrationOwnership will leave the contract without an migrationOwner,
     * thereby removing any functionality that is only available to the migrationOwner.
     */
    function renounceMigrationOwnership() public onlyMigrationOwner {
        emit MigrationOwnershipTransferred(_migrationOwner, address(0));
        _migrationOwner = address(0);
    }

    /**
     * @dev Transfers migrationOwnership of the contract to a new account (`newOwner`).
     */
    function _transferMigrationOwnership(address newMigrationOwner) internal {
        require(newMigrationOwner != address(0), "MigrationOwner: new migrationOwner is the zero address");
        emit MigrationOwnershipTransferred(_migrationOwner, newMigrationOwner);
        _migrationOwner = newMigrationOwner;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingMigrationOwner() {
        require(msg.sender == pendingMigrationOwner, "Caller is not the pending migrationOwner");
        _;
    }
    /**
     * @dev Allows the current migrationOwner to set the pendingOwner address.
     * @param newMigrationOwner The address to transfer migrationOwnership to.
     */
    function transferMigrationOwnership(address newMigrationOwner) public onlyMigrationOwner {
        pendingMigrationOwner = newMigrationOwner;
    }
    /**
     * @dev Allows the pendingMigrationOwner address to finalize the transfer.
     */
    function claimMigrationOwnership() external onlyPendingMigrationOwner {
        _transferMigrationOwnership(pendingMigrationOwner);
        pendingMigrationOwner = address(0);
    }
}

// File: contracts/Lockable.sol

pragma solidity 0.5.16;



/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Lockable is WithClaimableMigrationOwnership {

    bool public locked;

    event Locked();
    event Unlocked();

    function lock() external onlyMigrationOwner {
        locked = true;
        emit Locked();
    }

    function unlock() external onlyMigrationOwner {
        locked = false;
        emit Unlocked();
    }

    modifier onlyWhenActive() {
        require(!locked, "contract is locked for this operation");

        _;
    }
}

// File: contracts/spec_interfaces/IProtocolWallet.sol

pragma solidity 0.5.16;



pragma solidity 0.5.16;

/// @title Protocol Wallet interface
interface IProtocolWallet {
    event FundsAddedToPool(uint256 added, uint256 total);
    event ClientSet(address client);
    event MaxAnnualRateSet(uint256 maxAnnualRate);
    event EmergencyWithdrawal(address addr);

    /// @dev Returns the address of the underlying staked token.
    /// @return IERC20 The address of the token.
    function getToken() external view returns (IERC20);

    /// @dev Returns the address of the underlying staked token.
    /// @return IERC20 The address of the token.
    function getBalance() external view returns (uint256 balance);

    /// @dev Transfers the given amount of orbs tokens form the sender to this contract an update the pool.
    function topUp(uint256 amount) external;

    /// @dev Withdraw from pool to a the sender's address, limited by the pool's MaxRate.
    /// A maximum of MaxRate x time period since the last Orbs transfer may be transferred out.
    /// Flow:
    /// PoolWallet.approveTransfer(amount);
    /// ERC20.transferFrom(PoolWallet, client, amount)
    function withdraw(uint256 amount) external; /* onlyClient */

    /* Governance */
    /// @dev Sets a new transfer rate for the Orbs pool.
    function setMaxAnnualRate(uint256 annual_rate) external; /* onlyMigrationManager */

    /// @dev transfer the entire pool's balance to a new wallet.
    function emergencyWithdraw() external; /* onlyMigrationManager */

    /// @dev sets the address of the new contract
    function setClient(address client) external; /* onlyFunctionalManager */
}

// File: contracts/ContractRegistryAccessor.sol

pragma solidity 0.5.16;













contract ContractRegistryAccessor is WithClaimableMigrationOwnership {

    IContractRegistry contractRegistry;

    event ContractRegistryAddressUpdated(address addr);

    function setContractRegistry(IContractRegistry _contractRegistry) external onlyMigrationOwner {
        contractRegistry = _contractRegistry;
        emit ContractRegistryAddressUpdated(address(_contractRegistry));
    }

    function getProtocolContract() public view returns (IProtocol) {
        return IProtocol(contractRegistry.get("protocol"));
    }

    function getRewardsContract() public view returns (IRewards) {
        return IRewards(contractRegistry.get("rewards"));
    }

    function getCommitteeContract() public view returns (ICommittee) {
        return ICommittee(contractRegistry.get("committee"));
    }

    function getElectionsContract() public view returns (IElections) {
        return IElections(contractRegistry.get("elections"));
    }

    function getDelegationsContract() public view returns (IDelegations) {
        return IDelegations(contractRegistry.get("delegations"));
    }

    function getGuardiansRegistrationContract() public view returns (IGuardiansRegistration) {
        return IGuardiansRegistration(contractRegistry.get("guardiansRegistration"));
    }

    function getCertificationContract() public view returns (ICertification) {
        return ICertification(contractRegistry.get("certification"));
    }

    function getStakingContract() public view returns (IStakingContract) {
        return IStakingContract(contractRegistry.get("staking"));
    }

    function getSubscriptionsContract() public view returns (ISubscriptions) {
        return ISubscriptions(contractRegistry.get("subscriptions"));
    }

    function getStakingRewardsWallet() public view returns (IProtocolWallet) {
        return IProtocolWallet(contractRegistry.get("stakingRewardsWallet"));
    }

    function getBootstrapRewardsWallet() public view returns (IProtocolWallet) {
        return IProtocolWallet(contractRegistry.get("bootstrapRewardsWallet"));
    }

}

// File: contracts/WithClaimableFunctionalOwnership.sol

pragma solidity 0.5.16;


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract WithClaimableFunctionalOwnership is Context{
    address private _functionalOwner;
    address pendingFunctionalOwner;

    event FunctionalOwnershipTransferred(address indexed previousFunctionalOwner, address indexed newFunctionalOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial functionalFunctionalOwner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _functionalOwner = msgSender;
        emit FunctionalOwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current functionalOwner.
     */
    function functionalOwner() public view returns (address) {
        return _functionalOwner;
    }

    /**
     * @dev Throws if called by any account other than the functionalOwner.
     */
    modifier onlyFunctionalOwner() {
        require(isFunctionalOwner(), "WithClaimableFunctionalOwnership: caller is not the functionalOwner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current functionalOwner.
     */
    function isFunctionalOwner() public view returns (bool) {
        return _msgSender() == _functionalOwner;
    }

    /**
     * @dev Leaves the contract without functionalOwner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current functionalOwner.
     *
     * NOTE: Renouncing functionalOwnership will leave the contract without an functionalOwner,
     * thereby removing any functionality that is only available to the functionalOwner.
     */
    function renounceFunctionalOwnership() public onlyFunctionalOwner {
        emit FunctionalOwnershipTransferred(_functionalOwner, address(0));
        _functionalOwner = address(0);
    }

    /**
     * @dev Transfers functionalOwnership of the contract to a new account (`newOwner`).
     */
    function _transferFunctionalOwnership(address newFunctionalOwner) internal {
        require(newFunctionalOwner != address(0), "FunctionalOwner: new functionalOwner is the zero address");
        emit FunctionalOwnershipTransferred(_functionalOwner, newFunctionalOwner);
        _functionalOwner = newFunctionalOwner;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingFunctionalOwner() {
        require(msg.sender == pendingFunctionalOwner, "Caller is not the pending functionalOwner");
        _;
    }
    /**
     * @dev Allows the current functionalOwner to set the pendingOwner address.
     * @param newFunctionalOwner The address to transfer functionalOwnership to.
     */
    function transferFunctionalOwnership(address newFunctionalOwner) public onlyFunctionalOwner {
        pendingFunctionalOwner = newFunctionalOwner;
    }
    /**
     * @dev Allows the pendingFunctionalOwner address to finalize the transfer.
     */
    function claimFunctionalOwnership() external onlyPendingFunctionalOwner {
        _transferFunctionalOwnership(pendingFunctionalOwner);
        pendingFunctionalOwner = address(0);
    }
}

// File: ../contracts/Certification.sol

pragma solidity 0.5.16;




contract Certification is ICertification, ContractRegistryAccessor, WithClaimableFunctionalOwnership, Lockable {

    mapping (address => bool) guardianCertification;

    /*
     * External methods
     */

    function isGuardianCertified(address addr) external view returns (bool isCertified) {
        return guardianCertification[addr];
    }

    function setGuardianCertification(address addr, bool isCertified) external onlyFunctionalOwner onlyWhenActive {
        guardianCertification[addr] = isCertified;
        emit GuardianCertificationUpdate(addr, isCertified);
        getElectionsContract().guardianCertificationChanged(addr, isCertified);
    }

}