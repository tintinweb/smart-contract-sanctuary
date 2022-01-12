/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity >=0.6.0 <0.9.0;

contract Game{

    enum VAL {two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace}
    enum SUIT {spade, diamond, heart, clubs}
    enum STATUS {start, waiting, end}
    event GAME(string indexed status, string indexed _firstGameVal, string _firstGameSuit);

    struct newGame{
        VAL val;
        SUIT suit;
        STATUS status;
    }

    newGame public game1;
    newGame public game2;

    function getFirstCard(VAL _choice1, SUIT _choice2) public returns (VAL, SUIT){
        game1.val = _choice1;
        game1.suit = _choice2;
        game1.status = STATUS.waiting;
        return (game1.val, game1.suit);
    }

    function getSecondCard(VAL _choice1, SUIT _choice2) public returns (VAL, SUIT){
        game2.val = _choice1;
        game2.suit = _choice2;
        game2.status = STATUS.waiting;
        return (game2.val, game2.suit);
    }

    function compare() public view returns (string memory){
        require(game1.status==STATUS.waiting, "Please wait Player1 choose.");
        require(game2.status==STATUS.waiting, "Please wait Player2 choose.");

        if(game1.val > game2.val)
        {
            return "Player 1 Win.";
        }
        else if(game1.val == game2.val){
            if(game1.suit > game2.suit){
                return "Player 1 Win.";
            }
            else if (game1.suit == game2.suit){
                return "Draw!!!.";
            }
            else{
                return "Player 2 Win.";
            }
        }
        else
        {
            return "Player 2 Win.";
        }
    }

    function reset() public {
        game1.status=STATUS.start;
        game2.status=STATUS.start;
        delete game1.val;
        delete game2.val;
        delete game1.suit;
        delete game2.suit;
    }

}