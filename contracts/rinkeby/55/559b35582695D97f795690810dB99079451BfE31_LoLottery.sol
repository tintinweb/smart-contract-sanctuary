/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract LoLottery {


    bool gameResolved;
    address payable owner;


    event gameCreated(uint _numberOfPlayers, uint _ticketPrice);

    struct LotteryGame {

        address payable [] players;
        uint ticketPrice;
        uint numberOfPlayers;

    }

    LotteryGame game;



    constructor () {

        owner = payable(msg.sender);

    }


    function newGame (uint _numberOfPlayers, uint _ticketPrice) public {

            require(msg.sender == owner, "Must be owner to create new game");

            gameResolved = false;
            game.ticketPrice = _ticketPrice;
            game.numberOfPlayers = _numberOfPlayers;
        

            emit gameCreated(_numberOfPlayers, _ticketPrice);

    }


    function enterGame (address payable player) public payable {

        require(msg.value == game.ticketPrice, "Please Send Exact Ticket Price");
        
        
        
        require(game.players.length < game.numberOfPlayers, "Game finished");

        game.players.push(player);

        playGame();

    }

    function playGame() private {

        require(game.players.length == game.numberOfPlayers, "Game Not Full");
        
        uint currentBlockNumber = block.number;

        uint random1 = randomNumber() % game.numberOfPlayers;
        uint random2 = randomNumber() % game.numberOfPlayers;

        address[] memory round2;
        round2[0] = game.players[random1];
        round2[1] = game.players[random2]; 

        while(currentBlockNumber != currentBlockNumber+2){
            
            //do nothing
        }

        uint random3 = randomNumber()%2;

        address payable winner;

        winner = payable(round2[random3]);

        winner.transfer(game.ticketPrice*game.numberOfPlayers-game.ticketPrice);
        owner.transfer(game.ticketPrice);

        
    }

    uint nonce = 0;
    function randomNumber() internal returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 900;
        randomnumber = randomnumber + 100;
        nonce++;
        return randomnumber;
    }


}