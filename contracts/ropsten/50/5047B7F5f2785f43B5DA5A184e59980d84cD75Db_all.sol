/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

pragma solidity >=0.4.22 <0.9.0;

contract all {

  function to256(uint reveal) pure public returns (bytes32 ) {
    
    bytes32 signatureHash = keccak256(abi.encodePacked(reveal));
    return (signatureHash);

  }
  
    function committosing(uint commitLastBlock, uint commit) pure public returns (bytes32, uint, uint ) {
    
    bytes32 signatureHash = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));
    return (signatureHash, commitLastBlock, commit);

  }
  
  function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}