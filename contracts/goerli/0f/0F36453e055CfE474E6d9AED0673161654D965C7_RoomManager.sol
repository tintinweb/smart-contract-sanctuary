/**
 *Submitted for verification at Etherscan.io on 2021-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.0;

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract RoomManager {
	mapping (address => uint) enabledManagers;

	event ManagerUpdated(address indexed _from, uint256 _value);
	event ShowLength(uint256 alen);

	constructor() public {
		enabledManagers[msg.sender] = 1;
	}

	function setManager(address newManager) public {
		enabledManagers[newManager] = 2;
		emit ManagerUpdated(newManager, 1);
	}

	function removeManager(address toRemove) public {
		enabledManagers[toRemove] = 0;
		emit ManagerUpdated(toRemove, 0); 
	}

	function testLength() public returns (uint256){
		int256[] memory winners = new int256[](3);
		emit ShowLength(winners.length);
	}

	function isEnabled(address addr) public view returns(uint){
		return enabledManagers[addr];
	}
}