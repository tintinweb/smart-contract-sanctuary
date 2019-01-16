pragma solidity ^0.4.7;
//make an enter bet function that updates a count variable
//in the update count variable function, if countVariable is five, call the payout winner method
//payout winner calls the random number generator(makes n), and pays to the nth entry, then restarts the contract


contract ballot {
    
    address owner;
    mapping (uint => address) public contestants;
    //var mySeal = contestants[17];

    //variable int x = 0;
    uint numberOfContestants = 0;
    uint runningWagerTotal = 0;
    
    function random () public view returns(uint) {
        uint256 randomNumber = block.number % 5 + 1;
        return randomNumber;
    }
    
    function userAdd(uint userId) public {
        //Similar to an if statement, if true the method continues, if false, it breaks out of //the method
        if(userId > 0){
            //add the users addresses to the user array
            address addressOfContestant = msg.sender;
            addressOfContestant = contestants[userId];
        }
        //else do nothing
    }
    
    //no params for this one, go by aarons piazza post msg.sender
    function enterBet ()  public returns(uint) {
        // `msg.sender` and the ether they wager from `msg.value`
        //add the contestant to the contestants mapping
        userAdd(numberOfContestants);
        //addressOfContestant = contestants[addressOfContestant];
        
        //updates the prize pool
        uint wager = msg.value;
        runningWagerTotal = runningWagerTotal + wager;
        
        //update the numberOfContestants
        numberOfContestants++;
        
        //call the lottery method when there are 5 contestants
        if(numberOfContestants == 5){
            uint256 winner = random();
            //After generating a random number, the smart contract will then initiate a transaction that sends
            //the Ether to the winning address and then restarts the lottery
             contestants[winner].transfer(runningWagerTotal);
        }
        
        return 0;
    }

}