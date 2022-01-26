/**
 *Submitted for verification at snowtrace.io on 2022-01-26
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Migrations {
	address public owner;
	uint public lastCompletedMigration;

	modifier restricted() {
		if (msg.sender == owner) _;
	}

	constructor() {
		owner = msg.sender;
	}

	/**
	 * @notice set lastCompletedMigration variable
	 * @param completed - id of the desired migration level
	 */
	function setCompleted(uint completed) external restricted {
		lastCompletedMigration = completed;
	}

	function upgrade(address newAddress) external restricted {
		Migrations upgraded = Migrations(newAddress);
		upgraded.setCompleted(lastCompletedMigration);
	}
}