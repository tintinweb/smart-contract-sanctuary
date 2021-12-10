// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import "./SnarkConstants.sol";
import "./ErrorMsgs.sol";
import "./triadTree/TriadIncrementalMerkleTrees.sol";
import "./utils/DefaultOwnable.sol";
import "./utils/Utils.sol";

/**
 * @title IdentityRegister
 * @author Pantherprotocol Contributors
 * @notice Incremental Merkle trees of identity commitments
 */
contract IdentityRegister is
    DefaultOwnable,
    TriadIncrementalMerkleTrees,
    Utils
{
    enum State {
        notStarted,
        ongoing,
        finalized
    }

    event RegisterState(State);
    event EndTimeUpdated(uint256 newRegistrationEnd);

    /**
     * @dev Emitted on a new Identity Commitment registered
     * @param kycId ID of the KYC'd identity (encoded)
     * @param identityCommitment Identity Commitment
     * @param leafId ID of the leaf (on the tree of commitments)
     */
    event NewIdentity(
        bytes32 kycId,
        bytes32 indexed identityCommitment,
        uint256 leafId
    );

    /**
     * @dev Emitted on an Identity Commitment queued to be registered
     * @param kycId ID of the KYC'd identity (encoded)
     * @param identityCommitment Identity Commitment
     * @param leafId ID of the leaf (on the tree of commitments)
     */
    event QueuedIdentity(
        bytes32 kycId,
        bytes32 indexed identityCommitment,
        uint256 leafId
    );

    // solhint-disable-next-line var-name-mixedcase
    address public immutable DEFAULT_OWNER;

    /// @notice Mapping from kycId to the identityCommitment
    mapping(bytes32 => bytes32) public seenKycIds;

    /// @notice Mapping from identityCommitment to the block number (when seen)
    mapping(bytes32 => uint256) public seenIdentityCommitments;

    /// @notice Current state of registration campaign
    State public state;

    /// @notice Time when registration of Identities Commitments ends
    uint32 public registrationEnd;

    /// @notice Hash (keccak256) of the list of KYC'd identities IDs
    bytes32 public kycIdsHash;

    /// @notice Number of KYC'd identities IDs
    uint32 public kycIdsNum;

    /// @notice Number of registered (or yet queued) Identities Commitments
    uint32 public idsNum;

    /// @dev Cached (queued) KYC'd IDs (of queued Identities Commitments)
    bytes32[TRIAD_SIZE] internal _queuedIds;
    /// @dev Cached (queued) Identities Commitments
    bytes32[TRIAD_SIZE] internal _queuedCommitments;

    constructor(address defaultOwner, uint32 _regEnd) {
        require(address(defaultOwner) != address(0), ERR_ZERO_OWNER);
        require(uint256(_regEnd) > timeNow(), ERR_EXPIRED_REG_END);

        DEFAULT_OWNER = defaultOwner;
        registrationEnd = _regEnd;
    }

    /// @notice Queues given Identity Commitment, or registers it together with
    /// other queued commitments, if the queue is full.
    /// It emits {QueuedIdentity} event, or {NewIdentity} events.
    /// @dev Only the owner may call
    function registerCommitment(bytes32 kycId, bytes32 commitment)
        external
        onlyOwner
    {
        _revertIfExpired();
        _revertIfNotOngoing();
        _sanitizeCommit(kycId, commitment);
        _revertSeenKycId(kycId);
        _revertSeenCommitments(commitment);

        seenKycIds[kycId] = commitment;
        seenIdentityCommitments[commitment] = block.number;

        uint256 n = idsNum + 1;
        idsNum = uint32(n); // can't exceed uint32

        uint256 i = n % TRIAD_SIZE;
        if (i == 0) {
            // Prepare the triad (of commitments)
            bytes32[TRIAD_SIZE] memory triad;
            bytes32[TRIAD_SIZE] memory ids;
            for (uint256 k = 0; k < TRIAD_SIZE - 1; k++) {
                ids[k] = _queuedIds[k];
                triad[k] = _queuedCommitments[k];
            }
            ids[TRIAD_SIZE - 1] = kycId;
            triad[TRIAD_SIZE - 1] = commitment;

            // Register the triad
            addAndEmitTriad(ids, triad);
        } else {
            // Queue the Commitment
            uint256 leafId = getNextLeafId() + i - 1;
            _queuedIds[i - 1] = kycId;
            _queuedCommitments[i - 1] = commitment;
            emit QueuedIdentity(kycId, commitment, leafId);
        }
    }

    /// @notice Register given Identities Commitments, emits {NewIdentity}
    function registerCommitments(
        bytes32[] calldata kycIds,
        bytes32[] calldata commitments
    ) external onlyOwner {
        _revertIfExpired();
        _revertIfNotOngoing();

        uint256 n = kycIds.length;
        require(n % TRIAD_SIZE == 0, ERR_UNEVEN_TRIAD);
        require(n == commitments.length, ERR_UNMATCHED_ARRAYS);

        uint256 nTriads = n / TRIAD_SIZE;
        require(nTriads > 0, ERR_EMPTY_TRIADS);

        for (uint256 i = 0; i < n; i += TRIAD_SIZE) {
            bytes32[TRIAD_SIZE] memory triad;
            bytes32[TRIAD_SIZE] memory ids;

            // Process the triad (of commitments)
            for (uint256 k = 0; k < TRIAD_SIZE; k++) {
                _sanitizeCommit(kycIds[i + k], commitments[i + k]);
                _revertSeenKycId(kycIds[i + k]);
                _revertSeenCommitments(commitments[i + k]);

                seenKycIds[kycIds[i + k]] = commitments[i + k];
                seenIdentityCommitments[commitments[i + k]] = block.number;
                ids[k] = kycIds[i + k];
                triad[k] = commitments[i + k];
            }

            // Register the triad
            addAndEmitTriad(ids, triad);
        }

        idsNum = uint32(idsNum + n); // can't exceed uint32
    }

    /// @notice Sets state as "ongoing", and commits on KYC'd IDs
    /// @dev Only the owner may call, once only
    function openRegistration(bytes32 _kycIdsHash, uint256 _kycIdsNum)
        external
        onlyOwner
    {
        _revertIfExpired();
        require(
            state == State.notStarted &&
                uint256(_kycIdsHash) != 0 &&
                _kycIdsNum != 0,
            ERR_CANT_OPEN
        );
        kycIdsHash = _kycIdsHash;
        kycIdsNum = uint32(_kycIdsNum); // can't exceed uint32

        state = State.ongoing;
        emit RegisterState(State.ongoing);
    }

    /// @notice Sets "finalized" state, and registers queued Commitments
    function finalizeRegistration() external {
        require(timeNow() > uint256(registrationEnd), ERR_ONGOING_REG);
        require(state != State.finalized, ERR_FINALIZED_REG);
        state = State.finalized;

        uint256 i = idsNum % TRIAD_SIZE;
        if (i > 0) {
            // At least one commitment waits for registration
            bytes32[TRIAD_SIZE] memory triad;
            bytes32[TRIAD_SIZE] memory ids;
            for (uint256 k = 0; k < TRIAD_SIZE; k++) {
                if (i > k) {
                    // Take queued commitments, ...
                    ids[k] = _queuedIds[k];
                    triad[k] = _queuedCommitments[k];
                } else {
                    // ... then append dummy ones to fill the triad
                    ids[k] = 0;
                    triad[k] = ZERO_VALUE;
                }
            }
            // Register the triad
            addAndEmitTriad(ids, triad);
        }
        emit RegisterState(State.finalized);
    }

    function updateRegistrationEnd(uint32 _regEnd) external onlyOwner {
        require(
            uint256(_regEnd) > timeNow() && state != State.finalized,
            ERR_FAILED_REG_END
        );
        registrationEnd = _regEnd;
        emit EndTimeUpdated(uint256(_regEnd));
    }

    /// Internal and private functions follow

    function addAndEmitTriad(
        bytes32[TRIAD_SIZE] memory kycIds,
        bytes32[TRIAD_SIZE] memory commitments
    ) private {
        // Insert the triad into Merkle tree(s)
        uint256 leftLeafId = insertBatch(commitments);

        // Notify UI (wallets) on new Commitments
        for (uint256 k = 0; k < TRIAD_SIZE; k++) {
            emit NewIdentity(kycIds[k], commitments[k], leftLeafId + k);
        }
    }

    function _revertIfExpired() private view {
        require(timeNow() < uint256(registrationEnd), ERR_EXPIRED_REG);
    }

    function _revertIfNotOngoing() private view {
        require(state == State.ongoing, ERR_NOT_STARTED_REG);
    }

    function _revertSeenKycId(bytes32 kycId) private view {
        require(uint256(seenKycIds[kycId]) == 0, ERR_DOUBLE_COMMIT);
    }

    function _revertSeenCommitments(bytes32 commitment) private view {
        require(
            uint256(seenIdentityCommitments[commitment]) == 0,
            ERR_DOUBLE_COMMIT
        );
    }

    function _sanitizeCommit(bytes32 kycId, bytes32 commitment) private pure {
        require(uint256(kycId) != 0, ERR_ZERO_KYC_ID);
        require(
            uint256(commitment) < SNARK_SCALAR_FIELD,
            ERR_TOO_LARGE_COMMITMENTS
        );
    }

    function _defaultOwner() internal view virtual override returns (address) {
        return DEFAULT_OWNER;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.4;

// @dev Order of alt_bn128 and the field prime of Baby Jubjub and Poseidon hash
uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

// @dev Field prime of alt_bn128
uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

// Shared between contracts
string constant ERR_ZERO_OWNER = "SH:EB"; // zero address of owner provided

// TriadIncrementalMerkleTrees contract
string constant ERR_ZERO_ROOT = "TT:E1"; // merkle tree root can not be zero
string constant ERR_CANT_DEL_ROOT = "TT:E2"; // failed to delete a root from history

// IdentityRegister contract
string constant ERR_DOUBLE_COMMIT = "IdentityReg: already registered";
string constant ERR_EMPTY_TRIADS = "IR:E1"; // input arrays must have at least one TRIAD
string constant ERR_EXPIRED_REG = "IdentityReg: registration closed";
string constant ERR_EXPIRED_REG_END = "IR:E3"; // provided registration end already expired
string constant ERR_FINALIZED_REG = "IdentityReg: already finalized";
string constant ERR_CANT_OPEN = "IR:E4"; // registration already opened or invalid input
string constant ERR_NOT_STARTED_REG = "IdentityReg: not started"; // registration not yet started
string constant ERR_ONGOING_REG = "IdentityReg: not yet finished";
string constant ERR_FAILED_REG_END = "IR:E6"; // invalid registration deadline provided
string constant ERR_TOO_LARGE_COMMITMENTS = "IR:E7"; // commitment exceeds maximum scalar field size
string constant ERR_UNEVEN_TRIAD = "IR:E8"; // input array length must be multiple of TRIAD_SIZE
string constant ERR_UNMATCHED_ARRAYS = "IR:E9"; // input arrays have different length
string constant ERR_ZERO_KYC_ID = "IR:EA"; // kycId can't be zero

// PreZkpMinter contract
string constant ERR_ZERO_REGISTER = "PM:02"; // zero address of register provided
string constant ERR_MINT_ENDED = "PZMinter: minting period ended";
string constant ERR_MINT_NOT_STARTED = "PZMinter: minting not started";
string constant ERR_FAILED_MINT_START = "PM:05"; // invalid openMinting input
string constant ERR_FAILED_PREZKP = "PM:06"; // invalid setPreZkp input
string constant ERR_FAILED_MINT_END = "PM:07"; // invalid updateMintingEnd input
string constant ERR_INVALID_SIGN = "PZMinter: invalid signature";
string constant ERR_EXPIRED_SIGN = "PZMinter: signature expired";
string constant ERR_INVALID_PROOF = "PZMinter: invalid proof";
string constant ERR_SEEN_NULLIFIER = "PZMinter: seen nullifier";
string constant ERR_UNKNOWN_ROOT = "PZMinter: unknown root";

// ProofVerifier contract
string constant ERR_INVALID_PROOF_ELEMENT = "PZMinter: invalid proof (gte Q)";
string constant ERR_INVALID_PROOF_INPUT = "PZMinter: invalid proof (input)";
string constant ERR_INVALID_PROOF_SIZE = "PZMinter: invalid proof (size)";
string constant ERR_INVALID_PUBINPUTS = "PZMinter: invalid pub inputs";
string constant ERR_ZERO_VERIFIER = "PM:01"; // zero address of verifier provided

// PubInputsHasher contract
string constant ERR_LARGE_NULLIFIER = "PZMinter: nullifier gte SnarkField";
string constant ERR_LARGE_ROOT = "PZMinter: root gte SnarkField";

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.4;

import { PoseidonT3, PoseidonT4 } from "./Poseidon.sol";
import "./TriadMerkleZeros.sol";
import { ERR_ZERO_ROOT, ERR_CANT_DEL_ROOT } from "../ErrorMsgs.sol";

/**
 * @title TriadIncrementalMerkleTrees
 * @author Pantherprotocol Contributors
 * @notice Incremental Merkle trees with batch insertion of 3 leaves at once
 * @dev Refer to {TriadMerkleZeros} for comments on "triad trees" used
 * Inspired by MACI project
 * https://github.com/appliedzkp/maci/blob/master/contracts/sol/IncrementalMerkleTree.sol
 */
contract TriadIncrementalMerkleTrees is TriadMerkleZeros {
    /**
     * @dev {treeId} of a tree is the number of trees populated before the tree.
     * @dev {leafId} of a leaf is a "modified" number of leaves inserted in all
     * tries before this leaf. It is unique across all trees, starts from 0 for
     * the 1st leaf of the 1st tree, and constantly increments like this:
     * 0,1,2,  4,5,6,  8,9,10,  12,13,14  16,17,18 ...
     * (i.e, "modified" means every 4th number is skipped)
     * See comments to {TriadMerkleZeros}.
     */

    // `leafId` of the next leaf to insert
    uint256 private _nextLeafId;

    // Right-most elements (hashes) in the current tree per level
    // level index => hash
    mapping(uint256 => bytes32) private filledSubtrees;

    /// @notice Roots of fully populated trees
    /// @dev treeId => root
    mapping(uint256 => bytes32) public finalRoots;

    // Recent roots of trees seen
    // cacheIndex => root ^ treeId
    mapping(uint256 => uint256) private cachedRoots;

    // @dev Root permanently added to the `finalRoots`
    event AnchoredRoot(uint256 indexed treeId, bytes32 root);
    // @dev Root temporarily saved in the `cachedRoots`
    event CachedRoot(uint256 treeId, bytes32 root);

    // NOTE: No `constructor` (initialization) function needed

    // Max number of latest roots to cache (must be a power of 2)
    uint256 internal constant CACHED_ROOTS_NUM = 4;

    // Number of leaves in a modified triad used for leaf ID calculation
    uint256 internal constant iTRIAD_SIZE = 4;
    // The number of leaves in a tree used for leaf ID calculation
    uint256 internal constant iLEAVES_NUM = 2**(TREE_DEPTH - 1) * iTRIAD_SIZE;

    // Bitmasks and numbers of bits for "cheaper" arithmetics
    uint256 private constant iTRIAD_SIZE_MASK = iTRIAD_SIZE - 1;
    uint256 private constant iTRIAD_SIZE_BITS = 2;
    uint256 private constant iLEAVES_NUM_MASK = iLEAVES_NUM - 1;
    uint256 private constant iLEAVES_NUM_BITS =
        TREE_DEPTH - 1 + iTRIAD_SIZE_BITS;
    uint256 private constant CACHE_SIZE_MASK =
        CACHED_ROOTS_NUM * iTRIAD_SIZE - 1;

    /**
     * @notice Returns the number of leaves inserted in all trees so far
     */
    function leavesNum() external view returns (uint256) {
        return _nextLeafId2LeavesNum(_nextLeafId);
    }

    /**
     * @notice Returns `treeId` of the current tree
     */
    function curTree() external view returns (uint256) {
        return getTreeId(_nextLeafId);
    }

    /**
     * @notice Returns `treeId` of the given leaf tree
     */
    function getTreeId(uint256 leafId) public pure returns (uint256) {
        // equivalent to `leafId / iLEAVES_NUM`
        return leafId >> iLEAVES_NUM_BITS;
    }

    /**
     * @notice Returns the root of the current tree
     */
    function curRoot() external view returns (bytes32) {
        uint256 nextLeafId = _nextLeafId;
        uint256 leavesInTreeNum = nextLeafId & iLEAVES_NUM_MASK;
        if (leavesInTreeNum == 0) return ZERO_ROOT;

        uint256 treeId = getTreeId(nextLeafId);
        uint256 v = cachedRoots[_nextLeafId2CacheIndex(nextLeafId)];
        return bytes32(v ^ treeId);
    }

    /**
     * @notice Returns `true` if the given root of the given tree is known
     */
    function isKnownRoot(uint256 treeId, bytes32 root)
        public
        view
        returns (bool)
    {
        require(root != 0, ERR_ZERO_ROOT);

        // first, check the history
        bytes32 _root = finalRoots[treeId];
        if (_root == root) return true;

        // then, look in cache
        for (uint256 i = 0; i < CACHED_ROOTS_NUM; i++) {
            uint256 cacheIndex = i * iTRIAD_SIZE;
            uint256 v = cachedRoots[cacheIndex];
            if (v == treeId ^ uint256(root)) return true;
        }
        return false;
    }

    /**
     * @dev Inserts 3 leaves into the current tree, or a new one, if that's full
     * @param leaves The 3 leaves to insert (must be less than SNARK_SCALAR_FIELD)
     * @return leftLeafId The `leafId` of the first leaf from 3 inserted
     */
    function insertBatch(bytes32[TRIAD_SIZE] memory leaves)
        internal
        returns (uint256 leftLeafId)
    {
        leftLeafId = _nextLeafId;

        bytes32[TREE_DEPTH] memory zeros;
        populateZeros(zeros);

        // index of a "current" node (0 for the leftmost node/leaf of a level)
        uint256 nodeIndex;
        // hash (value) of a "current" node
        bytes32 nodeHash;
        // index of a "current" level (0 for leaves, increments toward root)
        uint256 level;

        // subtree from 3 leaves being inserted on `level = 0`
        nodeHash = poseidon(leaves[0], leaves[1], leaves[2]);
        // ... to be placed under this index on `level = 1`
        // (equivalent to `(leftLeafId % iLEAVES_NUM) / iTRIAD_SIZE`)
        nodeIndex = (leftLeafId & iLEAVES_NUM_MASK) >> iTRIAD_SIZE_BITS;

        bytes32 left;
        bytes32 right;
        for (level = 1; level < TREE_DEPTH; level++) {
            // if `nodeIndex` is, say, 25, over the iterations it will be:
            // 25, 12, 6, 3, 1, 0, 0 ...

            if (nodeIndex % 2 == 0) {
                left = nodeHash;
                right = zeros[level];
                filledSubtrees[level] = nodeHash;
            } else {
                // for a new tree, "than" block always run before "else" block
                // so `filledSubtrees[level]` gets updated before its use
                left = filledSubtrees[level];
                right = nodeHash;
            }

            nodeHash = poseidon(left, right);

            // equivalent to `nodeIndex /= 2`
            nodeIndex >>= 1;
        }

        uint256 nextLeafId = leftLeafId + iTRIAD_SIZE;
        _nextLeafId = nextLeafId;

        uint256 treeId = getTreeId(leftLeafId);
        if (isFullTree(leftLeafId)) {
            // Switch to a new tree
            // Ignore `filledSubtrees` old values as they are never re-used
            finalRoots[treeId] = nodeHash;
            emit AnchoredRoot(treeId, nodeHash);
        } else {
            uint256 cacheIndex = _nextLeafId2CacheIndex(nextLeafId);
            cachedRoots[cacheIndex] = uint256(nodeHash) ^ treeId;
            emit CachedRoot(treeId, nodeHash);
        }
    }

    function getNextLeafId() internal view returns (uint256) {
        return _nextLeafId;
    }

    function isFullTree(uint256 leftLeafId) internal pure returns (bool) {
        return (iLEAVES_NUM - (leftLeafId & iLEAVES_NUM_MASK)) <= iTRIAD_SIZE;
    }

    /// Private functions follow

    function _nextLeafId2LeavesNum(
        uint256 nextLeafId // declared as `internal` to facilitate testing
    ) internal pure returns (uint256) {
        // equiv to `nextLeafId / iTRIAD_SIZE * TRIAD_SIZE + nextLeafId % iTRIAD_SIZE`
        return
            (nextLeafId >> iTRIAD_SIZE_BITS) *
            TRIAD_SIZE +
            (nextLeafId & iTRIAD_SIZE_MASK);
    }

    function _nextLeafId2CacheIndex(uint256 nextLeafId)
        private
        pure
        returns (uint256)
    {
        return nextLeafId & CACHE_SIZE_MASK;
    }

    function poseidon(bytes32 left, bytes32 right)
        private
        pure
        returns (bytes32)
    {
        bytes32[2] memory input;
        input[0] = left;
        input[1] = right;
        return PoseidonT3.poseidon(input);
    }

    function poseidon(
        bytes32 left,
        bytes32 mid,
        bytes32 right
    ) private pure returns (bytes32) {
        bytes32[3] memory input;
        input[0] = left;
        input[1] = mid;
        input[2] = right;
        return PoseidonT4.poseidon(input);
    }

    // If a "child" of this contract runs behind a proxy that DELEGATECALLs it,
    // in case new variables added on upgrades, decrease the `__gap`
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * Inspired and borrowed by/from the openzeppelin/contracts` {Ownable}.
 * Unlike openzeppelin` version:
 * - by default, the owner account is the one returned by the {_defaultOwner}
 * function, but not the deployer address;
 * - this contract has no constructor and may run w/o initialization;
 * - the {renounceOwnership} function removed.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 * The child contract must define the {_defaultOwner} function.
 */
abstract contract DefaultOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev Returns the current owner address, if it's defined, or the default owner address otherwise.
    function owner() public view virtual returns (address) {
        return _owner == address(0) ? _defaultOwner() : _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @dev Transfers ownership of the contract to the `newOwner`. The owner can only call.
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function _defaultOwner() internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

contract Utils {
    /// @dev Returns the current block timestamp (added to ease testing)
    function timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// This is a stub to keep solc happy; the actual code is generated
// using poseidon_gencontract.js from circomlibjs.

library PoseidonT3 {
    function poseidon(bytes32[2] memory) external pure returns (bytes32) {
        revert("FAKE");
        return 0;
    }
}

library PoseidonT4 {
    function poseidon(bytes32[3] memory) external pure returns (bytes32) {
        revert("FAKE");
        return 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// Content is autogenerated by `lib/generateTriadMerkleZerosContract.ts`
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.4;

/**
 * @dev The "triad binary tree" is a modified Merkle (full) binary tree with:
 * - every node, from the root upto the level preceding leaves, excluding
 * that level, has 2 child nodes (i.e. this subtree is a full binary tree);
 * - every node of the layer preceding leaves has 3 child nodes (3 leaves).
 * Example:
 * [4]                                       0
 *                                           |
 * [3]                        0--------------------------------1
 *                            |                                |
 * [2]                0---------------1                 2--------------3
 *                    |               |                 |              |
 * [1]            0-------1       2-------3        4-------5       6-------7
 *               /|\     /|\     /|\     /|\      /|\     /|\     /|\     /|\
 * [0] index:   0..2    3..5    6..8    9...11  12..14  15..17  18..20  21..24
 *
 *   leaf ID:   0..2    4..6    8..10   12..14  16..18  20..23  24..27  28..30
 *
 * - Number in [] is the "level index" that starts from 0 for the leaves level.
 * - Numbers in node/leaf positions are "node/leaf indices" which starts from 0
 *   for the leftmost node/leaf of every level.
 * - Numbers bellow leaves are IDs of leaves.
 *
 * Arithmetic operations with multiples of 2 (i.e. shifting) is "cheaper" than
 * operations with multiples of 3 (both on-chain and in zk-circuits).
 * Therefore, IDs of leaves (but NOT hashes of nodes) are calculated as if the
 * tree would have 4 (not 3) leaves in branches, with every 4th leaf skipped.
 * In other words, there are no leaves with IDs 3, 7, 11, 15, 19...
 */

// @notice The "triad binary tree" populated with zero leaf values
abstract contract TriadMerkleZeros {
    // Number of levels in a tree including both leaf and root levels
    uint256 internal constant TREE_LEVELS = 11;

    // @dev Number of levels in a tree excluding the root level
    // (also defined in scripts/writeTriadMerkleZeroesContracts.sh)
    uint256 public constant TREE_DEPTH = 10;

    // Number of leaves in a branch with the root on the level 1
    uint256 internal constant TRIAD_SIZE = 3;

    // Number of leaves in the fully populated tree
    uint256 internal constant LEAVES_NUM = (2**(TREE_DEPTH - 1)) * TRIAD_SIZE;

    // @dev Leaf zero value (`keccak256("Pantherprotocol")%SNARK_SCALAR_FIELD`)
    bytes32 public constant ZERO_VALUE =
        bytes32(
            uint256(
                0x667764c376602b72ef22218e1673c2cc8546201f9a77807570b3e5de137680d
            )
        );
    // Merkle root of a tree that contains zeros only
    bytes32 internal constant ZERO_ROOT =
        bytes32(
            uint256(
                0x17b31de43ba4c687cf950ad00dfbe33df40047e79245b50bd1d9f87e622bf2af
            )
        );

    function populateZeros(bytes32[TREE_DEPTH] memory zeros) internal pure {
        zeros[0] = bytes32(
            uint256(
                0x667764c376602b72ef22218e1673c2cc8546201f9a77807570b3e5de137680d
            )
        );
        zeros[1] = bytes32(
            uint256(
                0x1be18cd72ac1586de27dd60eba90654bd54383004991951bccb0f6bad02c67f6
            )
        );
        zeros[2] = bytes32(
            uint256(
                0x7677e6102f0acf343edde864f79ef7652faa5a66d575b8b60bb826a4aa517e6
            )
        );
        zeros[3] = bytes32(
            uint256(
                0x28a85866ab97bd65cc94b0d1f5c5986481f8a0d65bdd5c1e562659eebb13cf63
            )
        );
        zeros[4] = bytes32(
            uint256(
                0x87321a66ea3af7780128ea1995d7fc6ec44a96a1b2d85d3021208cede68c15c
            )
        );
        zeros[5] = bytes32(
            uint256(
                0x233b4e488f0aaf5faef4fc8ea4fefeadb6934eb882bc33b9df782fd1d83b41a0
            )
        );
        zeros[6] = bytes32(
            uint256(
                0x1a0cefcf0c592da6426717d3718408c61af1d0a9492887f3faecefcba1a0a309
            )
        );
        zeros[7] = bytes32(
            uint256(
                0x2cdf963150b321923dd07b2b52659aceb529516a537dfebe24106881dd974293
            )
        );
        zeros[8] = bytes32(
            uint256(
                0x93a186bf9ec2cc874ceab26409d581579e1a431ecb6987d428777ceedfa15c4
            )
        );
        zeros[9] = bytes32(
            uint256(
                0xcbfc07131ef4197a4b4e60153d43381520ec9ab4c9c3ed34d88883a881a4e07
            )
        );
    }
}