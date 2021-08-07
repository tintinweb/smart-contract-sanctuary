/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

//How to play ETHtactoe:
//Go to the "Play against someone" function and imput your friend's ethereum address to create a match!

//You are X while your friend is O.

//To imput Xs and Os, you have to imput the corrisponsing number of the box
/*
______________________
|      |      |      |
|  1   |  2   |  3   |
______________________
|      |      |      |
|  4   |  5   |  6   |
______________________
|      |      |      |
|  7   |  8   |  9   |
______________________
*/

//Get a 3 in a row to win!

contract EthTacToe {
    
    address opponents;
    address challenger;
    uint8 contracttime = 1;
    
    function PlayAgainstSomeone(address opponent)public{
        
        require(msg.sender != opponent, "Bruh, you can't play against yourself");
        challenger = msg.sender;
        opponents = opponent;
    }
    
    function ResetGame() public {
        
        require(msg.sender == challenger || msg.sender == opponents);
        
        challenger = 0x0000000000000000000000000000000000000000;
        opponents = 0x0000000000000000000000000000000000000000;
        contracttime = 1;
        Xlocations = 0;
        Olocations = 0;
        turn1locationmemory = 0;
        turn2locationmemory = 0;
        turn3locationmemory = 0;
        turn4locationmemory = 0;
        turn5locationmemory = 0;
        turn6locationmemory = 0;
        turn7locationmemory = 0;
        turn8locationmemory = 0;
        turn9locationmemory = 0;
        
    }
    
    //oh god, I have no idea how to do this a short way, so I guess ill do it the long way
    //Hopefully this doesn't take a lot of gas to execute
    //nvm this actually this saves gas, since these are preloaded values
    
    uint8 evencontracttime2 = 2;
    uint8 evencontracttime4 = 4;
    uint8 evencontracttime6 = 6;
    uint8 evencontracttime8 = 8;
    uint8 oddcontracttime1 = 1;
    uint8 oddcontracttime3 = 3;
    uint8 oddcontracttime5 = 5;
    uint8 oddcontracttime7 = 7;
    uint8 oddcontracttime9 = 9;
    
    //ok fancy divider so I can put the important stuff here
    
    uint256 Xlocations;
    uint256 Olocations;
    
    //These variables are for memory, uses less gas
    
    uint8 turn1locationmemory = 0;
    uint8 turn2locationmemory = 0;
    uint8 turn3locationmemory = 0;
    uint8 turn4locationmemory = 0;
    uint8 turn5locationmemory = 0;
    uint8 turn6locationmemory = 0;
    uint8 turn7locationmemory = 0;
    uint8 turn8locationmemory = 0;
    uint8 turn9locationmemory = 0;
    
    function PlayX(uint8 PlacetoPlayX) public {
        
        require(msg.sender == challenger, "Wrong Symbol, ur O");
        require(contracttime == oddcontracttime1 || contracttime == oddcontracttime3 || contracttime == oddcontracttime5 || contracttime == oddcontracttime7 || contracttime == oddcontracttime9, "Its not your turn!");
        require(turn1locationmemory != PlacetoPlayX && PlacetoPlayX != turn2locationmemory && PlacetoPlayX != turn2locationmemory && PlacetoPlayX != turn3locationmemory && PlacetoPlayX != turn3locationmemory && 
                PlacetoPlayX != turn5locationmemory && PlacetoPlayX != turn6locationmemory, "You can't place this here because there is already an X or O here!");
        require(PlacetoPlayX >= oddcontracttime1);
        require(PlacetoPlayX <= oddcontracttime9);
        
        Xlocations = Xlocations * 10;
        Xlocations = Xlocations + PlacetoPlayX;
        
        if(contracttime == oddcontracttime1){
            turn1locationmemory = PlacetoPlayX;
        }
        else{}
        if(contracttime == oddcontracttime3){
            turn3locationmemory = PlacetoPlayX;
        }
        if(contracttime == oddcontracttime5){
            turn5locationmemory = PlacetoPlayX;
        }
        if(contracttime == oddcontracttime7){
            turn7locationmemory = PlacetoPlayX;
        }
        if(contracttime == oddcontracttime9){
            turn9locationmemory = PlacetoPlayX;
        }
        
        contracttime = contracttime + 1;
        
    }
    
    function PlayO(uint8 PlacetoPlayO) public{
        
        require(contracttime == evencontracttime2 || contracttime == evencontracttime4 || contracttime == evencontracttime6 || contracttime == evencontracttime8, "Its not your turn!");
        require(msg.sender == opponents, "Wrong Symbol, ur X");
        require(PlacetoPlayO != turn1locationmemory && PlacetoPlayO != turn2locationmemory && PlacetoPlayO != turn2locationmemory && PlacetoPlayO != turn3locationmemory && PlacetoPlayO != turn3locationmemory && 
                PlacetoPlayO != turn5locationmemory && PlacetoPlayO != turn6locationmemory, "You can't place this here because there is already an X or O here!");
        require(PlacetoPlayO >= oddcontracttime1);
        require(PlacetoPlayO <= oddcontracttime9);
        
        Olocations = Olocations * 10;
        Olocations = Olocations + PlacetoPlayO;
        
        if(contracttime == evencontracttime2){
            turn2locationmemory = PlacetoPlayO;
        }
        if(contracttime == evencontracttime4){
            turn4locationmemory = PlacetoPlayO;
        }
        if(contracttime == evencontracttime6){
            turn6locationmemory = PlacetoPlayO;
        }
        if(contracttime == evencontracttime8){
            turn8locationmemory = PlacetoPlayO;
        }
        
        contracttime = contracttime + 1;
        
    }
    
    string Aexplaination = "These numbers are the spaces where the O and X's are. Refer to the info on the left to view the board";
    
    function SeeBoardX() public view returns (uint256){
        
        return Xlocations;
    }
    
    function SeeboardO() public view returns (uint256){
        
        return Olocations;
    }
    
    function SeeBoardExplaination()public view returns (string memory){
        
        return Aexplaination;
    }
    
    string wintext = "Check the seeboard functions and the chart on the left to see if you won!";
    
    function CheckifWin() public view returns(string memory){
        
        return wintext;
    }
    
}