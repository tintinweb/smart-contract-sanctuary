// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Game.sol";

contract Generator{

    Game game;

    function _x() public view returns(uint256) {
        return game.x();
    }
    
    function _y() public view returns(uint256) {
        return game.y();
    }

    function _remaining() public view returns(uint256) {
        return game.cardsRemaining();
    }

    function _ownerOfCard(uint256 _cardNum) public view returns(address) {
        return game.ownerOfCard(_cardNum);
    }

    function _userCards(address _userAddr) public view returns(uint256[] memory) {
        return game.userCards(_userAddr);
    }

    function _signIn(string memory _username) public{
        game.signIn(_username);
    }
    
    function _buyCards(uint256 _numberOfCards) public {
        game.buyCards(_numberOfCards);
    }
    
    function resetGameContract(uint256 set_x, uint256 set_y) public{
        game = new Game(set_x, set_y);
    }
    
}