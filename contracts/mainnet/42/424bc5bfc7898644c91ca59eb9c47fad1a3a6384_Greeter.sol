pragma solidity 0.4.21;

contract Greeter {
    string public greeting;
    
    function Greeter(string _greeting) public {
        setGreeting(_greeting);
    }
    
    function setGreeting(string _greeting) public {
        greeting = _greeting;
    }
    
}