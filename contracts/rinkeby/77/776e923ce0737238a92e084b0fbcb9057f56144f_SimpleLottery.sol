/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity ^0.5.16;

contract SimpleLottery {
	address payable public manager;
	address payable[] public playersSlice;
	mapping(address => bool) public playersMap;
	uint256 public round = 0;
	address payable public winner;

	constructor() public {
		manager = msg.sender;
	}

	modifier onlyManager() {
		require(manager == msg.sender);
		_;
	}

	function play() public payable {
		require(msg.value == 1 ether);
		require(!playersMap[msg.sender]);
		playersMap[msg.sender] = true;
		playersSlice.push(msg.sender);
	}

	function getBalance() public view returns(uint256) {
		return address(this).balance;
	}

	function hasTicket() public view returns(bool) {
		return playersMap[msg.sender];
	}

	function getWinner() public view returns(address payable) {
		return winner;
	}

	function getPlayersCnt() public view returns(uint256) {
		return playersSlice.length;
	}

	function randomUInt256(uint256 seed) private view returns(uint256) {
		bytes memory v1 = abi.encodePacked(block.timestamp, block.difficulty, seed);
		bytes32 v2 = keccak256(v1);
		return uint256(v2);
	}

	function calBonusAndIncome(uint256 balance) private pure returns(uint256, uint256) {
		uint256 bonus = balance * 9 / 10;
		uint256 income = balance - bonus;
		return (bonus, income);
	}

	function drawPrize() onlyManager public {
		uint256 len = playersSlice.length;
		require(len > 0);
		uint256 idx = randomUInt256(len) % len;
		winner = playersSlice[idx];
		uint256 bonus;
		uint256 income;
		(bonus, income) = calBonusAndIncome(getBalance());
		manager.transfer(income);
		winner.transfer(bonus);
		++round;
		for (uint256 i = 0; i < len; ++i) {
			delete(playersMap[playersSlice[i]]);
		}
		delete(playersSlice);
	}

	function withdrawPrize() onlyManager public {
		for (uint256 i = 0; i < playersSlice.length; ++i) {
			address payable player = playersSlice[i];
			delete(playersMap[player]);
			player.transfer(1 ether);
		}
		delete(playersSlice);
	}
}