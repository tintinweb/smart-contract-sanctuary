// SPDX-License-Identifier: UNLICENSED

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
	function removeMember(address addr) external returns (bool memberRemoved, uint removedMemberEffectiveStake, bool removedMemberCertified)/* onlyElectionContract */;

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
}
