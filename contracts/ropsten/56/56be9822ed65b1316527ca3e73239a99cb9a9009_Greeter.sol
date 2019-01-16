pragma solidity ^0.4.24;

contract Greeter {
    string public greeting;

    function Greeter() {
        greeting = &#39;Hello&#39;;
    }

    function setGreeting(string _greeting) public {
        greeting = _greeting;
    }

    function greet() constant returns (string) {
        return greeting;
    }
}