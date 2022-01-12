/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

pragma solidity ^0.6.0;

contract Game{

    enum VAL {two,three,four,five,six,seven,eight,nine,ten,jack,queen,king,ace}
    enum SUIT {spade,diamond,heart,clubs}
    enum STATUS {start,waiting,end}

    struct newGame{
        STATUS status;
        VAL firstGameVal;
        SUIT firstGameSuit;
        VAL secondGameVal;
        SUIT secondGameSuit;
    }

    newGame public game;
    function pickCard(VAL _choice1,SUIT _choice2) public returns(bool){
        require(game.status==STATUS.start,"wrong game");
        game.firstGameSuit = _choice2;
        game.firstGameVal = _choice1;
        game.status = STATUS(uint(game.status)+1);
        return true;
    }

    function pickSecondCard(VAL _choice1,SUIT _choice2) public returns (string memory){
        require(game.status!=STATUS.waiting,"wrong game");
        game.secondGameSuit = _choice2;
        game.secondGameVal = _choice1;
        game.status = STATUS(uint(game.status)+1);
        if(uint(game.firstGameSuit)>= uint(game.secondGameSuit)) {
            return "WIN"; 
            if (uint(game.firstGameVal)< uint(game.secondGameVal)){
                return "LOSE";
            }
        }
        
        if (uint(game.firstGameVal) == uint(game.secondGameVal)){
            return "DRAW";
        }
        return "LOSE";
    }
}