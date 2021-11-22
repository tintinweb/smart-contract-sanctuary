/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

contract Implementation {
	uint256 private value;

	function setValue(uint256 newValue) public {
		value = newValue;
	}

	function getValue() public view returns (uint256) {
		return value;
	}

	function version() public pure returns (string memory) {
		return "2.0.0";
	}
}