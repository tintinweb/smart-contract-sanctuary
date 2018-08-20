pragma solidity ^0.4.0;

contract Greeter
{
    address admin;
    string greeting;

    constructor() public
    {
        admin = msg.sender;
        greeting = &#39;DEPLOYED&#39;;
    }

    function greet() constant public returns (string)
    {
        return greeting;
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
        if (msg.sender == admin)
            selfdestruct(admin);
    }

}