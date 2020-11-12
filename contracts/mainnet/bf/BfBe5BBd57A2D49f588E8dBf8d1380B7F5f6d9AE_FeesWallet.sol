// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: contracts/FeesWallet.sol

pragma solidity 0.6.12;







/// @title Fees Wallet contract interface, manages the fee buckets
contract FeesWallet is IFeesWallet, ManagedContract {
    using SafeMath for uint256;

    uint256 constant BUCKET_TIME_PERIOD = 30 days;
    uint constant MAX_FEE_BUCKET_ITERATIONS = 24;

    IERC20 public token;
    mapping(uint256 => uint256) public buckets;
    uint256 public lastCollectedAt;

    /// Constructor
    /// @param _contractRegistry is the contract registry address
    /// @param _registryAdmin is the registry admin address
    /// @param _token is the token used for virtual chains fees
    constructor(IContractRegistry _contractRegistry, address _registryAdmin, IERC20 _token) ManagedContract(_contractRegistry, _registryAdmin) public {
        token = _token;
        lastCollectedAt = block.timestamp;
    }

    modifier onlyRewardsContract() {
        require(msg.sender == rewardsContract, "caller is not the rewards contract");

        _;
    }

    /*
     *   External methods
     */

    /// Top-ups the fee pool with the given amount at the given rate
    /// @dev Called by: subscriptions contract. (not enforced)
    /// @dev fills the rewards in 30 days buckets based on the monthlyRate
    /// @param amount is the amount to fill
    /// @param monthlyRate is the monthly rate
    /// @param fromTimestamp is the to start fill the buckets, determines the first bucket to fill and the amount filled in the first bucket.
    function fillFeeBuckets(uint256 amount, uint256 monthlyRate, uint256 fromTimestamp) external override onlyWhenActive {
        uint256 bucket = _bucketTime(fromTimestamp);
        require(bucket >= _bucketTime(block.timestamp), "FeeWallet::cannot fill bucket from the past");

        uint256 _amount = amount;

        // add the partial amount to the first bucket
        uint256 bucketAmount = Math.min(amount, monthlyRate.mul(BUCKET_TIME_PERIOD.sub(fromTimestamp % BUCKET_TIME_PERIOD)).div(BUCKET_TIME_PERIOD));
        fillFeeBucket(bucket, bucketAmount);
        _amount = _amount.sub(bucketAmount);

        // following buckets are added with the monthly rate
        while (_amount > 0) {
            bucket = bucket.add(BUCKET_TIME_PERIOD);
            bucketAmount = Math.min(monthlyRate, _amount);
            fillFeeBucket(bucket, bucketAmount);

            _amount = _amount.sub(bucketAmount);
        }

        require(token.transferFrom(msg.sender, address(this), amount), "failed to transfer fees into fee wallet");
    }

    /// Collect fees from the buckets since the last call and transfers the amount back.
    /// @dev Called by: only FeesAndBootstrapRewards contract
    /// @dev The amount to collect may be queried before collect by calling getOutstandingFees
    /// @return collectedFees the amount of fees collected and transferred
    function collectFees() external override onlyRewardsContract returns (uint256 collectedFees)  {
        (uint256 _collectedFees, uint[] memory bucketsWithdrawn, uint[] memory amountsWithdrawn, uint[] memory newTotals) = _getOutstandingFees(block.timestamp);

        for (uint i = 0; i < bucketsWithdrawn.length; i++) {
            buckets[bucketsWithdrawn[i]] = newTotals[i];
            emit FeesWithdrawnFromBucket(bucketsWithdrawn[i], amountsWithdrawn[i], newTotals[i]);
        }

        lastCollectedAt = block.timestamp;

        require(token.transfer(msg.sender, _collectedFees), "FeesWallet::failed to transfer collected fees to rewards");
        return _collectedFees;
    }

    /// Returns the amount of fees that are currently available for withdrawal
    /// @param currentTime is the time to check the pending fees for
    /// @return outstandingFees is the amount of pending fees to collect at time currentTime
    function getOutstandingFees(uint256 currentTime) external override view returns (uint256 outstandingFees)  {
        require(currentTime >= block.timestamp, "currentTime must not be in the past");
        (outstandingFees,,,) = _getOutstandingFees(currentTime);
    }

    /*
     * Governance functions
     */

    /// Migrates the fees of a bucket starting at startTimestamp.
    /// @dev governance function called only by the migration manager
    /// @dev Calls acceptBucketMigration in the destination contract.
    /// @param destination is the address of the new FeesWallet contract
    /// @param bucketStartTime is the start time of the bucket to migration, must be a bucket's valid start time
    function migrateBucket(IMigratableFeesWallet destination, uint256 bucketStartTime) external override onlyMigrationManager {
        require(_bucketTime(bucketStartTime) == bucketStartTime,  "bucketStartTime must be the  start time of a bucket");

        uint bucketAmount = buckets[bucketStartTime];
        if (bucketAmount == 0) return;

        buckets[bucketStartTime] = 0;
        emit FeesWithdrawnFromBucket(bucketStartTime, bucketAmount, 0);

        token.approve(address(destination), bucketAmount);
        destination.acceptBucketMigration(bucketStartTime, bucketAmount);
    }

    /// Accepts a fees bucket balance from a previous fees wallet as part of the fees wallet migration
    /// @dev Called by the old FeesWallet contract.
    /// @dev Part of the IMigratableFeesWallet interface.
    /// @dev assumes the caller approved the amount prior to calling
    /// @param bucketStartTime is the start time of the bucket to migration, must be a bucket's valid start time
    /// @param amount is the amount to migrate (transfer) to the bucket
    function acceptBucketMigration(uint256 bucketStartTime, uint256 amount) external override {
        require(_bucketTime(bucketStartTime) == bucketStartTime,  "bucketStartTime must be the  start time of a bucket");
        fillFeeBucket(bucketStartTime, amount);
        require(token.transferFrom(msg.sender, address(this), amount), "failed to transfer fees into fee wallet on bucket migration");
    }

    /// Emergency withdraw the contract funds
    /// @dev governance function called only by the migration manager
    /// @dev used in emergencies only, where migrateBucket is not a suitable solution
    /// @param erc20 is the erc20 address of the token to withdraw
    function emergencyWithdraw(address erc20) external override onlyMigrationManager {
        IERC20 _token = IERC20(erc20);
        emit EmergencyWithdrawal(msg.sender, address(_token));
        require(_token.transfer(msg.sender, _token.balanceOf(address(this))), "FeesWallet::emergencyWithdraw - transfer failed");
    }

    /*
    * Private methods
    */

    /// Fills a bucket with the given amount and emits a corresponding event
    function fillFeeBucket(uint256 bucketId, uint256 amount) private {
        uint256 bucketTotal = buckets[bucketId].add(amount);
        buckets[bucketId] = bucketTotal;
        emit FeesAddedToBucket(bucketId, amount, bucketTotal);
    }

    /// Returns the amount of fees that are currently available for withdrawal
    /// Private function utilized by collectFees and getOutstandingFees
    /// @dev the buckets details returned by the function are used for the corresponding events generation
    /// @param currentTime is the time to check the pending fees for
    /// @return outstandingFees is the amount of pending fees to collect at time currentTime
    /// @return bucketsWithdrawn is the list of buckets that fees were withdrawn from
    /// @return withdrawnAmounts is the list of amounts withdrawn from the buckets
    /// @return newTotals is the updated total of the buckets
    function _getOutstandingFees(uint256 currentTime) private view returns (uint256 outstandingFees, uint[] memory bucketsWithdrawn, uint[] memory withdrawnAmounts, uint[] memory newTotals)  {
        uint _lastCollectedAt = lastCollectedAt;
        uint nUpdatedBuckets = _bucketTime(currentTime).sub(_bucketTime(_lastCollectedAt)).div(BUCKET_TIME_PERIOD).add(1);
        bucketsWithdrawn = new uint[](nUpdatedBuckets);
        withdrawnAmounts = new uint[](nUpdatedBuckets);
        newTotals = new uint[](nUpdatedBuckets);
        uint bucketsPayed = 0;
        while (bucketsPayed < MAX_FEE_BUCKET_ITERATIONS && _lastCollectedAt < currentTime) {
            uint256 bucketStart = _bucketTime(_lastCollectedAt);
            uint256 bucketEnd = bucketStart.add(BUCKET_TIME_PERIOD);
            uint256 payUntil = Math.min(bucketEnd, currentTime);
            uint256 bucketDuration = payUntil.sub(_lastCollectedAt);
            uint256 remainingBucketTime = bucketEnd.sub(_lastCollectedAt);

            uint256 bucketTotal = buckets[bucketStart];
            uint256 amount = bucketTotal.mul(bucketDuration).div(remainingBucketTime);
            outstandingFees = outstandingFees.add(amount);
            bucketTotal = bucketTotal.sub(amount);

            bucketsWithdrawn[bucketsPayed] = bucketStart;
            withdrawnAmounts[bucketsPayed] = amount;
            newTotals[bucketsPayed] = bucketTotal;

            _lastCollectedAt = payUntil;
            bucketsPayed++;
        }
    }

    /// Returns the start time of a bucket, used also to identify the bucket
    function _bucketTime(uint256 time) private pure returns (uint256) {
        return time.sub(time % BUCKET_TIME_PERIOD);
    }

    /*
     * Contracts topology / registry interface
     */

    address rewardsContract;

    /// Refreshes the address of the other contracts the contract interacts with
    /// @dev called by the registry contract upon an update of a contract in the registry
    function refreshContracts() external override {
        rewardsContract = getFeesAndBootstrapRewardsContract();
    }
}