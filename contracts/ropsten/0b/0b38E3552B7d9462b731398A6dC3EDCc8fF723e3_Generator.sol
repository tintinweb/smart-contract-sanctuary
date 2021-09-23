// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Game.sol";
import "./Market.sol";

contract Generator{

    address owner;
    Market public market;
    Game[100] public games;
    uint256 public gameIndex;

    constructor() {
        owner = msg.sender;
        market = new Market(address(this));
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function newGame(uint256 set_X, uint256 set_Y, uint256 baseFee) public onlyOwner {
        require(gameIndex < 100, "this is the end");
        games[gameIndex] = new Game(set_X, set_Y, baseFee, market.link(), address(this), owner);
        market.newGame(games[gameIndex].link());
        gameIndex ++;
    }

    function endGame(uint256 _gameIndex) public onlyOwner returns(address) {
        return games[_gameIndex].end();
    }

    function sellCard(uint256 _gameIndex, uint256 _cardNum, uint256 _minPrice) public onlyOwner {
        market.acceptBid(_gameIndex, _cardNum, _minPrice);
    }

    function withdraw(uint256 _gameIndex) public onlyOwner {
        games[_gameIndex].withdraw();
    }
}