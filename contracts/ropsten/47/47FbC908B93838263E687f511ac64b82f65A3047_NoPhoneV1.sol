// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract NoPhoneV1 {
	uint public val;

	function initialize(uint _val) external {
		val = _val;
	}
}