/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

pragma solidity ^0.4.18;

contract Greeter{
    
    struct GreetingMessage{
        string message;
        address owner;
    }
    
    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    }
    
    GreetingMessage[] public greetings;
    address owner;
    
    function Greeter() public {
        greetings.push(GreetingMessage("hello world", msg.sender));
    }
    
    function getGreeting(uint idx) onlyOwner public constant returns (string, address){
        GreetingMessage storage currentMessage = greetings[idx];
        return (currentMessage.message, currentMessage.owner);
    }
    
    function setGreeting(string newGreeting) public {
        greetings.push(GreetingMessage(newGreeting, msg.sender));
    }
}