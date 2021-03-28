/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity ^0.4.10;

contract EthereumDatabase
{
 
 address owner;
 int256 public CurrentID;
 
 struct database
 {
     address addr;
     int id;
     string name;
     string destinasi;
     int R1;
     int R2;
     int R3;
     int R4;
     int R5;
     int R6;
 }
 
    function EthereumDatabase()
    {
        owner = msg.sender;
    }
    
    database[] public databaseinput;
    
    mapping(address=>int) public userinput;
    
    function SetDatabase(int256 id, string name, string destinasi, int256 R1, int256 R2, int256 R3, int256 R4, int256 R5, int256 R6)
    {
        var hash = sha3(msg.sender, owner, R1);
        var CurrentData = userinput[msg.sender];
        id = CurrentID + 1;
        CurrentID = id;
        
        userinput[msg.sender] = R1;
        var data = database(msg.sender, id, name ,destinasi, R1, R2, R3, R4, R5, R6);
        databaseinput.push(data);
    }
    
        function getCountTopScores() returns(uint) {
        return databaseinput.length;
    }
    
}