/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.6.11;

/**
 * @title AragonNFT
 * @author Eduardo Antuña <[email protected]>
 * @dev The main goal of this token contract is to make it easy for anyone to install
 * this AragonApp to get an NFT Token that can be handled from a DAO. This will be the 
 * NFT used by the DAppNode association.
 * It's based on the ERC721 standard http://ERC721.org https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 * and the awesome smartcontracts and tools developed by https://github.com/OpenZeppelin/openzeppelin-solidity 
 * as well as those developed by Aragon https://github.com/aragon
 */
interface AragonNFT {

    /**
     * @notice Function to initialize the AragonApp
     * @dev it will revert if the name or symbol is not specified.
     * @param _name Token name
     * @param _symbol Token symbol
     */
    function initialize(string memory _name, string memory _symbol) external;
    /**
     * @notice Mint `_tokenId` and give the ownership to  `_to` 
     * @dev Only those who have the `MINT_ROLE` permission will be able to do it 
     * @param _to The address that will own the minted token
     * @param _tokenId uint256 ID of the token to be minted by the msg.sender
     */
    function mint(address _to, uint256 _tokenId) external;

    /**
     * @notice Burn tokenId: `_tokenId`
     * @dev Only those who have the `BURN_ROLE` persmission will be able to do it
     * Reverts if the token does not exist
     * @param _tokenId uint256 ID of the token being burned by the msg.sender
    */
    function burn(uint256 _tokenId) external;

    /**
     * @notice Set `_uri` for `_tokenId`, 
     * @dev Only those who have the `MINT_ROLE` persmission will be able to do it
     * Reverts if the token ID does not exist
     * @param _tokenId uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function setTokenURI(uint256 _tokenId, string memory _uri) external;

    /**
     * @notice Clear current approval of `_tokenId` owned by `_owner`,
     * @dev only the owner of the token can do it 
     * Reverts if the given address is not indeed the owner of the token
     * @param _owner owner of the token
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function clearApproval(address _owner, uint256 _tokenId) external;

    /**
     * @notice Returns whether `_tokenId` exists
     * @dev Returns whether the specified token exists
     * @param _tokenId uint256 ID of the token to query the existence of
     * @return whether the token exists
     */
    function exists(uint256 _tokenId) external view returns (bool);
    /**
     * @notice Gets the list of token IDs of the `_owner`
     * @dev Gets the list of token IDs of the requested owner
     * @param _owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory);
}



pragma solidity ^0.6.0;

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

pragma solidity >=0.5.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}

contract MerkleDistributor is IMerkleDistributor {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 tokenId, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, tokenId));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        
        AragonNFT(token).mint(account, tokenId);
        AragonNFT(token).setTokenURI(tokenId, "/ipfs/QmV6PZ2AiJGJK7PSf1HLcKpjb5oCHCKWU3TZHQwwb813L2");

        emit Claimed(index, account, tokenId);
    }
}