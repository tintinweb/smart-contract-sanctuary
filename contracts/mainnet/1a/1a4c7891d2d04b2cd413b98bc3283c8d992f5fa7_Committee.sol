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

// File: contracts/Committee.sol

pragma solidity 0.6.12;






/// @title Committee contract
contract Committee is ICommittee, ManagedContract {
	using SafeMath for uint256;
	using SafeMath for uint96;

	uint96 constant CERTIFICATION_MASK = 1 << 95;
	uint96 constant WEIGHT_MASK = ~CERTIFICATION_MASK;

	struct CommitteeMember {
		address addr;
		uint96 weightAndCertifiedBit;
	}
	CommitteeMember[] committee;

	struct MemberStatus {
		uint32 pos;
		bool inCommittee;
	}
	mapping(address => MemberStatus) public membersStatus;

	struct CommitteeStats {
		uint96 totalWeight;
		uint32 generalCommitteeSize;
		uint32 certifiedCommitteeSize;
	}
	CommitteeStats committeeStats;

	uint8 maxCommitteeSize;

    /// Constructor
    /// @param _contractRegistry is the contract registry address
    /// @param _registryAdmin is the registry admin address
    /// @param _maxCommitteeSize is the maximum number of committee members
	constructor(IContractRegistry _contractRegistry, address _registryAdmin, uint8 _maxCommitteeSize) ManagedContract(_contractRegistry, _registryAdmin) public {
		setMaxCommitteeSize(_maxCommitteeSize);
	}

	modifier onlyElectionsContract() {
		require(msg.sender == electionsContract, "caller is not the elections");

		_;
	}

	/*
	 * External functions
	 */

    /// Notifies a weight change of a member
    /// @dev Called only by: Elections contract
    /// @param addr is the committee member address
    /// @param weight is the updated weight of the committee member
	function memberWeightChange(address addr, uint256 weight) external override onlyElectionsContract onlyWhenActive {
		MemberStatus memory status = membersStatus[addr];

		if (!status.inCommittee) {
			return;
		}
		CommitteeMember memory member = committee[status.pos];
		(uint prevWeight, bool isCertified) = getWeightCertification(member);

		committeeStats.totalWeight = uint96(committeeStats.totalWeight.sub(prevWeight).add(weight));

		committee[status.pos].weightAndCertifiedBit = packWeightCertification(weight, isCertified);
		emit CommitteeChange(addr, weight, isCertified, true);
	}

    /// Notifies a change in the certification of a member
    /// @dev Called only by: Elections contract
    /// @param addr is the committee member address
    /// @param isCertified is the updated certification state of the member
	function memberCertificationChange(address addr, bool isCertified) external override onlyElectionsContract onlyWhenActive {
		MemberStatus memory status = membersStatus[addr];

		if (!status.inCommittee) {
			return;
		}
		CommitteeMember memory member = committee[status.pos];
		(uint weight, bool prevCertification) = getWeightCertification(member);

		CommitteeStats memory _committeeStats = committeeStats;

		feesAndBootstrapRewardsContract.committeeMembershipWillChange(addr, true, prevCertification, isCertified, _committeeStats.generalCommitteeSize, _committeeStats.certifiedCommitteeSize);

		committeeStats.certifiedCommitteeSize = _committeeStats.certifiedCommitteeSize - (prevCertification ? 1 : 0) + (isCertified ? 1 : 0);

		committee[status.pos].weightAndCertifiedBit = packWeightCertification(weight, isCertified);
		emit CommitteeChange(addr, weight, isCertified, true);
	}

    /// Notifies a member removal for example due to voteOut or voteUnready
    /// @dev Called only by: Elections contract
    /// @param memberRemoved is the removed committee member address
    /// @return memberRemoved indicates whether the member was removed from the committee
    /// @return removedMemberWeight indicates the removed member weight
    /// @return removedMemberCertified indicates whether the member was in the certified committee
	function removeMember(address addr) external override onlyElectionsContract onlyWhenActive returns (bool memberRemoved, uint removedMemberWeight, bool removedMemberCertified) {
		MemberStatus memory status = membersStatus[addr];
		if (!status.inCommittee) {
			return (false, 0, false);
		}

		memberRemoved = true;
		(removedMemberWeight, removedMemberCertified) = getWeightCertification(committee[status.pos]);

		committeeStats = removeMemberAtPos(status.pos, true, committeeStats);
	}

    /// Notifies a new member applicable for committee (due to registration, unbanning, certification change)
    /// The new member will be added only if it is qualified to join the committee 
    /// @dev Called only by: Elections contract
    /// @param addr is the added committee member address
    /// @param weight is the added member weight
    /// @param isCertified is the added member certification state
    /// @return memberAdded bool indicates whether the member was added
	function addMember(address addr, uint256 weight, bool isCertified) external override onlyElectionsContract onlyWhenActive returns (bool memberAdded) {
		return _addMember(addr, weight, isCertified, true);
	}

    /// Checks if addMember() would add a the member to the committee (qualified to join)
    /// @param addr is the candidate committee member address
    /// @param weight is the candidate committee member weight
    /// @return wouldAddMember bool indicates whether the member will be added
	function checkAddMember(address addr, uint256 weight) external view override returns (bool wouldAddMember) {
		if (membersStatus[addr].inCommittee) {
			return false;
		}

		(bool qualified, ) = qualifiesToEnterCommittee(addr, weight, maxCommitteeSize);
		return qualified;
	}

    /// Returns the committee members and their weights
    /// @return addrs is the committee members list
    /// @return weights is an array of uint, indicating committee members list weight
    /// @return certification is an array of bool, indicating the committee members certification status
	function getCommittee() external override view returns (address[] memory addrs, uint256[] memory weights, bool[] memory certification) {
		return _getCommittee();
	}

    /// Returns the currently appointed committee data
    /// @return generalCommitteeSize is the number of members in the committee
    /// @return certifiedCommitteeSize is the number of certified members in the committee
    /// @return totalWeight is the total effective stake (weight) of the committee
	function getCommitteeStats() external override view returns (uint generalCommitteeSize, uint certifiedCommitteeSize, uint totalWeight) {
		CommitteeStats memory _committeeStats = committeeStats;
		return (_committeeStats.generalCommitteeSize, _committeeStats.certifiedCommitteeSize, _committeeStats.totalWeight);
	}

    /// Returns a committee member data
    /// @param addr is the committee member address
    /// @return inCommittee indicates whether the queried address is a member in the committee
    /// @return weight is the committee member weight
    /// @return isCertified indicates whether the committee member is certified
    /// @return totalCommitteeWeight is the total weight of the committee.
	function getMemberInfo(address addr) external override view returns (bool inCommittee, uint weight, bool isCertified, uint totalCommitteeWeight) {
		MemberStatus memory status = membersStatus[addr];
		inCommittee = status.inCommittee;
		if (inCommittee) {
			(weight, isCertified) = getWeightCertification(committee[status.pos]);
		}
		totalCommitteeWeight = committeeStats.totalWeight;
	}
	
    /// Emits a CommitteeSnapshot events with current committee info
    /// @dev a CommitteeSnapshot is useful on contract migration or to remove the need to track past events.
	function emitCommitteeSnapshot() external override {
		(address[] memory addrs, uint256[] memory weights, bool[] memory certification) = _getCommittee();
		for (uint i = 0; i < addrs.length; i++) {
			emit CommitteeChange(addrs[i], weights[i], certification[i], true);
		}
		emit CommitteeSnapshot(addrs, weights, certification);
	}


	/*
	 * Governance functions
	 */

    /// Sets the maximum number of committee members
    /// @dev governance function called only by the functional manager
    /// @dev when reducing the number of members, the bottom ones are removed from the committee
    /// @param _maxCommitteeSize is the maximum number of committee members 
	function setMaxCommitteeSize(uint8 _maxCommitteeSize) public override onlyFunctionalManager {
		uint8 prevMaxCommitteeSize = maxCommitteeSize;
		maxCommitteeSize = _maxCommitteeSize;

		while (committee.length > _maxCommitteeSize) {
			(, ,uint pos) = _getMinCommitteeMember();
			committeeStats = removeMemberAtPos(pos, true, committeeStats);
		}

		emit MaxCommitteeSizeChanged(_maxCommitteeSize, prevMaxCommitteeSize);
	}

    /// Returns the maximum number of committee members
    /// @return maxCommitteeSize is the maximum number of committee members 
	function getMaxCommitteeSize() external override view returns (uint8) {
		return maxCommitteeSize;
	}

    /// Imports the committee members from a previous committee contract during migration
    /// @dev initialization function called only by the initializationManager
    /// @dev does not update the reward contract to avoid incorrect notifications 
    /// @param previousCommitteeContract is the address of the previous committee contract
	function importMembers(ICommittee previousCommitteeContract) external override onlyInitializationAdmin {
		(address[] memory addrs, uint256[] memory weights, bool[] memory certification) = previousCommitteeContract.getCommittee();
		for (uint i = 0; i < addrs.length; i++) {
			_addMember(addrs[i], weights[i], certification[i], false);
		}
	}

	/*
	 * Private
	 */

    /// Checks a member eligibility to join the committee and add if eligible
    /// @dev Private function called by AddMember and importMembers
    /// @dev checks if the maximum committee size has reached, removes the lowest weight member if needed
    /// @param addr is the added committee member address
    /// @param weight is the added member weight
    /// @param isCertified is the added member certification state
    /// @param notifyRewards indicates whether to notify the rewards contract on the update, false on members import during migration
	function _addMember(address addr, uint256 weight, bool isCertified, bool notifyRewards) private returns (bool memberAdded) {
		MemberStatus memory status = membersStatus[addr];

		if (status.inCommittee) {
			return false;
		}

		(bool qualified, uint entryPos) = qualifiesToEnterCommittee(addr, weight, maxCommitteeSize);
		if (!qualified) {
			return false;
		}

		memberAdded = true;

		CommitteeStats memory _committeeStats = committeeStats;

		if (notifyRewards) {
			stakingRewardsContract.committeeMembershipWillChange(addr, weight, _committeeStats.totalWeight, false, true);
			feesAndBootstrapRewardsContract.committeeMembershipWillChange(addr, false, isCertified, isCertified, _committeeStats.generalCommitteeSize, _committeeStats.certifiedCommitteeSize);
		}

		_committeeStats.generalCommitteeSize++;
		if (isCertified) _committeeStats.certifiedCommitteeSize++;
		_committeeStats.totalWeight = uint96(_committeeStats.totalWeight.add(weight));

		CommitteeMember memory newMember = CommitteeMember({
			addr: addr,
			weightAndCertifiedBit: packWeightCertification(weight, isCertified)
			});

		if (entryPos < committee.length) {
			CommitteeMember memory removed = committee[entryPos];
			unpackWeightCertification(removed.weightAndCertifiedBit);

			_committeeStats = removeMemberAtPos(entryPos, false, _committeeStats);
			committee[entryPos] = newMember;
		} else {
			committee.push(newMember);
		}

		status.inCommittee = true;
		status.pos = uint32(entryPos);
		membersStatus[addr] = status;

		committeeStats = _committeeStats;

		emit CommitteeChange(addr, weight, isCertified, true);
	}

    /// Pack a member's weight and certification to a compact uint96 representation
	function packWeightCertification(uint256 weight, bool certification) private pure returns (uint96 weightAndCertified) {
		return uint96(weight) | (certification ? CERTIFICATION_MASK : 0);
	}

    /// Unpacks a compact uint96 representation to a member's weight and certification
	function unpackWeightCertification(uint96 weightAndCertifiedBit) private pure returns (uint256 weight, bool certification) {
		return (uint256(weightAndCertifiedBit & WEIGHT_MASK), weightAndCertifiedBit & CERTIFICATION_MASK != 0);
	}

    /// Returns the weight and certification of a CommitteeMember entry
	function getWeightCertification(CommitteeMember memory member) private pure returns (uint256 weight, bool certification) {
		return unpackWeightCertification(member.weightAndCertifiedBit);
	}

    /// Returns the committee members and their weights
    /// @dev Private function called by getCommittee and emitCommitteeSnapshot
    /// @return addrs is the committee members list
    /// @return weights is an array of uint, indicating committee members list weight
    /// @return certification is an array of bool, indicating the committee members certification status
	function _getCommittee() private view returns (address[] memory addrs, uint256[] memory weights, bool[] memory certification) {
		CommitteeMember[] memory _committee = committee;
		addrs = new address[](_committee.length);
		weights = new uint[](_committee.length);
		certification = new bool[](_committee.length);

		for (uint i = 0; i < _committee.length; i++) {
			addrs[i] = _committee[i].addr;
			(weights[i], certification[i]) = getWeightCertification(_committee[i]);
		}
	}

    /// Returns the committee member with the minimum weight as a candidate to be removed from the committee 
    /// @dev Private function called by qualifiesToEnterCommittee and setMaxCommitteeSize
    /// @return minMemberAddress is the address of the committee member with the minimum weight
    /// @return minMemberWeight is the weight of the committee member with the minimum weight
    /// @return minMemberPos is the committee array pos of the committee member with the minimum weight
	function _getMinCommitteeMember() private view returns (
		address minMemberAddress,
		uint256 minMemberWeight,
		uint minMemberPos
	){
		CommitteeMember[] memory _committee = committee;
		minMemberPos = uint256(-1);
		minMemberWeight = uint256(-1);
		uint256 memberWeight;
		address memberAddress;
		for (uint i = 0; i < _committee.length; i++) {
			memberAddress = _committee[i].addr;
			(memberWeight,) = getWeightCertification(_committee[i]);
			if (memberWeight < minMemberWeight || memberWeight == minMemberWeight && memberAddress < minMemberAddress) {
				minMemberPos = i;
				minMemberWeight = memberWeight;
				minMemberAddress = memberAddress;
			}
		}
	}


    /// Checks if a potential candidate is qualified to join the committee
    /// @dev Private function called by checkAddMember and _addMember
    /// @param addr is the candidate committee member address
    /// @param weight is the candidate committee member weight
    /// @param _maxCommitteeSize is the maximum number of committee members
    /// @return qualified indicates whether the candidate committee member qualifies to join
    /// @return entryPos is the committee array pos allocated to the member (empty or the position of the minimum weight member)
	function qualifiesToEnterCommittee(address addr, uint256 weight, uint8 _maxCommitteeSize) private view returns (bool qualified, uint entryPos) {
		uint committeeLength = committee.length;
		if (committeeLength < _maxCommitteeSize) {
			return (true, committeeLength);
		}

		(address minMemberAddress, uint256 minMemberWeight, uint minMemberPos) = _getMinCommitteeMember();

		if (weight > minMemberWeight || weight == minMemberWeight && addr > minMemberAddress) {
			return (true, minMemberPos);
		}

		return (false, 0);
	}

    /// Removes a member at a certain pos in the committee array 
    /// @dev Private function called by _addMember, removeMember and setMaxCommitteeSize
    /// @param pos is the committee array pos to be removed
    /// @param clearFromList indicates whether to clear the entry in the committee array, false when overriding it with a new member
    /// @param _committeeStats is the current committee statistics
    /// @return newCommitteeStats is the updated committee committee statistics after the removal
	function removeMemberAtPos(uint pos, bool clearFromList, CommitteeStats memory _committeeStats) private returns (CommitteeStats memory newCommitteeStats){
		CommitteeMember memory member = committee[pos];

		(uint weight, bool certification) = getWeightCertification(member);

		stakingRewardsContract.committeeMembershipWillChange(member.addr, weight, _committeeStats.totalWeight, true, false);
		feesAndBootstrapRewardsContract.committeeMembershipWillChange(member.addr, true, certification, certification, _committeeStats.generalCommitteeSize, _committeeStats.certifiedCommitteeSize);

		delete membersStatus[member.addr];

		_committeeStats.generalCommitteeSize--;
		if (certification) _committeeStats.certifiedCommitteeSize--;
		_committeeStats.totalWeight = uint96(_committeeStats.totalWeight.sub(weight));

		emit CommitteeChange(member.addr, weight, certification, false);

		if (clearFromList) {
			uint committeeLength = committee.length;
			if (pos < committeeLength - 1) {
				CommitteeMember memory last = committee[committeeLength - 1];
				committee[pos] = last;
				membersStatus[last.addr].pos = uint32(pos);
			}
			committee.pop();
		}

		return _committeeStats;
	}

	/*
     * Contracts topology / registry interface
     */

	address electionsContract;
	IStakingRewards stakingRewardsContract;
	IFeesAndBootstrapRewards feesAndBootstrapRewardsContract;

    /// Refreshes the address of the other contracts the contract interacts with
    /// @dev called by the registry contract upon an update of a contract in the registry
	function refreshContracts() external override {
		electionsContract = getElectionsContract();
		stakingRewardsContract = IStakingRewards(getStakingRewardsContract());
		feesAndBootstrapRewardsContract = IFeesAndBootstrapRewards(getFeesAndBootstrapRewardsContract());
	}
}