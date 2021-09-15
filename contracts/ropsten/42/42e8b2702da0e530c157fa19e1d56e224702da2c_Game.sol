// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./Register.sol";

contract Game is Register{

    mapping(uint256 => address) cardToOwner;

    uint256 public cardsRemaining;
    uint256 public x;
    uint256 public y;

    event BuyCard(address indexed buyer, uint256 cardNumber);

    constructor (uint256 _x, uint256 _y) {
        x = _x;
        y = _y;
        cardsRemaining = x * y;
    }


    function ownerOfCard(uint256 _cardNum) public view returns(address) {
        require(cardToOwner[_cardNum] != address(0), "this card does not have an owner");
        return cardToOwner[_cardNum];
    }

    function buyCards(uint256 numberOfCards) public {
        require (numberOfCards > 0 , "buy some cards !!!");
        require(numberOfCards <= cardsRemaining, "not enough cards available. set lesser number.");
        require(numberOfCards <= 5, "you can only buy 5 cards.");

        //first card will be selected by random
        uint256 lastCard = _randomCard();

        //other cards will be selected near to last card
        for(uint i=1; i < numberOfCards; i++){
            lastCard = _randomSide(lastCard);
        }
    }


    function _randomCard() private returns(uint256) {
        //request for a random index from existing cards
        uint256 randIndex = (_randomHash() % cardsRemaining);

        //select from remaining cards
        uint256 counter = 0;
        uint256 selectedCard = 0;
        do {
            if (cardToOwner[selectedCard] == address(0)){
                counter ++;
            } 
            selectedCard ++;
        } while(counter <= randIndex);
        selectedCard --;


        //make sure the card would not be selected again
        cardsRemaining --;
        cardToOwner[selectedCard] = msg.sender;        
        _getCard(msg.sender, selectedCard);
    
        return selectedCard;
    }


    function _randomSide(uint256 _cardNum) private returns(uint256) {

        uint256[4] memory sidesAvailable;

        uint256 selectedCard;

        //available sides
        uint256 index = 0;
        //right side
        if (_cardNum % x != x-1 && cardToOwner[_cardNum + 1] == address(0)) {
            sidesAvailable[index] = _cardNum + 1;
            index++;
        }
        //top side
        if (_cardNum >= x && cardToOwner[_cardNum - x] == address(0)) {
            sidesAvailable[index] = _cardNum - x;
            index++;
        }
        //left side
        if (_cardNum % x != 0 && cardToOwner[_cardNum - 1] == address(0)) {
            sidesAvailable[index] = _cardNum - 1;
            index++;
        }
        //bottom side
        if (_cardNum < x*y - x && cardToOwner[_cardNum + x] == address(0)) {
            sidesAvailable[index] = _cardNum + x;
            index++;
        }


        if (index == 0){
            selectedCard = _randomCard();
        } else if (index == 1) {
            selectedCard = sidesAvailable[0];
        } else {
            //request for a random index from available sides
            uint256 randIndex = (_randomHash() % index);

            selectedCard = sidesAvailable[randIndex];
        }


        //make sure the card would not be selected again
        cardsRemaining --;
        cardToOwner[selectedCard] = msg.sender;        
        _getCard(msg.sender, selectedCard);

        
        
        return selectedCard;
    }


    function _randomHash() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

}