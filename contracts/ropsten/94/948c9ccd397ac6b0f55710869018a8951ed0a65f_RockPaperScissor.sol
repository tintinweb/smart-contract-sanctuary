/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract RockPaperScissor {
    
    constructor () payable {}
    
    event Won(address indexed player, Hand playerHand, Hand hostHand, uint256 amount);
    event Draw(address indexed player, Hand playerHand, Hand hostHand, uint256 amount);
    event Lost(address indexed player, Hand playerHand, Hand hostHand, uint256 amount);
    
    enum Hand {
        rock, paper, scissors
    }
    
    
    // The nonce used to generate Random
    // Not Secure
    uint256 private randNonce = 0;
    
    // minimal bet fee to play game
    // Before betting, player may need to check host's balance to see if it has enough Ether to pay when player wins.
    uint256 public constant MINIMAL_BET_FEE = 10; 
    
    // player needs to send ether to bet
    // host needs to have as sufficient ehter as at least the double of amount to return when lose.
    // if player won => returns the double
    // if player lost, do nothing
    // if player draw, returns just the amount of ether used to bet
    
    modifier isBetFeeEnough() {
        require(msg.value >= MINIMAL_BET_FEE, "insufficient bet fee.");
        _;
    }
    
    modifier isHostFundEnough () {
        require(address(this).balance >= msg.value *2, "insufficient host fund.");
        _;
    }
    
    function bet(Hand playerHand) public payable isBetFeeEnough isHostFundEnough {
        
        Hand hostHand = getRandomHand();
        int8 result = compareHand(playerHand, hostHand);
        
        if (result == 0){ // draw
            emit Draw(msg.sender, playerHand, hostHand, msg.value);
            returnFund(msg.value);
            return;
        } else if (result > 0) {// player wins
            emit Won(msg.sender, playerHand, hostHand, msg.value);
            returnFund(msg.value * 2);
            return;
        }
        // when host won, do nothing
        emit Lost(msg.sender, playerHand, hostHand, msg.value);
        
    }   
    
    function getRandomHand() internal returns (Hand) {
        uint256 rand = randMod(90);
        if (rand > 30) {
            return Hand.rock;
        } else if (rand > 60) {
            return Hand.paper;
        } 
            return Hand.scissors;
    }
    
    //The max - 1 of the random number range
    function randMod(uint256 _modulus) internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, ++randNonce))) % _modulus;
    }
    
    function compareHand(Hand playerHand, Hand hostHand) internal pure returns (int8) {
        uint8 player = uint8(playerHand);
        uint8 host = uint8(hostHand);
        
        if (player == host){ //draw
            return 0;
        }
        if ((player +1) % 3 == host) { // host wins
            return -1;
        }
        return 1; // player wins
    }
    
    function returnFund(uint256 amount) private {
        // payable() returns payable address
        payable(msg.sender).transfer(amount); 
    }
    
    // let contract receive ether
    receive() external payable {}
}