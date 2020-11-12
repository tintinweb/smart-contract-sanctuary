// SPDX-License-Identifier: UNLICENSED

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
