pragma solidity 0.4.24;

contract MessageHolder {
    address public owner;
    string public message;

    constructor() public {
        owner = msg.sender;
    }

    function setMessage(string value) public {
        require(msg.sender == owner);
        message = value;
    }

    function setOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
}