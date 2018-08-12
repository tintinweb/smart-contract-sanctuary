pragma solidity ^0.4.24;

contract Logistics{
    address public owner = msg.sender;
    mapping(address => string) public notes;

    function sign(string note) public {
        require(msg.sender == owner);
        notes[owner] = note;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
}