/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

pragma solidity ^0.6.0;

contract Enums {
    enum VAL {two,three,four,five,six,seven,eight,nine,ten,jack,queen,king,ace}
    enum SUIT {diamond,club,heart,spade}
    struct pickedCard {
        VAL val;
        SUIT suit;
    }

    pickedCard public card1;
    pickedCard public card2;
    function houseCard(VAL _val1, SUIT _suit1) public returns (VAL val, SUIT suit){
        card1.val = _val1;
        card1.suit = _suit1;
        return (card1.val, card1.suit);
    }

    function playerCard(VAL _val2, SUIT _suit2) public returns (VAL val, SUIT suit){
        // pickedCard storage card2;
        card2.val = _val2;
        card2.suit = _suit2;
        return (card2.val, card2.suit);
        // console.log(card1.val);
        // require(card2.suit > card1.suit, "Close Call");
        // require(card1.suit > card2.suit, "Bohoo");
    }

    function roundEnd() public view returns(string memory _winner ){
        // pickedCard memory card2;

        if(card2.val > card1.val || (card2.val == card1.val && card2.suit > card1.suit)){
            return "Player";
        }else{
            return "House";
        }
        // return(string _winner);
    }






}