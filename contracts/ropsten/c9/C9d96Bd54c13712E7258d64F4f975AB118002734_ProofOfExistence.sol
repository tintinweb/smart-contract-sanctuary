/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
// 1.
pragma solidity ^0.8.0; 
// 2,
contract ProofOfExistence {
    // 3.
    // Structure containing a single proof of existence
    struct proof {
        address owner;  // The owner of the proof
        string hash;    // Hash of proved preimage
        uint timestamp;    // Origination time of proof
     }
    // 4.
    mapping(string=>proof) hashToProof;    // map from hashes to proofs
    
    // 5.
    // Create proof for new hash
    function proveExistence(string memory hash) public {
        require(!checkExists(hash));    // Make sure it exists
        hashToProof[hash] = proof(msg.sender, hash, block.timestamp);    // set owner to msg.sender and time to now
    }
    
    // 6.
    // Check whether a hash exists or not
    function checkExists(string memory hash) public view returns (bool){
        return hashToProof[hash].timestamp > 0;   //seeing if it has a time of existence
   }
    
    // 7.
    // Read in the creation time of a hash
    function getCreationTime(string memory hash) public view returns(uint){
        require(checkExists(hash));    // Make sure it exists
        return hashToProof[hash].timestamp;    // Return timestamp
    }
    
    // 8.
    // read in the owner of a hash
    function getOwner(string memory hash) public view returns(address){
        require(checkExists(hash));    // Make sure it exists
        return hashToProof[hash].owner;    // return owner
    }

    // 9. 
    // transferOwnership ownership of hash to newOwner
    function transferOwnership(string memory hash, address newOwner) public returns (bool result){
        require(checkExists(hash));    // make sure it exists
        require(msg.sender == getOwner(hash));    // make sure owner is transfering
        hashToProof[hash].owner = newOwner;    // Transfer ownership
        result = true;
    }
}