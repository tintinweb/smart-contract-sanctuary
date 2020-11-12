// SPDX-License-Identifier: UNLICENSED

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
