pragma solidity ^0.4.11;

contract greeter {

    address owner;
    string message;

    function greeter(string _message) public {
        owner = msg.sender;
        message = _message;
    }

    function say() constant returns (string) {
        return message;
    }

    function die() {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }
}