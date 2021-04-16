/**
 *Submitted for verification at Etherscan.io on 2021-04-16
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

	constructor() public {
		enabledManagers[msg.sender] = 1;
	}

	function addToRoom(address newUser) public {
		enabledManagers[newUser] = 3;
		emit ManagerUpdated(newUser, 1);
	}

	function removeFromRoom(address toRemove) public {
		enabledManagers[toRemove] = 0;
		emit ManagerUpdated(toRemove, 0); 
	}

	function inRoom(address addr) public view returns(uint){
		return enabledManagers[addr];
	}
}