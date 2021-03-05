/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

// Sources flattened with hardhat v2.0.7 https://hardhat.org

// File @openzeppelin/contracts/cryptography/[email protected]

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

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
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// File contracts/interfaces/IMirrorWriteToken.sol

interface IMirrorWriteToken {
    function register(string calldata label, address owner) external;

    function registrationCost() external view returns (uint256);

    // ============ ERC20 Interface ============

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File contracts/lib/SafeMath.sol

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// File contracts/helpers/WriteDistributionHelperV1.sol

/**
 * @title WriteDistributionHelperV1
 * @author MirrorXYZ
 *
 * A helper contract for distributing $WRITE token.
 */
contract WriteDistributionHelperV1 {
    // ============ Constants ============

    uint64 constant units = 1e18;

    // ============ Immutable Storage ============

    address public immutable token;

    // ============ Mutable Storage ============

    address private _owner;
    /**
     * @dev Allows for two-step ownership transfer, whereby the next owner
     * needs to accept the ownership transfer explicitly.
     */
    address private _nextOwner;
    bytes32 public merkleRoot;
    mapping(uint256 => uint256) private claimedBitMap;

    // ============ Events ============

    event Distributed(address account);
    event RootUpdated(bytes32 oldRoot, bytes32 newRoot);
    event Claimed(uint256 index, address account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(isOwner(), "WriteDistributionV1: caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(
            isNextOwner(),
            "WriteDistributionV1: current owner must set caller as next owner."
        );
        _;
    }

    // ============ Constructor ============

    constructor(address token_) public {
        token = token_;

        _owner = tx.origin;
        emit OwnershipTransferred(address(0), _owner);
    }

    // ============ Ownership ============

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Returns true if the caller is the next owner.
     */
    function isNextOwner() public view returns (bool) {
        return msg.sender == _nextOwner;
    }

    /**
     * @dev Allows a new account (`newOwner`) to accept ownership.
     * Can only be called by the current owner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(
            nextOwner_ != address(0),
            "WriteDistributionV1: next owner is the zero address."
        );

        _nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel a transfer of ownership to a new account.
     * Can only be called by the current owner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete _nextOwner;
    }

    /**
     * @dev Transfers ownership of the contract to the caller.
     * Can only be called by a new potential owner set by the current owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete _nextOwner;

        emit OwnershipTransferred(_owner, msg.sender);

        _owner = msg.sender;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // ============ Distribution ============

    function distributeTo(address[] memory addresses)
        public
        onlyOwner
        returns (bool ok)
    {
        IMirrorWriteToken tokenContract = IMirrorWriteToken(token);

        for (uint256 i = 0; i < addresses.length; i++) {
            tokenContract.transfer(addresses[i], units);
            emit Distributed(addresses[i]);
        }

        return true;
    }

    // ============ Merkle-Tree Token Claim ============

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        emit RootUpdated(merkleRoot, merkleRoot_);
        merkleRoot = merkleRoot_;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!isClaimed(index), "WriteDistributionV1: already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "WriteDistributionV1: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(
            IMirrorWriteToken(token).transfer(account, amount),
            "WriteDistributionV1: Transfer failed."
        );

        emit Claimed(index, account, amount);
    }
}