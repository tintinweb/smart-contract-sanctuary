// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import "./AdminControlled.sol";
import "./INearBridge.sol";
import "./NearDecoder.sol";
import "./Ed25519.sol";

contract NearBridge is INearBridge, AdminControlled {
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
    Ed25519 immutable edwards;

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

    constructor(
        Ed25519 ed,
        uint256 lockEthAmount_,
        uint256 lockDuration_,
        uint256 replaceDuration_,
        address admin_,
        uint256 pausedFlags_
    ) AdminControlled(admin_, pausedFlags_) {
        require(replaceDuration_ > lockDuration_ * 1000000000);
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

    function deposit() public payable override pausable(PAUSED_DEPOSIT) {
        require(msg.value == lockEthAmount && balanceOf[msg.sender] == 0);
        balanceOf[msg.sender] = msg.value;
    }

    function withdraw() public override pausable(PAUSED_WITHDRAW) {
        require(msg.sender != lastSubmitter || block.timestamp >= lastValidAt);
        uint amount = balanceOf[msg.sender];
        require(amount != 0);
        balanceOf[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function challenge(address payable receiver, uint signatureIndex) public override pausable(PAUSED_CHALLENGE) {
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
    function initWithValidators(bytes memory data) public override onlyAdmin {
        require(!initialized && epochs[0].numBPs == 0, "Wrong initialization stage");

        Borsh.Data memory borsh = Borsh.from(data);
        NearDecoder.BlockProducer[] memory initialValidators = borsh.decodeBlockProducers();
        borsh.done();

        setBlockProducers(initialValidators, epochs[0]);
    }

    // The second part of the initialization -- setting the current head.
    function initWithBlock(bytes memory data) public override onlyAdmin {
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

    function bridgeState() public view returns (BridgeState memory res) {
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

    function addLightClientBlock(bytes memory data) public override pausable(PAUSED_ADD_BLOCK) {
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
        require(cnt <= MAX_BLOCK_PRODUCERS, "It is not expected having that many block producers for the provided block");
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

    function blockHashes(uint64 height) public view override pausable(PAUSED_VERIFY) returns (bytes32 res) {
        res = blockHashes_[height];
        if (res == 0 && block.timestamp >= lastValidAt && lastValidAt != 0 && height == untrustedHeight) {
            res = untrustedHash;
        }
    }

    function blockMerkleRoots(uint64 height) public view override pausable(PAUSED_VERIFY) returns (bytes32 res) {
        res = blockMerkleRoots_[height];
        if (res == 0 && block.timestamp >= lastValidAt && lastValidAt != 0 && height == untrustedHeight) {
            res = untrustedMerkleRoot;
        }
    }
}