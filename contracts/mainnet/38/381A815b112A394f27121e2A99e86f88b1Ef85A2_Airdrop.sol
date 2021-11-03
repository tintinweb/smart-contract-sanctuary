/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/MerkleProof.sol

// Forked from: https://gist.github.com/islishude/d33f8b6aed4df9d599187ec0aae9b5f5
pragma solidity 0.6.12;

/**
 * @dev This functions deal with verification of Merkle trees (hash trees)
 * The library is from OpenZeppelin
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

contract MerkleProofWrapper {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) external pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}


// File contracts/Interfaces.sol

interface IVesting {
    function create(
        address _usr,
        uint256 _tot,
        uint256 _bgn,
        uint256 _tau,
        uint256 _eta,
        address _mgr
    ) external returns (uint256 id);
}

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Start timestamp of the airdrop
    function vestingStartTimestamp() external view returns (uint256);

    // Vesting duration
    function vestingDuration() external view returns (uint256);

    // Claim End
    function claimEnd() external view returns (uint256);

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}


// File contracts/Airdrop.sol

// SPDX-License-Identifier: GPL-3.0

// Forked from: https://gist.github.com/islishude/d33f8b6aed4df9d599187ec0aae9b5f5
pragma solidity 0.6.12;

contract Airdrop {
    // ======================= Variables ========================

    // @notice Root of the merkle tree
    bytes32 public merkleRoot;

    // @notice Address of the reward token
    IERC20 public rewardToken;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private _claimedBitMap;

    // Owners of this contract
    mapping(address => uint256) public owners;

    // ======================= Events ========================

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    // ======================= Constructor ========================

    constructor(
        IERC20 rewardToken_,
        bytes32 merkleRoot_,
        address angleMaster
    ) public {
        merkleRoot = merkleRoot_;
        rewardToken = rewardToken_;

        owners[msg.sender] = 1;
        owners[angleMaster] = 1;
    }

    modifier onlyOwner() {
        require(owners[msg.sender] == 1, "Caller is not authorized");
        _;
    }

    // ======================= Functions ========================

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        _claimedBitMap[claimedWordIndex] = _claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and do the transfer.
        _setClaimed(index);
        rewardToken.transfer(account, amount);
        emit Claimed(index, account, amount);
    }

    // ======================= Governance ========================

    function rely(address usr) external onlyOwner {
        owners[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external onlyOwner {
        owners[usr] = 0;
        emit Deny(usr);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function recover(
        IERC20 token,
        address _guy,
        uint256 _amt
    ) external onlyOwner {
        require(token.transfer(_guy, _amt));
    }
}