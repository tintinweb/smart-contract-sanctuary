/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

pragma solidity ^0.4.24;

contract Notary {
    struct MyNotaryEntry { 
    string fileName;
    uint timestamp;
    bytes32 checkSum;
    string comments;
    bool isSet;
    address setBy;
}
/***
0x9F86D081884C7D659A2FEAA0C55AD015A3BF4F1B2B0B822CD15D6C15B0F00A08, "test","test"
***/
    mapping(bytes32 => MyNotaryEntry) public myMapping;

    event NewEntry(bytes32 _checksum, string _filename, address indexed _setBy);

    function addEntry(bytes32 _checksum, string _fileName, string _comments) public {
        require(!myMapping[_checksum].isSet);

        myMapping[_checksum].isSet = true;
        myMapping[_checksum].fileName = _fileName;
        myMapping[_checksum].timestamp = now;
        myMapping[_checksum].comments = _comments;
        myMapping[_checksum].setBy = msg.sender;

        emit NewEntry(_checksum, _fileName, msg.sender);
    }

    function entrySet(bytes32 _checksum) public view returns(string, uint, string, address) {
        require(myMapping[_checksum].isSet);
        return ( myMapping[_checksum].fileName, myMapping[_checksum].timestamp, myMapping[_checksum].comments, myMapping[_checksum].setBy);
    }

}