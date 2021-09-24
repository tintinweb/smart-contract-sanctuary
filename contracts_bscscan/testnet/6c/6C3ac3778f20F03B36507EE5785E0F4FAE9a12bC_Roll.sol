/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.7;

contract Roll {
    address public manager;

    bool public bettingEnabled;

    uint public rollUnderUpperLimit;
    uint public taxFree;
    uint public minimumBet;
    uint public maximumBet;
    uint public totalRolls;
    uint public totalBet;
    uint public totalWon;

    /* Random string to spice up generating random number */
    string private nonce;

    event ShowResult(uint indexed _sessionId, uint _timestamp, address indexed _wallet, uint _betAmount,  uint _rollUnder,  uint _roll, bool _win);
    event ShowWin(uint _winAmount);
    
    constructor(bool _bettingEnabled, string memory _nonce, uint _rollUnderUpperLimit, uint _taxFree, uint _minimumBet, uint _maximumBet, uint _totalRolls, uint _totalBet, uint _totalWon) {
        manager = msg.sender;
        nonce = _nonce;
        bettingEnabled = _bettingEnabled;
        rollUnderUpperLimit = _rollUnderUpperLimit;
        taxFree = _taxFree;
        minimumBet = _minimumBet;
        maximumBet = _maximumBet;
        totalRolls = _totalRolls;
        totalBet = _totalBet;
        totalWon = _totalWon;
    }

    function addToPool() public payable restricted {}
    
    function enter(uint rollUnder) public payable min max enabled {
        require(rollUnder < rollUnderUpperLimit);
        totalRolls++;
        totalBet = totalBet+msg.value;
        play(rollUnder);
    }

    function enableBetting() public restricted {
        bettingEnabled = true;
    }

    function disableBetting() public restricted {
        bettingEnabled = false;
    }

    function setRollUnderUpperLimit(uint value) public restricted {
        rollUnderUpperLimit = value;
    }

    function setMinimumBetValue(uint value) public restricted {
        minimumBet = value;
    }

    function setMaximumBetValue(uint value) public restricted {
        maximumBet = value;
    }

    function play(uint rollUnder) private {
        uint roll = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce))) % 101;
        bool win = roll < rollUnder;
        if (win) payout(rollUnder);
        emit ShowResult(totalRolls, block.timestamp, msg.sender, msg.value, rollUnder, roll, win);
    }

    function payout(uint rollUnder) private {
        uint prize = calculateWin(rollUnder);
        payable(msg.sender).transfer(prize);
        emit ShowWin(prize);
    }

    function calculateWin(uint rollUnder) private view returns (uint) {
        return (msg.value+(msg.value*(100-rollUnder)/rollUnder))*taxFree/100;
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    modifier min() {
        require(msg.value >= minimumBet);
        _;
    }

    modifier max() {
        require(msg.value <= maximumBet);
        _;
    }

    modifier enabled() {
        require(bettingEnabled == true);
        _;
    }
}