pragma solidity ^0.4.0;
contract FileNotarizer {

    mapping (bytes32 => bytes32) files;
    uint numFiles;
    
    function addFile(bytes32 fileHash) public returns (uint fileNum){
        fileNum = numFiles++;
        files[fileHash] = fileHash;
    }
    
    function getFileNum() public returns (uint fileNum){
        return numFiles;
    }
    
    function getFileByIndex(bytes32 fileIndex) public returns (bytes32 file){
        return files[fileIndex];
    }
    
    function echoTest(uint fileIndex) public returns (uint result){
        return fileIndex;
    }
}