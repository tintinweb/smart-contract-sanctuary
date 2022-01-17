// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the CallerAuthenticator using Schnorr protocol
 */
interface CallerAuthenticatorInterface {
    /**
     * @dev Returns the token ID if authenticated. Otherwise, it reverts.
     */
    function processAuthentication(uint256 preprocessed_id, uint256 p1, uint256 p2, uint256 s, uint256 e) external returns (uint256);
}


contract TestContract {
	event TokenIDReveal(uint256 id);
	CallerAuthenticatorInterface private authenticator;
	constructor () {
		authenticator = CallerAuthenticatorInterface(0x51655f7d39F24ff0a0e03726220E6CFD99B17516);
	}

	function test(uint256 preprocessed_id, uint256 p1, uint256 p2, uint256 s, uint256 e) public returns (uint256) {
		uint256 tokenID = authenticator.processAuthentication(preprocessed_id, p1, p2, s, e);
		emit TokenIDReveal(tokenID);
		return tokenID;
	}
}