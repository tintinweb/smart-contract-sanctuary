/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Game {
    enum VAL {two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace}
    enum SUIT {diamond, club, heart, spade}

    struct pickCard {
        VAL val;
        SUIT suit;
    }

    pickCard public firstCard;
    pickCard public secondCard;

    function getCardOne(VAL _choice1, SUIT _choice2) public returns(VAL ,SUIT) {
        firstCard.val = _choice1;
        firstCard.suit = _choice2;
         
        return (firstCard.val, firstCard.suit);
    }

    function getCardTwo(VAL _choice1, SUIT _choice2) public returns(VAL ,SUIT) {
        secondCard.val = _choice1;
        secondCard.suit = _choice2;

        return (secondCard.val, secondCard.suit);
    }

    function getWinnerLoser() public view returns(string memory winningStatus) {
        if(firstCard.val > secondCard.val) {
            winningStatus = "FirstCard";
        } else if(firstCard.suit > secondCard.suit) {
            winningStatus = "FirstCard";
        } else {
            winningStatus = "SecondCard";
        }

        return winningStatus;
    } 
}