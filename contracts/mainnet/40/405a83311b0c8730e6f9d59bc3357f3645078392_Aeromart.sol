pragma solidity ^0.4.18;

contract Owned {
    address owner;
    
    function Owned() public {
        owner = msg.sender;
    }
    
   modifier onlyOwner {
       require(msg.sender == owner);
       _;
   }
}

contract Aeromart is Owned {
    
    struct Note {
        bytes20 serialNumber;
        string text;
    }
    
    uint nextNoteID;
    mapping (uint256 => Note) public notes;
    
    event noteInfo(
       bytes20 serialNumber,
       string text
    );
    
    function addNote(bytes20 _serialNumber, string _text) onlyOwner public returns (uint) {
        var note = notes[nextNoteID];
        
        note.serialNumber = _serialNumber;
        note.text = _text;
        
        noteInfo(_serialNumber, _text);
        
        nextNoteID++;
        return nextNoteID;
    }
    
    function setNote(uint256 _id, bytes20 _serialNumber, string _text) onlyOwner public {
        var note = notes[_id];
        
        note.serialNumber = _serialNumber;
        note.text = _text;
        
        // notesAccts.push(_id) -1;
        noteInfo(_serialNumber, _text);
    }
    
    function getNote(uint256 _id) view public returns (bytes20, string) {
        return (notes[_id].serialNumber, notes[_id].text);
    }
    
    
}