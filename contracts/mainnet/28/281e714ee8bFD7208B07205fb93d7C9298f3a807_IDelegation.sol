// SPDX-License-Identifier: UNLICENSED

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
