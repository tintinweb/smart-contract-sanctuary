/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

contract Lottery {

	// manager for creator of Lottery
	// player for participant of Lottery
	// remember to make sure the address is payable
	address payable public manager;
	address payable[] public players;

	// If pass in address of the creator as an argument, it is not so programmatic.
	// So use global variable "msg" to get data, sender, gas, and value
	constructor() {

		// cast address to payable
		manager = payable(msg.sender);
	}

	// require minimum payment using modifier and require.
	// The function body is inserted where the special symbol "_;" appears in the definition of a modifier.
	modifier validEntrance {
		require(msg.value >= .01 ether);
	    _;
	}

	// identity check 
	modifier restricted {
		require(msg.sender == manager);
		_;
	}

	// players enter the lottery pool
	// call modifier validEntrance first.
	function enter() public payable validEntrance {

		// push player into the pool
		// cast address to payable
		players.push(payable(msg.sender));
	}

	// pseudo random generator
	function pseudo_random() private view returns (uint) {
		return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
	}

	// pick winner function
	function pickWinner() public restricted {

		// pick winner with pseudo-random generator
		uint index = pseudo_random() % players.length;

		// transfer money to the winner
		uint prize = uint(address(this).balance * 9 / 10);
		players[index].transfer(prize);

		// Agency fee
		manager.transfer(address(this).balance);

		// start new round with players array size = 0
		players = new address payable[](0);
	}

	// return all players
	function getPlayers() public view returns (address payable[] memory) {
		return players;
	}

}