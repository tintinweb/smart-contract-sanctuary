// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./buySpeceficCard.sol";

contract Generator{

    BuySpeceficCard public buyer;
    
    constructor() {
        buyer = new BuySpeceficCard();
    }

    function _resetBuyerContract() public{
        buyer = new BuySpeceficCard();
    }

    function _signIn(string memory _username) public {
        buyer.signIn(_username);
    }


    function _buyCard(uint256 cardNumber) public {
        buyer.buyCard(cardNumber);
    }
    

    function _getAllUsernames() public view {
        buyer.getAllUsernames();
    }
    function _getUserName() public view {
        buyer.getUserName();
    }
    function _getUserCards() public view {
        buyer.getUserCards();
    }


    function _getAllCards() public view {
        buyer.getAllCards();
    }
    function _getCardOwner(uint256 cardNumber) public view {
        buyer.getCardOwner(cardNumber);
    }
    function _cardHasSelected(uint256 cardNumber) public view {
        buyer.cardHasSelected(cardNumber);
    }
    function _getCardSides(uint256 cardNumber) public view {
        buyer.getCardSides(cardNumber);
    }
}