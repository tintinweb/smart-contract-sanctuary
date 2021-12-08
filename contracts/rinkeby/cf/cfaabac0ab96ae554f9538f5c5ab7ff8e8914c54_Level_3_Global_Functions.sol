/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity 0.6.0;

contract Level_3_Global_Functions {
    bytes32 guess;
    uint256 settlementBlockNumber;

    uint public totalSupply;
    bool public levelComplete;

    function guessTheFutureHash(bytes32 hash) public payable {
        guess = hash;
        settlementBlockNumber = block.number + 1;
    }

    function completeLevel() external {
    	require(block.number > settlementBlockNumber);
    	bytes32 answer = blockhash(settlementBlockNumber);
    	require(guess == answer);
    	levelComplete = true;
    }
}