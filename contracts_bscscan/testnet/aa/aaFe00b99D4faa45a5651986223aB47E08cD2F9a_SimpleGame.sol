/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: UNLICENSED

contract SimpleGame {
    
    address payable public owner;
    uint256 public minimumBet = 100000000000000;
    
    struct Round {
        uint256 lockTime;
        uint256 endTime;
        uint8 teamWinner; // default 0
        
        uint256 amountOne;
        uint256 amountTwo;
        uint256 amountThree;
    }
    
    struct Player {
        uint256 roundBet;
        uint8 teamSelection;
        uint256 amount;
        address payable playerAddress;
        bool claimed;
    }
    
    Round[] public roundList;
    Player[] public playerList;
    
    constructor() {
        // owner = payable(tx.origin);
        owner = payable(address(0x73A3A69BBC1451313B9290B06931472cd84C050C));
    }
    
    function startRound(uint256 _lockTime, uint256 _endTime) public {
        require(msg.sender == owner, 'Can only be start by owner');
        
        Round memory newRound;
        newRound.lockTime = _lockTime;
        newRound.endTime = _endTime;
        roundList.push(newRound);
    }
    
    function bet(uint256 _epoch, uint8 _teamSelection) public payable {
        require(_epoch < roundList.length, 'Round not exist');
        require(block.timestamp < roundList[_epoch].lockTime, 'Round had locked or ended');
        require(!checkPlayerExist(_epoch, msg.sender), 'Already bet in the round');
        require((_teamSelection == 1) || (_teamSelection == 2) || (_teamSelection == 3), 'Can only bet team 1 or 2 or 3');
        require(msg.value >= minimumBet, 'Can only bet more than minimumBet');
        
        Player memory newPlayer;
        newPlayer.roundBet = _epoch;
        newPlayer.teamSelection = _teamSelection;
        newPlayer.amount = msg.value;
        newPlayer.playerAddress = payable(msg.sender);
        playerList.push(newPlayer);
        
        if (_teamSelection == 1) {
            roundList[_epoch].amountOne += msg.value;
        }
        else if (_teamSelection == 2) {
            roundList[_epoch].amountTwo += msg.value;
        }
        else {
            roundList[_epoch].amountThree += msg.value;
        }
    }
    
    function checkPlayerExist(uint256 _epoch, address _player) public view returns(bool) {
        for (uint256 i = 0; i < playerList.length; i++) {
            if ((playerList[i].roundBet == _epoch) && (playerList[i].playerAddress == _player)) {
                return true;
            }
        }
        return false;
    }
    
    function setWinner(uint256 _epoch, uint8 _teamWinner) public {
        require(msg.sender == owner, 'Can only set by owner');
        require(block.timestamp > roundList[_epoch].endTime, 'Can only set after round end');
        require((_teamWinner == 1) || (_teamWinner == 2) || (_teamWinner == 3), 'Can only set team 1 or 2 or 3');
        roundList[_epoch].teamWinner = _teamWinner;
    }
    
    function claimPrize(uint256 _epoch, address _player) public {
        uint8 winner = roundList[_epoch].teamWinner;
        require(winner > 0, 'Winner have not set');
        require(checkPlayerExist(_epoch, _player), 'Player not bet');
        
        uint256 winnerAmount;
        uint256 loserAmount;
        
        if (winner == 1) {
            winnerAmount = roundList[_epoch].amountOne;
            loserAmount = roundList[_epoch].amountTwo + roundList[_epoch].amountThree;
        } 
        else if (winner == 2) {
            winnerAmount = roundList[_epoch].amountTwo;
            loserAmount = roundList[_epoch].amountOne + roundList[_epoch].amountThree;
        }
        else {
            winnerAmount = roundList[_epoch].amountThree;
            loserAmount = roundList[_epoch].amountOne + roundList[_epoch].amountTwo;
        }

        if (winnerAmount == 0) {
            owner.transfer(loserAmount);
        }
        else {
            for (uint256 i = 0; i < playerList.length; i++) {
                if ((playerList[i].roundBet == _epoch) && (playerList[i].playerAddress == _player)) {
                    require(playerList[i].teamSelection == winner, 'No prizes can be claimed');
                    require(!playerList[i].claimed, 'Prize already claimed');
                    
                    uint256 _amount = playerList[i].amount * (winnerAmount + loserAmount) / winnerAmount;
                    uint256 _reward = _amount * 95 / 100;
                    
                    payable(_player).transfer(_reward);
                    owner.transfer(_amount - _reward);
                    playerList[i].claimed = true;
                    
                    break;
                }
            }
        }
    }
}