pragma solidity ^0.4.0;
contract Ballot {

    address chairperson;  //my address
    uint public particNum;
    address[5] public participants;
    uint256[5] public betVals;
    uint256 public totalBets;
    uint256 theRandNum;

    constructor () public {   //similar to a main method in java
        chairperson = msg.sender;
        totalBets = 0;
        particNum = 0;
        theRandNum = 9999;
    }
    
    function getTheRandNum () public view returns(uint) {
        return theRandNum;
    }
    
    function getParticNum () public view returns(uint) {
        return particNum;
    }
    
    function getParticipants () public view returns(address[5]) {
        return participants;
    }
    
    function getTotalBets () public view returns(uint256) {
        return totalBets;
    }
    
    function Bet() public payable {
        participants[particNum] = msg.sender;
        betVals[particNum] = msg.value;
        particNum += 1;
        
        totalBets += msg.value;
        //totalBets += betAmount;

        if(particNum == 5) {
            randomByWeight();
            //random();
        }
    }
    
    function random1 () private view returns(uint) {
        return uint(keccak256(block.difficulty, now, participants));
    }

    // The more Ether you wager, the more likely you are to win 
    function randomByWeight() private {
        uint randomNum = random1() % totalBets;
        
        //uint256 randomNum = block.number % totalBets;
        theRandNum = randomNum;
        
        uint256 winnerFound = 0;
        uint256 totalSoFar = 0;
        for(uint256 i = 0 ; i < 5 ; i++) {
            totalSoFar += betVals[i];
            if(randomNum <= totalSoFar){
                distributePrize(i);
                winnerFound = 1;
                break;
            }
        }
        
        // if the above method didn&#39;t work, pick the winner totally randomly
        if(winnerFound == 0) {  
            random();
        }
    }
    
        
    function random() private {
        // uint256 randomNum = block.number % 5 + 1;
        uint randomNum = random1() % 5;
        distributePrize(randomNum);
    }
    
    function distributePrize(uint winner) private {
        participants[winner].transfer(totalBets);
        particNum = 0;
        totalBets = 0;
    }
}