// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./IGuardiansRegistration.sol";
import "./IElections.sol";
import "./ManagedContract.sol";

contract GuardiansRegistration is IGuardiansRegistration, ManagedContract {

	struct Guardian {
		address orbsAddr;
		bytes4 ip;
		uint32 registrationTime;
		uint32 lastUpdateTime;
		string name;
		string website;
	}
	mapping(address => Guardian) guardians;
	mapping(address => address) orbsAddressToGuardianAddress;
	mapping(bytes4 => address) public ipToGuardian;
	mapping(address => mapping(string => string)) guardianMetadata;

	constructor(IContractRegistry _contractRegistry, address _registryAdmin) ManagedContract(_contractRegistry, _registryAdmin) public {}

	modifier onlyRegisteredGuardian {
		require(isRegistered(msg.sender), "Guardian is not registered");

		_;
	}

	/*
     * External methods
     */

    /// @dev Called by a participant who wishes to register as a guardian
	function registerGuardian(bytes4 ip, address orbsAddr, string calldata name, string calldata website) external override onlyWhenActive {
		require(!isRegistered(msg.sender), "registerGuardian: Guardian is already registered");

		guardians[msg.sender].registrationTime = uint32(block.timestamp);
		emit GuardianRegistered(msg.sender);

		_updateGuardian(msg.sender, ip, orbsAddr, name, website);
	}

    /// @dev Called by a participant who wishes to update its properties
	function updateGuardian(bytes4 ip, address orbsAddr, string calldata name, string calldata website) external override onlyRegisteredGuardian onlyWhenActive {
		_updateGuardian(msg.sender, ip, orbsAddr, name, website);
	}

	function updateGuardianIp(bytes4 ip) external override onlyWhenActive {
		address guardianAddr = resolveGuardianAddress(msg.sender);
		Guardian memory data = guardians[guardianAddr];
		_updateGuardian(guardianAddr, ip, data.orbsAddr, data.name, data.website);
	}

    /// @dev Called by a guardian to update additional guardian metadata properties.
    function setMetadata(string calldata key, string calldata value) external override onlyRegisteredGuardian onlyWhenActive {
		_setMetadata(msg.sender, key, value);
	}

	function getMetadata(address guardian, string calldata key) external override view returns (string memory) {
		return guardianMetadata[guardian][key];
	}

	/// @dev Called by a participant who wishes to unregister
	function unregisterGuardian() external override onlyRegisteredGuardian onlyWhenActive {
		delete orbsAddressToGuardianAddress[guardians[msg.sender].orbsAddr];
		delete ipToGuardian[guardians[msg.sender].ip];
		Guardian memory guardian = guardians[msg.sender];
		delete guardians[msg.sender];

		electionsContract.guardianUnregistered(msg.sender);
		emit GuardianDataUpdated(msg.sender, false, guardian.ip, guardian.orbsAddr, guardian.name, guardian.website);
		emit GuardianUnregistered(msg.sender);
	}

    /// @dev Returns a guardian's data
	function getGuardianData(address guardian) external override view returns (bytes4 ip, address orbsAddr, string memory name, string memory website, uint registrationTime, uint lastUpdateTime) {
		Guardian memory v = guardians[guardian];
		return (v.ip, v.orbsAddr, v.name, v.website, v.registrationTime, v.lastUpdateTime);
	}

	function getGuardiansOrbsAddress(address[] calldata guardianAddrs) external override view returns (address[] memory orbsAddrs) {
		orbsAddrs = new address[](guardianAddrs.length);
		for (uint i = 0; i < guardianAddrs.length; i++) {
			orbsAddrs[i] = guardians[guardianAddrs[i]].orbsAddr;
		}
	}

	function getGuardianIp(address guardian) external override view returns (bytes4 ip) {
		return guardians[guardian].ip;
	}

	function getGuardianIps(address[] calldata guardianAddrs) external override view returns (bytes4[] memory ips) {
		ips = new bytes4[](guardianAddrs.length);
		for (uint i = 0; i < guardianAddrs.length; i++) {
			ips[i] = guardians[guardianAddrs[i]].ip;
		}
	}

	function isRegistered(address guardian) public override view returns (bool) {
		return guardians[guardian].registrationTime != 0;
	}

	function resolveGuardianAddress(address guardianOrOrbsAddress) public override view returns (address guardianAddress) {
		if (isRegistered(guardianOrOrbsAddress)) {
			guardianAddress = guardianOrOrbsAddress;
		} else {
			guardianAddress = orbsAddressToGuardianAddress[guardianOrOrbsAddress];
		}

		require(guardianAddress != address(0), "Cannot resolve address");
	}

	/// @dev Translates a list guardians Orbs addresses to Ethereum addresses
	function getGuardianAddresses(address[] calldata orbsAddrs) external override view returns (address[] memory guardianAddrs) {
		guardianAddrs = new address[](orbsAddrs.length);
		for (uint i = 0; i < orbsAddrs.length; i++) {
			guardianAddrs[i] = orbsAddressToGuardianAddress[orbsAddrs[i]];
		}
	}

	/*
	 * Governance
	 */

	function migrateGuardians(address[] calldata guardiansToMigrate, IGuardiansRegistration previousContract) external override onlyInitializationAdmin {
		require(previousContract != IGuardiansRegistration(0), "previousContract must not be the zero address");

		for (uint i = 0; i < guardiansToMigrate.length; i++) {
			require(guardiansToMigrate[i] != address(0), "guardian must not be the zero address");
			migrateGuardianData(previousContract, guardiansToMigrate[i]);
			migrateGuardianMetadata(previousContract, guardiansToMigrate[i]);
		}
	}

	/*
	 * Private methods
	 */

	function _updateGuardian(address guardianAddr, bytes4 ip, address orbsAddr, string memory name, string memory website) private {
		require(orbsAddr != address(0), "orbs address must be non zero");
		require(orbsAddr != guardianAddr, "orbs address must be different than the guardian address");
		require(!isRegistered(orbsAddr), "orbs address must not be a guardian address of a registered guardian");
		require(bytes(name).length != 0, "name must be given");

		delete ipToGuardian[guardians[guardianAddr].ip];
		require(ipToGuardian[ip] == address(0), "ip is already in use");
		ipToGuardian[ip] = guardianAddr;

		delete orbsAddressToGuardianAddress[guardians[guardianAddr].orbsAddr];
		require(orbsAddressToGuardianAddress[orbsAddr] == address(0), "orbs address is already in use");
		orbsAddressToGuardianAddress[orbsAddr] = guardianAddr;

		guardians[guardianAddr].orbsAddr = orbsAddr;
		guardians[guardianAddr].ip = ip;
		guardians[guardianAddr].name = name;
		guardians[guardianAddr].website = website;
		guardians[guardianAddr].lastUpdateTime = uint32(block.timestamp);

        emit GuardianDataUpdated(guardianAddr, true, ip, orbsAddr, name, website);
    }

	function _setMetadata(address guardian, string memory key, string memory value) private {
		string memory oldValue = guardianMetadata[guardian][key];
		guardianMetadata[guardian][key] = value;
		emit GuardianMetadataChanged(guardian, key, value, oldValue);
	}

	function migrateGuardianData(IGuardiansRegistration previousContract, address guardianAddress) private {
		(bytes4 ip, address orbsAddr, string memory name, string memory website, uint registrationTime, uint lastUpdateTime) = previousContract.getGuardianData(guardianAddress);
		guardians[guardianAddress] = Guardian({
			orbsAddr: orbsAddr,
			ip: ip,
			name: name,
			website: website,
			registrationTime: uint32(registrationTime),
			lastUpdateTime: uint32(lastUpdateTime)
		});
		orbsAddressToGuardianAddress[orbsAddr] = guardianAddress;
		ipToGuardian[ip] = guardianAddress;

		emit GuardianDataUpdated(guardianAddress, true, ip, orbsAddr, name, website);
	}

	string public constant ID_FORM_URL_METADATA_KEY = "ID_FORM_URL";
	function migrateGuardianMetadata(IGuardiansRegistration previousContract, address guardianAddress) private {
		string memory rewardsFreqMetadata = previousContract.getMetadata(guardianAddress, ID_FORM_URL_METADATA_KEY);
		if (bytes(rewardsFreqMetadata).length > 0) {
			_setMetadata(guardianAddress, ID_FORM_URL_METADATA_KEY, rewardsFreqMetadata);
		}
	}

	/*
     * Contracts topology / registry interface
     */

	IElections electionsContract;
	function refreshContracts() external override {
		electionsContract = IElections(getElectionsContract());
	}

}
