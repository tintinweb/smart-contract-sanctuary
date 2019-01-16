pragma solidity ^0.4.24;

contract HashContract {
 string ipfsHash;

 function setHash(string x) public {
   ipfsHash = x;
 }

 function getHash() public view returns (string x) {
   return ipfsHash;
 }
}