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

// File: contracts/spec_interfaces/ISubscriptions.sol

pragma solidity 0.6.12;

/// @title Subscriptions contract interface
interface ISubscriptions {
    event SubscriptionChanged(uint256 indexed vcId, address owner, string name, uint256 genRefTime, string tier, uint256 rate, uint256 expiresAt, bool isCertified, string deploymentSubset);
    event Payment(uint256 indexed vcId, address by, uint256 amount, string tier, uint256 rate);
    event VcConfigRecordChanged(uint256 indexed vcId, string key, string value);
    event VcCreated(uint256 indexed vcId);
    event VcOwnerChanged(uint256 indexed vcId, address previousOwner, address newOwner);

    /*
     *   External functions
     */

    /// Creates a new virtual chain
    /// @dev Called only by: an authorized subscription plan contract
    /// @dev the initial amount paid for the virtual chain must be large than minimumInitialVcPayment
    /// @param name is the virtual chain name
    /// @param tier is the virtual chain tier
    /// @param rate is the virtual chain tier rate as determined by the subscription plan
    /// @param amount is the amount paid for the virtual chain initial subscription
    /// @param owner is the virtual chain owner. The owner may change virtual chain properties or ser config records
    /// @param isCertified indicates the virtual is run by the certified committee
    /// @param deploymentSubset indicates the code deployment subset the virtual chain uses such as main or canary
    /// @return vcId is the virtual chain ID allocated to the new virtual chain
    /// @return genRefTime is the virtual chain genesis reference time that determines the first block committee
    function createVC(string calldata name, string calldata tier, uint256 rate, uint256 amount, address owner, bool isCertified, string calldata deploymentSubset) external returns (uint vcId, uint genRefTime);

    /// Extends the subscription of an existing virtual chain.
    /// @dev Called only by: an authorized subscription plan contract
    /// @dev assumes that the msg.sender approved the amount prior to the call
    /// @param vcId is the virtual chain ID
    /// @param amount is the amount paid for the virtual chain subscription extension
    /// @param tier is the virtual chain tier, must match the tier selected in the virtual creation
    /// @param rate is the virtual chain tier rate as determined by the subscription plan
    /// @param payer is the address paying for the subscription extension
    function extendSubscription(uint256 vcId, uint256 amount, string calldata tier, uint256 rate, address payer) external;

    /// Sets a virtual chain config record
    /// @dev may be called only by the virtual chain owner
    /// @param vcId is the virtual chain ID
    /// @param key is the name of the config record to update
    /// @param value is the config record value
    function setVcConfigRecord(uint256 vcId, string calldata key, string calldata value) external /* onlyVcOwner */;

    /// Returns the value of a virtual chain config record
    /// @param vcId is the virtual chain ID
    /// @param key is the name of the config record to query
    /// @return value is the config record value
    function getVcConfigRecord(uint256 vcId, string calldata key) external view returns (string memory);

    /// Transfers a virtual chain ownership to a new owner 
    /// @dev may be called only by the current virtual chain owner
    /// @param vcId is the virtual chain ID
    /// @param owner is the address of the new owner
    function setVcOwner(uint256 vcId, address owner) external /* onlyVcOwner */;

    /// Returns the data of a virtual chain
    /// @dev does not include config records data
    /// @param vcId is the virtual chain ID
    /// @return name is the virtual chain name
    /// @return tier is the virtual chain tier
    /// @return rate is the virtual chain tier rate
    /// @return expiresAt the virtual chain subscription expiration time
    /// @return genRefTime is the virtual chain genesis reference time
    /// @return owner is the virtual chain owner. The owner may change virtual chain properties or ser config records
    /// @return deploymentSubset indicates the code deployment subset the virtual chain uses such as main or canary
    /// @return isCertified indicates the virtual is run by the certified committee
    function getVcData(uint256 vcId) external view returns (
        string memory name,
        string memory tier,
        uint256 rate,
        uint expiresAt,
        uint256 genRefTime,
        address owner,
        string memory deploymentSubset,
        bool isCertified
    );

    /*
     *   Governance functions
     */

    event SubscriberAdded(address subscriber);
    event SubscriberRemoved(address subscriber);
    event GenesisRefTimeDelayChanged(uint256 newGenesisRefTimeDelay);
    event MinimumInitialVcPaymentChanged(uint256 newMinimumInitialVcPayment);

    /// Adds a subscription plan contract to the authorized subscribers list
    /// @dev governance function called only by the functional manager
    /// @param addr is the address of the subscription plan contract
    function addSubscriber(address addr) external /* onlyFunctionalManager */;

    /// Removes a subscription plan contract to the authorized subscribers list
    /// @dev governance function called only by the functional manager
    /// @param addr is the address of the subscription plan contract
    function removeSubscriber(address addr) external /* onlyFunctionalManager */;

    /// Sets the delay between a virtual chain genesis reference time and the virtual chain creation time
    /// @dev governance function called only by the functional manager
    /// @dev the reference time delay allows the guardian to be ready with the virtual chain resources for the first block consensus
    /// @param newGenesisRefTimeDelay is the delay time in seconds
    function setGenesisRefTimeDelay(uint256 newGenesisRefTimeDelay) external /* onlyFunctionalManager */;

    /// Returns the genesis reference time delay
    /// @return genesisRefTimeDelay is the delay time in seconds
    function getGenesisRefTimeDelay() external view returns (uint256);

    /// Sets the minimum initial virtual chain payment 
    /// @dev Prevents abuse of the guardian nodes resources
    /// @param newMinimumInitialVcPayment is the minimum payment required for the initial subscription
    function setMinimumInitialVcPayment(uint256 newMinimumInitialVcPayment) external /* onlyFunctionalManager */;

    /// Returns the minimum initial virtual chain payment 
    /// @return minimumInitialVcPayment is the minimum payment required for the initial subscription
    function getMinimumInitialVcPayment() external view returns (uint256);

    /// Returns the settings of this contract
    /// @return genesisRefTimeDelay is the delay time in seconds
    /// @return minimumInitialVcPayment is the minimum payment required for the initial subscription
    function getSettings() external view returns(
        uint genesisRefTimeDelay,
        uint256 minimumInitialVcPayment
    );

    /// Imports virtual chain subscription from a previous subscriptions contract
    /// @dev governance function called only by the initialization admin during migration
    /// @dev if the migrated vcId is larger or equal to the next virtual chain ID to allocate, increment the next virtual chain ID
    /// @param vcId is the virtual chain ID to migrate
    /// @param previousSubscriptionsContract is the address of the previous subscription contract
    function importSubscription(uint vcId, ISubscriptions previousSubscriptionsContract) external /* onlyInitializationAdmin */;

}

// File: contracts/spec_interfaces/IProtocol.sol

pragma solidity 0.6.12;

/// @title Protocol upgrades contract interface
interface IProtocol {
    event ProtocolVersionChanged(string deploymentSubset, uint256 currentVersion, uint256 nextVersion, uint256 fromTimestamp);

    /*
     *   External functions
     */

    /// Checks whether a deployment subset exists 
    /// @param deploymentSubset is the name of the deployment subset to query
    /// @return exists is a bool indicating the deployment subset exists
    function deploymentSubsetExists(string calldata deploymentSubset) external view returns (bool);

    /// Returns the current protocol version for a given deployment subset to query
    /// @dev an unexisting deployment subset returns protocol version 0
    /// @param deploymentSubset is the name of the deployment subset
    /// @return currentVersion is the current protocol version of the deployment subset
    function getProtocolVersion(string calldata deploymentSubset) external view returns (uint256 currentVersion);

    /*
     *   Governance functions
     */

    /// Creates a new deployment subset
    /// @dev governance function called only by the functional manager
    /// @param deploymentSubset is the name of the new deployment subset
    /// @param initialProtocolVersion is the initial protocol version of the deployment subset
    function createDeploymentSubset(string calldata deploymentSubset, uint256 initialProtocolVersion) external /* onlyFunctionalManager */;


    /// Schedules a protocol version upgrade for the given deployment subset
    /// @dev governance function called only by the functional manager
    /// @param deploymentSubset is the name of the deployment subset
    /// @param nextVersion is the new protocol version to upgrade to, must be greater or equal to current version
    /// @param fromTimestamp is the time the new protocol version takes effect, must be in the future
    function setProtocolVersion(string calldata deploymentSubset, uint256 nextVersion, uint256 fromTimestamp) external /* onlyFunctionalManager */;
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

// File: contracts/Subscriptions.sol

pragma solidity 0.6.12;







/// @title Subscriptions contract
contract Subscriptions is ISubscriptions, ManagedContract {
    using SafeMath for uint256;

    struct VirtualChain {
        string name;
        string tier;
        uint256 rate;
        uint expiresAt;
        uint256 genRefTime;
        address owner;
        string deploymentSubset;
        bool isCertified;
    }

    mapping(uint => mapping(string => string)) configRecords;
    mapping(address => bool) public authorizedSubscribers;
    mapping(uint => VirtualChain) virtualChains;

    uint public nextVcId;

    struct Settings {
        uint genesisRefTimeDelay;
        uint256 minimumInitialVcPayment;
    }
    Settings settings;

    IERC20 public erc20;

    /// Constructor
    /// @dev the next allocated virtual chain id on createVC is the next ID after the maximum between the migrated virtual chains and the initialNextVcId
    /// @param _contractRegistry is the contract registry address
    /// @param _registryAdmin is the registry admin address
    /// @param _erc20 is the token used for virtual chains fees
    /// @param _genesisRefTimeDelay is the initial genesis virtual chain reference time delay from the creation time
    /// @param _minimumInitialVcPayment is the minimum payment required for the initial subscription
    /// @param vcIds is a list of virtual chain ids to migrate from the previous subscription contract
    /// @param initialNextVcId is the initial virtual chain id
    /// @param previousSubscriptionsContract is the previous subscription contract to migrate virtual chains from
    constructor (IContractRegistry _contractRegistry, address _registryAdmin, IERC20 _erc20, uint256 _genesisRefTimeDelay, uint256 _minimumInitialVcPayment, uint[] memory vcIds, uint256 initialNextVcId, ISubscriptions previousSubscriptionsContract) ManagedContract(_contractRegistry, _registryAdmin) public {
        require(address(_erc20) != address(0), "erc20 must not be 0");

        erc20 = _erc20;
        nextVcId = initialNextVcId;

        setGenesisRefTimeDelay(_genesisRefTimeDelay);
        setMinimumInitialVcPayment(_minimumInitialVcPayment);

        for (uint i = 0; i < vcIds.length; i++) {
            importSubscription(vcIds[i], previousSubscriptionsContract);
        }
    }

    modifier onlySubscriber {
        require(authorizedSubscribers[msg.sender], "sender must be an authorized subscriber");

        _;
    }

    /*
     *   External functions
     */

    /// Creates a new virtual chain
    /// @dev Called only by: an authorized subscription plan contract
    /// @dev the initial amount paid for the virtual chain must be large than minimumInitialVcPayment
    /// @param name is the virtual chain name
    /// @param tier is the virtual chain tier
    /// @param rate is the virtual chain tier rate as determined by the subscription plan
    /// @param amount is the amount paid for the virtual chain initial subscription
    /// @param owner is the virtual chain owner. The owner may change virtual chain properties or ser config records
    /// @param isCertified indicates the virtual is run by the certified committee
    /// @param deploymentSubset indicates the code deployment subset the virtual chain uses such as main or canary
    /// @return vcId is the virtual chain ID allocated to the new virtual chain
    /// @return genRefTime is the virtual chain genesis reference time that determines the first block committee
    function createVC(string calldata name, string calldata tier, uint256 rate, uint256 amount, address owner, bool isCertified, string calldata deploymentSubset) external override onlySubscriber onlyWhenActive returns (uint vcId, uint genRefTime) {
        require(owner != address(0), "vc owner cannot be the zero address");
        require(protocolContract.deploymentSubsetExists(deploymentSubset) == true, "No such deployment subset");
        require(amount >= settings.minimumInitialVcPayment, "initial VC payment must be at least minimumInitialVcPayment");

        vcId = nextVcId++;
        genRefTime = now + settings.genesisRefTimeDelay;
        VirtualChain memory vc = VirtualChain({
            name: name,
            expiresAt: block.timestamp,
            genRefTime: genRefTime,
            owner: owner,
            tier: tier,
            rate: rate,
            deploymentSubset: deploymentSubset,
            isCertified: isCertified
            });
        virtualChains[vcId] = vc;

        emit VcCreated(vcId);

        _extendSubscription(vcId, amount, tier, rate, owner);
    }

    /// Extends the subscription of an existing virtual chain.
    /// @dev Called only by: an authorized subscription plan contract
    /// @param vcId is the virtual chain ID
    /// @param amount is the amount paid for the virtual chain subscription extension
    /// @param tier is the virtual chain tier, must match the tier selected in the virtual creation
    /// @param rate is the virtual chain tier rate as determined by the subscription plan
    /// @param payer is the address paying for the subscription extension
    function extendSubscription(uint256 vcId, uint256 amount, string calldata tier, uint256 rate, address payer) external override onlySubscriber onlyWhenActive {
        _extendSubscription(vcId, amount, tier, rate, payer);
    }

    /// Sets a virtual chain config record
    /// @dev may be called only by the virtual chain owner
    /// @param vcId is the virtual chain ID
    /// @param key is the name of the config record to update
    /// @param value is the config record value
    function setVcConfigRecord(uint256 vcId, string calldata key, string calldata value) external override onlyWhenActive {
        require(msg.sender == virtualChains[vcId].owner, "only vc owner can set a vc config record");
        configRecords[vcId][key] = value;
        emit VcConfigRecordChanged(vcId, key, value);
    }

    /// Returns the value of a virtual chain config record
    /// @param vcId is the virtual chain ID
    /// @param key is the name of the config record to query
    /// @return value is the config record value
    function getVcConfigRecord(uint256 vcId, string calldata key) external override view returns (string memory) {
        return configRecords[vcId][key];
    }

    /// Transfers a virtual chain ownership to a new owner
    /// @dev may be called only by the current virtual chain owner
    /// @param vcId is the virtual chain ID
    /// @param owner is the address of the new owner
    function setVcOwner(uint256 vcId, address owner) external override onlyWhenActive {
        require(msg.sender == virtualChains[vcId].owner, "only the vc owner can transfer ownership");
        require(owner != address(0), "cannot transfer ownership to the zero address");

        virtualChains[vcId].owner = owner;
        emit VcOwnerChanged(vcId, msg.sender, owner);
    }

    /// Returns the data of a virtual chain
    /// @dev does not include config records data
    /// @param vcId is the virtual chain ID
    /// @return name is the virtual chain name
    /// @return tier is the virtual chain tier
    /// @return rate is the virtual chain tier rate
    /// @return expiresAt the virtual chain subscription expiration time
    /// @return genRefTime is the virtual chain genesis reference time
    /// @return owner is the virtual chain owner. The owner may change virtual chain properties or ser config records
    /// @return deploymentSubset indicates the code deployment subset the virtual chain uses such as main or canary
    /// @return isCertified indicates the virtual is run by the certified committee
    function getVcData(uint256 vcId) external override view returns (
        string memory name,
        string memory tier,
        uint256 rate,
        uint expiresAt,
        uint256 genRefTime,
        address owner,
        string memory deploymentSubset,
        bool isCertified
    ) {
        VirtualChain memory vc = virtualChains[vcId];
        name = vc.name;
        tier = vc.tier;
        rate = vc.rate;
        expiresAt = vc.expiresAt;
        genRefTime = vc.genRefTime;
        owner = vc.owner;
        deploymentSubset = vc.deploymentSubset;
        isCertified = vc.isCertified;
    }

    /*
     *   Governance functions
     */

    /// Adds a subscription plan contract to the authorized subscribers list
    /// @dev governance function called only by the functional manager
    /// @param addr is the address of the subscription plan contract
    function addSubscriber(address addr) external override onlyFunctionalManager {
        authorizedSubscribers[addr] = true;
        emit SubscriberAdded(addr);
    }

    /// Removes a subscription plan contract to the authorized subscribers list
    /// @dev governance function called only by the functional manager
    /// @param addr is the address of the subscription plan contract
    function removeSubscriber(address addr) external override onlyFunctionalManager {
        require(authorizedSubscribers[addr], "given add is not an authorized subscriber");

        authorizedSubscribers[addr] = false;
        emit SubscriberRemoved(addr);
    }

    /// Sets the delay between a virtual chain genesis reference time and the virtual chain creation time
    /// @dev governance function called only by the functional manager
    /// @dev the reference time delay allows the guardian to be ready with the virtual chain resources for the first block consensus
    /// @param newGenesisRefTimeDelay is the delay time in seconds
    function setGenesisRefTimeDelay(uint256 newGenesisRefTimeDelay) public override onlyFunctionalManager {
        settings.genesisRefTimeDelay = newGenesisRefTimeDelay;
        emit GenesisRefTimeDelayChanged(newGenesisRefTimeDelay);
    }

    /// Returns the genesis reference time delay
    /// @return genesisRefTimeDelay is the delay time in seconds
    function getGenesisRefTimeDelay() external override view returns (uint) {
        return settings.genesisRefTimeDelay;
    }

    /// Sets the minimum initial virtual chain payment
    /// @dev Prevents abuse of the guardian nodes resources
    /// @param newMinimumInitialVcPayment is the minimum payment required for the initial subscription
    function setMinimumInitialVcPayment(uint256 newMinimumInitialVcPayment) public override onlyFunctionalManager {
        settings.minimumInitialVcPayment = newMinimumInitialVcPayment;
        emit MinimumInitialVcPaymentChanged(newMinimumInitialVcPayment);
    }

    /// Returns the minimum initial virtual chain payment
    /// @return minimumInitialVcPayment is the minimum payment required for the initial subscription
    function getMinimumInitialVcPayment() external override view returns (uint) {
        return settings.minimumInitialVcPayment;
    }

    /// Returns the settings of this contract
    /// @return genesisRefTimeDelay is the delay time in seconds
    /// @return minimumInitialVcPayment is the minimum payment required for the initial subscription
    function getSettings() external override view returns(
        uint genesisRefTimeDelay,
        uint256 minimumInitialVcPayment
    ) {
        Settings memory _settings = settings;
        genesisRefTimeDelay = _settings.genesisRefTimeDelay;
        minimumInitialVcPayment = _settings.minimumInitialVcPayment;
    }

    /// Imports virtual chain subscription from a previous subscriptions contract
    /// @dev governance function called only by the initialization admin during migration
    /// @dev if the migrated vcId is larger or equal to the next virtual chain ID to allocate, increment the next virtual chain ID
    /// @param vcId is the virtual chain ID to migrate
    /// @param previousSubscriptionsContract is the address of the previous subscription contract
    function importSubscription(uint vcId, ISubscriptions previousSubscriptionsContract) public override onlyInitializationAdmin {
        require(virtualChains[vcId].owner == address(0), "the vcId already exists");

        (string memory name,
        string memory tier,
        uint256 rate,
        uint expiresAt,
        uint256 genRefTime,
        address owner,
        string memory deploymentSubset,
        bool isCertified) = previousSubscriptionsContract.getVcData(vcId);

        virtualChains[vcId] = VirtualChain({
            name: name,
            tier: tier,
            rate: rate,
            expiresAt: expiresAt,
            genRefTime: genRefTime,
            owner: owner,
            deploymentSubset: deploymentSubset,
            isCertified: isCertified
            });

        if (vcId >= nextVcId) {
            nextVcId = vcId + 1;
        }

        emit SubscriptionChanged(vcId, owner, name, genRefTime, tier, rate, expiresAt, isCertified, deploymentSubset);
    }

    /*
    * Private functions
    */

    /// Extends the subscription of an existing virtual chain.
    /// @dev used by createVC and extendSubscription functions for subscription payment
    /// @dev assumes that the msg.sender approved the amount prior to the call
    /// @param vcId is the virtual chain ID
    /// @param amount is the amount paid for the virtual chain subscription extension
    /// @param tier is the virtual chain tier, must match the tier selected in the virtual creation
    /// @param rate is the virtual chain tier rate as determined by the subscription plan
    /// @param payer is the address paying for the subscription extension
    function _extendSubscription(uint256 vcId, uint256 amount, string memory tier, uint256 rate, address payer) private {
        VirtualChain memory vc = virtualChains[vcId];
        require(vc.genRefTime != 0, "vc does not exist");
        require(keccak256(bytes(tier)) == keccak256(bytes(virtualChains[vcId].tier)), "given tier must match the VC tier");

        IFeesWallet feesWallet = vc.isCertified ? certifiedFeesWallet : generalFeesWallet;
        require(erc20.transferFrom(msg.sender, address(this), amount), "failed to transfer subscription fees from subscriber to subscriptions");
        require(erc20.approve(address(feesWallet), amount), "failed to approve rewards to acquire subscription fees");

        uint fromTimestamp = vc.expiresAt > now ? vc.expiresAt : now;
        feesWallet.fillFeeBuckets(amount, rate, fromTimestamp);

        vc.expiresAt = fromTimestamp.add(amount.mul(30 days).div(rate));
        vc.rate = rate;

        // commit new expiration timestamp to storage
        virtualChains[vcId].expiresAt = vc.expiresAt;
        virtualChains[vcId].rate = vc.rate;

        emit SubscriptionChanged(vcId, vc.owner, vc.name, vc.genRefTime, vc.tier, vc.rate, vc.expiresAt, vc.isCertified, vc.deploymentSubset);
        emit Payment(vcId, payer, amount, vc.tier, vc.rate);
    }

    /*
     * Contracts topology / registry interface
     */

    IFeesWallet generalFeesWallet;
    IFeesWallet certifiedFeesWallet;
    IProtocol protocolContract;

    /// Refreshes the address of the other contracts the contract interacts with
    /// @dev called by the registry contract upon an update of a contract in the registry
    function refreshContracts() external override {
        generalFeesWallet = IFeesWallet(getGeneralFeesWallet());
        certifiedFeesWallet = IFeesWallet(getCertifiedFeesWallet());
        protocolContract = IProtocol(getProtocolContract());
    }
}