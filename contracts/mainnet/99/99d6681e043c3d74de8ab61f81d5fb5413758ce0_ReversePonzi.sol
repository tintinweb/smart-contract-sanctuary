/**
 *Submitted for verification at Etherscan.io on 2020-12-30
*/

//SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.0;


contract ReversePonzi {
    
    address payable owner; //the devs, gotta pay these cunts something
    address payable leader; //the current leader, set to win 1000x returns
    uint256 gameNumber;
    uint256 lastBlockPlayedOn;
    uint256 blocksPerGame;
    uint256 betsThisGame;
    
    event newPayment(address player, uint amount, uint betsThisGame); // Event for when shit goes down bruh
    
    constructor(){
        owner = payable(msg.sender); //the devs, gotta pay these cunts something
        leader = payable(msg.sender); //the current leader, set to win 1000x returns
        gameNumber = 1;
        lastBlockPlayedOn = block.number;
        blocksPerGame = 6646;
        betsThisGame = 0;
    }
    
    function getStats() public view returns (uint256, uint256, uint256, address, uint256){
        //tell them the contract balance, game number, blocks left, current leader, minimum to become leader
        uint256 blocksLeft = lastBlockPlayedOn + blocksPerGame - block.number;
        uint256 minamount = address(this).balance * 90 / 100 / 1000;
        return ( address(this).balance, gameNumber, blocksLeft, leader, minamount);
    }
    
    receive() external payable { //when some cunt sends fundz

        
        //make sure they sent enough eth
        uint256 amountRequired = (address(this).balance - msg.value) * 90 / 100 / 1000; //it's 90% of the contract balance, divided by 1000, so it's a 1000x multiple;
        
        if(amountRequired > msg.value){
            //they didn't send enough, cunts
            revert("Send more money cunt");
        }
    
        
        //if it's been over 24hrs, then they're too late, game should be finishing
        if(block.number > lastBlockPlayedOn + blocksPerGame){
            revert("Too late cunt");
        }
        
        //well, they sent enough, its not too late, guess the cunt is the leader. Make it so.
        leader = payable(msg.sender);
        lastBlockPlayedOn = block.number;
        
        betsThisGame++;
        
        //tell the world about it
        emit newPayment(msg.sender, msg.value, betsThisGame);
    }
    
    function finishGame() public payable{
        //anyone can 'finish' the game by calling this function, as long as the criteria is met. The devs will do it, but anyone could do it.
        if(block.number < lastBlockPlayedOn + blocksPerGame){
            revert("Slow down cunt, game aint done yet");
        }
        
        uint amountForLeader = address(this).balance * 90 / 100;
        uint amountForDevs = address(this).balance * 5 / 100;
        //5% remains for the next game
        
        //5% to the devs for being sick cunts
        address payable devAddress = owner;
        devAddress.transfer(amountForDevs);
        
        
        //send 90% to the Leader
        address payable leaderAddress = payable(leader);
        //null address is just the devs, so if no-one ends up playing it'll just win
        leader = payable(owner);
        leaderAddress.transfer(amountForLeader);
        
        //increase game number
        gameNumber++;
        lastBlockPlayedOn = block.number;
        betsThisGame = 0;
        
    }
    
}