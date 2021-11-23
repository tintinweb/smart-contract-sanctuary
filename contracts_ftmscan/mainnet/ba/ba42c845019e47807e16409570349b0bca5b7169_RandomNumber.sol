// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
 
contract RandomNumber is Ownable {

	uint[] private randomNumbers;
	uint private numbersGenerated;

	event GenerateRandomNumber(uint randomNumber);

	function getRandomNumbers() external view returns (uint[] memory) {
		return randomNumbers;
	}

	function checkAlreadyExist(uint number) internal view returns (bool) {
		for (uint i = 0; i < numbersGenerated; i++) {
			if (number == randomNumbers[i]) {
				return true;
			}
		}
		return false;
	}

	function generateRandomNumber() external onlyOwner {
		require(numbersGenerated < 5, "You have already drawn 5 random numbers.");
       	uint randomNumber = uint(uint(keccak256(abi.encodePacked(gasleft(), block.timestamp))) % 155) + 1;
		if (!checkAlreadyExist(randomNumber)) {
			randomNumbers.push(randomNumber);
			numbersGenerated++;
			emit GenerateRandomNumber(randomNumber);
		}
    }
}