/**
 *Submitted for verification at Etherscan.io on 2021-08-17
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
     string R;
     string P;
     
 }
 
    function EthereumDatabase()
    {
        owner = msg.sender;
    }
    
    database[] public databaseinput;
    
    mapping(address=>int) public userinput;
    
    function SetDatabase(int256 id, string name, string destinasi, string R, string P)
    {
        var hash = sha3(msg.sender, owner, R);
        var CurrentData = userinput[msg.sender];
        id = CurrentID + 1;
        CurrentID = id;
        
        userinput[msg.sender] = id;
        var data = database(msg.sender, id, name ,destinasi, R, P);
        databaseinput.push(data);
    }
    
        function getCountTopScores() returns(uint) {
        return databaseinput.length;
    }
    
}