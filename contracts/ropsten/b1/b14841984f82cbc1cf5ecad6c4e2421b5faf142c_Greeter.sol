pragma solidity ^0.4.17;
contract Greeter {
    string public greeting;

    function Greeter() public {
        greeting = &#39;Hello&#39;;
    }

    function setGreeting(string _greeting) public {
        greeting = _greeting;
    }

    function greet() view public returns (string) {
        return greeting;
    }
}