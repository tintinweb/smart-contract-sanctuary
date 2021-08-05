/**
 *Submitted for verification at Etherscan.io on 2020-05-20
*/

// BULLRUN - 4 EASY AND FAIR
// 100 % PAYOUT
// MINIMAL TRANSACTION COST
//-----------------------------

pragma solidity ^0.6.6;
contract Bullrun4 {
    
    // Counter how many players are in the game
    uint32 public num_players = 0;
    
    // For every player the position and the public ETH address is saved in a map.
    mapping (uint => address payable) public players;
    
    // Only method of the contract
    function add() public payable{
        if (msg.value == 500 finney) { // To participate you must pay 500 finney (0.5 ETH)
            players[num_players] = msg.sender; //save address of player
            
            num_players++; // One player is added, so we increase the player counter
            
            // Transfer the just now added 0.5 ETH to player position num_players divided by 2.
            // This payout is done 2 times for one player, because odd and even number divided by 2 is the same integer. = 1 ETH return
            players[num_players/2].transfer(address(this).balance);
        }
        else
            revert(); // Error executing the function
    }
    
    // Nothing more... no exit scam, fraud, nothing...
}