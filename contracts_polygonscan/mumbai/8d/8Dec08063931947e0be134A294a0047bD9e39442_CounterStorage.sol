// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract CounterStorage {
	uint256 counter = 0;
	string name;

	function changeCounter(uint newNum) public {
		counter = newNum;
	}

	function getCounter() public view returns(uint256){
		return counter;
	}

	function changeName(string memory newName) public {
		name = newName;
	}

	function getName() public view returns(string memory){
		return name;
	}
}