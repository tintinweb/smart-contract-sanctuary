// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract BoxV2 {
	uint256 public val;

	// function initialize(uint _val) external{
	// val = _val;
	// }

	function inc() external {
		unchecked {
			val++;
		}
	}
}