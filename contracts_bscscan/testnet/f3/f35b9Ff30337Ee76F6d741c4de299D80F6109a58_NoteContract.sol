/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

pragma solidity ^0.5.0;

contract NoteContract {    
    mapping(address => string [] ) public notes;

    constructor() public {
    }

    event NewNote(address, string note);

// 添加记事
    function addNote( string memory note) public {
        notes[msg.sender].push(note);
        emit NewNote(msg.sender, note);
    }

    function getNotesLen(address own) public view returns (uint) {
        return notes[own].length;
    }
}