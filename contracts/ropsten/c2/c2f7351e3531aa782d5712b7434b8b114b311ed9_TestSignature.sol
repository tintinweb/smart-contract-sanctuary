/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

pragma solidity >=0.4.22 <0.9.0;

contract TestSignature {

  function placeBet(uint commitLastBlock, uint commit) pure public returns (bytes32, uint, uint ) {
    
    bytes32 signatureHash = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));
    return (signatureHash, commitLastBlock, commit);

  }
}