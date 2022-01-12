/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

pragma solidity ^0.6.0;

contract Suit{
    enum VALUS {two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace}
    enum SUIT {diamond, club, heart, spade}

    struct Card{
        VALUS val;
        SUIT suit;
    }

    Card public firstCard;
    Card public secondCard;

    function drawFirstCard(VALUS _val, SUIT _suit) public returns (VALUS, SUIT) {
        firstCard.val = _val;
        firstCard.suit = _suit;

        return (firstCard.val, firstCard.suit);
    }

    function drawSecondCard(VALUS _val, SUIT _suit) public returns (VALUS, SUIT) {
        secondCard.val = _val;
        secondCard.suit = _suit;

        return (secondCard.val, secondCard.suit);
    }

    function getResult() public view returns (string memory result){
        result = "DRAW";
        if(firstCard.val > secondCard.val){
            result = "first Card Win";
        }
        else if(firstCard.val == secondCard.val){
            if(firstCard.suit > secondCard.suit){
                result = "first Card Win";
            }
            else{
                result = "Second Card Win";
            }
        }
        else if(secondCard.val > firstCard.val){
            result = "Second Card Win";
        }
        
        return result;
    }
}