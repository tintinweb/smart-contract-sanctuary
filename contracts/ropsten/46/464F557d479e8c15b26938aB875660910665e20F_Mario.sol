/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Mario {
   
    struct Bet {
        uint number;
        uint256 value;
    }

    mapping(address => Bet[]) public bets;

    uint256 public numBets;
    uint256 public totalBetValue;


    function bet(uint number) payable public {
        require(msg.value > 0, "Need to place a bet");
        require(number >= 0 && number <= 9999, "Number must be between 0 and 9999 inclusive");
        bets[msg.sender].push(Bet(number, msg.value));
        
        numBets++;
        totalBetValue += msg.value;
    }
}