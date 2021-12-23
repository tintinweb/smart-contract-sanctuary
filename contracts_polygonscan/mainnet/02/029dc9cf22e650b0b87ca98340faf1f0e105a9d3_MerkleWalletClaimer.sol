/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

pragma solidity 0.8.10;

// Allows anyone to claim a wallet if they exist in a merkle root.
interface IMerkleWalletClaimer {
    // Returns the address of the wallet factory.
    function factory() external view returns (address);
    // Returns the merkle root of the merkle tree containing wallets available to claim.
    function merkleRoot() external view returns (bytes32);
    // How long must elapse between committing and revealing.
    function commitRevealDelaySeconds() external view returns (uint256);
    // Whether a given commit is set and valid to claim.
    function commitments(address caller, bytes32 commitHash) external view returns (bool committed, uint256 commitTime, uint256 revealable);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Schedule making a claim
    function commit(bytes32 hash) external;
    // Claim the wallet. Reverts if the inputs are invalid.
    function claim(uint256 index, address wallet, address initialSigningKey, bytes32 secret, bytes32[] calldata merkleProof) external;

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

contract MerkleWalletClaimer is IMerkleWalletClaimer {
    address public immutable override factory;
    bytes32 public immutable override merkleRoot;
    uint256 public immutable override commitRevealDelaySeconds;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    // Track timestamps for committed hashes by caller.
    mapping(address => mapping(bytes32 => uint256)) private _commitments;

    constructor(
        address factory_,
        bytes32 merkleRoot_,
        uint256 commitRevealDelaySeconds_
    ) {
        factory = factory_;
        merkleRoot = merkleRoot_;
        commitRevealDelaySeconds = commitRevealDelaySeconds_;
    }

    function commitments(
        address caller,
        bytes32 commitHash
    ) external view override returns (
        bool committed,
        uint256 commitTime,
        uint256 revealable
    ) {
        commitTime = _commitments[caller][commitHash];
        committed = commitTime != 0;
        revealable = committed ? commitTime + commitRevealDelaySeconds : 0;
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

    function commit(bytes32 hash) external override {
        _commitments[msg.sender][hash] = block.timestamp;
    }

    function claim(
        uint256 index,
        address wallet,
        address initialSigningKey,
        bytes32 secret,
        bytes32[] calldata merkleProof
    ) external override {
        require(
            !isClaimed(index),
            'MerkleWalletClaimer: Wallet already claimed.'
        );

        bytes32 commitHash = keccak256(abi.encodePacked(index, wallet, msg.sender, secret));

        uint256 commitTime = _commitments[msg.sender][commitHash];

        require(
            commitTime != 0 && block.timestamp > commitTime + commitRevealDelaySeconds,
            'MerkleWalletClaimer: No valid commit found.'
        );

        // Verify the merkle proof.
        bytes32 secretHash = keccak256(abi.encodePacked(wallet, secret));
        bytes32 node = keccak256(abi.encodePacked(index, wallet, secretHash));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            'MerkleWalletClaimer: Invalid proof.'
        );

        // Deploy the wallet if necessary.
        uint256 walletCode;
        assembly {
            walletCode := extcodesize(wallet)
        }

        if (walletCode == 0) {
            WalletFactory(factory).newSmartWallet(initialSigningKey);

            assembly {
                walletCode := extcodesize(wallet)
            }

            require(
                walletCode != 0,
                'MerkleWalletClaimer: Invalid initial signing key supplied.'
            );
        }

        // Mark it claimed and set the caller as the owner.
        _setClaimed(index);
        Wallet(wallet).claimOwnership(msg.sender);

        emit Claimed(index, wallet, msg.sender);
    }
}