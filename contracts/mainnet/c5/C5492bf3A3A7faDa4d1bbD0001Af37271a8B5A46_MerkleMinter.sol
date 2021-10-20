/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: IMintableAirdrop

interface IMintableAirdrop {

  function mintAirdrops(
    address _owner,
    uint256 _amount,
    uint256 _upfront,
    uint256 _start,
    uint256 _end) external returns(uint256);
}

// Part: OpenZeppelin/[email protected]/MerkleProof

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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
}

// File: MerkleMinter.sol

contract MerkleMinter {
  using MerkleProof for bytes32[];

  IMintableAirdrop public toAirdrop;

  bytes32 public merkleRoot;
  mapping(uint256 => uint256) public claimedBitMap;
  uint256 public start;
  uint256 public end;
  uint256 upfrontDivisor;


  event Claimed(uint256 index, address account, uint256 amount);

  constructor(address _toAirdrop, bytes32 _root, uint256 _start, uint256 _end, uint _upfrontDivisor) public {
    toAirdrop = IMintableAirdrop(_toAirdrop);
    merkleRoot = _root;
    start = _start;
    end = _end;
    upfrontDivisor = _upfrontDivisor;
  }


  function isClaimed(uint256 _index) public view returns(bool) {
    uint256 wordIndex = _index / 256;
    uint256 bitIndex = _index % 256;
    uint256 word = claimedBitMap[wordIndex];
    uint256 bitMask = 1 << bitIndex;
    return word & bitMask == bitMask;
  }

  function _setClaimed(uint256 _index) internal {
    uint256 wordIndex = _index / 256;
    uint256 bitIndex = _index % 256;
    claimedBitMap[wordIndex] |= 1 << bitIndex;
  }

  function claim(address account, uint256 _index, uint256 _amount, bytes32[] memory _proof) external {
    require(!isClaimed(_index), "Claimed already");

    bytes32 node = keccak256(abi.encodePacked(_index, account, _amount));
    require(_proof.verify(merkleRoot, node), "Wrong proof");

    _setClaimed(_index);
    uint256 upfront = _amount / upfrontDivisor;
    uint256 adjustedAmount = _amount - upfront;

    toAirdrop.mintAirdrops(account, adjustedAmount, upfront, start, end);
    emit Claimed(_index, account, _amount);
  }
}