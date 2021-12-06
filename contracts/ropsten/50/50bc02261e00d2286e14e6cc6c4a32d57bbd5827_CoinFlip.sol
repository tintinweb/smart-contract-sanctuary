/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract CoinFlip {

    enum gameState{noBet, betMade, betAccepted, betWon}

    uint minBetSize = 1000000 gwei;
    uint256 public gameCtr;

    struct GameData {
        uint gameId;
        uint betSize;
        address player1;
        address player2;
        address winner;
        gameState thisGameState;
    }

    GameData[] public gamesInfo;

    constructor() {
    }

    modifier requireState(gameState expectedState, uint gameId) {
        if(gamesInfo[gameId].thisGameState == expectedState) {
            _;
        } else {
            revert();
        }
    }

    modifier noActiveGame(address player) {
        uint amountOfActiveGames = 0;
        for(uint i = 0; i < gameArrayCount(); i++) {
            if(gamesInfo[i].player1 == player && gamesInfo[i].thisGameState != gameState.betWon) {
                amountOfActiveGames++;
            }
        }
        if(amountOfActiveGames == 0) {
            _;
        } else {
            revert();
        }
    }

    function gameArrayCount() public view returns(uint count) {
        return gamesInfo.length;
    }

    function flip() internal view returns(uint){
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % 2;
        return random;
    }

    function makeBet() noActiveGame(msg.sender) public payable returns(bool){
        require(msg.value >= minBetSize, "Bet too small!");
        gameCtr++;
        gamesInfo.push(GameData(gameCtr, msg.value, msg.sender, address(0), address(0), gameState.betMade));
        return true;
    }

    function resolveBet(uint gameId) requireState(gameState.betAccepted, gameId) public returns (bool) {
        require((gamesInfo[gameId].player1 != address(0)) && gamesInfo[gameId].player1 != address(0), "Bet isnt accepted");
        if(flip() == 0)
        {
            gamesInfo[gameId].winner = gamesInfo[gameId].player1;
            payable(gamesInfo[gameId].player1).transfer(address(this).balance);
        } else {
            gamesInfo[gameId].winner = gamesInfo[gameId].player2;
            payable(gamesInfo[gameId].player2).transfer(address(this).balance);
        }
        gamesInfo[gameId].thisGameState = gameState.betWon;
        return true; 
    }

    function acceptBet(uint gameId) requireState(gameState.betMade, gameId) public payable returns(bool) {
        require((msg.value == gamesInfo[gameId].betSize), "You do not have enough to accept the bet!");
		require((gamesInfo[gameId].player1 != msg.sender), "Same player can't take the bet!");
		gamesInfo[gameId].player2 = msg.sender;
        gamesInfo[gameId].thisGameState = gameState.betAccepted;
        resolveBet(gameId);
        return true;
    }


}