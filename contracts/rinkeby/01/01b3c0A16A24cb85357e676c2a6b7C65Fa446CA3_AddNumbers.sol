pragma solidity ^0.8.0;


contract AddNumbers {

	uint256 num1;
	uint256 num2;

	constructor(uint256 _num1, uint256 _num2) {
		num1 = _num1;
		num2 = _num2;
	}

	function addNumbers() public view returns (uint256) {
		uint256 result = num1 + num2;
		return result;
	}

	function setNumberOne(uint256 _num1) public {
		num1 = _num1;
	}

	function setNumberTwo(uint256 _num2) public {
		num2 = _num2;
	}

	function getNumberOne() public view returns (uint256) {
		return num1;
	}

	function getNumberTwo() public view returns (uint256) {
		return num2;
	}
}