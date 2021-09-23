// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Register.sol";

contract Game is Register{

    address public link;
    uint256 public cardsRemaining;
    uint256 public baseFee;
    uint256 public totalPrize;
    bool public marketIsOpen;
    

    event BuyCard(address indexed buyer, uint256 numberOfCards);

    constructor (uint256 _x, uint256 _y,uint256 _baseFee, address marketAddr, address generatorAddr, address ownerAddr) {
        link = address(this);
        x = _x;
        y = _y;
        cardsRemaining = x * y;
        baseFee = _baseFee;
        generatorAddress = generatorAddr;
        marketAddress = marketAddr;
        ownerAddress = ownerAddr;
    }

    modifier onlyGenerator() {
        require(msg.sender == marketAddress);
        _;
    }

    function end() public onlyGenerator returns(address) {
        _closeMarket();
        _updateScores();
        address winner = _whoWins();
        _win(winner);
        totalPrize = 0;
        increaseCredit(winner, totalPrize);
        return winner;
    }

    function buyCards(uint256 numberOfCards) public {
        require (numberOfCards > 0 , "buy some cards !!!");
        //continue untill 70% of cards bought.
        require(cardsRemaining - numberOfCards >= (x * y) * 3 / 10, "not enough cards available. set lesser number.");
        //maximum cards random for every person 
        require(numberOfCards <= cardsRemaining * 35 / 100, "you can only buy 20% of remaining cards.");

        uint256 fee = numberOfCards * baseFee;

        require(checkCredit(msg.sender) >= fee, "not enough eth, please charge your credit.");

        //first card will be selected by random
        uint256 lastCard = _randomCard();       
        _getCard(msg.sender, lastCard);

        //other cards will be selected near to last card
        for(uint i = 1; i < numberOfCards; i++) {
            lastCard = _randomSide(lastCard);       
            _getCard(msg.sender, lastCard);
        }

        cardsRemaining -= numberOfCards;
        decreaseCredit(msg.sender, fee);
        totalPrize += fee;

        emit BuyCard(msg.sender, numberOfCards);

        _updateScores();

        if(cardsRemaining == (x * y) * 3 / 10) {
            _openMarket();
            _ownRestOfCards();
        }
    }


    function _openMarket() private {
        marketIsOpen = true;
    }

    function _closeMarket() private {
        marketIsOpen = false;
    }

    function _randomCard() private view returns(uint256) {
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
    
        return selectedCard;
    }

    function _randomSide(uint256 _cardNum) private view returns(uint256) {

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
        
        return selectedCard;
    }


    function _randomHash() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

}