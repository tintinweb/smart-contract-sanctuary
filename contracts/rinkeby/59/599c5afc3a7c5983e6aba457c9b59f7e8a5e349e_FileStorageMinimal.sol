/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract FileStorageMinimal {
    // Events
    event FileAdded(bytes32 fileId, string name, string location, address creator, uint timestamp);
    event FileRemoved(bytes32 fileId, string name, string location, address creator, uint timestamp);

    struct FileEntry {
        uint index;
        bytes32 id;
        string name;
        string location;
        address creator;
        uint createdDate;
    }
    
    mapping(bytes32 => FileEntry) public fileMap;
    bytes32[] public fileList;
    
    constructor() { }

    function add(bytes32 _fileId, string memory _name, string memory _location) public {
        FileEntry storage entry = fileMap[_fileId];
        require(!_contains(entry), "FileId already exists!");
        require(_fileId != 0, "Parameter _fileId is required!");
        require(bytes(_location).length > 0, "Parameter _location is required!");
        
        fileList.push(_fileId);
        entry.index = fileList.length - 1;
        entry.id = _fileId;
        entry.name = _name;
        entry.location = _location;
        entry.creator = msg.sender;
        entry.createdDate = block.timestamp;

        emit FileAdded(entry.id, entry.name, entry.location, entry.creator, entry.createdDate);
    }
    
    function remove(bytes32 _fileId) public {
        FileEntry memory entry = fileMap[_fileId];
        require(_contains(entry), "FileId does not exist!");
        require(_isInRange(entry.index), "Index out of range!");
        require(entry.creator == msg.sender, "Only uploader allowed to remove file");
        uint256 deleteEntryIdx = entry.index;

        uint256 lastEntryIdx = fileList.length - 1;
        bytes32 lastEntryFileId = fileList[lastEntryIdx];
        fileMap[lastEntryFileId].index = deleteEntryIdx;
        fileList[deleteEntryIdx] = fileList[lastEntryIdx];
        fileList.pop();
        delete fileMap[_fileId];

        emit FileRemoved(_fileId, entry.name, entry.location, msg.sender, block.timestamp);
    }
    
    function getById(bytes32 _fileId) public view returns (
        bytes32 fileId, 
        string memory name,
        string memory location,
        address creator,
        uint createdDate) {
        FileEntry memory entry = fileMap[_fileId];
        require(_contains(entry), "fileId not found in map!");

        return (entry.id, entry.name, entry.location, entry.creator, entry.createdDate);
    }
    
    function getByIndex(uint _index) public view returns (
        bytes32 fileId, 
        string memory name,
        string memory location,
        address creator,
        uint createdDate) {
        require(_isInRange(_index), "index must be in range");
        return getById(fileList[_index]);
    }

    function size() public view returns (uint) {
        return fileList.length;
    }
    
    function contains(bytes32 _fileId) public view returns (bool) {
        FileEntry memory entry = fileMap[_fileId];
        return _contains(entry);
    }

    function _contains(FileEntry memory _entry) private pure returns (bool){
        return bytes(_entry.location).length > 0;
    }
    
    function _isInRange(uint256 _index) private view returns (bool) {
        return (_index >= 0) && (_index < fileList.length);
    }
}