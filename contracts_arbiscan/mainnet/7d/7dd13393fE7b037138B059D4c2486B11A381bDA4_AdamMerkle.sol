pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ERC721 {
    function mint(address _to) external;

    function totalSupply() external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface Game {
    function addScore(uint256 id, uint256 score) external;

    function nftToId(address _nft, uint256 _id) external view returns (uint256);

    function giveLife(address nft, uint256 _id) external;
}

interface IToken {
    function approve(address spender, uint256 tokens)
        external
        returns (bool success);
}

contract AdamMerkle {
    bytes32 public immutable merkleRoot;
    mapping(address => bool) claimed;

    ERC721 public cudlPets;
    Game public game;

    constructor(
        bytes32 merkleRoot_,
        address _game,
        address _cudlPets
    ) {
        merkleRoot = merkleRoot_;
        cudlPets = ERC721(_cudlPets);
        game = Game(_game);

        IToken(0x0f4676178b5c53Ae0a655f1B19A96387E4b8B5f2).approve(
            address(game),
            100000 ether
        );
    }

    function claim() external {
        // address user;
        // uint256[] memory scores;
        // bytes32 node = keccak256(params);
        // (user, scores) = abi.decode(params, (address, uint256[]));

        // require(!claimed[user], "already claimed");
        // claimed[user] = true;

        // require(
        //     MerkleProof.verify(merkleProof, merkleRoot, node),
        //     "MerkleDistributor: Invalid proof."
        // );

        cudlPets.mint(address(this));
        game.giveLife(address(cudlPets), cudlPets.totalSupply() - 1);

        uint256 petId = game.nftToId(
            address(cudlPets),
            cudlPets.totalSupply() - 1
        );
        game.addScore(petId, 100); // TODO add id

        cudlPets.safeTransferFrom(
            address(this),
            msg.sender,
            cudlPets.totalSupply() - 1
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
}