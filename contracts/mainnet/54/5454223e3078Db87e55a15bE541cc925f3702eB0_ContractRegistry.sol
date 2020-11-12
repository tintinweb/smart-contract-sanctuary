// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;
import "./IContractRegistry.sol";
import "./ILockable.sol";
import "./IContractRegistryListener.sol";
import "./WithClaimableRegistryManagement.sol";
import "./Initializable.sol";

contract ContractRegistry is IContractRegistry, Initializable, WithClaimableRegistryManagement {

	address previousContractRegistry;
	mapping(string => address) contracts;
	address[] managedContractAddresses;
	mapping(string => address) managers;

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

	function getContract(string calldata contractName) external override view returns (address) {
		return contracts[contractName];
	}

	function lockContracts() external override onlyAdminOrMigrationManager {
		for (uint i = 0; i < managedContractAddresses.length; i++) {
			ILockable(managedContractAddresses[i]).lock();
		}
	}

	function unlockContracts() external override onlyAdminOrMigrationManager {
		for (uint i = 0; i < managedContractAddresses.length; i++) {
			ILockable(managedContractAddresses[i]).unlock();
		}
	}

	function getManagedContracts() external override view returns (address[] memory) {
		return managedContractAddresses;
	}

	function setManager(string calldata role, address manager) external override onlyAdmin {
		managers[role] = manager;
		emit ManagerChanged(role, manager);
	}

	function getManager(string calldata role) external override view returns (address) {
		return managers[role];
	}

	function setNewContractRegistry(IContractRegistry newRegistry) external override onlyAdmin {
		for (uint i = 0; i < managedContractAddresses.length; i++) {
			IContractRegistryListener(managedContractAddresses[i]).setContractRegistry(newRegistry);
			IContractRegistryListener(managedContractAddresses[i]).refreshContracts();
		}
		emit ContractRegistryUpdated(address(newRegistry));
	}

	function getPreviousContractRegistry() external override view returns (address) {
		return previousContractRegistry;
	}

	/*
	* Private methods
	*/

	function notifyOnContractsChange() private {
		for (uint i = 0; i < managedContractAddresses.length; i++) {
			IContractRegistryListener(managedContractAddresses[i]).refreshContracts();
		}
	}

	function addManagedContract(address addr) private {
		managedContractAddresses.push(addr);
	}

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
