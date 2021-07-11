/**
 *Submitted for verification at Etherscan.io on 2021-07-11
*/

pragma solidity ^0.8.0;

contract Guess {
    
    uint256 public finalSubmitBlock;
    
    struct guessObject{
        address user;
        string guess;
    }
    
    guessObject[] public guesses;
    
    constructor(){
        finalSubmitBlock = block.number + 40320;
    }
    
    
    function submitGuess(string memory _guess) public{
        require(block.number <= finalSubmitBlock, "ERROR: the guessing period has ended");
        guessObject memory g = guessObject(msg.sender, _guess);
        guesses.push(g);
    }
    
    function viewGuesses() public view returns(guessObject[] memory){
        return guesses;
    }
    
}