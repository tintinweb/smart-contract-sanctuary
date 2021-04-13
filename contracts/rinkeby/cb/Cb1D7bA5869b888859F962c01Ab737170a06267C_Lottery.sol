/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity ^0.8.3;

contract Lottery{
    
	// General
	string public name;

	// Users
	address payable public manager;
	address payable[] public players;

	// Money
	uint public minimum = .001 ether;

	// Constructor
	constructor (string memory n) {
		name = n;
		manager = payable(msg.sender);
	}

	// Enter Lottery
	function enter() public payable{
		require(msg.value > minimum); // Validation
		players.push(payable(msg.sender));
	}

	// Pick Winner
	function pickWinner() public restricted {
		uint idx = random() % players.length;
		players[idx].transfer(address(this).balance);
		resetState();
	}

	// Return arr of players
	function getPlayers() public view returns(address payable[] memory){
		return players;
	}

	// Resets state
	function resetState() private{
		players=new address payable[](0); // (0) is initial size
	}

	// Helper function to create psuedo rando num
	function random() private view returns(uint){
		return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
	}

	// Modifier that we can use to reduce duplicated code
	modifier restricted() {
		require(msg.sender == manager);
		_; // Take out all code in func and replace the _ with it
	}
}
// Global MSG
// msg.data
// msg.gas
// msg.sender
// msg.value

// Array .push(elem)
//		 .length
// arr[0]

// Mapping(string => string)
// struct Car{string make; string model;}