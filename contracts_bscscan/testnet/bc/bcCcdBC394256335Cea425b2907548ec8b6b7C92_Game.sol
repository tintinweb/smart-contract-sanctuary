/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

pragma solidity 0.8.0;

contract Game {
    enum Val {two, three, four, five , six, seven, eight, nine, ten, J, Q, K, Ace}
    enum Suit {Spade, Heart, Clubs, Diamond}
    enum Status {start, waiting, end}
    enum Result { win, lose}

    struct pickCard {
        Val val;
        Suit suit;
    }

    struct newGame {
        Result result;
        Status status;
    }

    pickCard public firstCard;
    pickCard public secondCard;
    newGame public currentGame;

    function pickFirstCard(Val _choice1, Suit _choice2) public returns (Val, Suit) {
        firstCard.val = _choice1;
        firstCard.suit = _choice2;
        return (firstCard.val, firstCard.suit);
    }

    function pickSecondCard(Val _choice1, Suit _choice2) public returns (Val, Suit, Status) {
        secondCard.val = _choice1;
        secondCard.suit = _choice2;
        currentGame.status = Status.waiting;
        return (secondCard.val, secondCard.suit, currentGame.status);
    }

    function compareCards() public returns (Status, Result) {
        if(uint8(firstCard.val) > uint8(secondCard.val)){
            if(uint8(firstCard.suit) > uint8(secondCard.suit)) {
                currentGame.result = Result.win;
            }
        }
        else {
            if ( uint8(firstCard.suit) < uint8(secondCard.suit) ) {
                currentGame.result = Result.lose;
            }
        }
        currentGame.status = Status.end;
        return (currentGame.status, currentGame.result);
    }
}