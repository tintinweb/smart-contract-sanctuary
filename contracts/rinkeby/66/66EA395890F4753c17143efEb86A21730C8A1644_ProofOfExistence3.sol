/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ProofOfExistence3 {
  mapping (bytes32 => bool) private proofs;

  function storeProof(bytes32 proof) public {
    proofs[proof] = true;
  }

  function notarize(string calldata document) external {
    bytes32 proof = proofFor(document);
    storeProof(proof);
  }

  function proofFor(string memory document) public pure returns (bytes32) {
    return sha256(abi.encodePacked(document));
  }

  function checkDocument(string memory document) public view returns (bool) {
    bytes32 proof = proofFor(document);
    return hasProof(proof);
  }

  function hasProof(bytes32 proof) internal view returns (bool) {
    return proofs[proof];
  }
}