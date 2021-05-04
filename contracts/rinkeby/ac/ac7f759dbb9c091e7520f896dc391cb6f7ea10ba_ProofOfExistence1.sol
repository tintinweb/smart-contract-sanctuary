/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity ^0.4.15;
contract ProofOfExistence1 {
  // state
 bytes32 public proof;
uint public blocknumber;
  // calculate and store the proof for a document
  function notarize (string document) public {
    proof = proofFor(document);
     blocknumber=block.number;
  }
  // helper function to get a document's sha256
  function proofFor(string document) internal returns (bytes32) {
    return sha256(document);
  }
}