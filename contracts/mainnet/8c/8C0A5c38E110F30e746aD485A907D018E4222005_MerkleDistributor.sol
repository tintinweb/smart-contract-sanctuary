// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
    address private immutable _token;
    address private immutable _governance;
    bytes32 private immutable _merkleRoot;
    uint256 private immutable _unlockTimestamp;
    uint256 private immutable _clawbackTimestamp;
    uint256 private immutable _amountToClaim;

    mapping(bytes32 => bool) private _claimed;

    error ClaimLocked();
    error ClawbackLocked();
    error AlreadyClaimed();
    error InvalidProof();
    error NotGovernance();
    error NotGovernanceOrSelf();
    error ClawbackFailed();
    error ClaimFailed();

    modifier unlocked() {
        if (block.timestamp < _unlockTimestamp) revert ClaimLocked();
        _;
    }

    modifier clawbackAllowed() {
        if (block.timestamp < _clawbackTimestamp) revert ClawbackLocked();
        _;
    }

    modifier notClaimed(uint256 index, address account) {
        if (isClaimed(index, account)) revert AlreadyClaimed();
        _;
    }

    modifier validProof(
        uint256 index,
        address account,
        bytes32[] memory merkleProof
    ) {
        bool result = verifyMerkleProof(
            index,
            account,
            merkleProof
        );
        if (!result) revert InvalidProof();
        _;
    }

    modifier isGovernance() {
        if (msg.sender != _governance) revert NotGovernance();
        _;
    }

    constructor(
        address token_,
        uint256 amountToClaim_,
        bytes32 merkleRoot_,
        address governance_,
        uint256 unlockTimestamp_,
        uint256 clawbackTimestamp_
    ) {
        _token = token_;
        _amountToClaim = amountToClaim_;
        _merkleRoot = merkleRoot_;
        _governance = governance_;
        _unlockTimestamp = unlockTimestamp_;
        _clawbackTimestamp = clawbackTimestamp_;
    }

    // Claim the given amount of the token to self. Reverts if the inputs are invalid.
    function claim(
        uint256 index,
        bytes32[] calldata merkleProof
    )
        external
        override
        unlocked
    {
        _claim(index, msg.sender, merkleProof);
    }

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claimByGovernance(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    )
        external
        override
        isGovernance
        unlocked
    {
        _claim(index, account, merkleProof);
    }

    // Clawback the given amount of the token to the given address.
    function clawback()
        external
        override
        isGovernance
        clawbackAllowed
    {
        emit Clawback();

        uint256 balance = IERC20(_token).balanceOf(address(this));
        bool result = IERC20(_token).transfer(_governance, balance);
        if (!result) revert ClawbackFailed();
    }

    // Returns the address of the token distributed by this contract.
    function token() external view override returns (address) {
        return _token;
    }

    // Returns the amount of the token distributed by this contract.
    function amountToClaim() external view override returns (uint256) {
        return _amountToClaim;
    }

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view override returns (bytes32) {
        return _merkleRoot;
    }

    // Returns the unlock block timestamp
    function unlockTimestamp() external view override returns (uint256) {
        return _unlockTimestamp;
    }

    // Returns the clawback block timestamp
    function clawbackTimestamp() external view override returns (uint256) {
        return _clawbackTimestamp;
    }

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index, address account) public view override returns (bool) {
        return _claimed[_node(index, account)] == true;
    }

    // Verify the merkle proof.
    function verifyMerkleProof(
        uint256 index,
        address account,
        bytes32[] memory merkleProof
    )
        public
        view
        override
        returns (bool)
    {
        bytes32 node = _node(index, account);
        return MerkleProof.verify(merkleProof, _merkleRoot, node);
    }

    function _claim(
        uint256 index,
        address account,
        bytes32[] memory merkleProof
    )
        private
        notClaimed(index, account)
        validProof(index, account, merkleProof)
    {
        // Mark it claimed and send the token.
        _setClaimed(index, account);
        emit Claimed(index, account);

        bool result = IERC20(_token).transfer(account, _amountToClaim);
        if (!result) revert ClaimFailed();
    }

    function _setClaimed(uint256 index, address account) private {
        _claimed[_node(index, account)] = true;
    }

    function _node(uint256 index, address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, account));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

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
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account);

    // This event is triggered whenever a call to #clawback succeeds
    event Clawback();

    // Claim the given amount of the token to self. Reverts if the inputs are invalid.
    function claim(
        uint256 index,
        bytes32[] calldata merkleProof
    )
        external;
    
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claimByGovernance(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    ) external;

    // Clawback the given amount of the token to the given address.
    function clawback() external;

    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    // Returns the amount of the token distributed by this contract.
    function amountToClaim() external view returns (uint256);

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index, address account) external view returns (bool);

    // Returns the unlock block timestamp
    function unlockTimestamp() external view returns (uint256);

    // Returns the clawback block timestamp
    function clawbackTimestamp() external view returns (uint256);

    // Verify the merkle proof.
    function verifyMerkleProof(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    )
        external
        view
        returns (bool);
}