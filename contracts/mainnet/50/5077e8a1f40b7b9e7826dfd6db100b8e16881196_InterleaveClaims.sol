//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IinterleaveNFT {
    function mint(address to, uint256 id, uint256 amount) external;
}

contract InterleaveClaims {
    bytes32 _root;

    mapping (uint256 => mapping(address => bool)) private _isClaimed;

    address public interleaveNFT;
    address public owner;

    constructor() {
        _root = 0xc1bef884e9c09a044ac646fde85f284e3bc25b487384edd98eb2cab32e693481;
        interleaveNFT = 0xB02FDEddE59aba04FF14062519e880B5E6BA316E;
        owner = msg.sender;
    }  

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
 

    function updateMerkleRoot(bytes32 newRoot) public {
        require(msg.sender == owner, "You are not the owner!");
        _root = newRoot;
    }

    function changeInterleave(address newAddress) public {
        require(msg.sender == owner,"You are not the owner!");
        interleaveNFT = newAddress;
    }

    function isClaimed(uint256 id, address userAddress) public view returns (bool) {
        return _isClaimed[id][userAddress];
    }

    function claim(uint256 id, uint256 amount, address userAddress, bytes32[] memory merkleProof) public {
        require(!isClaimed(id, userAddress), "You've already claimed!");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(id, amount, userAddress));
        require(verify(merkleProof, _root, node), 'Invalid proof.');

        _isClaimed[id][userAddress] = true;
        
        IinterleaveNFT(interleaveNFT).mint(userAddress, id, amount);

    }

}