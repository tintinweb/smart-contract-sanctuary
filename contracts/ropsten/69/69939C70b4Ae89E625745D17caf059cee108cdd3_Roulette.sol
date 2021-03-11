/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity 0.7.4;


contract Roulette {
    
    struct dealer {
        address dealAddress;
        uint currentFlip;
        uint randomNum;
    }
    
    struct bet {
        address betAddress;
        uint guess;
        uint amount;
    }
    
    mapping(uint => bet) public bets;
    
    dealer private dude;
    uint public numBets = 0;
    bool public openBet = false;

        
    // Makes dealer the one who calls the generateFlip function. Will not run if the previous flip has not been resolved
    function generateFlip(uint x, uint r) public {
        require(openBet == false, "Bet is already open");
        dude = dealer(msg.sender, x, r);
        openBet = true;
    }
    
    // Adds bets. Will not allow bets < 5 or > 500, more than 8 bets, or the dealer to bet.
    function addBet(uint guess, uint amount) public returns(bool){
        require(msg.sender != dude.dealAddress, "Dealer cannot bet");
        require((5 <= amount) && (amount <= 500), "Bet must be: 5 < x < 500");
        require(openBet == true, "Betting is not open");
        require(numBets < 8, "Too many bets already");
        bets[numBets] = bet(msg.sender, guess, amount);
        numBets++;
        return(true);
    }
    
    function viewHash() view public returns(bytes32) {
        
        return(sha256(abi.encodePacked(dude.currentFlip, dude.randomNum)));
    }
    
    function callBets() public {
        require(msg.sender == dude.dealAddress);
        openBet = false;
        require(numBets > 0, "No bets to call");
        for (uint i = 0; i < numBets; i++) {
            // This is where the token gets dealt with
            // Not sure how exactly to deal with this
            delete bets[i];
        }
        numBets = 0;
        dude = dealer(address(0),0,0);
    }
}