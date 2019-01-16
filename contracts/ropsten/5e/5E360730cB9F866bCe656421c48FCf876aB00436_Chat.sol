pragma solidity ^0.4.0;
contract Chat {

string public lemessage;
     
    function Message(string _messageoriginal) public {
 
        lemessage = _messageoriginal;
 
    }
     
    function definirMessage(string _nouveaumessage) public{
 
    lemessage = _nouveaumessage;
     
    }
     
    function voirMessage() public view returns (string){  
 
        return lemessage;
 
    }
     
}