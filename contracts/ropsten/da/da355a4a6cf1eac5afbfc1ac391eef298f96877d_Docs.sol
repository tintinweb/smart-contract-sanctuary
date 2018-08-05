pragma solidity ^0.4.24;

contract Docs {
    
    uint256 private id;
    mapping(uint256 => doc) private docs;
    mapping(uint256 => string) private guids;
    mapping(string => bool) private guidExists;

    struct doc {
        string name;
        string timestamp;
        string hash;
    }
    
    function totalSupply() public view returns(uint256) {
        return id;
    }

    function isExist(string _guid) public view returns(bool) {
        return guidExists[_guid];
    }
    
    function getDoc(uint256 _id) public view returns (string, string, string, string) {
        require(guidExists[guids[_id]]);
        return (guids[_id], docs[_id].name, docs[_id].timestamp, docs[_id].hash);
    }
    
    function createDoc(string _guid, string _name, string _timestamp, string _hash) public {
        require(!guidExists[_guid]);
        guidExists[_guid] = true;
        guids[id] = _guid;
        docs[id] = doc(_name, _timestamp, _hash);
        id += 1;
    }
}