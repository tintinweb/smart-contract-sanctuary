pragma solidity ^0.4.25;

contract ArrayInsertions {

	uint256[] public values;

	constructor() public {
		values = new uint256[](0);
	}

	function insertValue(uint256 value) public {
		values.push(value);
	}
}