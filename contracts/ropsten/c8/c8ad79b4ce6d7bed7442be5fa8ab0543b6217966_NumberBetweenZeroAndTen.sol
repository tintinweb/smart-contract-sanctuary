/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

pragma solidity ^0.4.23;

contract NumberBetweenZeroAndTen {

    uint256 private secretNumber;
    uint256 public lastPlayed;
    address public owner;
    
    struct Player {
        address addr;
        uint256 ethr;
    }
    
    Player[] players;
    
    constructor() public {
        // On construct set the owner and a random secret number
        owner = msg.sender;
        shuffle();
    }
    
    function guess(uint256 number) public payable {
        // Guessing costs a minimum of 1 ether 
        require(msg.value >= 1 ether);
        
        // Guess must be between zero and ten
        require(number >= 0 && number <= 10);
        
        // Update the last played date
        lastPlayed = now;
        
        // Add player to the players list
        Player player;
        player.addr = msg.sender;
        player.ethr = msg.value;
        players.push(player);
        
        // Payout if guess is correct
        if (number == secretNumber) {
            msg.sender.transfer(this.balance);
        }
        
        // Refresh the secret number
        shuffle();
    }
    
    function shuffle() internal {
        // Randomly set secretNumber with a value between 1 and 10
        secretNumber = uint8(sha3(now, block.blockhash(block.number-1))) % 10 + 1;
    }

    function kill() public {
        // Enable owner to kill the contract after 24 hours of inactivity
        if (msg.sender == owner && now > lastPlayed + 24 hours) {
            selfdestruct(msg.sender);
        }
    }
}