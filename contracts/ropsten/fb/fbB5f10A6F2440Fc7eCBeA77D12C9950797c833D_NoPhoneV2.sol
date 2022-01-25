// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract NoPhoneV2 {
	uint public val;

	function inc(uint _val) external {
		val += _val;
	}
}