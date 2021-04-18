/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

pragma solidity ^0.4.18;

contract GreeterArray {
    
    struct GreetingMessage {
           string message;
           address owner;
    }
    
    GreetingMessage[] public greetings;
    
    address contractOwner;
    
    modifier onlyOwner(){
        require (contractOwner  == msg.sender);
        _;       
    }
    
    function GreeterArray() public {
        greetings.push(GreetingMessage("Hello Codefistion", msg.sender));
        contractOwner = msg.sender;
    }
    
    function getGreeting(uint idx) onlyOwner public constant returns (string, address){
        GreetingMessage storage currentMessage = greetings[idx];
        return (currentMessage.message, currentMessage.owner);
        
    }

    function setGreeting(string greetingMsg) public{
        greetings.push(GreetingMessage(greetingMsg, msg.sender));
    }
    
}