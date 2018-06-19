/**
 * Copyright (C) 2017-2018 Hashfuture Inc. All rights reserved.
 */


pragma solidity ^0.4.19;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Bet4Land is owned {

    /* Struct for one game */
    struct Game {
        uint gameId;            // Unique id for a game
        bytes8 landKey;         // Unique key for a land, derived from longitude and latitude
        uint seedBlock;         // Block number whose hash as random seed
        uint userNum;           // Number of users joined this game, maximum 100
        string content;         // Full content of one game
    }

    uint gameNum;
    /* This notes all games and a map from gameId to gameIdx */
    mapping(uint => Game) games;
    mapping(uint => uint) indexMap;

    /** constructor */
    function Bet4Land() public {
        gameNum = 1;
    }

    /**
     * Initialize a new game
     */
    function newGame(uint gameId, bytes8 landKey, uint seedBlock, uint userNum, string content) onlyOwner public returns (uint gameIndex) {
        require(indexMap[gameId] == 0);             // gameId should be unique
        gameIndex = gameNum++;
        indexMap[gameId] = gameIndex;
        games[gameIndex] = Game(gameId, landKey, seedBlock, userNum, content);
    }

    /**
     * Get game info by index
     * Only can be called by newOwner
     */
    function getGameInfoByIndex(uint gameIndex) onlyOwner public view returns (uint gameId, bytes8 landKey, uint seedBlock, uint userNum, string content) {
        require(gameIndex < gameNum);               // should exist
        require(gameIndex >= 1);                    // should exist
        gameId = games[gameIndex].gameId;
        landKey = games[gameIndex].landKey;
        seedBlock = games[gameIndex].seedBlock;
        userNum = games[gameIndex].userNum;
        content = games[gameIndex].content;
    }

    /**
     * Get game info by game id
     * Only can be called by newOwner
     */
    function getGameInfoById(uint gameId) public view returns (uint gameIndex, bytes8 landKey, uint seedBlock, uint userNum, string content) {
        gameIndex = indexMap[gameId];
        require(gameIndex < gameNum);              // should exist
        require(gameIndex >= 1);                   // should exist
        landKey = games[gameIndex].landKey;
        seedBlock = games[gameIndex].seedBlock;
        userNum = games[gameIndex].userNum;
        content = games[gameIndex].content;
    }

    /**
     * Get the number of games
     */
    function getGameNum() onlyOwner public view returns (uint num) {
        num = gameNum - 1;
    }
}