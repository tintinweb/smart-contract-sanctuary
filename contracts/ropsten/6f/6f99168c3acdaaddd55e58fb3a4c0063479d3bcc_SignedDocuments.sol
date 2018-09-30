pragma solidity ^0.4.24;

contract SignedDocuments {
    
    struct Document {
        address from;
        string  username;
        uint   timestamp;
    }
    
    mapping(bytes32 => Document) private docs;
    event DOCSAVE(address indexed  _from, string indexed username, bytes32 indexed hash);
    
    function newDoc(bytes32 hash, uint timestamp, string username) public {
        docs[hash] = Document({from: msg.sender, username: username, timestamp: timestamp});
        emit DOCSAVE(msg.sender, username,  hash);
    }
    
    function getDocument(bytes32 hash) public view returns (address, string, uint) {
       Document memory d =  docs[hash];
       return (d.from, d.username, d.timestamp);
    }
    
}