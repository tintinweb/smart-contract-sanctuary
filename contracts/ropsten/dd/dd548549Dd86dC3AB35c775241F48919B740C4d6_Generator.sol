// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./game.sol";

contract Generator{

    Game game;

    function resetGameContract(uint256 set_x, uint256 set_y) public{
        game = new Game(set_x, set_y);
    }
    
    
    function _signIn(string memory _username) public{
        game.signIn(_username);
    }
    
    function _buyCards(uint256 _numberOfCards) public {
        game.buyCards(_numberOfCards);
    }
    
    function _remaining() public view returns(uint256) {
        return game.cardsRemaining();
    }
    
    function _x() public view returns(uint256) {
        return game.x();
    }
    
    function _y() public view returns(uint256) {
        return game.y();
    }
}