pragma solidity ^0.4.25;

contract OurMessage {
    string public message;
    
    constructor (string _message) public {
        message = _message;
    }
}