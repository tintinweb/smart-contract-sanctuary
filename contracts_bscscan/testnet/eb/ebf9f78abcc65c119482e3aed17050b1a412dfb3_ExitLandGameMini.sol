/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract ExitLandGameMini {
    
    mapping(address => bool) public players;
    mapping(address => bool) public validPlayers;
    mapping(address => bool) public votes;
    address[] public playerList;
    uint256[] public gameSeeds;
    uint256 public playerNumber;
    uint256 public startSeed;
    uint256 public turn;
    uint256 public elimPlayerNumber;
    uint256 public voteNumber;
    
    uint256 MAX_PLAYER=1000;
    uint256 PRICE_GWEI=10900000;
    uint256 PRICE_NO_FEE_GWEI=9000000;
    
    address owner;
    bool feeWithdrawn;
    bool prizeWithdrawn;
    bool gameStarted;
    bool gameStoped;
    bool gameCancelled;
    
    constructor() {
        owner = msg.sender;
    }
    
    function joinGame() public payable {
        require(playerNumber < MAX_PLAYER, "The Game cannot have players exceed 10,000 players.");
        require(!gameStarted, "Game is started.");
        require(!validPlayers[msg.sender], "You have already joined the game.");
        require(msg.sender != owner, "You are the contract owner.");
        require(msg.value == PRICE_GWEI * 10 ** 9, "You need to send only 0.0109 BNB.");
        players[msg.sender] = true;
        validPlayers[msg.sender] = true;
        playerList.push(msg.sender);
        playerNumber += 1;
    }
    
    function giftTicket(address reciever) public payable {
        require(playerNumber < MAX_PLAYER, "The Game cannot have players exceed 10,000 players.");
        require(!gameStarted, "Game is started.");
        require(!validPlayers[reciever], "Reciever has already joined the game.");
        require(msg.sender != owner, "You are the contract owner.");
        require(msg.value == PRICE_GWEI * 10 ** 9, "You need to send only 0.0109 BNB.");
        players[msg.sender] = true;
        validPlayers[reciever] = true;
        playerList.push(msg.sender);
        playerNumber += 1;
    }
    
    function withdrawPrize() public payable {
        require(!gameCancelled, "Game is Cancelled.");
        require(gameStarted && gameStoped, "Game is not finished yet.");
        require(!prizeWithdrawn, "Prize are withdrawn.");
        require(validPlayers[msg.sender], "You are not in the game.");
        if (feeWithdrawn) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            payable(msg.sender).transfer(playerNumber * PRICE_NO_FEE_GWEI * 10 ** 9);
        }
        prizeWithdrawn = true;
    }
    
    function withdrawFee() public payable {
        require(gameStarted, "Game is not start yet.");
        require(!feeWithdrawn,"Fees are withdrawn.");
        require(msg.sender == owner,"You are not the contract owner.");
        payable(msg.sender).transfer(playerNumber * (PRICE_GWEI - PRICE_NO_FEE_GWEI) * 10 ** 9);
        feeWithdrawn = true;
    }
    
    function eliminate(address player) public {
        require(gameStarted && !gameStoped, "Game is not running.");
        require(msg.sender == owner, "You are not the contract owner.");
        require(validPlayers[player], "The player is not in the game.");
        validPlayers[player] = false;
        if (votes[player]) {
            votes[player] = false;
            voteNumber -= 1;
        }
        elimPlayerNumber += 1;
        if (elimPlayerNumber + 1 >= playerNumber) {
            gameStoped = true;
        }
        if (voteNumber + voteNumber > playerNumber - elimPlayerNumber) {
            gameStoped = true;
            gameCancelled = true;
        }
    }
    
    function eliminateBan(address player) public {
        require(gameStarted && !gameStoped, "Game is not running.");
        require(msg.sender == owner, "You are not the contract owner.");
        require(validPlayers[player], "The player is not in the game.");
        validPlayers[player] = false;
        if (votes[player]) {
            votes[player] = false;
            voteNumber -= 1;
        }
        elimPlayerNumber += 1;
        if (elimPlayerNumber + 1 >= playerNumber) {
            gameStoped = true;
        }
        if (voteNumber + voteNumber > playerNumber - elimPlayerNumber) {
            gameStoped = true;
            gameCancelled = true;
        }
        players[player] = false;
    }
    
    function refund() public payable {
        require(gameCancelled, "Game is not Cancelled.");
        require(players[msg.sender], "You are not the player.");
        payable(msg.sender).transfer(PRICE_NO_FEE_GWEI * 10 ** 9);
        players[msg.sender] = false;
    }
    
    function startGame() public {
        require(playerNumber == MAX_PLAYER, "The Game must have 10,000 players to start.");
        require(!gameStarted, "Game is started.");
        require(msg.sender == owner, "You are not the contract owner.");
        startSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        gameSeeds.push(startSeed);
        gameStarted = true;
    }
    
    function recordSnapshot(uint256 gameSeed) public {
        require(gameStarted && !gameStoped, "Game is not running.");
        require(msg.sender == owner, "You are not the contract owner.");
        gameSeeds.push(gameSeed);
        turn += 1;
    }
    
    function voteStopGame() public {
        require(gameStarted && !gameStoped, "Game is not running.");
        require(validPlayers[msg.sender], "You are not in the game.");
        require(!votes[msg.sender], "You voted to stop the game.");
        votes[msg.sender] = true;
        voteNumber += 1;
        if (voteNumber + voteNumber > playerNumber - elimPlayerNumber) {
            gameStoped = true;
            gameCancelled = true;
        }
    }
    
    function unvoteStopGame() public {
        require(gameStarted && !gameStoped, "Game is not running.");
        require(validPlayers[msg.sender], "You are not in the game.");
        require(votes[msg.sender], "You are not vote yet.");
        votes[msg.sender] = false;
        voteNumber -= 1;
    }
}