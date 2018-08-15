pragma solidity ^0.4.17;

contract Greeter{
    address creator;
    string greeting;

    constructor(string _greeting) public {
        creator = msg.sender;
        greeting = _greeting;
    }

    function greet() public view returns (string) {
        return greeting;
    }

    function getCreator() public view returns (string) {
        return greeting;
    }

    function setGreeting(string _newgreeting) public {
        greeting = _newgreeting;
    }

    function kill() public{
        if (msg.sender == creator) {
            selfdestruct(creator);
        }
    }
}