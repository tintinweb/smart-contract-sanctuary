pragma solidity ^0.4.24;

/*
   Validity Labs AG, 2018, MIT license
   
   a simple introduction smart contract
   with an example of how to set and get values in Solidity
*/

contract Hello {
    
    // making this property `public` automatically creates a getter, so `getGreeting` is not really needed
    string public greeting;
    
    // for event logging that allows to easily list past greetings in javascript
    event GotGreeting(string);
    
    // setter function
    function setGreeting(string newGreeting) public {
        greeting = newGreeting;
        emit GotGreeting(newGreeting);
    }
    
    // getter function, should be marked as `view` so that the value can be querried from javascript
    // `view` functions cannot change any contract properties that are written to storage
    // e.g. this function could not change the value of the property `greeting`.
    function getGreeting() public view returns (string g) {
        g = greeting;
    }
}