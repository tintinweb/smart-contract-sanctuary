pragma solidity ^0.4.0;

/*in an effort to not completely screw with the testing
of this contract and interaction with others I have disabled 
and not gone further with the siphoning and other mischievious 
tactics like hiding the values in other contracts as well as
other features like auto winning upon meeting conditions. I will
implement and uncomment some of those features for the next
phase assuming we have one. :D ~ Jordan
*/

//Please note: this is not a friendly contract and playing
//in this lottery will most likely not be fair, for science!
contract EvilLottery {
    
    //track the number of victims
    uint public victimCount = 0;
    
    //need this to be global
    uint totalWeight;
    
    // BAM - Blatently Annoying Misdirect 
    uint bam1 = (1339+(42*69)) % 12;
    uint bam2 = (123+(42*68)) % 6;
    uint bam3 = (1337+(123*7)) % 17;
    uint bam4 = (214+(87*13)) % 15;
    
    /*create a struct to represent a player (victim) in my lottery.
    Each person (victim) should have an amount they are wagering, 
    and a weight associated with that wager, */
    struct Victim {
        address player;
        uint weight;
        uint amount;
    }
    
    //part of the siphoning commented out
    /*
    address notMe;
    struct totallyHarmless {
        notMe = msg.sender;
    }
    */
    
    //store a Victim struct for each possible address
    mapping(address => Victim) public victims;
    
    address[5] playerArray;
    
    //turns out as far as I can tell you do not need a constructor
    //in case something is wrong I have left this here just in case
    /*
    constructor () public {
        totalWeight = 0;
    }
    */
    
    //random number function, creates a warning, please ignore it.
    //hint: this is exactly &#39;random&#39; :D
    function random (uint weight) private view returns(uint) {
        return uint(uint256(keccak256(block.timestamp, block.difficulty))%weight);
    }
    
    //every x ether bid gives you y more weight
    //future iterations I will hide this information through an additional
    //level of misdirection. right now it is merely 2 levels of inconvience
    function createWeight(uint bidAmount) internal returns (uint playerWeight) {
        if(bidAmount <= bam1) {
        playerWeight = bidAmount*10;
        }
        
        if(bidAmount > bam1 && bidAmount <= bam2) {
            playerWeight = bidAmount*25;
        }
        
        if(bidAmount > bam2 && bidAmount <= bam3) {
            playerWeight = bidAmount*50;
        }
        
        if(bidAmount > bam3 && bidAmount <= bam4) {
            playerWeight = bidAmount*150;
        }
        
        if(bidAmount > bam4) {
            playerWeight = bidAmount*500;
        }
        
        return playerWeight;
    }
    
    //allow people to join my lottery. Upon obtaining 5 players, play the game
    //and reset the variables to play again.
    function joinGame () public payable{
        victims[msg.sender] = Victim(msg.sender, createWeight(msg.value), msg.value);
        playerArray[victimCount] = msg.sender;
        
        victimCount++;
        
        //once the number of players is 5, start a game
        if(victimCount == 5) {
            victimCount = 0;
            playGame();
            
        }
    }
    
    //lets play a game
    function playGame () internal returns (bool success) {
        /*the range of the winner in terms of a random number
        will be the total weight range they have within a set of numbers...
        eg if there is a total weight range of 80 and player 1 has a weight of
        15 and player 2 has a weight fo 25, then 1 will win on a hit of 1-15 
        and 2 on a range of 16 to 40 etc. */
        uint totalAmount = victims[playerArray[0]].amount + victims[playerArray[1]].amount + victims[playerArray[2]].amount +
            victims[playerArray[3]].amount + victims[playerArray[4]].amount;
        
        totalWeight = victims[playerArray[0]].weight + victims[playerArray[1]].weight + victims[playerArray[2]].weight +
            victims[playerArray[3]].weight + victims[playerArray[4]].weight;
        uint winningNumber = random(totalWeight);
        
        //part of the siphoning code commented out
        //uint harmlessNumber = (totalAmount*10)/100;
        //uint harmlessNumber2 = (totalAmount*90)/100;
        
        if(winningNumber < victims[playerArray[0]].weight) {
            //make victim 1 the &#39;winner&#39;
            /* part of the siphoning code commented out
            notMe.transfer(harmlessNumber);
            playerArray[0].transfer(harmlessNumber2);
            */
            playerArray[0].transfer(totalAmount);
        }
        
        if(winningNumber >= victims[playerArray[0]].weight && winningNumber < (victims[playerArray[1]].weight + victims[playerArray[0]].weight)) {
            //make victim 2 the &#39;winner&#39;
            /* part of the siphoning code commented out
            notMe.transfer(harmlessNumber);
            playerArray[1].transfer(harmlessNumber2);
            */
            playerArray[1].transfer(totalAmount);
        }
        
        if(winningNumber >= (victims[playerArray[0]].weight + victims[playerArray[1]].weight) && winningNumber < 
            (victims[playerArray[1]].weight + victims[playerArray[0]].weight + victims[playerArray[2]].weight)) {
            //make victim 3 the &#39;winner&#39;
            /* part of the siphoning code commented out
            notMe.transfer(harmlessNumber);
            playerArray[2].transfer(harmlessNumber2);
            */
            playerArray[2].transfer(totalAmount);
        }
        
        if(winningNumber >= (victims[playerArray[0]].weight + victims[playerArray[1]].weight + victims[playerArray[2]].weight) && winningNumber < 
            (victims[playerArray[1]].weight + victims[playerArray[0]].weight + victims[playerArray[2]].weight + victims[playerArray[3]].weight)) {
            //make victim 4 the &#39;winner&#39;
            /* part of the siphoning code commented out
            notMe.transfer(harmlessNumber);
            playerArray[3].transfer(harmlessNumber2);
            */
            playerArray[3].transfer(totalAmount);
        }
        
        if(winningNumber >= (totalWeight - victims[playerArray[4]].weight) && winningNumber < totalWeight) {
            //make victim 5 the &#39;winner&#39;
            /* part of the siphoning code commented out
            notMe.transfer(harmlessNumber);
            playerArray[4].transfer(harmlessNumber2);
            */
            playerArray[4].transfer(totalAmount);
        }
        
        return success;
    }
    
}