pragma solidity 0.4.25;

contract Greeting {
    string public greeting;
    
    function setGreeting(string newGreeting) public {
        greeting = newGreeting;
    }
}