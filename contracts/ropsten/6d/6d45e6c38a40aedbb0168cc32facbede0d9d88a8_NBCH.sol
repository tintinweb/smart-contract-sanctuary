pragma solidity ^0.4.23;

contract NBCH {
    
    address public owner;
    
    mapping(string => bool) users; 
    
    constructor() public {
        owner = msg.sender;
    }
    
    function write(string creditDocumentHash) public {
        require(msg.sender == owner);
        users[creditDocumentHash] = true;
    }
    
    function read(string creditDocumentHash) public view returns (bool) {
        return users[creditDocumentHash]; 
    }
    
}