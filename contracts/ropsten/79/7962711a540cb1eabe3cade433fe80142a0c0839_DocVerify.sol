/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.5.0;

contract DocVerify {
    
    struct Document {
        address owner;
        uint date;
        string owners;
    }
   
    
    address public creator;
    uint public numDocuments;
    mapping(bytes32 => Document) public documentHashMap;
    constructor() public {
        creator = msg.sender;
        numDocuments = 0;
    }
    
    function newDocument(bytes32 hash,string memory owners) public returns (bool success) {
        if (documentExists(hash)) {
            success = false;
        }else {
            Document storage d = documentHashMap[hash];
            owners = owners;
            d.owner = msg.sender;
            d.date = now;
            numDocuments++;
            success = true;
        }
        return success;
    }
    
    function documentExists(bytes32 hash) public view returns (bool exists) {
        if (documentHashMap[hash].date > 0) {
            exists = true;
        } else {
            exists = false;
        }
        return exists;
    }
    
    function getDocument(bytes32 hash) public view returns (uint date, address owner) {
        date = documentHashMap[hash].date;
        owner = documentHashMap[hash].owner;
    }

    function getNumDocs() public view returns (uint numDocs) {
        return numDocuments;
    }
}