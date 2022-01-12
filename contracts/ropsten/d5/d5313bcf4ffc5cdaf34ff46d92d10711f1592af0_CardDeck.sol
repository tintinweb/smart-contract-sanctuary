/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity >= 0.4.22 <0.6.0;

contract CardDeck {
    enum Status { OFF, ON }
    enum Suit { Spades, Clubs, Diamonds, Hearts}
    enum Value { 
        Two, Three, Four, Five, Six, 
        Seven, Eight, Nine, Ten, 
        Jack, King, Queen, Ace 
    }
    struct Card {
        Suit suit;
        Value value;
    }
    
    Card public card1;
    Card public card2;
    Card public card3;
    Status public status;
    
    function pick_card_1(Suit _suit, Value _value) public returns (Suit, Value) {
        card1.suit = _suit;
        card1.value = _value;
        status = Status.ON;
        return (card1.suit, card1.value);
    }
    function pick_card_2(Suit _suit, Value _value) public returns (Suit, Value) {
        card2.suit = _suit;
        card2.value = _value;
        status = Status.ON;
        return (card2.suit, card2.value);
    }
    function pick_card_3(Suit _suit, Value _value) public returns (Suit, Value) {
        card3.suit = _suit;
        card3.value = _value;
        status = Status.ON;
        return (card3.suit, card3.value);
    }

    function highest_value() public view returns(uint) {
       if (card1.value > card2.value)
        {
            if (card1.value > card3.value)
            {
                return 1;
            }
            else
            {
                return 3;
            }
        }
        else if (card2.value > card3.value)
        {
            return 2;
        }
        else
        {
            return 3;
        }
        }

    function changeSuit(Suit _suit) public {
        status = Status.ON;
        card1.suit = _suit;
    }
    
}