/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity 0.8.3;

contract NoteStore {
    
    event NoteSet(address, string);
    
    mapping (address => string) private notes;
    
    function noteOf(address account) external view returns (string memory) {
        return _noteOf(account);
    }
    
    function note() external view returns (string memory) {
        return _noteOf(msg.sender);
    }
    
    function setNote(string memory note) external {
        require(bytes(note).length <= 64, "Note is over 64 characters");
        require(bytes(note).length > 0, "Note is empty");
        notes[msg.sender] = note;
        emit NoteSet(msg.sender, note);
    }
    
    function _noteOf(address account) private view returns (string memory) {
        return notes[account]; 
    }
}