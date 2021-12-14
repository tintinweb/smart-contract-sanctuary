/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Betting {
    address private _owner;
    bool private _hasEnded;
    uint256 private _winTeam;

    // By default use 10000000000000000 = 10^16 = 0.01 BNB
    uint256 public immutable minimumBet;

    uint256 public totalBetOne;
    uint256 public totalBetTwo;
    uint256 public numberOfBets;
    
    struct Player {
       uint256 amountBet;
       uint16 teamSelected;
       bool betted;
       bool claimed;
    }

    mapping(address => Player) public playerInfo;

    constructor(uint256 _minimumBet) {
        minimumBet = _minimumBet;

        _winTeam = 0;
        _owner = payable(msg.sender);
        _hasEnded = false;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner.");
        _;
    }

    function getHasEnded() public view returns (bool) {
        return _hasEnded;
    }

    function getPlayerBetted(address player) public view returns (bool) {
        return playerInfo[player].betted;
    }

    function getPlayerWon(address player) public view returns (bool) {
        return playerInfo[player].teamSelected == _winTeam;
    }

    function getWinTeam() public view returns (uint256) {
        return _winTeam;
    }

    function getTotalBetOne() public view returns (uint256) {
        return totalBetOne;
    }

    function getTotalBetTwo() public view returns (uint256) {
        return totalBetTwo;
    }

    function bet(uint8 _teamSelected) public payable {
        require(playerInfo[msg.sender].betted == false, "You can only bet once. :)");
        require(msg.value >= minimumBet, "Bet at least minimum bet.");
        require(_teamSelected == 1 || _teamSelected == 2, "You have to either pick team 1 or team 2.");
        require(_hasEnded == false, "Betting time ended.");

        numberOfBets += 1;
        
        playerInfo[msg.sender].amountBet = msg.value;
        playerInfo[msg.sender].teamSelected = _teamSelected;
        playerInfo[msg.sender].betted = true;
        
        if ( _teamSelected == 1) {
            totalBetOne += msg.value;
        } else {
            totalBetTwo += msg.value;
        }
    }

    function claimReward() public {
        require(_hasEnded == true, "Betting period has not ended.");
        require(playerInfo[msg.sender].teamSelected == _winTeam, "You did not win on this bet!");
        require(playerInfo[msg.sender].betted == true, "You did not bet on this.");
        require(playerInfo[msg.sender].claimed == false, "You can't claim twice.");

        uint256 _winAmount = 0;
        uint256 _winningTeamPot;
        uint256 _losingTeamPot;
        uint256 _decimals = 10000000;

        if (_winTeam == 1) {
            _winningTeamPot = totalBetOne;
            _losingTeamPot = totalBetTwo;
        } else {
            _winningTeamPot = totalBetTwo;
            _losingTeamPot = totalBetOne;
        }

        _winAmount = (
            playerInfo[msg.sender].amountBet * (_decimals + (_losingTeamPot * _decimals / _winningTeamPot))
        ) / _decimals;

        payable(msg.sender).transfer(_winAmount);
        playerInfo[msg.sender].claimed = true;
    }

    function endBetting(uint256 winTeam) public onlyOwner {
        require(_hasEnded == false, "You can't end twice.");

        _hasEnded = true;
        _winTeam = winTeam;
    }
}