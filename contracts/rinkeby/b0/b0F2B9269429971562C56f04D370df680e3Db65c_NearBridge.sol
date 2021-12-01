// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.7;

import "./AdminControlled.sol";
import "./INearBridge.sol";
import "./NearDecoder.sol";
import "./Ed25519.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NearBridge is INearBridge, UUPSUpgradeable, AdminControlled {
    using Borsh for Borsh.Data;
    using NearDecoder for Borsh.Data;

    // Assumed to be even and to not exceed 256.
    uint constant MAX_BLOCK_PRODUCERS = 100;

    struct Epoch {
        bytes32 epochId;
        uint numBPs;
        bytes32[MAX_BLOCK_PRODUCERS] keys;
        bytes32[MAX_BLOCK_PRODUCERS / 2] packedStakes;
        uint256 stakeThreshold;
    }

    // Whether the contract was initialized.
    bool public initialized;
    uint256 public lockEthAmount;
    // lockDuration and replaceDuration shouldn't be extremely big, so adding them to an uint64 timestamp should not overflow uint256.
    uint256 public lockDuration;
    // replaceDuration is in nanoseconds, because it is a difference between NEAR timestamps.
    uint256 public replaceDuration;
    Ed25519 private edwards;

    Epoch[3] epochs;
    uint curEpoch;
    uint64 curHeight;

    // The most recently added block. May still be in its challenge period, so should not be trusted.
    uint64 untrustedHeight;
    uint256 untrustedTimestamp;
    bool untrustedNextEpoch;
    bytes32 untrustedHash;
    bytes32 untrustedMerkleRoot;
    bytes32 untrustedNextHash;
    uint256 untrustedSignatureSet;
    NearDecoder.Signature[MAX_BLOCK_PRODUCERS] untrustedSignatures;

    // Address of the account which submitted the last block.
    address lastSubmitter;
    // End of challenge period. If zero, untrusted* fields and lastSubmitter are not meaningful.
    uint public lastValidAt;

    mapping(uint64 => bytes32) blockHashes_;
    mapping(uint64 => bytes32) blockMerkleRoots_;
    mapping(address => uint256) public override balanceOf;

    modifier checkDuration(uint256 replaceDuration_, uint256 lockDuration_) {
        require(replaceDuration_ > lockDuration_ * 1000000000, "Invalid Duration");
        _;
    }

    function initialize(
        Ed25519 ed,
        uint256 lockEthAmount_,
        uint256 lockDuration_,
        uint256 replaceDuration_,
        address admin_,
        uint256 pausedFlags_
    ) public initializer checkDuration(replaceDuration_, lockDuration_) {
        __UUPSUpgradeable_init();
        __AdminControlled_init(admin_, pausedFlags_);

        edwards = ed;
        lockEthAmount = lockEthAmount_;
        lockDuration = lockDuration_;
        replaceDuration = replaceDuration_;
    }

    uint constant UNPAUSE_ALL = 0;
    uint constant PAUSED_DEPOSIT = 1;
    uint constant PAUSED_WITHDRAW = 2;
    uint constant PAUSED_ADD_BLOCK = 4;
    uint constant PAUSED_CHALLENGE = 8;
    uint constant PAUSED_VERIFY = 16;

    function deposit() external payable override pausable(PAUSED_DEPOSIT) {
        require(msg.value == lockEthAmount && balanceOf[msg.sender] == 0);
        balanceOf[msg.sender] = msg.value;
    }

    function withdraw() external override pausable(PAUSED_WITHDRAW) {
        require(msg.sender != lastSubmitter || block.timestamp >= lastValidAt);
        uint amount = balanceOf[msg.sender];
        require(amount != 0);
        balanceOf[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function challenge(address payable receiver, uint signatureIndex) external override pausable(PAUSED_CHALLENGE) {
        require(block.timestamp < lastValidAt, "No block can be challenged at this time");
        require(!checkBlockProducerSignatureInHead(signatureIndex), "Can't challenge valid signature");

        balanceOf[lastSubmitter] = balanceOf[lastSubmitter] - lockEthAmount;
        receiver.transfer(lockEthAmount / 2);
        lastValidAt = 0;
    }

    function checkBlockProducerSignatureInHead(uint signatureIndex) public view override returns (bool) {
        // Shifting by a number >= 256 returns zero.
        require((untrustedSignatureSet & (1 << signatureIndex)) != 0, "No such signature");
        unchecked {
            Epoch storage untrustedEpoch = epochs[untrustedNextEpoch ? (curEpoch + 1) % 3 : curEpoch];
            NearDecoder.Signature storage signature = untrustedSignatures[signatureIndex];
            bytes memory message = abi.encodePacked(
                uint8(0),
                untrustedNextHash,
                Utils.swapBytes8(untrustedHeight + 2),
                bytes23(0)
            );
            (bytes32 arg1, bytes9 arg2) = abi.decode(message, (bytes32, bytes9));
            return edwards.check(untrustedEpoch.keys[signatureIndex], signature.r, signature.s, arg1, arg2);
        }
    }

    // The first part of initialization -- setting the validators of the current epoch.
    function initWithValidators(bytes memory data) external override onlyAdmin {
        require(!initialized && epochs[0].numBPs == 0, "Wrong initialization stage");

        Borsh.Data memory borsh = Borsh.from(data);
        NearDecoder.BlockProducer[] memory initialValidators = borsh.decodeBlockProducers();
        borsh.done();

        setBlockProducers(initialValidators, epochs[0]);
    }

    // The second part of the initialization -- setting the current head.
    function initWithBlock(bytes memory data) external override onlyAdmin {
        require(!initialized && epochs[0].numBPs != 0, "Wrong initialization stage");
        initialized = true;

        Borsh.Data memory borsh = Borsh.from(data);
        NearDecoder.LightClientBlock memory nearBlock = borsh.decodeLightClientBlock();
        borsh.done();

        require(nearBlock.next_bps.some, "Initialization block must contain next_bps");

        curHeight = nearBlock.inner_lite.height;
        epochs[0].epochId = nearBlock.inner_lite.epoch_id;
        epochs[1].epochId = nearBlock.inner_lite.next_epoch_id;
        blockHashes_[nearBlock.inner_lite.height] = nearBlock.hash;
        blockMerkleRoots_[nearBlock.inner_lite.height] = nearBlock.inner_lite.block_merkle_root;
        setBlockProducers(nearBlock.next_bps.blockProducers, epochs[1]);
    }

    struct BridgeState {
        uint currentHeight; // Height of the current confirmed block
        // If there is currently no unconfirmed block, the last three fields are zero.
        uint nextTimestamp; // Timestamp of the current unconfirmed block
        uint nextValidAt; // Timestamp when the current unconfirmed block will be confirmed
        uint numBlockProducers; // Number of block producers for the current unconfirmed block
    }

    function bridgeState() external view returns (BridgeState memory res) {
        if (block.timestamp < lastValidAt) {
            res.currentHeight = curHeight;
            res.nextTimestamp = untrustedTimestamp;
            res.nextValidAt = lastValidAt;
            unchecked {
                res.numBlockProducers = epochs[untrustedNextEpoch ? (curEpoch + 1) % 3 : curEpoch].numBPs;
            }
        } else {
            res.currentHeight = lastValidAt == 0 ? curHeight : untrustedHeight;
        }
    }

    function addLightClientBlock(bytes memory data) external override pausable(PAUSED_ADD_BLOCK) {
        require(initialized, "Contract is not initialized");
        require(balanceOf[msg.sender] >= lockEthAmount, "Balance is not enough");

        Borsh.Data memory borsh = Borsh.from(data);
        NearDecoder.LightClientBlock memory nearBlock = borsh.decodeLightClientBlock();
        borsh.done();

        unchecked {
            // Commit the previous block, or make sure that it is OK to replace it.
            if (block.timestamp < lastValidAt) {
                require(
                    nearBlock.inner_lite.timestamp >= untrustedTimestamp + replaceDuration,
                    "Can only replace with a sufficiently newer block"
                );
            } else if (lastValidAt != 0) {
                curHeight = untrustedHeight;
                if (untrustedNextEpoch) {
                    curEpoch = (curEpoch + 1) % 3;
                }
                lastValidAt = 0;

                blockHashes_[curHeight] = untrustedHash;
                blockMerkleRoots_[curHeight] = untrustedMerkleRoot;
            }

            // Check that the new block's height is greater than the current one's.
            require(nearBlock.inner_lite.height > curHeight, "New block must have higher height");

            // Check that the new block is from the same epoch as the current one, or from the next one.
            bool fromNextEpoch;
            if (nearBlock.inner_lite.epoch_id == epochs[curEpoch].epochId) {
                fromNextEpoch = false;
            } else if (nearBlock.inner_lite.epoch_id == epochs[(curEpoch + 1) % 3].epochId) {
                fromNextEpoch = true;
            } else {
                revert("Epoch id of the block is not valid");
            }

            // Check that the new block is signed by more than 2/3 of the validators.
            Epoch storage thisEpoch = epochs[fromNextEpoch ? (curEpoch + 1) % 3 : curEpoch];
            // Last block in the epoch might contain extra approvals that light client can ignore.
            require(nearBlock.approvals_after_next.length >= thisEpoch.numBPs, "Approval list is too short");
            // The sum of uint128 values cannot overflow.
            uint256 votedFor = 0;
            for ((uint i, uint cnt) = (0, thisEpoch.numBPs); i != cnt; ++i) {
                bytes32 stakes = thisEpoch.packedStakes[i >> 1];
                if (nearBlock.approvals_after_next[i].some) {
                    votedFor += uint128(bytes16(stakes));
                }
                if (++i == cnt) {
                    break;
                }
                if (nearBlock.approvals_after_next[i].some) {
                    votedFor += uint128(uint256(stakes));
                }
            }
            require(votedFor > thisEpoch.stakeThreshold, "Too few approvals");

            // If the block is from the next epoch, make sure that next_bps is supplied and has a correct hash.
            if (fromNextEpoch) {
                require(nearBlock.next_bps.some, "Next next_bps should not be None");
                require(
                    nearBlock.next_bps.hash == nearBlock.inner_lite.next_bp_hash,
                    "Hash of block producers does not match"
                );
            }

            untrustedHeight = nearBlock.inner_lite.height;
            untrustedTimestamp = nearBlock.inner_lite.timestamp;
            untrustedHash = nearBlock.hash;
            untrustedMerkleRoot = nearBlock.inner_lite.block_merkle_root;
            untrustedNextHash = nearBlock.next_hash;

            uint256 signatureSet = 0;
            for ((uint i, uint cnt) = (0, thisEpoch.numBPs); i < cnt; i++) {
                NearDecoder.OptionalSignature memory approval = nearBlock.approvals_after_next[i];
                if (approval.some) {
                    signatureSet |= 1 << i;
                    untrustedSignatures[i] = approval.signature;
                }
            }
            untrustedSignatureSet = signatureSet;
            untrustedNextEpoch = fromNextEpoch;
            if (fromNextEpoch) {
                Epoch storage nextEpoch = epochs[(curEpoch + 2) % 3];
                nextEpoch.epochId = nearBlock.inner_lite.next_epoch_id;
                setBlockProducers(nearBlock.next_bps.blockProducers, nextEpoch);
            }
            lastSubmitter = msg.sender;
            lastValidAt = block.timestamp + lockDuration;
        }
    }

    function setBlockProducers(NearDecoder.BlockProducer[] memory src, Epoch storage epoch) internal {
        uint cnt = src.length;
        require(cnt <= MAX_BLOCK_PRODUCERS);
        epoch.numBPs = cnt;
        unchecked {
            for (uint i = 0; i < cnt; i++) {
                epoch.keys[i] = src[i].publicKey.k;
            }
            uint256 totalStake = 0; // Sum of uint128, can't be too big.
            for (uint i = 0; i != cnt; ++i) {
                uint128 stake1 = src[i].stake;
                totalStake += stake1;
                if (++i == cnt) {
                    epoch.packedStakes[i >> 1] = bytes32(bytes16(stake1));
                    break;
                }
                uint128 stake2 = src[i].stake;
                totalStake += stake2;
                epoch.packedStakes[i >> 1] = bytes32(uint256(bytes32(bytes16(stake1))) + stake2);
            }
            epoch.stakeThreshold = (totalStake * 2) / 3;
        }
    }

    function blockHashes(uint64 height) external view override pausable(PAUSED_VERIFY) returns (bytes32 res) {
        res = blockHashes_[height];
        if (res == 0 && block.timestamp >= lastValidAt && lastValidAt != 0 && height == untrustedHeight) {
            res = untrustedHash;
        }
    }

    function blockMerkleRoots(uint64 height) external view override pausable(PAUSED_VERIFY) returns (bytes32 res) {
        res = blockMerkleRoots_[height];
        if (res == 0 && block.timestamp >= lastValidAt && lastValidAt != 0 && height == untrustedHeight) {
            res = untrustedMerkleRoot;
        }
    }

    function setEdwards(Ed25519 ed_) external onlyAdmin {
        edwards = ed_;
    }

    function setDuration(uint256 replaceDuration_, uint256 lockDuration_)
        external
        onlyAdmin
        checkDuration(replaceDuration_, lockDuration_)
    {
        replaceDuration = replaceDuration_;
        lockDuration = lockDuration_;
    }

    function setLockEthAmount(uint256 lockEthAmount_) external onlyAdmin {
        lockEthAmount = lockEthAmount_;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AdminControlled is Initializable {
    address public admin;
    uint public paused;

    function __AdminControlled_init(address _admin, uint flags) public initializer {
        admin = _admin;
        paused = flags;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized");
        _;
    }

    modifier pausable(uint flag) {
        require((paused & flag) == 0 || msg.sender == admin);
        _;
    }

    function adminPause(uint flags) external onlyAdmin {
        paused = flags;
    }

    function transferOwnership(address newAdmin) external virtual onlyAdmin {
        require(newAdmin != address(0), "Ownable: new owner is the zero address");
        address oldAdmin = admin;
        admin = newAdmin;
        emit OwnershipTransferred(oldAdmin, newAdmin);
    }

    function adminSstore(uint key, uint value) external onlyAdmin {
        assembly {
            sstore(key, value)
        }
    }

    function adminSstoreWithMask(
        uint key,
        uint value,
        uint mask
    ) external onlyAdmin {
        assembly {
            let oldval := sload(key)
            sstore(key, xor(and(xor(value, oldval), mask), oldval))
        }
    }

    function adminSendEth(address payable destination, uint amount) external onlyAdmin {
        destination.transfer(amount);
    }

    function adminReceiveEth() external payable onlyAdmin {}

    event OwnershipTransferred(address oldAdmin, address newAdmin);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.7;

interface INearBridge {
    event BlockHashAdded(uint64 indexed height, bytes32 blockHash);

    event BlockHashReverted(uint64 indexed height, bytes32 blockHash);

    function blockHashes(uint64 blockNumber) external view returns (bytes32);

    function blockMerkleRoots(uint64 blockNumber) external view returns (bytes32);

    function balanceOf(address wallet) external view returns (uint256);

    function deposit() external payable;

    function withdraw() external;

    function initWithValidators(bytes calldata initialValidators) external;

    function initWithBlock(bytes calldata data) external;

    function addLightClientBlock(bytes calldata data) external;

    function challenge(address payable receiver, uint256 signatureIndex) external;

    function checkBlockProducerSignatureInHead(uint256 signatureIndex) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.7;

import "./Borsh.sol";

library NearDecoder {
    using Borsh for Borsh.Data;
    using NearDecoder for Borsh.Data;

    struct PublicKey {
        bytes32 k;
    }

    function decodePublicKey(Borsh.Data memory data) internal pure returns (PublicKey memory res) {
        require(data.decodeU8() == 0, "Parse error: invalid key type");
        res.k = data.decodeBytes32();
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
    }

    function decodeSignature(Borsh.Data memory data) internal pure returns (Signature memory res) {
        require(data.decodeU8() == 0, "Parse error: invalid signature type");
        res.r = data.decodeBytes32();
        res.s = data.decodeBytes32();
    }

    struct BlockProducer {
        PublicKey publicKey;
        uint128 stake;
    }

    function decodeBlockProducer(Borsh.Data memory data) internal pure returns (BlockProducer memory res) {
        data.skipBytes();
        res.publicKey = data.decodePublicKey();
        res.stake = data.decodeU128();
    }

    function decodeBlockProducers(Borsh.Data memory data) internal pure returns (BlockProducer[] memory res) {
        uint length = data.decodeU32();
        res = new BlockProducer[](length);
        for (uint i = 0; i < length; i++) {
            res[i] = data.decodeBlockProducer();
        }
    }

    struct OptionalBlockProducers {
        bool some;
        BlockProducer[] blockProducers;
        bytes32 hash; // Additional computable element
    }

    function decodeOptionalBlockProducers(Borsh.Data memory data)
        internal
        view
        returns (OptionalBlockProducers memory res)
    {
        res.some = data.decodeBool();
        if (res.some) {
            uint start = data.ptr;
            res.blockProducers = data.decodeBlockProducers();
            res.hash = Utils.sha256Raw(start, data.ptr - start);
        }
    }

    struct OptionalSignature {
        bool some;
        Signature signature;
    }

    function decodeOptionalSignature(Borsh.Data memory data) internal pure returns (OptionalSignature memory res) {
        res.some = data.decodeBool();
        if (res.some) {
            res.signature = data.decodeSignature();
        }
    }

    struct BlockHeaderInnerLite {
        uint64 height; // Height of this block since the genesis block (height 0).
        bytes32 epoch_id; // Epoch start hash of this block's epoch. Used for retrieving validator information
        bytes32 next_epoch_id;
        bytes32 prev_state_root; // Root hash of the state at the previous block.
        bytes32 outcome_root; // Root of the outcomes of transactions and receipts.
        uint64 timestamp; // Timestamp at which the block was built.
        bytes32 next_bp_hash; // Hash of the next epoch block producers set
        bytes32 block_merkle_root;
        bytes32 hash; // Additional computable element
    }

    function decodeBlockHeaderInnerLite(Borsh.Data memory data)
        internal
        view
        returns (BlockHeaderInnerLite memory res)
    {
        res.hash = data.peekSha256(208);
        res.height = data.decodeU64();
        res.epoch_id = data.decodeBytes32();
        res.next_epoch_id = data.decodeBytes32();
        res.prev_state_root = data.decodeBytes32();
        res.outcome_root = data.decodeBytes32();
        res.timestamp = data.decodeU64();
        res.next_bp_hash = data.decodeBytes32();
        res.block_merkle_root = data.decodeBytes32();
    }

    struct LightClientBlock {
        bytes32 prev_block_hash;
        bytes32 next_block_inner_hash;
        BlockHeaderInnerLite inner_lite;
        bytes32 inner_rest_hash;
        OptionalBlockProducers next_bps;
        OptionalSignature[] approvals_after_next;
        bytes32 hash;
        bytes32 next_hash;
    }

    function decodeLightClientBlock(Borsh.Data memory data) internal view returns (LightClientBlock memory res) {
        res.prev_block_hash = data.decodeBytes32();
        res.next_block_inner_hash = data.decodeBytes32();
        res.inner_lite = data.decodeBlockHeaderInnerLite();
        res.inner_rest_hash = data.decodeBytes32();
        res.next_bps = data.decodeOptionalBlockProducers();

        uint length = data.decodeU32();
        res.approvals_after_next = new OptionalSignature[](length);
        for (uint i = 0; i < length; i++) {
            res.approvals_after_next[i] = data.decodeOptionalSignature();
        }

        res.hash = sha256(
            abi.encodePacked(sha256(abi.encodePacked(res.inner_lite.hash, res.inner_rest_hash)), res.prev_block_hash)
        );

        res.next_hash = sha256(abi.encodePacked(res.next_block_inner_hash, res.hash));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.7;

contract Ed25519 {
    // Computes (v^(2^250-1), v^11) mod p
    function pow22501(uint256 v) private pure returns (uint256 p22501, uint256 p11) {
        p11 = mulmod(v, v, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        p22501 = mulmod(p11, p11, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        p22501 = mulmod(
            mulmod(p22501, p22501, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed),
            v,
            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
        );
        p11 = mulmod(p22501, p11, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        p22501 = mulmod(
            mulmod(p11, p11, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed),
            p22501,
            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
        );
        uint256 a = mulmod(p22501, p22501, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        p22501 = mulmod(p22501, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(p22501, p22501, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(p22501, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        uint256 b = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        p22501 = mulmod(p22501, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(p22501, p22501, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(p22501, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        b = mulmod(b, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, b, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        a = mulmod(a, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
        p22501 = mulmod(p22501, a, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
    }

    function check(
        bytes32 k,
        bytes32 r,
        bytes32 s,
        bytes32 m1,
        bytes9 m2
    ) public pure returns (bool) {
        unchecked {
            uint256 hh;
            // Step 1: compute SHA-512(R, A, M)
            {
                uint256[5][16] memory kk = [
                    [
                        uint256(0x428a2f98_d728ae22),
                        uint256(0xe49b69c1_9ef14ad2),
                        uint256(0x27b70a85_46d22ffc),
                        uint256(0x19a4c116_b8d2d0c8),
                        uint256(0xca273ece_ea26619c)
                    ],
                    [
                        uint256(0x71374491_23ef65cd),
                        uint256(0xefbe4786_384f25e3),
                        uint256(0x2e1b2138_5c26c926),
                        uint256(0x1e376c08_5141ab53),
                        uint256(0xd186b8c7_21c0c207)
                    ],
                    [
                        uint256(0xb5c0fbcf_ec4d3b2f),
                        uint256(0xfc19dc6_8b8cd5b5),
                        uint256(0x4d2c6dfc_5ac42aed),
                        uint256(0x2748774c_df8eeb99),
                        uint256(0xeada7dd6_cde0eb1e)
                    ],
                    [
                        uint256(0xe9b5dba5_8189dbbc),
                        uint256(0x240ca1cc_77ac9c65),
                        uint256(0x53380d13_9d95b3df),
                        uint256(0x34b0bcb5_e19b48a8),
                        uint256(0xf57d4f7f_ee6ed178)
                    ],
                    [
                        uint256(0x3956c25b_f348b538),
                        uint256(0x2de92c6f_592b0275),
                        uint256(0x650a7354_8baf63de),
                        uint256(0x391c0cb3_c5c95a63),
                        uint256(0x6f067aa_72176fba)
                    ],
                    [
                        uint256(0x59f111f1_b605d019),
                        uint256(0x4a7484aa_6ea6e483),
                        uint256(0x766a0abb_3c77b2a8),
                        uint256(0x4ed8aa4a_e3418acb),
                        uint256(0xa637dc5_a2c898a6)
                    ],
                    [
                        uint256(0x923f82a4_af194f9b),
                        uint256(0x5cb0a9dc_bd41fbd4),
                        uint256(0x81c2c92e_47edaee6),
                        uint256(0x5b9cca4f_7763e373),
                        uint256(0x113f9804_bef90dae)
                    ],
                    [
                        uint256(0xab1c5ed5_da6d8118),
                        uint256(0x76f988da_831153b5),
                        uint256(0x92722c85_1482353b),
                        uint256(0x682e6ff3_d6b2b8a3),
                        uint256(0x1b710b35_131c471b)
                    ],
                    [
                        uint256(0xd807aa98_a3030242),
                        uint256(0x983e5152_ee66dfab),
                        uint256(0xa2bfe8a1_4cf10364),
                        uint256(0x748f82ee_5defb2fc),
                        uint256(0x28db77f5_23047d84)
                    ],
                    [
                        uint256(0x12835b01_45706fbe),
                        uint256(0xa831c66d_2db43210),
                        uint256(0xa81a664b_bc423001),
                        uint256(0x78a5636f_43172f60),
                        uint256(0x32caab7b_40c72493)
                    ],
                    [
                        uint256(0x243185be_4ee4b28c),
                        uint256(0xb00327c8_98fb213f),
                        uint256(0xc24b8b70_d0f89791),
                        uint256(0x84c87814_a1f0ab72),
                        uint256(0x3c9ebe0a_15c9bebc)
                    ],
                    [
                        uint256(0x550c7dc3_d5ffb4e2),
                        uint256(0xbf597fc7_beef0ee4),
                        uint256(0xc76c51a3_0654be30),
                        uint256(0x8cc70208_1a6439ec),
                        uint256(0x431d67c4_9c100d4c)
                    ],
                    [
                        uint256(0x72be5d74_f27b896f),
                        uint256(0xc6e00bf3_3da88fc2),
                        uint256(0xd192e819_d6ef5218),
                        uint256(0x90befffa_23631e28),
                        uint256(0x4cc5d4be_cb3e42b6)
                    ],
                    [
                        uint256(0x80deb1fe_3b1696b1),
                        uint256(0xd5a79147_930aa725),
                        uint256(0xd6990624_5565a910),
                        uint256(0xa4506ceb_de82bde9),
                        uint256(0x597f299c_fc657e2a)
                    ],
                    [
                        uint256(0x9bdc06a7_25c71235),
                        uint256(0x6ca6351_e003826f),
                        uint256(0xf40e3585_5771202a),
                        uint256(0xbef9a3f7_b2c67915),
                        uint256(0x5fcb6fab_3ad6faec)
                    ],
                    [
                        uint256(0xc19bf174_cf692694),
                        uint256(0x14292967_0a0e6e70),
                        uint256(0x106aa070_32bbd1b8),
                        uint256(0xc67178f2_e372532b),
                        uint256(0x6c44198c_4a475817)
                    ]
                ];
                uint256 w0 = (uint256(r) & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000_ffffffff_ffffffff) |
                    ((uint256(r) & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 64) |
                    ((uint256(r) & 0xffffffff_ffffffff_00000000_00000000) << 64);
                uint256 w1 = (uint256(k) & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000_ffffffff_ffffffff) |
                    ((uint256(k) & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 64) |
                    ((uint256(k) & 0xffffffff_ffffffff_00000000_00000000) << 64);
                uint256 w2 = (uint256(m1) & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000_ffffffff_ffffffff) |
                    ((uint256(m1) & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 64) |
                    ((uint256(m1) & 0xffffffff_ffffffff_00000000_00000000) << 64);
                uint256 w3 = (uint256(bytes32(m2)) &
                    0xffffffff_ffffffff_00000000_00000000_00000000_00000000_00000000_00000000) |
                    ((uint256(bytes32(m2)) & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 64) |
                    0x800000_00000000_00000000_00000348;
                uint256 a = 0x6a09e667_f3bcc908;
                uint256 b = 0xbb67ae85_84caa73b;
                uint256 c = 0x3c6ef372_fe94f82b;
                uint256 d = 0xa54ff53a_5f1d36f1;
                uint256 e = 0x510e527f_ade682d1;
                uint256 f = 0x9b05688c_2b3e6c1f;
                uint256 g = 0x1f83d9ab_fb41bd6b;
                uint256 h = 0x5be0cd19_137e2179;
                for (uint256 i = 0; ; i++) {
                    // Round 16 * i
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[0][i];
                        temp1 += w0 >> 192;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 1
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[1][i];
                        temp1 += w0 >> 64;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 2
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[2][i];
                        temp1 += w0 >> 128;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 3
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[3][i];
                        temp1 += w0;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 4
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[4][i];
                        temp1 += w1 >> 192;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 5
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[5][i];
                        temp1 += w1 >> 64;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 6
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[6][i];
                        temp1 += w1 >> 128;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 7
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[7][i];
                        temp1 += w1;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 8
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[8][i];
                        temp1 += w2 >> 192;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 9
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[9][i];
                        temp1 += w2 >> 64;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 10
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[10][i];
                        temp1 += w2 >> 128;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 11
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[11][i];
                        temp1 += w2;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 12
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[12][i];
                        temp1 += w3 >> 192;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 13
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[13][i];
                        temp1 += w3 >> 64;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 14
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[14][i];
                        temp1 += w3 >> 128;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    // Round 16 * i + 15
                    {
                        uint256 temp1;
                        uint256 temp2;
                        e &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = e | (e << 64);
                            uint256 s1 = (ss >> 14) ^ (ss >> 18) ^ (ss >> 41);
                            uint256 ch = (e & (f ^ g)) ^ g;
                            temp1 = h + s1 + ch;
                        }
                        temp1 += kk[15][i];
                        temp1 += w3;
                        a &= 0xffffffff_ffffffff;
                        {
                            uint256 ss = a | (a << 64);
                            uint256 s0 = (ss >> 28) ^ (ss >> 34) ^ (ss >> 39);
                            uint256 maj = (a & (b | c)) | (b & c);
                            temp2 = s0 + maj;
                        }
                        h = g;
                        g = f;
                        f = e;
                        e = d + temp1;
                        d = c;
                        c = b;
                        b = a;
                        a = temp1 + temp2;
                    }
                    if (i == 4) {
                        break;
                    }
                    // Message expansion
                    uint256 t0 = w0;
                    uint256 t1 = w1;
                    {
                        uint256 t2 = w2;
                        uint256 t3 = w3;
                        {
                            uint256 n1 = t0 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            n1 +=
                                ((t2 & 0xffffffff_ffffffff_00000000_00000000) << 128) |
                                ((t2 & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 64);
                            {
                                uint256 u1 = ((t0 & 0xffffffff_ffffffff_00000000_00000000) << 64) |
                                    ((t0 & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 128);
                                uint256 uu1 = u1 | (u1 << 64);
                                n1 +=
                                    ((uu1 << 63) ^ (uu1 << 56) ^ (u1 << 57)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            }
                            {
                                uint256 v1 = t3 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                                uint256 vv1 = v1 | (v1 << 64);
                                n1 +=
                                    ((vv1 << 45) ^ (vv1 << 3) ^ (v1 << 58)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            }
                            n1 &= 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            uint256 n2 = t0 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            n2 += ((t2 & 0xffffffff_ffffffff) << 128) | (t3 >> 192);
                            {
                                uint256 u2 = ((t0 & 0xffffffff_ffffffff) << 128) | (t1 >> 192);
                                uint256 uu2 = u2 | (u2 << 64);
                                n2 +=
                                    ((uu2 >> 1) ^ (uu2 >> 8) ^ (u2 >> 7)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            }
                            {
                                uint256 vv2 = n1 | (n1 >> 64);
                                n2 +=
                                    ((vv2 >> 19) ^ (vv2 >> 61) ^ (n1 >> 70)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            }
                            n2 &= 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            t0 = n1 | n2;
                        }
                        {
                            uint256 n1 = t1 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            n1 +=
                                ((t3 & 0xffffffff_ffffffff_00000000_00000000) << 128) |
                                ((t3 & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 64);
                            {
                                uint256 u1 = ((t1 & 0xffffffff_ffffffff_00000000_00000000) << 64) |
                                    ((t1 & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 128);
                                uint256 uu1 = u1 | (u1 << 64);
                                n1 +=
                                    ((uu1 << 63) ^ (uu1 << 56) ^ (u1 << 57)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            }
                            {
                                uint256 v1 = t0 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                                uint256 vv1 = v1 | (v1 << 64);
                                n1 +=
                                    ((vv1 << 45) ^ (vv1 << 3) ^ (v1 << 58)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            }
                            n1 &= 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            uint256 n2 = t1 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            n2 += ((t3 & 0xffffffff_ffffffff) << 128) | (t0 >> 192);
                            {
                                uint256 u2 = ((t1 & 0xffffffff_ffffffff) << 128) | (t2 >> 192);
                                uint256 uu2 = u2 | (u2 << 64);
                                n2 +=
                                    ((uu2 >> 1) ^ (uu2 >> 8) ^ (u2 >> 7)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            }
                            {
                                uint256 vv2 = n1 | (n1 >> 64);
                                n2 +=
                                    ((vv2 >> 19) ^ (vv2 >> 61) ^ (n1 >> 70)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            }
                            n2 &= 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            t1 = n1 | n2;
                        }
                        {
                            uint256 n1 = t2 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            n1 +=
                                ((t0 & 0xffffffff_ffffffff_00000000_00000000) << 128) |
                                ((t0 & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 64);
                            {
                                uint256 u1 = ((t2 & 0xffffffff_ffffffff_00000000_00000000) << 64) |
                                    ((t2 & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 128);
                                uint256 uu1 = u1 | (u1 << 64);
                                n1 +=
                                    ((uu1 << 63) ^ (uu1 << 56) ^ (u1 << 57)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            }
                            {
                                uint256 v1 = t1 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                                uint256 vv1 = v1 | (v1 << 64);
                                n1 +=
                                    ((vv1 << 45) ^ (vv1 << 3) ^ (v1 << 58)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            }
                            n1 &= 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            uint256 n2 = t2 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            n2 += ((t0 & 0xffffffff_ffffffff) << 128) | (t1 >> 192);
                            {
                                uint256 u2 = ((t2 & 0xffffffff_ffffffff) << 128) | (t3 >> 192);
                                uint256 uu2 = u2 | (u2 << 64);
                                n2 +=
                                    ((uu2 >> 1) ^ (uu2 >> 8) ^ (u2 >> 7)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            }
                            {
                                uint256 vv2 = n1 | (n1 >> 64);
                                n2 +=
                                    ((vv2 >> 19) ^ (vv2 >> 61) ^ (n1 >> 70)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            }
                            n2 &= 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            t2 = n1 | n2;
                        }
                        {
                            uint256 n1 = t3 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            n1 +=
                                ((t1 & 0xffffffff_ffffffff_00000000_00000000) << 128) |
                                ((t1 & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 64);
                            {
                                uint256 u1 = ((t3 & 0xffffffff_ffffffff_00000000_00000000) << 64) |
                                    ((t3 & 0xffffffff_ffffffff_00000000_00000000_00000000_00000000) >> 128);
                                uint256 uu1 = u1 | (u1 << 64);
                                n1 +=
                                    ((uu1 << 63) ^ (uu1 << 56) ^ (u1 << 57)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            }
                            {
                                uint256 v1 = t2 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                                uint256 vv1 = v1 | (v1 << 64);
                                n1 +=
                                    ((vv1 << 45) ^ (vv1 << 3) ^ (v1 << 58)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            }
                            n1 &= 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000;
                            uint256 n2 = t3 & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            n2 += ((t1 & 0xffffffff_ffffffff) << 128) | (t2 >> 192);
                            {
                                uint256 u2 = ((t3 & 0xffffffff_ffffffff) << 128) | (t0 >> 192);
                                uint256 uu2 = u2 | (u2 << 64);
                                n2 +=
                                    ((uu2 >> 1) ^ (uu2 >> 8) ^ (u2 >> 7)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            }
                            {
                                uint256 vv2 = n1 | (n1 >> 64);
                                n2 +=
                                    ((vv2 >> 19) ^ (vv2 >> 61) ^ (n1 >> 70)) &
                                    0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            }
                            n2 &= 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff;
                            t3 = n1 | n2;
                        }
                        w3 = t3;
                        w2 = t2;
                    }
                    w1 = t1;
                    w0 = t0;
                }
                uint256 h0 = ((a + 0x6a09e667_f3bcc908) & 0xffffffff_ffffffff) |
                    (((b + 0xbb67ae85_84caa73b) & 0xffffffff_ffffffff) << 64) |
                    (((c + 0x3c6ef372_fe94f82b) & 0xffffffff_ffffffff) << 128) |
                    ((d + 0xa54ff53a_5f1d36f1) << 192);
                h0 =
                    ((h0 & 0xff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff) << 8) |
                    ((h0 & 0xff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00) >> 8);
                h0 =
                    ((h0 & 0xffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff) << 16) |
                    ((h0 & 0xffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000) >> 16);
                h0 =
                    ((h0 & 0xffffffff_00000000_ffffffff_00000000_ffffffff_00000000_ffffffff) << 32) |
                    ((h0 & 0xffffffff_00000000_ffffffff_00000000_ffffffff_00000000_ffffffff_00000000) >> 32);
                uint256 h1 = ((e + 0x510e527f_ade682d1) & 0xffffffff_ffffffff) |
                    (((f + 0x9b05688c_2b3e6c1f) & 0xffffffff_ffffffff) << 64) |
                    (((g + 0x1f83d9ab_fb41bd6b) & 0xffffffff_ffffffff) << 128) |
                    ((h + 0x5be0cd19_137e2179) << 192);
                h1 =
                    ((h1 & 0xff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff) << 8) |
                    ((h1 & 0xff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00) >> 8);
                h1 =
                    ((h1 & 0xffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff) << 16) |
                    ((h1 & 0xffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000) >> 16);
                h1 =
                    ((h1 & 0xffffffff_00000000_ffffffff_00000000_ffffffff_00000000_ffffffff) << 32) |
                    ((h1 & 0xffffffff_00000000_ffffffff_00000000_ffffffff_00000000_ffffffff_00000000) >> 32);
                hh = addmod(
                    h0,
                    mulmod(
                        h1,
                        0xfffffff_ffffffff_ffffffff_fffffffe_c6ef5bf4_737dcf70_d6ec3174_8d98951d,
                        0x10000000_00000000_00000000_00000000_14def9de_a2f79cd6_5812631a_5cf5d3ed
                    ),
                    0x10000000_00000000_00000000_00000000_14def9de_a2f79cd6_5812631a_5cf5d3ed
                );
            }
            // Step 2: unpack k
            k = bytes32(
                ((uint256(k) & 0xff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff) << 8) |
                    ((uint256(k) & 0xff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00) >> 8)
            );
            k = bytes32(
                ((uint256(k) & 0xffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff) << 16) |
                    ((uint256(k) & 0xffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000) >> 16)
            );
            k = bytes32(
                ((uint256(k) & 0xffffffff_00000000_ffffffff_00000000_ffffffff_00000000_ffffffff) << 32) |
                    ((uint256(k) & 0xffffffff_00000000_ffffffff_00000000_ffffffff_00000000_ffffffff_00000000) >> 32)
            );
            k = bytes32(
                ((uint256(k) & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff) << 64) |
                    ((uint256(k) & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000) >> 64)
            );
            k = bytes32((uint256(k) << 128) | (uint256(k) >> 128));
            uint256 ky = uint256(k) & 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff;
            uint256 kx;
            {
                uint256 ky2 = mulmod(ky, ky, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
                uint256 u = addmod(
                    ky2,
                    0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffec,
                    0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                );
                uint256 v = mulmod(
                    ky2,
                    0x52036cee_2b6ffe73_8cc74079_7779e898_00700a4d_4141d8ab_75eb4dca_135978a3,
                    0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                ) + 1;
                uint256 t = mulmod(u, v, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
                (kx, ) = pow22501(t);
                kx = mulmod(kx, kx, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
                kx = mulmod(
                    u,
                    mulmod(
                        mulmod(kx, kx, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed),
                        t,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    ),
                    0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                );
                t = mulmod(
                    mulmod(kx, kx, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed),
                    v,
                    0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                );
                if (t != u) {
                    if (t != 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed - u) {
                        return false;
                    }
                    kx = mulmod(
                        kx,
                        0x2b832480_4fc1df0b_2b4d0099_3dfbd7a7_2f431806_ad2fe478_c4ee1b27_4a0ea0b0,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                }
            }
            if ((kx & 1) != uint256(k) >> 255) {
                kx = 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed - kx;
            }
            // Verify s
            s = bytes32(
                ((uint256(s) & 0xff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff) << 8) |
                    ((uint256(s) & 0xff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00) >> 8)
            );
            s = bytes32(
                ((uint256(s) & 0xffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff) << 16) |
                    ((uint256(s) & 0xffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000) >> 16)
            );
            s = bytes32(
                ((uint256(s) & 0xffffffff_00000000_ffffffff_00000000_ffffffff_00000000_ffffffff) << 32) |
                    ((uint256(s) & 0xffffffff_00000000_ffffffff_00000000_ffffffff_00000000_ffffffff_00000000) >> 32)
            );
            s = bytes32(
                ((uint256(s) & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff) << 64) |
                    ((uint256(s) & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000) >> 64)
            );
            s = bytes32((uint256(s) << 128) | (uint256(s) >> 128));
            if (uint256(s) >= 0x10000000_00000000_00000000_00000000_14def9de_a2f79cd6_5812631a_5cf5d3ed) {
                return false;
            }
            uint256 vx;
            uint256 vu;
            uint256 vy;
            uint256 vv;
            // Step 3: compute multiples of k
            uint256[8][3][2] memory tables;
            {
                uint256 ks = ky + kx;
                uint256 kd = ky + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed - kx;
                uint256 k2dt = mulmod(
                    mulmod(kx, ky, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed),
                    0x2406d9dc_56dffce7_198e80f2_eef3d130_00e0149a_8283b156_ebd69b94_26b2f159,
                    0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                );
                uint256 kky = ky;
                uint256 kkx = kx;
                uint256 kku = 1;
                uint256 kkv = 1;
                {
                    uint256 xx = mulmod(
                        kkx,
                        kkv,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 yy = mulmod(
                        kky,
                        kku,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 zz = mulmod(
                        kku,
                        kkv,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 xx2 = mulmod(
                        xx,
                        xx,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 yy2 = mulmod(
                        yy,
                        yy,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 xxyy = mulmod(
                        xx,
                        yy,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 zz2 = mulmod(
                        zz,
                        zz,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    kkx = xxyy + xxyy;
                    kku = yy2 - xx2 + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                    kky = xx2 + yy2;
                    kkv = addmod(
                        zz2 + zz2,
                        0xffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffda - kku,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                }
                {
                    uint256 xx = mulmod(
                        kkx,
                        kkv,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 yy = mulmod(
                        kky,
                        kku,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 zz = mulmod(
                        kku,
                        kkv,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 xx2 = mulmod(
                        xx,
                        xx,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 yy2 = mulmod(
                        yy,
                        yy,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 xxyy = mulmod(
                        xx,
                        yy,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 zz2 = mulmod(
                        zz,
                        zz,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    kkx = xxyy + xxyy;
                    kku = yy2 - xx2 + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                    kky = xx2 + yy2;
                    kkv = addmod(
                        zz2 + zz2,
                        0xffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffda - kku,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                }
                {
                    uint256 xx = mulmod(
                        kkx,
                        kkv,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 yy = mulmod(
                        kky,
                        kku,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 zz = mulmod(
                        kku,
                        kkv,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 xx2 = mulmod(
                        xx,
                        xx,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 yy2 = mulmod(
                        yy,
                        yy,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 xxyy = mulmod(
                        xx,
                        yy,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 zz2 = mulmod(
                        zz,
                        zz,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    kkx = xxyy + xxyy;
                    kku = yy2 - xx2 + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                    kky = xx2 + yy2;
                    kkv = addmod(
                        zz2 + zz2,
                        0xffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffda - kku,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                }
                uint256 cprod = 1;
                uint256[8][3][2] memory tables_ = tables;
                for (uint256 i = 0; ; i++) {
                    uint256 cs;
                    uint256 cd;
                    uint256 ct;
                    uint256 c2z;
                    {
                        uint256 cx = mulmod(
                            kkx,
                            kkv,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 cy = mulmod(
                            kky,
                            kku,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 cz = mulmod(
                            kku,
                            kkv,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        ct = mulmod(
                            kkx,
                            kky,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        cs = cy + cx;
                        cd = cy - cx + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                        c2z = cz + cz;
                    }
                    tables_[1][0][i] = cs;
                    tables_[1][1][i] = cd;
                    tables_[1][2][i] = mulmod(
                        ct,
                        0x2406d9dc_56dffce7_198e80f2_eef3d130_00e0149a_8283b156_ebd69b94_26b2f159,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    tables_[0][0][i] = c2z;
                    tables_[0][1][i] = cprod;
                    cprod = mulmod(
                        cprod,
                        c2z,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    if (i == 7) {
                        break;
                    }
                    uint256 ab = mulmod(
                        cs,
                        ks,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 aa = mulmod(
                        cd,
                        kd,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    uint256 ac = mulmod(
                        ct,
                        k2dt,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    kkx = ab - aa + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                    kku = addmod(c2z, ac, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
                    kky = ab + aa;
                    kkv = addmod(
                        c2z,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed - ac,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                }
                uint256 t;
                (cprod, t) = pow22501(cprod);
                cprod = mulmod(cprod, cprod, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
                cprod = mulmod(cprod, cprod, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
                cprod = mulmod(cprod, cprod, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
                cprod = mulmod(cprod, cprod, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
                cprod = mulmod(cprod, cprod, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
                cprod = mulmod(cprod, t, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
                for (uint256 i = 7; ; i--) {
                    uint256 cinv = mulmod(
                        cprod,
                        tables_[0][1][i],
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    tables_[1][0][i] = mulmod(
                        tables_[1][0][i],
                        cinv,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    tables_[1][1][i] = mulmod(
                        tables_[1][1][i],
                        cinv,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    tables_[1][2][i] = mulmod(
                        tables_[1][2][i],
                        cinv,
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                    if (i == 0) {
                        break;
                    }
                    cprod = mulmod(
                        cprod,
                        tables_[0][0][i],
                        0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                    );
                }
                tables_[0] = [
                    [
                        0x43e7ce9d_19ea5d32_9385a44c_321ea161_67c996e3_7dc6070c_97de49e3_7ac61db9,
                        0x40cff344_25d8ec30_a3bb74ba_58cd5854_fa1e3818_6ad0d31e_bc8ae251_ceb2c97e,
                        0x459bd270_46e8dd45_aea7008d_b87a5a8f_79067792_53d64523_58951859_9fdfbf4b,
                        0x69fdd1e2_8c23cc38_94d0c8ff_90e76f6d_5b6e4c2e_620136d0_4dd83c4a_51581ab9,
                        0x54dceb34_13ce5cfa_11196dfc_960b6eda_f4b380c6_d4d23784_19cc0279_ba49c5f3,
                        0x4e24184d_d71a3d77_eef3729f_7f8cf7c1_7224cf40_aa7b9548_b9942f3c_5084ceed,
                        0x5a0e5aab_20262674_ae117576_1cbf5e88_9b52a55f_d7ac5027_c228cebd_c8d2360a,
                        0x26239334_073e9b38_c6285955_6d451c3d_cc8d30e8_4b361174_f488eadd_e2cf17d9
                    ],
                    [
                        0x227e97c9_4c7c0933_d2e0c21a_3447c504_fe9ccf82_e8a05f59_ce881c82_eba0489f,
                        0x226a3e0e_cc4afec6_fd0d2884_13014a9d_bddecf06_c1a2f0bb_702ba77c_613d8209,
                        0x34d7efc8_51d45c5e_71efeb0f_235b7946_91de6228_877569b3_a8d52bf0_58b8a4a0,
                        0x3c1f5fb3_ca7166fc_e1471c9b_752b6d28_c56301ad_7b65e845_1b2c8c55_26726e12,
                        0x6102416c_f02f02ff_5be75275_f55f28db_89b2a9d2_456b860c_e22fc0e5_031f7cc5,
                        0x40adf677_f1bfdae0_57f0fd17_9c126179_18ddaa28_91a6530f_b1a4294f_a8665490,
                        0x61936f3c_41560904_6187b8ba_a978cbc9_b4789336_3ae5a3cc_7d909f36_35ae7f48,
                        0x562a9662_b6ec47f9_e979d473_c02b51e4_42336823_8c58ddb5_2f0e5c6a_180e6410
                    ],
                    [
                        0x3788bdb4_4f8632d4_2d0dbee5_eea1acc6_136cf411_e655624f_55e48902_c3bd5534,
                        0x6190cf2c_2a7b5ad7_69d594a8_2844f23b_4167fa7c_8ac30e51_aa6cfbeb_dcd4b945,
                        0x65f77870_96be9204_123a71f3_ac88a87b_e1513217_737d6a1e_2f3a13a4_3d7e3a9a,
                        0x23af32d_bfa67975_536479a7_a7ce74a0_2142147f_ac048018_7f1f1334_9cda1f2d,
                        0x64fc44b7_fc6841bd_db0ced8b_8b0fe675_9137ef87_ee966512_15fc1dbc_d25c64dc,
                        0x1434aa37_48b701d5_b69df3d7_d340c1fe_3f6b9c1e_fc617484_caadb47e_382f4475,
                        0x457a6da8_c962ef35_f2b21742_3e5844e9_d2353452_7e8ea429_0d24e3dd_f21720c6,
                        0x63b9540c_eb60ccb5_1e4d989d_956e053c_f2511837_efb79089_d2ff4028_4202c53d
                    ]
                ];
            }
            // Step 4: compute s*G - h*A
            {
                uint256 ss = uint256(s) << 3;
                uint256 hhh = hh + 0x80000000_00000000_00000000_00000000_a6f7cef5_17bce6b2_c09318d2_e7ae9f60;
                uint256 vvx = 0;
                uint256 vvu = 1;
                uint256 vvy = 1;
                uint256 vvv = 1;
                for (uint256 i = 252; ; i--) {
                    uint256 bit = 8 << i;
                    if ((ss & bit) != 0) {
                        uint256 ws;
                        uint256 wd;
                        uint256 wz;
                        uint256 wt;
                        {
                            uint256 wx = mulmod(
                                vvx,
                                vvv,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                            uint256 wy = mulmod(
                                vvy,
                                vvu,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                            ws = wy + wx;
                            wd = wy - wx + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                            wz = mulmod(
                                vvu,
                                vvv,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                            wt = mulmod(
                                vvx,
                                vvy,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                        }
                        uint256 j = (ss >> i) & 7;
                        ss &= ~(7 << i);
                        uint256[8][3][2] memory tables_ = tables;
                        uint256 aa = mulmod(
                            wd,
                            tables_[0][1][j],
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 ab = mulmod(
                            ws,
                            tables_[0][0][j],
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 ac = mulmod(
                            wt,
                            tables_[0][2][j],
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        vvx = ab - aa + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                        vvu = wz + ac;
                        vvy = ab + aa;
                        vvv = wz - ac + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                    }
                    if ((hhh & bit) != 0) {
                        uint256 ws;
                        uint256 wd;
                        uint256 wz;
                        uint256 wt;
                        {
                            uint256 wx = mulmod(
                                vvx,
                                vvv,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                            uint256 wy = mulmod(
                                vvy,
                                vvu,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                            ws = wy + wx;
                            wd = wy - wx + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                            wz = mulmod(
                                vvu,
                                vvv,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                            wt = mulmod(
                                vvx,
                                vvy,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                        }
                        uint256 j = (hhh >> i) & 7;
                        hhh &= ~(7 << i);
                        uint256[8][3][2] memory tables_ = tables;
                        uint256 aa = mulmod(
                            wd,
                            tables_[1][0][j],
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 ab = mulmod(
                            ws,
                            tables_[1][1][j],
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 ac = mulmod(
                            wt,
                            tables_[1][2][j],
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        vvx = ab - aa + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                        vvu = wz - ac + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                        vvy = ab + aa;
                        vvv = wz + ac;
                    }
                    if (i == 0) {
                        uint256 ws;
                        uint256 wd;
                        uint256 wz;
                        uint256 wt;
                        {
                            uint256 wx = mulmod(
                                vvx,
                                vvv,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                            uint256 wy = mulmod(
                                vvy,
                                vvu,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                            ws = wy + wx;
                            wd = wy - wx + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                            wz = mulmod(
                                vvu,
                                vvv,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                            wt = mulmod(
                                vvx,
                                vvy,
                                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                            );
                        }
                        uint256 j = hhh & 7;
                        uint256[8][3][2] memory tables_ = tables;
                        uint256 aa = mulmod(
                            wd,
                            tables_[1][0][j],
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 ab = mulmod(
                            ws,
                            tables_[1][1][j],
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 ac = mulmod(
                            wt,
                            tables_[1][2][j],
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        vvx = ab - aa + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                        vvu = wz - ac + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                        vvy = ab + aa;
                        vvv = wz + ac;
                        break;
                    }
                    {
                        uint256 xx = mulmod(
                            vvx,
                            vvv,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 yy = mulmod(
                            vvy,
                            vvu,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 zz = mulmod(
                            vvu,
                            vvv,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 xx2 = mulmod(
                            xx,
                            xx,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 yy2 = mulmod(
                            yy,
                            yy,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 xxyy = mulmod(
                            xx,
                            yy,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        uint256 zz2 = mulmod(
                            zz,
                            zz,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                        vvx = xxyy + xxyy;
                        vvu = yy2 - xx2 + 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed;
                        vvy = xx2 + yy2;
                        vvv = addmod(
                            zz2 + zz2,
                            0xffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffda - vvu,
                            0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
                        );
                    }
                }
                vx = vvx;
                vu = vvu;
                vy = vvy;
                vv = vvv;
            }
            // Step 5: compare the points
            (uint256 vi, uint256 vj) = pow22501(
                mulmod(vu, vv, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed)
            );
            vi = mulmod(vi, vi, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
            vi = mulmod(vi, vi, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
            vi = mulmod(vi, vi, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
            vi = mulmod(vi, vi, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
            vi = mulmod(vi, vi, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
            vi = mulmod(vi, vj, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed);
            vx = mulmod(
                vx,
                mulmod(vi, vv, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed),
                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
            );
            vy = mulmod(
                vy,
                mulmod(vi, vu, 0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed),
                0x7fffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffff_ffffffed
            );
            bytes32 vr = bytes32(vy | (vx << 255));
            vr = bytes32(
                ((uint256(vr) & 0xff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff_00ff00ff) << 8) |
                    ((uint256(vr) & 0xff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00_ff00ff00) >> 8)
            );
            vr = bytes32(
                ((uint256(vr) & 0xffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff_0000ffff) << 16) |
                    ((uint256(vr) & 0xffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000_ffff0000) >> 16)
            );
            vr = bytes32(
                ((uint256(vr) & 0xffffffff_00000000_ffffffff_00000000_ffffffff_00000000_ffffffff) << 32) |
                    ((uint256(vr) & 0xffffffff_00000000_ffffffff_00000000_ffffffff_00000000_ffffffff_00000000) >> 32)
            );
            vr = bytes32(
                ((uint256(vr) & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff) << 64) |
                    ((uint256(vr) & 0xffffffff_ffffffff_00000000_00000000_ffffffff_ffffffff_00000000_00000000) >> 64)
            );
            vr = bytes32((uint256(vr) << 128) | (uint256(vr) >> 128));
            return vr == r;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.7;

import "./Utils.sol";

library Borsh {
    using Borsh for Data;

    struct Data {
        uint ptr;
        uint end;
    }

    function from(bytes memory data) internal pure returns (Data memory res) {
        uint ptr;
        assembly {
            ptr := data
        }
        unchecked {
            res.ptr = ptr + 32;
            res.end = res.ptr + Utils.readMemory(ptr);
        }
    }

    // This function assumes that length is reasonably small, so that data.ptr + length will not overflow. In the current code, length is always less than 2^32.
    function requireSpace(Data memory data, uint length) internal pure {
        unchecked {
            require(data.ptr + length <= data.end, "Parse error: unexpected EOI");
        }
    }

    function read(Data memory data, uint length) internal pure returns (bytes32 res) {
        data.requireSpace(length);
        res = bytes32(Utils.readMemory(data.ptr));
        unchecked {
            data.ptr += length;
        }
        return res;
    }

    function done(Data memory data) internal pure {
        require(data.ptr == data.end, "Parse error: EOI expected");
    }

    // Same considerations as for requireSpace.
    function peekKeccak256(Data memory data, uint length) internal pure returns (bytes32) {
        data.requireSpace(length);
        return Utils.keccak256Raw(data.ptr, length);
    }

    // Same considerations as for requireSpace.
    function peekSha256(Data memory data, uint length) internal view returns (bytes32) {
        data.requireSpace(length);
        return Utils.sha256Raw(data.ptr, length);
    }

    function decodeU8(Data memory data) internal pure returns (uint8) {
        return uint8(bytes1(data.read(1)));
    }

    function decodeU16(Data memory data) internal pure returns (uint16) {
        return Utils.swapBytes2(uint16(bytes2(data.read(2))));
    }

    function decodeU32(Data memory data) internal pure returns (uint32) {
        return Utils.swapBytes4(uint32(bytes4(data.read(4))));
    }

    function decodeU64(Data memory data) internal pure returns (uint64) {
        return Utils.swapBytes8(uint64(bytes8(data.read(8))));
    }

    function decodeU128(Data memory data) internal pure returns (uint128) {
        return Utils.swapBytes16(uint128(bytes16(data.read(16))));
    }

    function decodeU256(Data memory data) internal pure returns (uint256) {
        return Utils.swapBytes32(uint256(data.read(32)));
    }

    function decodeBytes20(Data memory data) internal pure returns (bytes20) {
        return bytes20(data.read(20));
    }

    function decodeBytes32(Data memory data) internal pure returns (bytes32) {
        return data.read(32);
    }

    function decodeBool(Data memory data) internal pure returns (bool) {
        uint8 res = data.decodeU8();
        require(res <= 1, "Parse error: invalid bool");
        return res != 0;
    }

    function skipBytes(Data memory data) internal pure {
        uint length = data.decodeU32();
        data.requireSpace(length);
        unchecked {
            data.ptr += length;
        }
    }

    function decodeBytes(Data memory data) internal pure returns (bytes memory res) {
        uint length = data.decodeU32();
        data.requireSpace(length);
        res = Utils.memoryToBytes(data.ptr, length);
        unchecked {
            data.ptr += length;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.7;

library Utils {
    function swapBytes2(uint16 v) internal pure returns (uint16) {
        return (v << 8) | (v >> 8);
    }

    function swapBytes4(uint32 v) internal pure returns (uint32) {
        v = ((v & 0x00ff00ff) << 8) | ((v & 0xff00ff00) >> 8);
        return (v << 16) | (v >> 16);
    }

    function swapBytes8(uint64 v) internal pure returns (uint64) {
        v = ((v & 0x00ff00ff00ff00ff) << 8) | ((v & 0xff00ff00ff00ff00) >> 8);
        v = ((v & 0x0000ffff0000ffff) << 16) | ((v & 0xffff0000ffff0000) >> 16);
        return (v << 32) | (v >> 32);
    }

    function swapBytes16(uint128 v) internal pure returns (uint128) {
        v = ((v & 0x00ff00ff00ff00ff00ff00ff00ff00ff) << 8) | ((v & 0xff00ff00ff00ff00ff00ff00ff00ff00) >> 8);
        v = ((v & 0x0000ffff0000ffff0000ffff0000ffff) << 16) | ((v & 0xffff0000ffff0000ffff0000ffff0000) >> 16);
        v = ((v & 0x00000000ffffffff00000000ffffffff) << 32) | ((v & 0xffffffff00000000ffffffff00000000) >> 32);
        return (v << 64) | (v >> 64);
    }

    function swapBytes32(uint256 v) internal pure returns (uint256) {
        v =
            ((v & 0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff) << 8) |
            ((v & 0xff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00) >> 8);
        v =
            ((v & 0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff) << 16) |
            ((v & 0xffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000) >> 16);
        v =
            ((v & 0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff) << 32) |
            ((v & 0xffffffff00000000ffffffff00000000ffffffff00000000ffffffff00000000) >> 32);
        v =
            ((v & 0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff) << 64) |
            ((v & 0xffffffffffffffff0000000000000000ffffffffffffffff0000000000000000) >> 64);
        return (v << 128) | (v >> 128);
    }

    function readMemory(uint ptr) internal pure returns (uint res) {
        assembly {
            res := mload(ptr)
        }
    }

    function writeMemory(uint ptr, uint value) internal pure {
        assembly {
            mstore(ptr, value)
        }
    }

    function memoryToBytes(uint ptr, uint length) internal pure returns (bytes memory res) {
        if (length != 0) {
            assembly {
                // 0x40 is the address of free memory pointer.
                res := mload(0x40)
                let end := add(
                    res,
                    and(add(length, 63), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0)
                )
                // end = res + 32 + 32 * ceil(length / 32).
                mstore(0x40, end)
                mstore(res, length)
                let destPtr := add(res, 32)
                // prettier-ignore
                for { } 1 { } {
                    mstore(destPtr, mload(ptr))
                    destPtr := add(destPtr, 32)
                    if eq(destPtr, end) {
                        break
                    }
                    ptr := add(ptr, 32)
                }
            }
        }
    }

    function keccak256Raw(uint ptr, uint length) internal pure returns (bytes32 res) {
        assembly {
            res := keccak256(ptr, length)
        }
    }

    function sha256Raw(uint ptr, uint length) internal view returns (bytes32 res) {
        assembly {
            // 2 is the address of SHA256 precompiled contract.
            // First 64 bytes of memory can be used as scratch space.
            let ret := staticcall(gas(), 2, ptr, length, 0, 32)
            // If the call to SHA256 precompile ran out of gas, burn any gas that remains.
            // prettier-ignore
            for { } iszero(ret) { } { }
            res := mload(0)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}