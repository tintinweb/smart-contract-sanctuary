/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.5.0;

contract NoteContract {    
    mapping(address => string [] ) public notes;

    constructor() public {
    }

    event NewNote(address, string note);

// 添加記事
    function addNote( string memory note) public {
        notes[msg.sender].push(note);
        emit NewNote(msg.sender, note);
    }

    function getNotesLen(address own) public view returns (uint) {
        return notes[own].length;
    }

    event ModifyNote(address, uint index);

    function modifyNote(address own, uint index, string memory note) public {
        require(own == msg.sender);
        notes[own][index] = note;
        emit ModifyNote(own, index);
    }
}