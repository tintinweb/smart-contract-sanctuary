/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

/// ============ Libraries ============

/// @notice OpenZeppelin: MerkleProof
/// @dev The hashing algorithm should be keccak256 and pair sorting should be enabled.
library MerkleProof {
  /// @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree defined by `root`.
  function verify(
    bytes32[] memory proof,
    bytes32 root,
    bytes32 leaf
  ) internal pure returns (bool) {
    return processProof(proof, leaf) == root;
  }

  /// @dev Returns the rebuilt hash obtained by traversing a Merklee tree up from `leaf` using `proof`.
  function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
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
    return computedHash;
  }
}

/// ============ Interfaces ============

interface IERC721 {
  /// @notice ERC721 transfer from (from) to (to)
  function transferFrom(address from, address to, uint256 tokenId) external;
}

contract SantaSwapExchange {

  /// ============ Structs ============

  /// @notice Individual ERC721 NFT details
  struct SantaNFT {
    /// @notice NFT contract
    address nftContract;
    /// @notice NFT tokenId
    uint256 tokenId;
  }

  /// ============ Immutable storage ============

  /// @notice Timestamp when reclaim is enabled
  uint256 immutable public RECLAIM_OPEN;

  /// ============ Mutable storage ============

  /// @notice Contract owner
  address public owner;
  /// @notice Merkle root of santa => giftee
  /// @dev keccak256(giftee, santa, santaNFTIndex)
  bytes32 public merkle;
  /// @notice Helper to iterate nfts for front-en
  /// @dev Keeps santaNFTIndex count
  mapping(address => uint256) public nftCount;
  /// @notice Address to deposited NFTs
  mapping(address => SantaNFT[]) public nfts;

  // ============ Errors ============

  /// @notice Thrown if caller is not owner
  error NotOwner();
  /// @notice Thrown if cannot claim NFT
  error NotClaimable();

  /// ============ Constructor ============

  constructor() {
    // Update contract owner
    owner = msg.sender;
    // Allow reclaiming 7 days after depositing
    RECLAIM_OPEN = block.timestamp + 604_800;
  }

  /// @notice Computes leaf of merkle tree by hashing params
  /// @param giftee address receiving NFT gift
  /// @param santa address giving NFT gift
  /// @param santaIndex index of gift (for multiple tickets)
  /// @return hash of leaf
  function _leaf(
    address giftee, 
    address santa, 
    uint256 santaIndex
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(giftee, santa, santaIndex));
  }

  /// @notice Verifies that leaf matches provided proof
  /// @param leaf (computed in contract)
  /// @param proof (provided externally)
  /// @return whether santa => giftee matches up
  function _verify(
    bytes32 leaf,
    bytes32[] calldata proof
  ) internal view returns (bool) {
    return MerkleProof.verify(proof, merkle, leaf);
  }

  /// @notice Allows santas to deposit NFTs to contract
  /// @param nftContract of NFT being deposited
  /// @param tokenId being deposited
  function santaDepositNFT(address nftContract, uint256 tokenId) external {
    // Transfer NFT to contract
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    // Mark as deposited by santa
    nftCount[msg.sender]++;
    nfts[msg.sender].push(SantaNFT(nftContract, tokenId));
  }

  /// @notice Allows giftees to claim NFTs
  /// @param santa who is gifting them
  /// @param santaIndex index of gift in santa's array
  /// @param proof merkle proof of claim
  function gifteeClaimNFT(
    address santa,
    uint256 santaIndex,
    bytes32[] calldata proof
  ) external {
    // Require merkle to be set
    if (merkle == 0) revert NotClaimable();
    // Require giftee to be claiming correct santa NFT
    if (!_verify(_leaf(msg.sender, santa, santaIndex), proof)) revert NotClaimable();

    // Collect NFT
    SantaNFT memory nft = nfts[santa][santaIndex];
    // Transfer NFT
    IERC721(nft.nftContract).transferFrom(address(this), msg.sender, nft.tokenId);
  }

  /// @notice ALlows santas to reclaim their NFTs given reclaim period is active
  /// @param index of gift in santa's array (fka: santaIndex)
  function santaReclaimNFT(uint256 index) external {
    // Require reclaim period to be active
    if (block.timestamp < RECLAIM_OPEN) revert NotClaimable();
    // Require provided index to be in range of owned NFTs
    if (index + 1 > nfts[msg.sender].length) revert NotClaimable();

    // Collect NFT
    SantaNFT memory nft = nfts[msg.sender][index];
    // Transfer unclaimed NFT
    IERC721(nft.nftContract).transferFrom(address(this), msg.sender, nft.tokenId);
  }

  /// @notice Allows contract owner to withdraw any single NFT
  /// @notice nftContract of NFT to withdraw
  /// @notice tokenId to withdraw
  /// @notice recipient of withdrawn NFT
  function adminWithdrawNFT(
    address nftContract,
    uint256 tokenId,
    address recipient
  ) external {
    // Require caller to be owner
    if (msg.sender != owner) revert NotOwner();

    IERC721(nftContract).transferFrom(
      // From this contract
      address(this),
      // To provided recipient
      recipient,
      // Transfer specified NFT tokenId
      tokenId
    );
  }

  /// @notice Allows contract owner to withdraw bulk NFTs
  /// @notice contracts of NFTs to withdraw
  /// @notice tokenIds to withdraw
  /// @notice recipients of withdrawn NFT
  /// @dev Does not check for array length equality
  function adminWithdrawNFTBulk(
    address[] calldata contracts,
    uint256[] calldata tokenIds,
    address[] calldata recipients
  ) external {
    // Require caller to be owner
    if (msg.sender != owner) revert NotOwner();

    // For each provided contract
    for (uint256 i = 0; i < contracts.length; i++) {
      IERC721(contracts[i]).transferFrom(
        // From contract
        address(this),
        // To provided recipient
        recipients[i],
        // Transfer specified NFT tokenId
        tokenIds[i]
      );
    }
  }

  /// @notice Allows owner to update merkle
  /// @param merkleRoot to update
  function adminUpdateMerkle(bytes32 merkleRoot) external {
    // Require caller to be owner
    if (msg.sender != owner) revert NotOwner();
    // Update merkle root
    merkle = merkleRoot;
  }

  /// @notice Allows owner to update new owner
  /// @param newOwner to update
  function adminUpdateOwner(address newOwner) external {
    // Require caller to be owner
    if (msg.sender != owner) revert NotOwner();
    // Update to new owner
    owner = newOwner;
  }
}