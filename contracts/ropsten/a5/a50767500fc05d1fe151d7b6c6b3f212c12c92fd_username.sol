pragma solidity ^0.4.24;

contract username {
    string myname = "demo";
    
    constructor (username) public {
       // msg.sender;
    }
    
    function getUsername () public constant returns (string) {
        //address = myAdd; 
        //if myAdd = msg.sender
        return myname;  
    }
}