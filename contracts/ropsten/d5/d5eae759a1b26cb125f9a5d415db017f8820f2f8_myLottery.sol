pragma solidity ^0.4.0;
contract myLottery {
    //parameters of contract 
    address public owner; 
   
    //uint public highestbid; 
    
    constructor() public {
        //constructor 
        owner = msg.sender;
    }
    
    uint public playerCount; 
    
    struct player {
        address wallet;
        uint ethAmount; 
    }
    //player public Winner; 
     
    player[] public players; 
    address[] p2;
    
    function joinLottery() payable{
        players.push(player({wallet: msg.sender, ethAmount: msg.value}));
        p2.push(msg.sender);
        playerCount++;
        if(playerCount == 5){
            winner(); 
            playerCount = 0;
            delete players;
            delete p2;
        }
    }
    
    function random () private view returns(uint) {
        return uint(keccak256(block.difficulty, now, p2));
    }
    function winner() public payable {
        uint index = random() % 5;
        player Winner = players[index]; 
        uint balance = this.balance; 
        address winnerAddress = Winner.wallet;
        winnerAddress.transfer(balance);
    }
}