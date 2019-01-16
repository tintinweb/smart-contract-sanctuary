pragma solidity ^0.4.24;

contract Docs {
    
    uint256 public id;
    mapping(uint256 => doc) public docs;
    mapping(uint256 => bool) public docExists;

    struct doc {
        string name;
        string timestamp;
        string hash;
    }
    
    function createDoc(string _name, string _timestamp, string _hash) public {
        docs[id] = doc(_name, _timestamp, _hash);
        docExists[id] = true;
        id += 1;
    }
}