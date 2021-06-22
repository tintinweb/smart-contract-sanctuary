/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.8.0;


// 
/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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

interface IERC721Mintable {
	function claim(
		address to, 
		uint256 tokenId, 
		uint256 universeId, 
		uint256 earthId,
		uint256 personId, 
		uint256 blockchainId,
		uint256 sattoshiId) external returns (bool);
}

contract MerkleDistribution {
	bytes32 public root;
	IERC721Mintable  public token;
	mapping (bytes32=>bool) claimedMap;
	
	event Claim(address, uint256);

	constructor(address _token, bytes32 _root) public{
		token = IERC721Mintable(_token);
		root = _root;
	} 

	function isClaimed(
		address _addr, 
		uint256 _id,
		uint256 _universeId,
		uint256 _earthId,
		uint256 _personId,
		uint256 _blockchainId,
		uint256 _sattoshiId )
		public view returns(bool){
		bytes32 node = keccak256(abi.encodePacked(_id, _universeId, _earthId, _personId, _blockchainId, _sattoshiId, _addr));
		return claimedMap[node];
	}

	function setClaimed(bytes32 _node) private {
		claimedMap[_node] = true;
	}

	function claim(
		address _addr, 
		uint256 _id,
		uint256 _universeId,
		uint256 _earthId,
		uint256 _personId,
		uint256 _blockchainId,
		uint256 _sattoshiId,
		bytes32[] calldata merkleProof) external {
		bytes32 node = keccak256(abi.encodePacked(_id, _universeId, _earthId, _personId, _blockchainId, _sattoshiId, _addr));
		require(!claimedMap[node], "token id of this address is already claimed");
		require(MerkleProof.verify(merkleProof, root, node), "MerkleDistribution: Invalid Proof");
		setClaimed(node);
		require(token.claim(_addr, _id, _universeId, _earthId, _personId, _blockchainId, _sattoshiId), "MerkleDistribution: Mint Failed");
		emit Claim(_addr, _id);
	}
}