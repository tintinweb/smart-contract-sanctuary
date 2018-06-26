pragma solidity ^0.4.24;

contract SignedDocuments {
    
    address public owner;
    
    mapping(bytes32 => mapping(address => uint)) private docs;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function savePost(bytes32 hash, uint timestamp) public returns (bool) {
        docs[hash][msg.sender] = timestamp;
        return true;
    }
    
    function getPost(bytes32 hash) public view returns (uint) {
        return docs[hash][msg.sender];
    }
    
    
}