/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

pragma solidity >=0.7.0 <0.8.0;

pragma experimental ABIEncoderV2;

contract Repository {
    struct File {
        string name;
        string URL;
    }
    
    mapping(string => uint) private filesIndex;
    
    File[] private files;
    
    function addFile(string memory fileName, string memory fileURL) public {
        files.push(File(fileName, fileURL));
        
        uint filesLength = files.length;
        uint lastFileIndex = filesLength - 1;
        
        filesIndex[fileName] = lastFileIndex;
    }
    
    function getFile(string memory fileName) public view returns (File memory) {
        uint fileIndexName = filesIndex[fileName];
        
        return files[fileIndexName];
    }
    
    function getAllFiles() public view returns (File[] memory) {
        return files;
    }
}