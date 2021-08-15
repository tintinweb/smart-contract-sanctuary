/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity 0.6.0;

 

contract RockPaperScissors {

 

    uint8 public constant ROCK = 1;
    uint8 public constant PAPER = 2;
    uint8 public constant SCISSORS = 3;
    
    mapping(address => bytes32) public choices;

 

    function play(uint8 choice, uint8 random) external {
        
        require(choices[msg.sender] == 0 );

 

        choices[msg.sender] = keccak256(abi.encodePacked(choice, random));
    }
    
    
    // View means it doesn't change the state of the contract.
    function evaluate(address alice, uint8 aliceRawChoice, uint8 aliceRandom, address bob, uint8 bobRawChoice, uint8 bobRandom) external view returns (address) {
    
        require(keccak256(abi.encodePacked(aliceRawChoice, aliceRandom)) == choices[alice]);
        
        require(keccak256(abi.encodePacked(bobRawChoice, bobRandom)) == choices[bob]);
        
        uint8 bobChoice = bobRawChoice;
        uint8 aliceChoice = aliceRawChoice;
        
        
        // Check if its a draw
        if (aliceChoice == bobChoice) {
            return address(0);
        }
        
        if (aliceChoice == ROCK && bobChoice == PAPER) {
            return bob;
        } else if (aliceChoice == ROCK && bobChoice == SCISSORS) {
            return alice;
        } else if (aliceChoice == PAPER && bobChoice == ROCK) {
            return alice;
        } else if (aliceChoice == PAPER && bobChoice == SCISSORS) {
            return bob;
        } else if (aliceChoice == SCISSORS && bobChoice == ROCK) {
            return bob;
        } else if (aliceChoice == SCISSORS && bobChoice == PAPER) {
            return alice;
        }
        
    }
    
}