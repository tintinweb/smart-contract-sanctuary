/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Notes
 * @dev Stores notes by keys
 */
contract Notes {

    mapping(string => string) notes;


    function addNote(string memory noteName,string memory content) public {
        require(compareStringsbyBytes(notes[noteName],""),"Item cannot be replaced");
        notes[noteName] = content;
    }

    function getNote(string memory noteName) public view returns(string memory) {
        return notes[noteName];
    }

    function compareStringsbyBytes(string memory s1, string memory s2) public pure returns(bool){
          return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}