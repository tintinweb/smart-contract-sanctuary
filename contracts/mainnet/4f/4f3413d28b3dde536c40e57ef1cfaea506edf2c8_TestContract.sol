// We will be using Solidity version 0.5.3
pragma solidity 0.5.3;

contract TestContract {
    // Container of the greeting
    string private greeting;
    
    // Initialize the greeting to Hello!!. 
    constructor() public {
        greeting = "Hello!!";        
    }
    
    /** @dev Function to set a new greeting.
      * @param newGreeting The new greeting message. 
      */
    function setGreeting(string memory newGreeting) public {
        greeting = newGreeting;
    }
    
    /** @dev Function to greet. 
      * @return The greeting string. 
      */
    function greet() public view returns (string memory) {
        return greeting;
    }
}