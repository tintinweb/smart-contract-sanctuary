/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

pragma solidity >=0.4.22 <0.9.0;

contract reveal2commit {

  function to256(uint reveal) pure public returns (bytes32 ) {
    
    bytes32 signatureHash = keccak256(abi.encodePacked(reveal));
    return (signatureHash);

  }
}