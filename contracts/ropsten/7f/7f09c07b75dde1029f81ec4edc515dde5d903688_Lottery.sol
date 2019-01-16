// Jonathan Sphar
// CSE 297 
pragma solidity ^0.4.25;

contract Lottery{
    
    address[5] players;
    uint winnings;
    uint numEntries;
    address owner;
    
    constructor() public{
        // starts the Lottery
        numEntries = 0;
        winnings = 0;
        owner = msg.sender;
    }
    
    function getWinnings() public view returns(uint){
        if (owner == msg.sender){
            return winnings;
        }
    }
        
    function getNumEntries() public view returns(uint){
        if (owner == msg.sender){
            return numEntries;
        }
    }
    
    function payOut() private{
        // compute winner 
        uint winner = (random() % 5);
        
        // pay to winner
        players[winner].transfer(winnings);
        
        // restart
        restartLottery();
    }
    
    function restartLottery() private{
        // reset numEntries - new players will overwrite allPlayers and entries
        numEntries = 0;
        winnings = 0;
    }
    
    
    
    function wager() public payable {
        numEntries++;
        winnings += msg.value;
        players[numEntries -1] = msg.sender;
        if(numEntries == 5){
            payOut();
        }
    }
    
    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, players)));
    }
}