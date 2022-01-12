/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity 0.6.0;

contract Game {
    enum VAL {two , three, four, five, six, seven, eight, nine, ten, jack, king, queen, ace}
    enum SUIT {spade, clubs, diamond, hearts}
    enum STATUS {start, waiting, end}
    event GAME (string indexed status, string indexed _firstGameVal, string firstGameSuit);

    struct newGame {
        VAL firstGameVal;
        SUIT firstGameSuit;
        VAL secondGameVal;
        SUIT secondGameSuit;
        STATUS status;
    }

    newGame public game;

    function getFirstCard(VAL _choice1, SUIT _choice2) public returns (bool){
        // game.status = STATUS.start;
        require(game.status != STATUS.start, "wrong game");
        game.firstGameVal = _choice1;
        game.firstGameSuit = _choice2;
        game.status = STATUS.waiting;
        // game.status = STATUS(uint(game.status)+1);
        return true;
    }

    function getSecondCard(VAL _choice1, SUIT _choice2) public returns (bool){
        require(game.status != STATUS.waiting, "wrong game");
        game.secondGameVal = _choice1;
        game.secondGameSuit = _choice2;
        return true;
    }

    function compare() public view returns(string memory){
        require(game.status != STATUS.waiting, "wrong game");
        
        if(game.firstGameVal > game.secondGameVal){
            return "Card 1 Win";
        } else if (game.firstGameVal == game.secondGameVal){
            if(game.firstGameSuit > game.secondGameSuit){
                return "Card 1 Win";
            } else if (game.firstGameSuit < game.secondGameSuit){
                return "Card 2 Win";
            } else return "Draw";
        } else {
            return "Card 2 Win";
        }
        
        // game.status = STATUS(uint(game.status)+1);
        // emit GAME("WIN","two","spade");
        // if(uint(game.firstGameSuit) >= uint(game.secondGameSuit))
        // {
        //     return "Card 2 WIN";
        // }
        // else if(uint(game.firstGameVal) >= uint(game.secondGameVal)){
        //     return "WIN";
        // }
        // else
        // {
        //     return "LOSE";
        // }
    }
}