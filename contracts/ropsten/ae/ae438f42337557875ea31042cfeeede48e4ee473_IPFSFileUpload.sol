pragma solidity ^0.4.24;
contract IPFSFileUpload {
    string ipfsHash;
 
    event savedHash(
        
    );
    
    function setHash(string x) public {
        ipfsHash = x;
        emit savedHash();
    }

    function getHash() public view returns (string x) {
        return ipfsHash;
    }
}