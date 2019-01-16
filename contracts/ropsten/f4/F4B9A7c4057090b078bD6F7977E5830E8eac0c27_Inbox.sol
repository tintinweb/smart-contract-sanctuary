pragma solidity ^0.4.24;

contract Inbox {

    string public message;
    int public age;
    address public owner;

    constructor (string newMessage, int newAge) public  {
        message = newMessage;
        age = newAge;
        owner = msg.sender;
    }

    function getMessage() public view returns (string){
        return message;
    }

    function getOwner() public view returns (address){
        return owner;   
    }

    function setMessage(string newMessage) public {
        message = newMessage;
    }

    function setNewAge(int newAge) public {
        age = newAge;
    }
}