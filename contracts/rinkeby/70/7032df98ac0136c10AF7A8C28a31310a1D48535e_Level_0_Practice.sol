pragma solidity 0.6.0;

contract Level_0_Practice {
	
	bool public levelComplete;
	uint8 answer;

	constructor() public {
        levelComplete = false;
        answer = 42;
    }

    function completeLevel(uint8 n) public payable {
        if (n == answer) {
            levelComplete = true;
        }
    }
	
}