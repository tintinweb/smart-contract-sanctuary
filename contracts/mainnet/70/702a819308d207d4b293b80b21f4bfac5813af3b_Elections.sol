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
	event StakeChanged(address indexed addr, uint256 selfStake, uint256 delegatedStake, uint256 effectiveStake);
	event GuardianStatusUpdated(address indexed guardian, bool readyToSync, bool readyForCommittee);

	// Vote out / Vote unready
	event GuardianVotedUnready(address indexed guardian);
	event VoteUnreadyCasted(address indexed voter, address indexed subject, uint256 expiration);
	event GuardianVotedOut(address indexed guardian);
	event VoteOutCasted(address indexed voter, address indexed subject);

	/*
	 * External functions
	 */

	/// @dev Called by a guardian when ready to start syncing with other nodes
	function readyToSync() external;

	/// @dev Called by a guardian when ready to join the committee, typically after syncing is complete or after being voted out
	function readyForCommittee() external;

	/// @dev Called to test if a guardian calling readyForCommittee() will lead to joining the committee
	function canJoinCommittee(address guardian) external view returns (bool);

	/// @dev Returns an address effective stake
	function getEffectiveStake(address guardian) external view returns (uint effectiveStake);

	/// @dev returns the current committee
	/// used also by the rewards and fees contracts
	function getCommittee() external view returns (address[] memory committee, uint256[] memory weights, address[] memory orbsAddrs, bool[] memory certification, bytes4[] memory ips);

	// Vote-unready

	/// @dev Called by a guardian as part of the automatic vote-unready flow
	function voteUnready(address subject, uint expiration) external;

	function getVoteUnreadyVote(address voter, address subject) external view returns (bool valid, uint256 expiration);

	/// @dev Returns the current vote-unready status of a subject guardian.
	/// votes indicates wether the specific committee member voted the guardian unready
	function getVoteUnreadyStatus(address subject) external view returns (
		address[] memory committee,
		uint256[] memory weights,
		bool[] memory certification,
		bool[] memory votes,
		bool subjectInCommittee,
		bool subjectInCertifiedCommittee
	);

	// Vote-out

	/// @dev Casts a voteOut vote by the sender to the given address
	function voteOut(address subject) external;

	/// @dev Returns the subject address the addr has voted-out against
	function getVoteOutVote(address voter) external view returns (address);

	/// @dev Returns the governance voteOut status of a guardian.
	/// A guardian is voted out if votedStake / totalDelegatedStake (in percent mille) > threshold
	function getVoteOutStatus(address subject) external view returns (bool votedOut, uint votedStake, uint totalDelegatedStake);

	/*
	 * Notification functions from other PoS contracts
	 */

	/// @dev Called by: delegation contract
	/// Notifies a delegated stake change event
	/// total_delegated_stake = 0 if addr delegates to another guardian
	function delegatedStakeChange(address delegate, uint256 selfStake, uint256 delegatedStake, uint256 totalDelegatedStake) external /* onlyDelegationsContract onlyWhenActive */;

	/// @dev Called by: guardian registration contract
	/// Notifies a new guardian was unregistered
	function guardianUnregistered(address guardian) external /* onlyGuardiansRegistrationContract */;

	/// @dev Called by: guardian registration contract
	/// Notifies on a guardian certification change
	function guardianCertificationChanged(address guardian, bool isCertified) external /* onlyCertificationContract */;


	/*
     * Governance functions
	 */

	event VoteUnreadyTimeoutSecondsChanged(uint32 newValue, uint32 oldValue);
	event VoteOutPercentMilleThresholdChanged(uint32 newValue, uint32 oldValue);
	event VoteUnreadyPercentMilleThresholdChanged(uint32 newValue, uint32 oldValue);
	event MinSelfStakePercentMilleChanged(uint32 newValue, uint32 oldValue);

	/// @dev Sets the minimum self-stake required for the effective stake
	/// minSelfStakePercentMille - the minimum self stake in percent-mille (0-100,000)
	function setMinSelfStakePercentMille(uint32 minSelfStakePercentMille) external /* onlyFunctionalManager onlyWhenActive */;

	/// @dev Returns the minimum self-stake required for the effective stake
	function getMinSelfStakePercentMille() external view returns (uint32);

	/// @dev Sets the vote-out threshold
	/// voteOutPercentMilleThreshold - the minimum threshold in percent-mille (0-100,000)
	function setVoteOutPercentMilleThreshold(uint32 voteUnreadyPercentMilleThreshold) external /* onlyFunctionalManager onlyWhenActive */;

	/// @dev Returns the vote-out threshold
	function getVoteOutPercentMilleThreshold() external view returns (uint32);

	/// @dev Sets the vote-unready threshold
	/// voteUnreadyPercentMilleThreshold - the minimum threshold in percent-mille (0-100,000)
	function setVoteUnreadyPercentMilleThreshold(uint32 voteUnreadyPercentMilleThreshold) external /* onlyFunctionalManager onlyWhenActive */;

	/// @dev Returns the vote-unready threshold
	function getVoteUnreadyPercentMilleThreshold() external view returns (uint32);

	/// @dev Returns the contract's settings 
	function getSettings() external view returns (
		uint32 minSelfStakePercentMille,
		uint32 voteUnreadyPercentMilleThreshold,
		uint32 voteOutPercentMilleThreshold
	);

	function initReadyForCommittee(address[] calldata guardians) external /* onlyInitializationAdmin */;

}

// File: contracts/spec_interfaces/IDelegation.sol


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

	/// @dev Stake delegation
	function delegate(address to) external /* onlyWhenActive */;

	function refreshStake(address addr) external /* onlyWhenActive */;

	function getDelegatedStake(address addr) external view returns (uint256);

	function getDelegation(address addr) external view returns (address);

	function getDelegationInfo(address addr) external view returns (address delegation, uint256 delegatorStake);

	function getTotalDelegatedStake() external view returns (uint256) ;

	/*
	 * Governance functions
	 */

	event DelegationsImported(address[] from, address indexed to);

	event DelegationInitialized(address indexed from, address indexed to);

	function importDelegations(address[] calldata from, address to) external /* onlyMigrationManager onlyDuringDelegationImport */;

	function initDelegation(address from, address to) external /* onlyInitializationAdmin */;
}

// File: contracts/spec_interfaces/IGuardiansRegistration.sol


pragma solidity 0.6.12;

/// @title Guardian registration contract interface
interface IGuardiansRegistration {
	event GuardianRegistered(address indexed guardian);
	event GuardianUnregistered(address indexed guardian);
	event GuardianDataUpdated(address indexed guardian, bool isRegistered, bytes4 ip, address orbsAddr, string name, string website);
	event GuardianMetadataChanged(address indexed guardian, string key, string newValue, string oldValue);

	/*
     * External methods
     */

    /// @dev Called by a participant who wishes to register as a guardian
	function registerGuardian(bytes4 ip, address orbsAddr, string calldata name, string calldata website) external;

    /// @dev Called by a participant who wishes to update its propertires
	function updateGuardian(bytes4 ip, address orbsAddr, string calldata name, string calldata website) external;

	/// @dev Called by a participant who wishes to update its IP address (can be call by both main and Orbs addresses)
	function updateGuardianIp(bytes4 ip) external /* onlyWhenActive */;

    /// @dev Called by a participant to update additional guardian metadata properties.
    function setMetadata(string calldata key, string calldata value) external;

    /// @dev Called by a participant to get additional guardian metadata properties.
    function getMetadata(address guardian, string calldata key) external view returns (string memory);

    /// @dev Called by a participant who wishes to unregister
	function unregisterGuardian() external;

    /// @dev Returns a guardian's data
	function getGuardianData(address guardian) external view returns (bytes4 ip, address orbsAddr, string memory name, string memory website, uint registrationTime, uint lastUpdateTime);

	/// @dev Returns the Orbs addresses of a list of guardians
	function getGuardiansOrbsAddress(address[] calldata guardianAddrs) external view returns (address[] memory orbsAddrs);

	/// @dev Returns a guardian's ip
	function getGuardianIp(address guardian) external view returns (bytes4 ip);

	/// @dev Returns guardian ips
	function getGuardianIps(address[] calldata guardian) external view returns (bytes4[] memory ips);

	/// @dev Returns true if the given address is of a registered guardian
	function isRegistered(address guardian) external view returns (bool);

	/// @dev Translates a list guardians Orbs addresses to guardian addresses
	function getGuardianAddresses(address[] calldata orbsAddrs) external view returns (address[] memory guardianAddrs);

	/// @dev Resolves the guardian address for a guardian, given a Guardian/Orbs address
	function resolveGuardianAddress(address guardianOrOrbsAddress) external view returns (address guardianAddress);

	/*
	 * Governance functions
	 */

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

	/// @dev Called by: Elections contract
	/// Notifies a weight change of certification change of a member
	function memberWeightChange(address addr, uint256 weight) external /* onlyElectionsContract onlyWhenActive */;

	function memberCertificationChange(address addr, bool isCertified) external /* onlyElectionsContract onlyWhenActive */;

	/// @dev Called by: Elections contract
	/// Notifies a a member removal for example due to voteOut / voteUnready
	function removeMember(address addr) external returns (bool memberRemoved, uint removedMemberWeight, bool removedMemberCertified)/* onlyElectionContract */;

	/// @dev Called by: Elections contract
	/// Notifies a new member applicable for committee (due to registration, unbanning, certification change)
	function addMember(address addr, uint256 weight, bool isCertified) external returns (bool memberAdded)  /* onlyElectionsContract */;

	/// @dev Called by: Elections contract
	/// Checks if addMember() would add a the member to the committee
	function checkAddMember(address addr, uint256 weight) external view returns (bool wouldAddMember);

	/// @dev Called by: Elections contract
	/// Returns the committee members and their weights
	function getCommittee() external view returns (address[] memory addrs, uint256[] memory weights, bool[] memory certification);

	function getCommitteeStats() external view returns (uint generalCommitteeSize, uint certifiedCommitteeSize, uint totalStake);

	function getMemberInfo(address addr) external view returns (bool inCommittee, uint weight, bool isCertified, uint totalCommitteeWeight);

	function emitCommitteeSnapshot() external;

	/*
	 * Governance functions
	 */

	event MaxCommitteeSizeChanged(uint8 newValue, uint8 oldValue);

	function setMaxCommitteeSize(uint8 maxCommitteeSize) external /* onlyFunctionalManager onlyWhenActive */;

	function getMaxCommitteeSize() external view returns (uint8);

	function importMembers(ICommittee previousCommitteeContract) external /* onlyInitializationAdmin */;
}

// File: contracts/spec_interfaces/ICertification.sol


pragma solidity 0.6.12;

/// @title Elections contract interface
interface ICertification /* is Ownable */ {
	event GuardianCertificationUpdate(address indexed guardian, bool isCertified);

	/*
     * External methods
     */

	/// @dev Returns the certification status of a guardian
	function isGuardianCertified(address guardian) external view returns (bool isCertified);

	/// @dev Sets the guardian certification status
	function setGuardianCertification(address guardian, bool isCertified) external /* Owner only */ ;
}

// File: contracts/spec_interfaces/IContractRegistry.sol


pragma solidity 0.6.12;

interface IContractRegistry {

	event ContractAddressUpdated(string contractName, address addr, bool managedContract);
	event ManagerChanged(string role, address newManager);
	event ContractRegistryUpdated(address newContractRegistry);

	/*
	* External functions
	*/

	/// @dev updates the contracts address and emits a corresponding event
	/// managedContract indicates whether the contract is managed by the registry and notified on changes
	function setContract(string calldata contractName, address addr, bool managedContract) external /* onlyAdmin */;

	/// @dev returns the current address of the given contracts
	function getContract(string calldata contractName) external view returns (address);

	/// @dev returns the list of contract addresses managed by the registry
	function getManagedContracts() external view returns (address[] memory);

	function setManager(string calldata role, address manager) external /* onlyAdmin */;

	function getManager(string calldata role) external view returns (address);

	function lockContracts() external /* onlyAdmin */;

	function unlockContracts() external /* onlyAdmin */;

	function setNewContractRegistry(IContractRegistry newRegistry) external /* onlyAdmin */;

	function getPreviousContractRegistry() external view returns (address);

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

    function initializationAdmin() public view returns (address) {
        return _initializationAdmin;
    }

    function initializationComplete() external onlyInitializationAdmin {
        _initializationAdmin = address(0);
        emit InitializationComplete();
    }

    function isInitializationComplete() public view returns (bool) {
        return _initializationAdmin == address(0);
    }

}

// File: contracts/ContractRegistryAccessor.sol


pragma solidity 0.6.12;




contract ContractRegistryAccessor is WithClaimableRegistryManagement, Initializable {

    IContractRegistry private contractRegistry;

    constructor(IContractRegistry _contractRegistry, address _registryAdmin) public {
        require(address(_contractRegistry) != address(0), "_contractRegistry cannot be 0");
        setContractRegistry(_contractRegistry);
        _transferRegistryManagement(_registryAdmin);
    }

    modifier onlyAdmin {
        require(isAdmin(), "sender is not an admin (registryManger or initializationAdmin)");

        _;
    }

    function isManager(string memory role) internal view returns (bool) {
        IContractRegistry _contractRegistry = contractRegistry;
        return isAdmin() || _contractRegistry != IContractRegistry(0) && contractRegistry.getManager(role) == msg.sender;
    }

    function isAdmin() internal view returns (bool) {
        return msg.sender == registryAdmin() || msg.sender == initializationAdmin() || msg.sender == address(contractRegistry);
    }

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

    function setContractRegistry(IContractRegistry newContractRegistry) public onlyAdmin {
        require(newContractRegistry.getPreviousContractRegistry() == address(contractRegistry), "new contract registry must provide the previous contract registry");
        contractRegistry = newContractRegistry;
        emit ContractRegistryAddressUpdated(address(newContractRegistry));
    }

    function getContractRegistry() public view returns (IContractRegistry) {
        return contractRegistry;
    }

}

// File: contracts/spec_interfaces/ILockable.sol


pragma solidity 0.6.12;

interface ILockable {

    event Locked();
    event Unlocked();

    function lock() external /* onlyLockOwner */;
    function unlock() external /* onlyLockOwner */;
    function isLocked() view external returns (bool);

}

// File: contracts/Lockable.sol


pragma solidity 0.6.12;



contract Lockable is ILockable, ContractRegistryAccessor {

    bool public locked;

    constructor(IContractRegistry _contractRegistry, address _registryAdmin) ContractRegistryAccessor(_contractRegistry, _registryAdmin) public {}

    modifier onlyLockOwner() {
        require(msg.sender == registryAdmin() || msg.sender == address(getContractRegistry()), "caller is not a lock owner");

        _;
    }

    function lock() external override onlyLockOwner {
        locked = true;
        emit Locked();
    }

    function unlock() external override onlyLockOwner {
        locked = false;
        emit Unlocked();
    }

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


contract ManagedContract is Lockable {

    constructor(IContractRegistry _contractRegistry, address _registryAdmin) Lockable(_contractRegistry, _registryAdmin) public {}

    modifier onlyMigrationManager {
        require(isManager("migrationManager"), "sender is not the migration manager");

        _;
    }

    modifier onlyFunctionalManager {
        require(isManager("functionalManager"), "sender is not the functional manager");

        _;
    }

    function refreshContracts() virtual external {}

}

// File: contracts/Elections.sol


pragma solidity 0.6.12;








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

	function readyToSync() external override onlyWhenActive {
		address guardian = guardianRegistrationContract.resolveGuardianAddress(msg.sender); // this validates registration
		require(!isVotedOut(guardian), "caller is voted-out");

		emit GuardianStatusUpdated(guardian, true, false);

		committeeContract.removeMember(guardian);
	}

	function readyForCommittee() external override onlyWhenActive {
		_readyForCommittee(msg.sender);
	}

	function canJoinCommittee(address guardian) external view override returns (bool) {
		guardian = guardianRegistrationContract.resolveGuardianAddress(guardian); // this validates registration

		if (isVotedOut(guardian)) {
			return false;
		}

		(, uint256 effectiveStake, ) = getGuardianStakeInfo(guardian, settings);
		return committeeContract.checkAddMember(guardian, effectiveStake);
	}

	function getEffectiveStake(address guardian) external override view returns (uint effectiveStake) {
		(, effectiveStake, ) = getGuardianStakeInfo(guardian, settings);
	}

	/// @dev returns the current committee
	function getCommittee() external override view returns (address[] memory committee, uint256[] memory weights, address[] memory orbsAddrs, bool[] memory certification, bytes4[] memory ips) {
		IGuardiansRegistration _guardianRegistrationContract = guardianRegistrationContract;
		(committee, weights, certification) = committeeContract.getCommittee();
		orbsAddrs = _guardianRegistrationContract.getGuardiansOrbsAddress(committee);
		ips = _guardianRegistrationContract.getGuardianIps(committee);
	}

	// Vote-unready

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

	function getVoteUnreadyVote(address voter, address subject) public override view returns (bool valid, uint256 expiration) {
		expiration = voteUnreadyVotes[voter][subject];
		valid = expiration != 0 && block.timestamp < expiration;
	}

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

	function getVoteOutVote(address voter) external override view returns (address) {
		return voteOutVotes[voter];
	}

	function getVoteOutStatus(address subject) external override view returns (bool votedOut, uint votedStake, uint totalDelegatedStake) {
		votedOut = isVotedOut(subject);
		votedStake = accumulatedStakesForVoteOut[subject];
		totalDelegatedStake = delegationsContract.getTotalDelegatedStake();
	}

	/*
	 * Notification functions from other PoS contracts
	 */

	function delegatedStakeChange(address delegate, uint256 selfStake, uint256 delegatedStake, uint256 totalDelegatedStake) external override onlyDelegationsContract onlyWhenActive {
		Settings memory _settings = settings;

		uint effectiveStake = calcEffectiveStake(selfStake, delegatedStake, _settings);
		emit StakeChanged(delegate, selfStake, delegatedStake, effectiveStake);

		committeeContract.memberWeightChange(delegate, effectiveStake);

		applyStakesToVoteOutBy(delegate, delegatedStake, totalDelegatedStake, _settings);
	}

	/// @dev Called by: guardian registration contract
	/// Notifies a new guardian was unregistered
	function guardianUnregistered(address guardian) external override onlyGuardiansRegistrationContract onlyWhenActive {
		emit GuardianStatusUpdated(guardian, false, false);
		committeeContract.removeMember(guardian);
	}

	/// @dev Called by: guardian registration contract§
	/// Notifies on a guardian certification change
	function guardianCertificationChanged(address guardian, bool isCertified) external override onlyCertificationContract onlyWhenActive {
		committeeContract.memberCertificationChange(guardian, isCertified);
	}

	/*
     * Governance functions
	 */

	function setMinSelfStakePercentMille(uint32 minSelfStakePercentMille) public override onlyFunctionalManager {
		require(minSelfStakePercentMille <= PERCENT_MILLIE_BASE, "minSelfStakePercentMille must be 100000 at most");
		emit MinSelfStakePercentMilleChanged(minSelfStakePercentMille, settings.minSelfStakePercentMille);
		settings.minSelfStakePercentMille = minSelfStakePercentMille;
	}

	function getMinSelfStakePercentMille() external override view returns (uint32) {
		return settings.minSelfStakePercentMille;
	}

	function setVoteOutPercentMilleThreshold(uint32 voteOutPercentMilleThreshold) public override onlyFunctionalManager {
		require(voteOutPercentMilleThreshold <= PERCENT_MILLIE_BASE, "voteOutPercentMilleThreshold must not be larger than 100000");
		emit VoteOutPercentMilleThresholdChanged(voteOutPercentMilleThreshold, settings.voteOutPercentMilleThreshold);
		settings.voteOutPercentMilleThreshold = voteOutPercentMilleThreshold;
	}

	function getVoteOutPercentMilleThreshold() external override view returns (uint32) {
		return settings.voteOutPercentMilleThreshold;
	}

	function setVoteUnreadyPercentMilleThreshold(uint32 voteUnreadyPercentMilleThreshold) public override onlyFunctionalManager {
		require(voteUnreadyPercentMilleThreshold <= PERCENT_MILLIE_BASE, "voteUnreadyPercentMilleThreshold must not be larger than 100000");
		emit VoteUnreadyPercentMilleThresholdChanged(voteUnreadyPercentMilleThreshold, settings.voteUnreadyPercentMilleThreshold);
		settings.voteUnreadyPercentMilleThreshold = voteUnreadyPercentMilleThreshold;
	}

	function getVoteUnreadyPercentMilleThreshold() external override view returns (uint32) {
		return settings.voteUnreadyPercentMilleThreshold;
	}

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

	function initReadyForCommittee(address[] calldata guardians) external override onlyInitializationAdmin {
		for (uint i = 0; i < guardians.length; i++) {
			_readyForCommittee(guardians[i]);
		}
	}

	/*
     * Private functions
	 */

	function _readyForCommittee(address guardian) private {
		guardian = guardianRegistrationContract.resolveGuardianAddress(guardian); // this validates registration
		require(!isVotedOut(guardian), "caller is voted-out");

		emit GuardianStatusUpdated(guardian, true, true);

		(, uint256 effectiveStake, ) = getGuardianStakeInfo(guardian, settings);
		committeeContract.addMember(guardian, effectiveStake, certificationContract.isGuardianCertified(guardian));
	}

	function calcEffectiveStake(uint256 selfStake, uint256 delegatedStake, Settings memory _settings) private pure returns (uint256) {
		if (selfStake.mul(PERCENT_MILLIE_BASE) >= delegatedStake.mul(_settings.minSelfStakePercentMille)) {
			return delegatedStake;
		}
		return selfStake.mul(PERCENT_MILLIE_BASE).div(_settings.minSelfStakePercentMille); // never overflows or divides by zero
	}

	function getGuardianStakeInfo(address guardian, Settings memory _settings) private view returns (uint256 selfStake, uint256 effectiveStake, uint256 delegatedStake) {
		IDelegations _delegationsContract = delegationsContract;
		(,selfStake) = _delegationsContract.getDelegationInfo(guardian);
		delegatedStake = _delegationsContract.getDelegatedStake(guardian);
		effectiveStake = calcEffectiveStake(selfStake, delegatedStake, _settings);
	}

	// Vote-unready

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

	function clearCommitteeUnreadyVotes(address[] memory committee, address subject) private {
		for (uint i = 0; i < committee.length; i++) {
			voteUnreadyVotes[committee[i]][subject] = 0; // clear vote-outs
		}
	}

	// Vote-out

	function applyStakesToVoteOutBy(address voter, uint256 currentVoterStake, uint256 totalGovernanceStake, Settings memory _settings) private {
		address subject = voteOutVotes[voter];
		if (subject == address(0)) return;

		uint256 prevVoterStake = votersStake[voter];
		votersStake[voter] = currentVoterStake;

		applyVoteOutVotesFor(subject, currentVoterStake, prevVoterStake, totalGovernanceStake, _settings);
	}

    function applyVoteOutVotesFor(address subject, uint256 voteOutStakeAdded, uint256 voteOutStakeRemoved, uint256 totalGovernanceStake, Settings memory _settings) private {
		if (isVotedOut(subject)) {
			return;
		}

		uint256 accumulated = accumulatedStakesForVoteOut[subject].
			sub(voteOutStakeRemoved).
			add(voteOutStakeAdded);

		bool shouldBeVotedOut = totalGovernanceStake > 0 && accumulated.mul(PERCENT_MILLIE_BASE) >= uint256(_settings.voteOutPercentMilleThreshold).mul(totalGovernanceStake);
		if (shouldBeVotedOut) {
			votedOutGuardians[subject] = true;
			emit GuardianVotedOut(subject);

			emit GuardianStatusUpdated(subject, false, false);
			committeeContract.removeMember(subject);
		}

		accumulatedStakesForVoteOut[subject] = accumulated;
	}

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
	function refreshContracts() external override {
		committeeContract = ICommittee(getCommitteeContract());
		delegationsContract = IDelegations(getDelegationsContract());
		guardianRegistrationContract = IGuardiansRegistration(getGuardiansRegistrationContract());
		certificationContract = ICertification(getCertificationContract());
	}

}