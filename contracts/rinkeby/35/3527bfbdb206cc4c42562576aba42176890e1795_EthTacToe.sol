/**
 *Submitted for verification at Etherscan.io on 2021-08-05
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
    string matchmade = "TicTacToe match has been made!";
    uint256 Player1;
    uint256 contracttime = 1;
    
    function PlayAgainstSomeone(address opponent)public returns(string memory){
        
        require(msg.sender != opponents, "Bruh, you can't play against yourself");
        challenger = msg.sender;
        opponents = opponent;
        return matchmade;
    }
    
    string ResetText = "Successfully Reset";
    
    function ResetGame() public returns (string memory){
        
        challenger = 0x0000000000000000000000000000000000000000;
        opponents = 0x0000000000000000000000000000000000000000;
        contracttime = 1;
        Xlocations = 0;
        Olocations = 0;
        
        return ResetText;
        
    }
    
    //oh god, I have no idea how to do this a short way, so I guess ill do it the long way
    //Hopefully this doesn't take a lot of gas to execute
    
    uint256 evencontracttime2 = 2;
    uint256 evencontracttime4 = 4;
    uint256 evencontracttime6 = 6;
    uint256 evencontracttime8 = 8;
    uint256 oddcontracttime1 = 1;
    uint256 oddcontracttime3 = 3;
    uint256 oddcontracttime5 = 5;
    uint256 oddcontracttime7 = 7;
    uint256 oddcontracttime9 = 9;
    
    //ok fancy divider so I can put the important stuff here
    
    string placedmessageX = "X has been placed, wait for the other person to play";
    string placedmessageO = "O has been placed, wait for the other person to play";
    uint256 Xlocations;
    uint256 preXlocation;
    uint256 Olocations;
    uint256 preOlocations;
    
    function PlayX(uint256 PlacetoPlayX) public returns (string memory){
        
        require(msg.sender == challenger, "Wrong Symbol, ur O");
        require(contracttime == evencontracttime2 || contracttime == evencontracttime4 || contracttime == evencontracttime6 || contracttime == evencontracttime8, "Its not your turn!");
        require(PlacetoPlayX >= oddcontracttime1);
        require(PlacetoPlayX <= oddcontracttime9);
        
        contracttime = contracttime + 1;
        PlacetoPlayX = preXlocation;
        
        Xlocations = Xlocations * 10;
        Xlocations = Xlocations + preXlocation;
        
        require(Xlocations != PlacetoPlayX);
        
        return placedmessageX;
        
    }
    
    function PlayO(uint256 PlacetoPlayO) public returns (string memory){
        
        require(contracttime == oddcontracttime1 || contracttime == oddcontracttime3 || contracttime == oddcontracttime5 || contracttime == oddcontracttime7 || contracttime == oddcontracttime9, "Its not your turn!");
        require(msg.sender == opponents, "Wrong Symbol, ur X");
        require(PlacetoPlayO >= oddcontracttime1);
        require(PlacetoPlayO <= oddcontracttime9);
        
        contracttime = contracttime + 1;
        PlacetoPlayO = preOlocations;
        Olocations = Olocations * 10;
        Olocations = Olocations + preOlocations;
        
        return placedmessageO;
    }
    
    string Aexplaination = "These numbers are the spaces where the O and X's are. O on the top, X on the bottom.";
    
    function SeeBoard() public view returns (uint256){
        
        return Xlocations;
        return Olocations;
    }
    
    function SeeBoardExplaination()public view returns (string memory){
        
        return Aexplaination;
    }
}