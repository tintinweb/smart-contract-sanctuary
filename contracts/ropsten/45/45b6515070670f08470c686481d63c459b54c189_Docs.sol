pragma solidity ^0.4.24;

contract Docs {
    
    uint256 private id;
    mapping(uint256 => doc) private docs;
    mapping(uint256 => bool) private docExists;

    struct doc {
        string name;
        string timestamp;
        string hash;
    }

    constructor(uint256 _id) public {
        id = _id;
    }
    
    function lastId() public view returns(uint256) {
        return id;
    }
    
    function getDoc(uint256 _id) public view returns (string, string, string) {
        require(docExists[_id]);
        return (docs[_id].name, docs[_id].timestamp, docs[_id].hash);
    }
    
    function createDoc(string _name, string _timestamp, string _hash) public {
        docs[id] = doc(_name, _timestamp, _hash);
        docExists[id] = true;
        id += 1;
    }
}