pragma solidity ^0.4.25;

contract kikk {
    string[] public participants;
    
    constructor() {
        participants.push("Suyash Sumaroo");
    }
    
    function getParticipants(uint index) public view returns (string participant) {
        return participants[index];
    }
}