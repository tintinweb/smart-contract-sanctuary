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


    function giveRightToVote(uint number) payable public {
        bets[msg.sender].push(Bet(number, msg.value));
        
        numBets++;
        totalBetValue += msg.value;
    }

    function numberOfBets() public view
            returns (uint256)
    {
        return numBets;
    }
    
    function totalValueOfBets() public view
            returns (uint256)
    {
        return totalBetValue;
    }
}