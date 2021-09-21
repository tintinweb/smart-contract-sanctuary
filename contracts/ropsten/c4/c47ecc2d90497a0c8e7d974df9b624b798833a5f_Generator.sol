// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Game.sol";
import "./Market.sol";

contract Generator{

    Market public market;
    Game[100] public games;
    uint256 public gameIndex;

    constructor(uint256 set_X, uint256 set_Y, uint256 baseFee) {
        market = new Market();
        games[gameIndex] = new Game(set_X, set_Y, baseFee, market.link());
        market.newGame(games[gameIndex].link());
    }

    function newGame(uint256 set_X, uint256 set_Y, uint256 baseFee) public {
        require(gameIndex < 100, "this is the end");
        gameIndex ++;
        games[gameIndex] = new Game(set_X, set_Y, baseFee, market.link());
        market.newGame(games[gameIndex].link());
    }

    // function _x() public view returns(uint256) {
    //     return game.x();
    // }
    
    // function _y() public view returns(uint256) {
    //     return game.y();
    // }

    // function _remaining() public view returns(uint256) {
    //     return game.cardsRemaining();
    // }

    // function _ownerOf(uint256 _cardNum) public view returns(address) {
    //     return game.ownerOf(_cardNum);
    // }

    // function _signIn(string memory _username) public{
    //     game.signIn(_username);
    // }
    
    // function _buyCards(uint256 _numberOfCards) public {
    //     game.buyCards(_numberOfCards);
    // }
    
    // function end() public returns(address) {
    //     game.updateScores();
    //     return game.whoWins();
    // }
}