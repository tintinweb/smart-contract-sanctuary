/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract TryEnum {
    enum CardValue {
        ACE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, TEN,
        JACK, QUEEN, KING
    }
    
    enum CardSuit {
        SPADE, DIAMOND, HEART, CLUBS
    }
    struct Card {
        CardValue val;
        CardSuit suit;
    }
    enum GameStatus {
        INITIAL, WAITING, ENDED
    }

    Card public firstCard;
    Card public secondCard;
    GameStatus private gameStatus;

    function getResult() public view returns(string memory)
    {
        GameStatus _status = gameStatus;
        Card memory _first = firstCard;
        Card memory _second = secondCard;

        if(_status == GameStatus.INITIAL){
            return "Draw 1st card";
        } else if (_status == GameStatus.WAITING){
            return "Draw 2nd card";
        } else if(_status == GameStatus.ENDED) {
            return _first.val == _second.val ? "Tie" :
                        (_first.val > _second.val ? "1st Card Won" : "2nd Card Won");
        }
    }

    function restartGame() public
    {
        gameStatus = GameStatus.INITIAL;
    }

    function drawCard(CardValue _val, CardSuit _suit) public 
    {
        GameStatus _status = gameStatus;
        require(_status == GameStatus.INITIAL || _status == GameStatus.WAITING, "Game ended");

        if(_status == GameStatus.INITIAL){
            firstCard.val = _val;
            firstCard.suit = _suit;
            gameStatus = GameStatus.WAITING;
        } else if (_status == GameStatus.WAITING){
            secondCard.val = _val;
            secondCard.suit = _suit;
            gameStatus = GameStatus.ENDED;
        }
    }
}