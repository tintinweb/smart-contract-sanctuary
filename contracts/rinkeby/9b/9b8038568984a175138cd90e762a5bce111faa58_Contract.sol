/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

pragma solidity ^0.4.17;


contract Contract {
 string ipfsHash;
 
 function sendHash(string x) public {
   ipfsHash = x;
 }

 function getHash() public view returns (string x) {
   return ipfsHash;
 }
}