/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

pragma solidity ^0.4.26;


contract Notebook {
    struct Note {
        address owner;
        uint id;
        string title;
        string contents;
    }
    
    uint id_index;
    mapping(uint => Note) notes;
    mapping(address => uint[]) user_notes;
    
    constructor() public {
        id_index = 0;
    }
    
    function createNote(string title, string contents) public returns (uint) {
        notes[id_index] = Note(msg.sender, id_index, title, contents);
        user_notes[msg.sender].push(id_index);
        id_index++;
        return id_index-1;
    }
    
    function changeNote(uint id, string title, string contents) public {
        Note storage note = notes[id];
        require(note.owner == msg.sender);
        notes[id].title = title;
        notes[id].contents = contents;
    }
    
    function getNotesByUser() public view returns (uint[]) {
        return user_notes[msg.sender];
    }
    
    function getNoteByID(uint id) public view returns (string, string) {
        Note storage note = notes[id];
        return (note.title, note.contents);
    }
    
    
}