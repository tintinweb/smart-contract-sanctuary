pragma solidity ^0.4.24;

contract Greeter
{
    string goodBye = "Bye Bye~";
    string message = "Say Hello";
    
    function sayHello() public view returns (string)
    {
        return message;
    }
    
    function changeHello(string _newText) public 
    {
        message = _newText;
    }
    
    function sayGoodbye() public view returns (string)
    {
        return goodBye;
    }
    
    function changeGoodBye(string _newText) public
    {
        goodBye = _newText;
    }
}