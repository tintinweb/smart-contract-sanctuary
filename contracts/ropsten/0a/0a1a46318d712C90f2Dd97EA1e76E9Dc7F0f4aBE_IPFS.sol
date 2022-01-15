/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity ^0.8.3;

contract IPFS {
    string ipfsHash;
    
    function sendHash(string memory x) public {
        ipfsHash = x;
    }
    
    function getHash() public view returns (string memory) {
        return ipfsHash;
    }
}