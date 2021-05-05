/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.4.23;
contract ipfs_store {
 string ipfsHash;
 
function sendHash(string x) public {
   ipfsHash = x;
}
function getHash() public view returns (string x) {
   return ipfsHash;
 }
}