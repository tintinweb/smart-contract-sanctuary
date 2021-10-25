//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NoteContract {    
    mapping(address => string [] ) public notes;

    constructor() {
    }

    event NewNote(address, string note);

// add note
    function addNote( string memory note) public {
        notes[msg.sender].push(note);
        emit NewNote(msg.sender, note);
    }

    function getNotesLen(address own) public view returns (uint) {
        return notes[own].length;
    }
    event ModifyNote(address, uint index);
    
    function modifyNote(address own, uint index, string memory note) public {
        notes[own][index] = note;
        emit ModifyNote(own, index);
    }
}