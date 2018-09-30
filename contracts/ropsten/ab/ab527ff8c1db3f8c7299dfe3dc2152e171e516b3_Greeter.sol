pragma solidity ^0.4.20;

contract Greeter         // The contract definition. A constructor of the same name will be automatically called on contract creation. 
{
    address creator;     // At first, an empty "address"-type variable of the name "creator". Will be set in the constructor.
    string greeting;     // At first, an empty "string"-type variable of the name "greeting". Will be set in constructor and can be changed.

    constructor(string _greeting) public   // The constructor. It accepts a string input and saves it to the contract&#39;s "greeting" variable.
    {
        creator = msg.sender;
        greeting = _greeting;
    }

    function greet() constant public returns (string)          
    {
        return greeting;
    }
    
    function getBlockNumber() constant public returns (uint) // this doesn&#39;t have anything to do with the act of greeting
    {													// just demonstrating return of some global variable
        return block.number;
    }
    
    function setGreeting(string _newgreeting) public
    {
        greeting = _newgreeting;
    }
    
     /**********
     Standard kill() function to recover funds 
     **********/
    
    function kill() public
    { 
        if (msg.sender == creator)  // only allow this action if the account sending the signal is the creator
            selfdestruct(creator);       // kills this contract and sends remaining funds back to creator
    }

}