/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Hasher {
	function testHasher(uint256 in_xL, uint256 in_xR) public pure returns (uint256) {
		return in_xL + in_xR;
	}
}

contract TestLib {
	function test0(uint256 _left, uint256 _right) public pure returns (uint256) {
		return Hasher.testHasher(_left, _right);
	}
}