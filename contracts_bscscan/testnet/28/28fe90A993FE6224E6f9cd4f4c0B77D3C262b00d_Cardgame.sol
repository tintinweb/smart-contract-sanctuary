/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

pragma solidity ^0.6.0;

contract Cardgame {
    enum VAL { two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace }
    enum SUIT { diamond, club, heart, spade }

    uint8 constant LAST_PHASE = 2;
    uint8 currentPhase = 0;

    struct pickCard {
        VAL val;
        SUIT suit;
    }

    pickCard public firstCard;
    function getFirstCard(VAL _choice1, SUIT _choice2) public returns(VAL, SUIT) {
        firstCard.val = _choice1;
        firstCard.suit = _choice2;
        if (currentPhase < LAST_PHASE) {
            currentPhase++;
        }
        return (firstCard.val, firstCard.suit);
    }

    pickCard public secondCard;
    function getSecondCard(VAL _choice1, SUIT _choice2) public returns(VAL, SUIT) {
        secondCard.val = _choice1;
        secondCard.suit = _choice2;
        if (currentPhase < LAST_PHASE) {
            currentPhase++;
        }
        return (secondCard.val, secondCard.suit);
    }

    function compareCard() public view returns(string memory) {
        require(currentPhase == 2, "Get more cards.");
        if (secondCard.val > firstCard.val) {
            return "larger";
        } else if (secondCard.val == firstCard.val) {
            return "equal";
        } else {
            return "smaller";
        }
    }
}