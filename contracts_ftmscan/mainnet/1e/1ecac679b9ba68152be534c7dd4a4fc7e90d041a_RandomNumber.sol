// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
 
contract RandomNumber is Ownable {

	uint[] private randomNumbers;
	uint private numbersGenerated;

	uint private maxRange;
	uint private maxNbDraws;

	event GenerateRandomNumber(uint randomNumber);

	constructor(uint _maxRange, uint _maxNbDraws) {
		require(_maxRange > _maxNbDraws, "Increase the _maxRange value.");
		maxRange = _maxRange;
		maxNbDraws = _maxNbDraws;
	}

	function getMaxRange() external view returns (uint) {
		return maxRange;
	}

	function getMaxNbDraws() external view returns (uint) {
		return maxNbDraws;
	}

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
		require(numbersGenerated < maxNbDraws, "You can't draw more random numbers.");
       	uint randomNumber = uint(uint(keccak256(abi.encodePacked(gasleft(), block.timestamp))) % maxRange) + 1;
		if (!checkAlreadyExist(randomNumber)) {
			randomNumbers.push(randomNumber);
			numbersGenerated++;
			emit GenerateRandomNumber(randomNumber);
		}
    }
}