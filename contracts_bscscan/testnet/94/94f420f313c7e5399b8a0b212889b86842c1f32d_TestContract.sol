/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TestContract {
    struct Bet {
        address creator;
        uint256 value;
        uint256 min;
        uint256 max;
    }
    
    mapping(uint256 => Bet) public bets;
    uint256 public numBets;
    uint256 sumWon;
    uint256 sumLost;
    
    constructor () {
		
    }
    
    function createBet(address creator, uint256 value, uint256 min, uint256 max) external {
        bets[numBets++] = Bet({ creator: creator, value: value, min: min, max: max });
    }
    
    function sum(uint256 n) public view returns (uint256 _sumWon, uint256 _sumLost) {
        for (uint256 i = 0; i < numBets; i++) {
            if (n >= bets[i].min && n <= bets[i].max) {
                _sumWon += bets[i].value;
            } else {
                _sumLost += bets[i].value;
            }
        }
    }
    
    function writeSum(uint256 n) external {
        (sumWon, sumLost) = sum(n);
    }
}