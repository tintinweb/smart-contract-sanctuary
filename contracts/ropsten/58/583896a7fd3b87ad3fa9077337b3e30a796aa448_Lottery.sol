pragma solidity ^0.4.0;
contract Lottery {
    
    constructor() public payable {
        
    }
    
    address[5] participants;
    uint count = 0;
    uint wagerAmount = 0;
    
    function enterContract() public {
        participants[count] = msg.sender;
        wagerAmount += msg.value;   //Add participant&#39;s waged amount
        count += 1;
        //Have enough participants when count = 4, call random
        if(count == 4){
            uint winner = random()%5;
            //Send wagerAmount to winner&#39;s address
            participants[winner].transfer(wagerAmount);
            wagerAmount = 0;
            count = 0;
        }
    }
    
    function random () private view returns(uint) {
        return uint(keccak256(block.difficulty, now, participants));
    }
    
}