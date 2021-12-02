/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract TwoPlayersFlip {

    enum gameState{noBet, betMade, betAccepted, betWon}
    gameState public currentState;

    address public player1;
    address public player2;
    address public winner;

    uint betSize;
    uint minSize = 1000000 gwei;

    constructor() {
        currentState = gameState.noBet;
    }

    modifier requireState(gameState expectedState) {
        if(currentState == expectedState) {
            _;
        } else {
            revert();
        }
    }

    function flip() internal view returns(uint){
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % 2;
        return random;
    }

    function makeBet() requireState(gameState.noBet) public payable returns(bool){
        require(msg.value == minSize);
        betSize = msg.value;
        player1 = msg.sender;
        currentState = gameState.betMade;
        return true;
    }

    function acceptBet() requireState(gameState.betMade) public payable returns(bool) {
        require((msg.value == betSize), "You do not have enough to accept the bet!");
		require((player1 != msg.sender), "Same player can't take the bet!");
		player2 = msg.sender;
        currentState = gameState.betAccepted;
        return true;
    }

    function resolveBet() requireState(gameState.betAccepted) public returns (bool) {
        if(flip() == 0)
        {
            winner = player1;
            payable(player1).transfer(address(this).balance);
        } else {
            winner = player2;
            payable(player2).transfer(address(this).balance);
        }
        currentState = gameState.betWon;
        return true;
    }
}