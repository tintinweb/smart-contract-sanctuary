/**
 *Submitted for verification at polygonscan.com on 2021-12-30
*/

pragma solidity 0.8.11;

// Take ownership of a wallet if a claim for it exists in a merkle root.
interface IMerkleWalletClaimer {
    // Returns the address of the wallet factory.
    function factory() external view returns (address);
    // Returns the merkle root of the merkle tree containing wallets available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the wallet. Reverts if the inputs are invalid. Deploys the wallet if necessary using the initial signing key.
    function claim(uint256 index, address wallet, address initialSigningKey, bytes calldata claimantSignature, bytes32[] calldata merkleProof) external;
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address wallet, address owner);
}

/**
 * @dev Partial interface of the wallet factory.
 */
interface WalletFactory {
    /**
     * @dev Deploys a new wallet.
     */
    function newSmartWallet(
        address userSigningKey
    ) external returns (address wallet);
}

/**
 * @dev Partial interface of the wallet.
 */
interface Wallet {
    /**
     * @dev Sets ownership on the wallet.
     */
    function claimOwnership(address owner) external;
}

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

library ECDSA {
  function recover(
    bytes32 hash, bytes memory signature
  ) internal pure returns (address) {
    if (signature.length != 65) {
      return (address(0));
    }

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      return address(0);
    }

    if (v != 27 && v != 28) {
      return address(0);
    }

    return ecrecover(hash, v, r, s);
  }

  function toEthSignedMessageHash(address subject) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n20", subject));
  }
}

contract MerkleWalletClaimer is IMerkleWalletClaimer {
    using ECDSA for address;
    using ECDSA for bytes32;
    address public immutable override factory;
    bytes32 public immutable override merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address factory_, bytes32 merkleRoot_) {
        factory = factory_;
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask != 0;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function _deployIfNecessary(address wallet, address initialSigningKey) private {
        // Deploy the wallet if necessary.
        uint256 walletCode;
        assembly { walletCode := extcodesize(wallet) }
        if (walletCode == 0) {
            WalletFactory(factory).newSmartWallet(initialSigningKey);

            assembly { walletCode := extcodesize(wallet) }
            require(
                walletCode != 0,
                'MerkleWalletClaimer: Invalid initial signing key supplied.'
            );
        }
    }

    function claim(
        uint256 index,
        address wallet,
        address initialSigningKey,
        bytes calldata claimantSignature,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isClaimed(index), 'MerkleWalletClaimer: Wallet already claimed.');

        // Claimant signs an EIP-191 v0x45 message consisting of the current caller.
        bytes32 messageHash = msg.sender.toEthSignedMessageHash();

        // Recover the claimant from the signature and cast the type.
        uint256 claimantKey = uint256(uint160(messageHash.recover(claimantSignature)));

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, wallet, claimantKey));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            'MerkleWalletClaimer: Invalid proof.'
        );

        // Mark it claimed.
        _setClaimed(index);

        // Deploy the wallet if necessary.
        _deployIfNecessary(wallet, initialSigningKey);

        // Set the caller as the owner on the wallet.
        Wallet(wallet).claimOwnership(msg.sender);

        emit Claimed(index, wallet, msg.sender);
    }
}