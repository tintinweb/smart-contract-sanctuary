/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

contract IsAmbireAccount {
	// This bytecode is the minimal proxy bytecode defined here: https://eips.ethereum.org/EIPS/eip-1167
	// With this base identity: 0x2A2b85EB1054d6f0c6c2E37dA05eD3E5feA684EF (can be seen towards the middle of the bytecode)
	bytes32 public constant HASH = keccak256(hex"363d3d373d3d3d363d732a2b85eb1054d6f0c6c2e37da05ed3e5fea684ef5af43d82803e903d91602b57fd5bf3");
	function isAmbireAccount(address addr) external view returns (bool) {
		return keccak256(addr.code) == HASH;
	}
}