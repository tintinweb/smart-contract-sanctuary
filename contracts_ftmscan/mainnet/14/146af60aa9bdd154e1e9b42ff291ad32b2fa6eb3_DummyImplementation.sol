/**
 *Submitted for verification at FtmScan.com on 2021-12-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract DummyImplementation {
	uint256 private value;

	// Emitted when the stored value changes
	event ValueChanged(uint256 newValue);

	// Stores a new value in the contract
	function store(uint256 newValue) public {
		value = newValue;
		emit ValueChanged(newValue);
	}

	// Reads the last stored value
	function retrieve() public view returns (uint256) {
		return value;
	}
}