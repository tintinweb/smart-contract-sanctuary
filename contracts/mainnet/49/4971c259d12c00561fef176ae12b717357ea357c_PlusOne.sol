/**
 *Submitted for verification at Etherscan.io on 2020-09-29
*/

pragma solidity ^0.6.6;

// In this game, players play by depositing ether.
// Players must deposit more ether than the last player. See the minimumDeposit variable to check how much must be deposited.
// When the game times out, the last player can withdraw all the ether on the contract, minus a 10% fee.
// The game times out 3 days after the last successful "play" call or 1 year after the beginning of the game.
contract PlusOne {
    uint constant public incrementPercent = 10; // each player must play at list 10% more than the previous player
    uint constant public feePercent = 19;

    address public owner;
    address public lastPlayer;
    uint256 public fees;
    uint256 public playerTimeout;
    uint256 public gameTimeout;
    uint256 public minimumDeposit;
    bool public winnerFundWithdrawn;

    // Builds the contract. The owner is in fact the first player.
    constructor() public payable {
        owner = msg.sender;
        gameTimeout = block.number + 2102400; // approx 1 year
        playerTimeout = gameTimeout;
        fees = msg.value * feePercent / 100;
        lastPlayer = msg.sender;
        setMinimumDeposit(msg.value);
    }
    
    // Plays. You need to deposit more than the minimumDeposit.
    function play() payable public {
        require(msg.value >= minimumDeposit, 'Send more than minimumDeposit');

        setMinimumDeposit(msg.value);
        fees += msg.value * feePercent / 100;

        if (block.number < playerTimeout && block.number < gameTimeout) {
            lastPlayer = msg.sender;
            playerTimeout = block.number + 17280; // approx 3 days
        }
    }
    
    function setMinimumDeposit(uint256 currentDeposit) private {
        minimumDeposit = currentDeposit * (100 + incrementPercent) / 100; // Next player will need to play with at least 10% more
    }
    
    // Sends the contract balance (minus the fees) to the winner
    function withdraw() public {
        require(!winnerFundWithdrawn, 'Already withdrawn');
        require(block.number >= playerTimeout || block.number >= gameTimeout);

        winnerFundWithdrawn = true;
        payable(lastPlayer).transfer(address(this).balance - fees);
    }
    
    // Send the fees to the owner
    function withdrawFees() public {
        require(msg.sender == owner, 'Not owner');
        
        if (winnerFundWithdrawn) {
            // If the winner has already withdrawn its prize, we can withdraw everything remaining
            payable(owner).transfer(address(this).balance);
        }
        else {
            fees = 0;
            payable(owner).transfer(fees);
        }
    }
    
    receive() external payable { }
}