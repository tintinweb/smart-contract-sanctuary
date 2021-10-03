/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.7;

contract Roll {
    address public manager;

    bool public bettingEnabled;

    uint public rollUnderLowerLimit;
    uint public rollUnderUpperLimit;
    uint public taxFree;
    uint public minimumBet;
    uint public maximumBet;
    uint public totalRolls;
    uint public totalBet;
    uint public totalWon;

    event ShowResult(uint indexed _sessionId, uint _timestamp, address indexed _wallet, uint _betAmount,  uint _rollUnder,  uint _roll, bool _win);
    
    constructor(bool _bettingEnabled, uint _rollUnderLowerLimit, uint _rollUnderUpperLimit, uint _taxFree, uint _minimumBet, uint _maximumBet, uint _totalRolls, uint _totalBet, uint _totalWon) {
        manager = msg.sender;
        bettingEnabled = _bettingEnabled;
        rollUnderLowerLimit = _rollUnderLowerLimit;
        rollUnderUpperLimit = _rollUnderUpperLimit;
        taxFree = _taxFree;
        minimumBet = _minimumBet;
        maximumBet = _maximumBet;
        totalRolls = _totalRolls;
        totalBet = _totalBet;
        totalWon = _totalWon;
    }

    function addToPool() public payable restricted {}

    function transferOut(uint amount) public restricted {
        payable(manager).transfer(amount);
    }
    
    function enter(uint rollUnder, uint salty) public payable min max enabled {
        require(rollUnder > rollUnderLowerLimit && rollUnder < rollUnderUpperLimit, "Chance of winning % out of range.");
        totalRolls++;
        totalBet = totalBet+msg.value;
        play(rollUnder, salty);
    }

    function enableBetting() public restricted {
        bettingEnabled = true;
    }

    function disableBetting() public restricted {
        bettingEnabled = false;
    }

    function setRollUnderLowerLimit(uint value) public restricted {
        rollUnderLowerLimit = value;
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

    function play(uint rollUnder, uint salty) private {
        uint roll = getRandom(salty);
        bool win = roll < rollUnder;
        if (win) payout(rollUnder);
        emit ShowResult(totalRolls, block.timestamp, msg.sender, msg.value, rollUnder, roll, win);
    }

    function payout(uint rollUnder) private {
        uint prize = calculateWin(rollUnder);
        uint profit = prize-msg.value;
        totalWon = totalWon+profit;
        payable(msg.sender).transfer(prize);
    }

    function calculateWin(uint rollUnder) private view returns (uint) {
        return (msg.value+(msg.value*(100-rollUnder)/rollUnder))*taxFree/100;
    }

    function getRandom(uint256 salty) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number +
                    salty
                )
            )
        );
        return (seed % (rollUnderUpperLimit - rollUnderLowerLimit) + rollUnderLowerLimit);
    }
    
    modifier restricted() {
        require(msg.sender == manager, "Permission denied.");
        _;
    }

    modifier min() {
        require(msg.value >= minimumBet, "Bet value must be equal or greater than minimum limit.");
        _;
    }

    modifier max() {
        require(msg.value <= maximumBet, "Bet value must be equal or less than maximum limit.");
        _;
    }

    modifier enabled() {
        require(bettingEnabled == true, "Betting has been disabled.");
        _;
    }
}