/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

pragma solidity 0.8.0;

contract Game {

        enum VAL {two,three,four,five,six,seven,eight,nine,ten,jack,queen,king,ace}
        enum SUIT {space,diamond,heart,clubs}
        enum STATUS {start,waiting,end}

        struct newGame{
             VAL val;
             SUIT suit;
             STATUS status;
        }

        newGame public firstCard;
        newGame public secondCard;

    function drawFirstCard(VAL _choice1, SUIT _choice2) public returns (VAL){
            firstCard.val  = _choice1;
            firstCard.suit = _choice2;
            firstCard.status = STATUS.waiting;
        }

    function drawSecondCard(VAL _choice1, SUIT _choice2) public returns (SUIT){
        require(secondCard.status!=STATUS.waiting,"wrong game");
            secondCard.val  = _choice1;
            secondCard.suit = _choice2;
            secondCard.status = STATUS.end;
    }

    function checkCardGame() public returns (string memory){
         require(secondCard.status!=STATUS.waiting,"wrong game");

         if(firstCard.val == secondCard.val && firstCard.suit == secondCard.suit){
             return "Draw";
         }

         if(firstCard.val == secondCard.val){
            if(firstCard.suit > secondCard.suit){
                 return "First Winning";
             }
             else{
             return "Second Winning";
             }
         }
         else{
             if(firstCard.val > secondCard.val){
                 return "First Winning";
             }
             else{
                 return "Second Winning";
             }
         }
      
    
    }

}