/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity ^0.4.10;

contract EthereumDatabase
{
 
 address owner;
 int256 public CurrentID;
 
 struct databaseR
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
 
  struct databaseP
 {
     address addr;
     int id;
     string name;
     string destinasi;
     int P1;
     int P2;
     int P3;
     int P4;
     int P5;
     int P6;
     int P7;
     int P8;
 }
 
    function EthereumDatabase()
    {
        owner = msg.sender;
    }
    
    databaseR[] public databaseinputR;
    
    databaseP[] public databaseinputP;
    
    mapping(address=>int) public userinput;
    
    function SetDatabaseR(int256 id, string name, string destinasi, int256 R1, int256 R2, int256 R3, int256 R4, int256 R5, int256 R6)
    {
       // var hash = sha3(msg.sender, owner, R1);
        var CurrentData = userinput[msg.sender];
        id = CurrentID + 1;
        CurrentID = id;
        
        userinput[msg.sender] = R1;
        var dataR = databaseR(msg.sender, id, name ,destinasi, R1, R2, R3, R4, R5, R6);
        
        databaseinputR.push(dataR);
    }
    
        function SetDatabaseP(int256 id, string name, string destinasi, int256 P1, int256 P2, int256 P3, int256 P4, int256 P5, int256 P6, int256 P7, int256 P8 )
    {
       // var hash = sha3(msg.sender, owner, R1);
        var CurrentData = userinput[msg.sender];
        id = CurrentID + 1;
        CurrentID = id;
        
        userinput[msg.sender] = P1;
        var dataP = databaseP(msg.sender, id, name ,destinasi, P1, P2, P3, P4, P5, P6, P7, P8);
        
        databaseinputP.push(dataP);
    }
    
    
    
    function getCountTopScoresDatabaseR() returns(uint) {
        return databaseinputR.length;
    }
    
    function getCountTopScoresDatabaseP() returns(uint) {
        return databaseinputR.length;
    }
    
}