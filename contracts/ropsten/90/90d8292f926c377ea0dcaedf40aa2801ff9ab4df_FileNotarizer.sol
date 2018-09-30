pragma solidity ^0.4.0;



contract FileNotarizer {

    mapping (uint => bytes32) files;
    uint numFiles; 
    
    function addFile(bytes32 fileHash, bytes32 fileHash2) public returns (uint fileNum){
        fileNum = numFiles++;
        files[fileNum] = fileHash;
    }
    
    function getFileNum() public returns (uint fileNum){
        return numFiles;
    }
    
    function getFileByIndex(uint fileIndex) public returns (bytes32 file){
        return files[fileIndex];
    }
    
    function echoTest(uint fileIndex) public returns (uint result){
        return fileIndex;
    }
}