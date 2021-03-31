/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract ProofOfExistence {
    event ProofCreated(uint indexed id, bytes32 documentHash, string fileName, bytes19 timestamp, uint fileSize);

    address public owner;

    
    struct FileData {
        bytes32 fileHash;
        string fileName;
        bytes19 timestamp;
        uint fileSize;
    }
    
    mapping(uint => FileData) hashesById;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner is allowed to access this function."
        );
        _;
    }

    modifier noHashExistsYet(uint id) {
        require(hashesById[id].fileHash == "", "No hash exists for this id.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function storeDocument(uint id, bytes32 _docHash, string calldata _fileName, bytes19 _timestamp, uint _fileSize)
        public onlyOwner noHashExistsYet(id)
    {
        hashesById[id] = FileData(_docHash, _fileName, _timestamp, _fileSize);
        emit ProofCreated(id, _docHash, _fileName, _timestamp, _fileSize);
    }

    function verifyDocument(uint id, bytes32 documentHash) public view returns (bool)
    {
        return hashesById[id].fileHash == documentHash;
    }
    
    function getDocument(uint id) public view returns (bytes32, string memory, bytes19, uint)
    {
        //return hashesById[id];
        return (hashesById[id].fileHash, hashesById[id].fileName, hashesById[id].timestamp, hashesById[id].fileSize);
    }
    
}