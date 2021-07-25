/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Mario {
    
    address payable public owner;
   
    struct Bet {
        uint number;
        uint256 value;
    }

    // Bets placed by users
    mapping(address => Bet[]) userToBets;
    // Bets to value
    mapping(uint => uint256) betToValue;

    uint public numBets;
    uint256 public totalBetValue;
    
    // Draw ended?
    bool ended;
    uint public endTime;
    
    uint public winningNumber;
    
    constructor() {
        winningNumber = 10000; // or another constant
        owner = payable(msg.sender);
        endTime = block.timestamp + 1 days;
    }


    function bet(uint number) payable public {
        require(block.timestamp < endTime, "Draw ended");
        require(!ended, "Draw ended");
        require(msg.value > 0, "Need to place a bet");
        require(number >= 0 && number <= 9999, "Number must be between 0 and 9999 inclusive");
        
        userToBets[msg.sender].push(Bet(number, msg.value));
        betToValue[number] += msg.value;
        
        numBets++;
        totalBetValue += msg.value;
    }
    
    function claim() public returns (bool) {
        require(ended, "Draw has not ended");
        
        Bet[] storage bets = userToBets[msg.sender];
        for (uint i=0; i<bets.length; i++) {
            if (bets[i].number == winningNumber && bets[i].value > 0) {
                if (payable(msg.sender).send(bets[i].value)) {
                    bets[i].value = 0;
                    betToValue[winningNumber] -= bets[i].value;
                    // return true;
                } else {
                    return false;
                }
            }
        }
        return true;
    }
    
    // Temp
    function setWinningNumber(uint number) public {
        require(msg.sender == owner, "Only owner can do this");
        require(!ended, "Draw ended");
        require(number >= 0 && number <= 9999, "Number must be between 0 and 9999 inclusive");
        
        ended = true;
        winningNumber = number;
    }
}