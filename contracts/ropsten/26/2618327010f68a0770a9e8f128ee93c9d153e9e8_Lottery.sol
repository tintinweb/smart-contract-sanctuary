pragma solidity ^0.4.0;

contract Lottery{
    
    address public dealer;
    uint count;
    
    address[5] public playerIds; 
   
    constructor () public{
        dealer = msg.sender;
        count = 0;
    }
    
    //function to address the entry of a new player 
    function enterLottery() public payable{
        playerIds[count] = msg.sender;
        count += 1;
        
        //if 5 players have entered choose a winner and reset 
        if(count == 4)
            chooseWinner();
            count = 0;

    }
    
    //random function
    function random() private view returns(uint){
        return uint(keccak256(block.difficulty, now, playerIds));
    }
    
    //choose a winner and send them the winnings
    function chooseWinner() public{
        //require(count == 4, "There must be 5 players present in order to run the lottery");
        
        if(count ==4)
            uint winnerIndex = random()%playerIds.length;
            playerIds[winnerIndex].transfer(address(this).balance);
    }
}