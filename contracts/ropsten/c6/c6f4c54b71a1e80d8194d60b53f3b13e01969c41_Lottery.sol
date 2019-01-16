// William Peracchio
// CSE 297
// Professor Korth
// Grader Aaron

pragma solidity ^0.4.0;

/// @title Blockchain Lottery
contract Lottery {
    
    // Entrants into the lottery system
    address[5] public players;
    address public winner;
    
    // Totals
    uint8 public numEntrants;
    uint public totalWager;
    uint8 public MAX_ENTRANTS;
    
    // Initializes the contract
    constructor() public {
        MAX_ENTRANTS = 5;
        numEntrants = 0;
        totalWager = 0;
    }
    
    // Enter the lottery
    function enter () public payable {
        
        // Check to see if all necessary conditions are met
        require(msg.value > 0, "Wager must be greater than 0");
        require(numEntrants < MAX_ENTRANTS, "Too many entrants");

        // Add to totals        
        totalWager += msg.value;
        players[numEntrants] = msg.sender;
        numEntrants++;
        
        // If max number of players reached, pick a winner and reset
        if (numEntrants == MAX_ENTRANTS) {
            endLottery();
            reset();
        }
    }
    
    // Picks a random number
    function random () private view returns(uint) {
        return uint(keccak256(block.difficulty, now, MAX_ENTRANTS));
    }
    
    // Chooses a winner
    function chooseWinner () private view returns(uint) {
        return random() % MAX_ENTRANTS;
    }
    
    // End the lottery
    function endLottery () private {
        winner = players[chooseWinner()];
        winner.transfer(totalWager);
    }
    
    // Reset necessary variables
    function reset () private {
        numEntrants = 0;
        totalWager = 0;
    }
    
}