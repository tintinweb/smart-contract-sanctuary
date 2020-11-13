// File: contracts/spec_interfaces/IContractRegistry.sol

// SPDX-License-Identifier: MIT

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

// File: contracts/spec_interfaces/IManagedContract.sol

pragma solidity 0.6.12;

/// @title managed contract interface, used by the contracts registry to notify the contract on updates
interface IManagedContract /* is ILockable, IContractRegistryAccessor, Initializable */ {

    /// Refreshes the address of the other contracts the contract interacts with
    /// @dev called by the registry contract upon an update of a contract in the registry
    function refreshContracts() external;

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

// File: contracts/ContractRegistry.sol

pragma solidity 0.6.12;







/// @title Contract registry
/// @dev The contract registry holds Orbs PoS contracts and managers lists
/// @dev The contract registry updates the managed contracts on changes in the contract list
/// @dev Governance functions restricted to managers access the registry to retrieve the manager address 
/// @dev The contract registry represents the source of truth for Orbs Ethereum contracts 
/// @dev By tracking the registry events or query before interaction, one can access the up to date contracts 
contract ContractRegistry is IContractRegistry, Initializable, WithClaimableRegistryManagement {

	address previousContractRegistry;
	mapping(string => address) contracts;
	address[] managedContractAddresses;
	mapping(string => address) managers;

    /// Constructor
    /// @param _previousContractRegistry is the previous contract registry address
    /// @param registryAdmin is the registry contract admin address
	constructor(address _previousContractRegistry, address registryAdmin) public {
		previousContractRegistry = _previousContractRegistry;
		_transferRegistryManagement(registryAdmin);
	}

	modifier onlyAdmin {
		require(msg.sender == registryAdmin() || msg.sender == initializationAdmin(), "sender is not an admin (registryAdmin or initializationAdmin when initialization in progress)");

		_;
	}

	modifier onlyAdminOrMigrationManager {
		require(msg.sender == registryAdmin() || msg.sender == initializationAdmin() || msg.sender == managers["migrationManager"], "sender is not an admin (registryAdmin or initializationAdmin when initialization in progress) and not the migration manager");

		_;
	}

	/*
	* External functions
	*/

    /// Updates the contracts address and emits a corresponding event
    /// @dev governance function called only by the migrationManager or registryAdmin
    /// @param contractName is the contract name, used to identify it
    /// @param addr is the contract updated address
    /// @param managedContract indicates whether the contract is managed by the registry and notified on changes
	function setContract(string calldata contractName, address addr, bool managedContract) external override onlyAdminOrMigrationManager {
		require(!managedContract || addr != address(0), "managed contract may not have address(0)");
		removeManagedContract(contracts[contractName]);
		contracts[contractName] = addr;
		if (managedContract) {
			addManagedContract(addr);
		}
		emit ContractAddressUpdated(contractName, addr, managedContract);
		notifyOnContractsChange();
	}

    /// Returns the current address of the given contracts
    /// @param contractName is the contract name, used to identify it
    /// @return addr is the contract updated address
	function getContract(string calldata contractName) external override view returns (address) {
		return contracts[contractName];
	}

    /// Returns the list of contract addresses managed by the registry
    /// @dev Managed contracts are updated on changes in the registry contracts addresses 
    /// @return addrs is the list of managed contracts
	function getManagedContracts() external override view returns (address[] memory) {
		return managedContractAddresses;
	}

    /// Locks all the managed contracts 
    /// @dev governance function called only by the migrationManager or registryAdmin
    /// @dev When set all onlyWhenActive functions will revert
	function lockContracts() external override onlyAdminOrMigrationManager {
		for (uint i = 0; i < managedContractAddresses.length; i++) {
			ILockable(managedContractAddresses[i]).lock();
		}
	}

    /// Unlocks all the managed contracts 
    /// @dev governance function called only by the migrationManager or registryAdmin
	function unlockContracts() external override onlyAdminOrMigrationManager {
		for (uint i = 0; i < managedContractAddresses.length; i++) {
			ILockable(managedContractAddresses[i]).unlock();
		}
	}

    /// Updates a manager address and emits a corresponding event
    /// @dev governance function called only by the registryAdmin
    /// @dev the managers list is a flexible list of role to the manager's address
    /// @param role is the managers' role name, for example "functionalManager"
    /// @param manager is the manager updated address
	function setManager(string calldata role, address manager) external override onlyAdmin {
		managers[role] = manager;
		emit ManagerChanged(role, manager);
	}

    /// Returns the current address of the given manager
    /// @param role is the manager name, used to identify it
    /// @return addr is the manager updated address
	function getManager(string calldata role) external override view returns (address) {
		return managers[role];
	}

    /// Sets a new contract registry to migrate to
    /// @dev governance function called only by the registryAdmin
    /// @dev updates the registry address record in all the managed contracts
    /// @dev by tracking the emitted ContractRegistryUpdated, tools can track the up to date contracts
    /// @param newRegistry is the new registry contract 
	function setNewContractRegistry(IContractRegistry newRegistry) external override onlyAdmin {
		for (uint i = 0; i < managedContractAddresses.length; i++) {
			IContractRegistryAccessor(managedContractAddresses[i]).setContractRegistry(newRegistry);
			IManagedContract(managedContractAddresses[i]).refreshContracts();
		}
		emit ContractRegistryUpdated(address(newRegistry));
	}

    /// Returns the previous contract registry address 
    /// @dev used when the setting the contract as a new registry to assure a valid registry
    /// @return previousContractRegistry is the previous contract registry
	function getPreviousContractRegistry() external override view returns (address) {
		return previousContractRegistry;
	}

	/*
	* Private methods
	*/

    /// Notifies the managed contracts on a change in a contract address
    /// @dev invokes the refreshContracts() function in each contract that queries the relevant contract addresses
	function notifyOnContractsChange() private {
		for (uint i = 0; i < managedContractAddresses.length; i++) {
			IManagedContract(managedContractAddresses[i]).refreshContracts();
		}
	}

    /// Adds a new managed contract address to the managed contracts list
	function addManagedContract(address addr) private {
		managedContractAddresses.push(addr);
	}

    /// Removes a managed contract address from the managed contracts list
	function removeManagedContract(address addr) private {
		uint length = managedContractAddresses.length;
		for (uint i = 0; i < length; i++) {
			if (managedContractAddresses[i] == addr) {
				if (i != length - 1) {
					managedContractAddresses[i] = managedContractAddresses[length-1];
				}
				managedContractAddresses.pop();
				length--;
			}
		}
	}

}