// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interface/IBlockManager.sol";
import "./interface/IParameters.sol";
import "./interface/IStakeManager.sol";
import "./interface/IRewardManager.sol";
import "./interface/IVoteManager.sol";
import "./interface/IAssetManager.sol";
import "../randomNumber/IRandomNoProvider.sol";
import "./storage/BlockStorage.sol";
import "./StateManager.sol";
import "../lib/Random.sol";
import "../Initializable.sol";
import "./ACL.sol";

contract BlockManager is Initializable, ACL, BlockStorage, StateManager, IBlockManager {
    IParameters public parameters;
    IStakeManager public stakeManager;
    IRewardManager public rewardManager;
    IVoteManager public voteManager;
    IAssetManager public assetManager;
    IRandomNoProvider public randomNoProvider;

    event BlockConfirmed(uint32 epoch, uint32 stakerId, uint32[] medians, uint256 timestamp);

    event Proposed(uint32 epoch, uint32 stakerId, uint32[] medians, uint256 iteration, uint32 biggestInfluencerId, uint256 timestamp);

    function initialize(
        address stakeManagerAddress,
        address rewardManagerAddress,
        address voteManagerAddress,
        address assetManagerAddress,
        address parametersAddress,
        address randomNoManagerAddress
    ) external initializer onlyRole(DEFAULT_ADMIN_ROLE) {
        stakeManager = IStakeManager(stakeManagerAddress);
        rewardManager = IRewardManager(rewardManagerAddress);
        voteManager = IVoteManager(voteManagerAddress);
        assetManager = IAssetManager(assetManagerAddress);
        parameters = IParameters(parametersAddress);
        randomNoProvider = IRandomNoProvider(randomNoManagerAddress);
    }

    // elected proposer proposes block.
    //we use a probabilistic method to elect stakers weighted by stake
    // protocol works like this.
    //select a staker pseudorandomly (not weighted by anything)
    // that staker then tosses a biased coin.
    //bias = hisStake/biggestStake. if its heads, he can propose block
    // end of iteration. try next iteration
    // note that only one staker or no stakers selected in each iteration.
    // stakers elected in higher iterations can also propose hoping that
    // stakers with lower iteration do not propose for some reason
    function propose(
        uint32 epoch,
        uint32[] memory medians,
        uint256 iteration,
        uint32 biggestInfluencerId
    ) external initialized checkEpochAndState(State.Propose, epoch, parameters.epochLength()) {
        uint32 proposerId = stakeManager.getStakerId(msg.sender);
        require(isElectedProposer(iteration, biggestInfluencerId, proposerId), "not elected");
        require(stakeManager.getStake(proposerId) >= parameters.minStake(), "stake below minimum stake");
        //staker can just skip commit/reveal and only propose every epoch to avoid penalty.
        //following line is to prevent that
        require(voteManager.getEpochLastRevealed(proposerId) == epoch, "Cannot propose without revealing");
        require(medians.length == assetManager.getNumActiveAssets(), "invalid block proposed");

        uint256 biggestInfluence = stakeManager.getInfluence(biggestInfluencerId);
        if (sortedProposedBlockIds[epoch].length == 0) numProposedBlocks = 0;
        proposedBlocks[epoch][numProposedBlocks] = Structs.Block(proposerId, medians, iteration, biggestInfluence, true);
        _insertAppropriately(epoch, numProposedBlocks, iteration, biggestInfluence);
        numProposedBlocks = numProposedBlocks + 1;
        emit Proposed(epoch, proposerId, medians, iteration, biggestInfluencerId, block.timestamp);
    }

    //anyone can give sorted votes in batches in dispute state
    function giveSorted(
        uint32 epoch,
        uint8 assetId,
        uint32[] memory sortedStakers
    ) external initialized checkEpochAndState(State.Dispute, epoch, parameters.epochLength()) {
        uint256 accWeight = disputes[epoch][msg.sender].accWeight;
        uint256 accProd = disputes[epoch][msg.sender].accProd;
        uint32 lastVisitedStaker = disputes[epoch][msg.sender].lastVisitedStaker;
        uint8 assetIndex = assetManager.getAssetIndex(assetId);
        if (disputes[epoch][msg.sender].accWeight == 0) {
            disputes[epoch][msg.sender].assetId = assetId;
        } else {
            require(disputes[epoch][msg.sender].assetId == assetId, "AssetId not matching");
            // require(disputes[epoch][msg.sender].median == 0, "median already found");
        }
        for (uint16 i = 0; i < sortedStakers.length; i++) {
            require(sortedStakers[i] > lastVisitedStaker, "sorted[i] is not greater than lastVisited");
            lastVisitedStaker = sortedStakers[i];
            // slither-disable-next-line calls-loop
            Structs.Vote memory vote = voteManager.getVote(lastVisitedStaker);
            require(vote.epoch == epoch, "epoch in vote doesnt match with current");

            uint48 value = vote.values[assetIndex - 1];
            // slither-disable-next-line calls-loop
            uint256 influence = voteManager.getInfluenceSnapshot(epoch, lastVisitedStaker);
            accProd = accProd + value * influence;
            accWeight = accWeight + influence;
        }
        disputes[epoch][msg.sender].lastVisitedStaker = lastVisitedStaker;
        disputes[epoch][msg.sender].accWeight = accWeight;
        disputes[epoch][msg.sender].accProd = accProd;
    }

    // //if any mistake made during giveSorted, resetDispute and start again
    function resetDispute(uint32 epoch) external initialized checkEpochAndState(State.Dispute, epoch, parameters.epochLength()) {
        disputes[epoch][msg.sender] = Structs.Dispute(0, 0, 0, 0);
    }

    //O(1)
    function claimBlockReward() external initialized checkState(State.Confirm, parameters.epochLength()) {
        uint32 epoch = parameters.getEpoch();
        uint32 stakerId = stakeManager.getStakerId(msg.sender);
        require(stakerId > 0, "Structs.Staker does not exist");
        require(blocks[epoch].proposerId == 0, "Block already confirmed");

        uint8[] memory deactivatedAssets = assetManager.getPendingDeactivations();
        if (sortedProposedBlockIds[epoch].length == 0 || blockIndexToBeConfirmed == -1) {
            assetManager.executePendingDeactivations(epoch);
            return;
        }
        uint32 proposerId = proposedBlocks[epoch][sortedProposedBlockIds[epoch][uint8(blockIndexToBeConfirmed)]].proposerId;
        require(proposerId == stakerId, "Block can be confirmed by proposer of the block");
        _confirmBlock(epoch, deactivatedAssets, proposerId);
    }

    function confirmPreviousEpochBlock(uint32 stakerId) external override initialized onlyRole(BLOCK_CONFIRMER_ROLE) {
        uint32 epoch = parameters.getEpoch();
        uint8[] memory deactivatedAssets = assetManager.getPendingDeactivations();
        if (sortedProposedBlockIds[epoch - 1].length == 0 || blockIndexToBeConfirmed == -1) {
            assetManager.executePendingDeactivations(epoch);
            return;
        }
        _confirmBlock(epoch - 1, deactivatedAssets, stakerId);
    }

    function disputeBiggestInfluenceProposed(
        uint32 epoch,
        uint8 blockIndex,
        uint32 correctBiggestInfluencerId
    ) external initialized checkEpochAndState(State.Dispute, epoch, parameters.epochLength()) returns (uint32) {
        uint8 blockId = sortedProposedBlockIds[epoch][blockIndex];
        require(proposedBlocks[epoch][blockId].valid, "Block already has been disputed");
        uint256 correctBiggestInfluence = stakeManager.getInfluence(correctBiggestInfluencerId);
        require(correctBiggestInfluence > proposedBlocks[epoch][blockId].biggestInfluence, "Invalid dispute : Influence");
        return _executeDispute(epoch, blockIndex, blockId);
    }

    // Complexity O(1)
    function finalizeDispute(uint32 epoch, uint8 blockIndex)
        external
        initialized
        checkEpochAndState(State.Dispute, epoch, parameters.epochLength())
        returns (uint32)
    {
        require(
            disputes[epoch][msg.sender].accWeight == voteManager.getTotalInfluenceRevealed(epoch),
            "Total influence revealed doesnt match"
        );
        uint32 median = uint32(disputes[epoch][msg.sender].accProd / disputes[epoch][msg.sender].accWeight);
        require(median > 0, "median can not be zero");
        uint8 blockId = sortedProposedBlockIds[epoch][blockIndex];
        require(proposedBlocks[epoch][blockId].valid, "Block already has been disputed");
        uint8 assetId = disputes[epoch][msg.sender].assetId;
        uint8 assetIndex = assetManager.getAssetIndex(assetId);
        require(
            proposedBlocks[epoch][blockId].medians[assetIndex - 1] != median,
            "Proposed Alternate block is identical to proposed block"
        );
        return _executeDispute(epoch, blockIndex, blockId);
    }

    function getBlock(uint32 epoch) external view override returns (Structs.Block memory _block) {
        return (blocks[epoch]);
    }

    function getProposedBlock(uint32 epoch, uint8 proposedBlock) external view returns (Structs.Block memory _block) {
        _block = proposedBlocks[epoch][proposedBlock];
        return (_block);
    }

    function getNumProposedBlocks(uint32 epoch) external view returns (uint8) {
        return (uint8(sortedProposedBlockIds[epoch].length));
    }

    function isBlockConfirmed(uint32 epoch) external view override returns (bool) {
        return (blocks[epoch].proposerId != 0);
    }

    function isElectedProposer(
        uint256 iteration,
        uint32 biggestInfluencerId,
        uint32 stakerId
    ) public view initialized returns (bool) {
        // generating pseudo random number (range 0..(totalstake - 1)), add (+1) to the result,
        // since prng returns 0 to max-1 and staker start from 1

        bytes32 randaoHashes = voteManager.getRandaoHash();
        bytes32 seed1 = Random.prngHash(randaoHashes, keccak256(abi.encode(iteration)));
        uint256 rand1 = Random.prng(stakeManager.getNumStakers(), seed1);
        if ((rand1 + 1) != stakerId) {
            return false;
        }
        bytes32 seed2 = Random.prngHash(randaoHashes, keccak256(abi.encode(stakerId, iteration)));
        uint256 rand2 = Random.prng(2**32, seed2);

        uint256 biggestInfluence = stakeManager.getInfluence(biggestInfluencerId);
        uint256 influence = stakeManager.getInfluence(stakerId);
        if (rand2 * (biggestInfluence) > influence * (2**32)) return (false);
        return true;
    }

    function _confirmBlock(
        uint32 epoch,
        uint8[] memory deactivatedAssets,
        uint32 stakerId
    ) internal {
        uint8 blockId = sortedProposedBlockIds[epoch][uint8(blockIndexToBeConfirmed)];
        for (uint8 i = uint8(deactivatedAssets.length); i > 0; i--) {
            // slither-disable-next-line calls-loop
            uint8 index = assetManager.getAssetIndex(deactivatedAssets[i - 1]);
            if (index == proposedBlocks[epoch][blockId].medians.length) {
                proposedBlocks[epoch][blockId].medians.pop();
            } else {
                proposedBlocks[epoch][blockId].medians[index - 1] = proposedBlocks[epoch][blockId].medians[
                    proposedBlocks[epoch][blockId].medians.length - 1
                ];
                proposedBlocks[epoch][blockId].medians.pop();
            }
        }
        blocks[epoch] = proposedBlocks[epoch][blockId];
        emit BlockConfirmed(epoch, proposedBlocks[epoch][blockId].proposerId, proposedBlocks[epoch][blockId].medians, block.timestamp);
        assetManager.executePendingDeactivations(epoch);
        rewardManager.giveBlockReward(stakerId, epoch);
        randomNoProvider.provideSecret(epoch, voteManager.getRandaoHash());
    }

    function _insertAppropriately(
        uint32 epoch,
        uint8 blockId,
        uint256 iteration,
        uint256 biggestInfluence
    ) internal {
        uint8 sortedProposedBlockslength = uint8(sortedProposedBlockIds[epoch].length);

        if (sortedProposedBlockslength == 0) {
            sortedProposedBlockIds[epoch].push(0);
            blockIndexToBeConfirmed = 0;
            return;
        }
        uint8 maxAltBlocks = parameters.maxAltBlocks();

        for (uint8 i = 0; i < sortedProposedBlockslength; i++) {
            // Replace : New Block has better biggest influence
            if (proposedBlocks[epoch][sortedProposedBlockIds[epoch][i]].biggestInfluence < biggestInfluence) {
                sortedProposedBlockIds[epoch][i] = blockId;
                return;
            }
            // Push and Shift
            else if (proposedBlocks[epoch][sortedProposedBlockIds[epoch][i]].iteration > iteration) {
                sortedProposedBlockIds[epoch].push(blockId);

                sortedProposedBlockslength = sortedProposedBlockslength + 1;

                for (uint256 j = sortedProposedBlockslength - 1; j > i; j--) {
                    sortedProposedBlockIds[epoch][j] = sortedProposedBlockIds[epoch][j - 1];
                }

                sortedProposedBlockIds[epoch][i] = blockId;

                if (sortedProposedBlockIds[epoch].length > maxAltBlocks) {
                    sortedProposedBlockIds[epoch].pop();
                }

                return;
            }
        }
        // Worst Iteration and for all other blocks, influence was >=
        if (sortedProposedBlockIds[epoch].length < maxAltBlocks) {
            sortedProposedBlockIds[epoch].push(blockId);
        }
    }

    function _executeDispute(
        uint32 epoch,
        uint8 blockIndex,
        uint8 blockId
    ) internal returns (uint32) {
        proposedBlocks[epoch][blockId].valid = false;

        uint8 sortedProposedBlocksLength = uint8(sortedProposedBlockIds[epoch].length);
        if (uint8(blockIndexToBeConfirmed) == blockIndex) {
            // If the chosen one only is the culprit one, find successor
            // O(maxAltBlocks)

            blockIndexToBeConfirmed = -1;
            for (uint8 i = blockIndex + 1; i < sortedProposedBlocksLength; i++) {
                uint8 _blockId = sortedProposedBlockIds[epoch][i];
                if (proposedBlocks[epoch][_blockId].valid) {
                    // slither-disable-next-line costly-loop
                    blockIndexToBeConfirmed = int8(i);
                    break;
                }
            }
        }

        uint32 proposerId = proposedBlocks[epoch][blockId].proposerId;
        return stakeManager.slash(epoch, proposerId, msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/Structs.sol";

interface IBlockManager {
    function confirmPreviousEpochBlock(uint32 stakerId) external;

    function getBlock(uint32 epoch) external view returns (Structs.Block memory _block);

    function isBlockConfirmed(uint32 epoch) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IParameters {
    function getEpoch() external view returns (uint32);

    function getState() external view returns (uint8);

    function getAllSlashParams()
        external
        view
        returns (
            uint16,
            uint16,
            uint16,
            uint16
        );

    function epochLength() external view returns (uint16);

    function minStake() external view returns (uint256);

    function aggregationRange() external view returns (uint8);

    function maxAltBlocks() external view returns (uint8);

    function blockReward() external view returns (uint256);

    function penaltyNotRevealNum() external view returns (uint16);

    function baseDenominator() external view returns (uint16);

    function maxCommission() external view returns (uint8);

    function withdrawLockPeriod() external view returns (uint8);

    function withdrawReleasePeriod() external view returns (uint8);

    function escapeHatchEnabled() external view returns (bool);

    function gracePeriod() external view returns (uint16);

    function maxAge() external view returns (uint32);

    function exposureDenominator() external view returns (uint16);

    function extendLockPenalty() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/Structs.sol";
import "../storage/Constants.sol";

interface IStakeManager {
    function setStakerStake(
        uint32 _epoch,
        uint32 _id,
        Constants.StakeChanged reason,
        uint256 _stake
    ) external;

    function slash(
        uint32 epoch,
        uint32 stakerId,
        address bountyHunter
    ) external returns (uint32);

    function setStakerAge(
        uint32 _epoch,
        uint32 _id,
        uint32 _age
    ) external;

    function setStakerEpochFirstStakedOrLastPenalized(uint32 _epoch, uint32 _id) external;

    function escape(address _address) external;

    function getStakerId(address _address) external view returns (uint32);

    function getStaker(uint32 _id) external view returns (Structs.Staker memory staker);

    function getNumStakers() external view returns (uint32);

    function getInfluence(uint32 stakerId) external view returns (uint256);

    function getStake(uint32 stakerId) external view returns (uint256);

    function getEpochFirstStakedOrLastPenalized(uint32 stakerId) external view returns (uint32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/Structs.sol";

interface IRewardManager {
    function givePenalties(uint32 epoch, uint32 stakerId) external;

    function giveBlockReward(uint32 epoch, uint32 stakerId) external;

    function giveInactivityPenalties(uint32 epoch, uint32 stakerId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../lib/Structs.sol";

interface IVoteManager {
    function getVoteValue(uint8 assetId, uint32 stakerId) external view returns (uint48);

    function getVote(uint32 stakerId) external view returns (Structs.Vote memory vote);

    function getInfluenceSnapshot(uint32 epoch, uint32 stakerId) external view returns (uint256);

    function getTotalInfluenceRevealed(uint32 epoch) external view returns (uint256);

    function getEpochLastRevealed(uint32 stakerId) external view returns (uint32);

    function getEpochLastCommitted(uint32 stakerId) external view returns (uint32);

    function getRandaoHash() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAssetManager {
    function executePendingDeactivations(uint32 epoch) external;

    function getActiveAssets() external view returns (uint8[] memory);

    function getPendingDeactivations() external view returns (uint8[] memory);

    function getAssetIndex(uint8 id) external view returns (uint8);

    function getNumActiveAssets() external view returns (uint256);

    function getCollectionPower(uint8 id) external view returns (int8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRandomNoProvider {
    /// @notice Called by BlockManager in ClaimBlockReward or ConfirmBlockLastEpoch
    /// @param epoch current epoch
    /// @param _secret hash of encoded rando secret from stakers
    function provideSecret(uint32 epoch, bytes32 _secret) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../../lib/Structs.sol";

contract BlockStorage {
    //epoch -> address -> dispute -> assetid
    mapping(uint32 => mapping(address => Structs.Dispute)) public disputes;
    //epoch -> blockId -> block
    mapping(uint32 => mapping(uint8 => Structs.Block)) public proposedBlocks;
    //epoch->blockId
    mapping(uint32 => uint8[]) public sortedProposedBlockIds;

    // slither-disable-next-line constable-states
    uint8 public numProposedBlocks;
    // slither-disable-next-line constable-states
    int8 public blockIndexToBeConfirmed; // Index in sortedProposedBlockIds
    // epoch -> blocks
    mapping(uint32 => Structs.Block) public blocks;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./storage/Constants.sol";

contract StateManager is Constants {
    modifier checkState(State state, uint32 epochLength) {
        // slither-disable-next-line incorrect-equality
        require(state == getState(epochLength), "incorrect state");
        _;
    }

    modifier notState(State state, uint32 epochLength) {
        // slither-disable-next-line incorrect-equality
        require(state != getState(epochLength), "incorrect state");
        _;
    }

    modifier checkEpochAndState(
        State state,
        uint32 epoch,
        uint32 epochLength
    ) {
        // slither-disable-next-line incorrect-equality
        require(epoch == getEpoch(epochLength), "incorrect epoch");
        // slither-disable-next-line incorrect-equality
        require(state == getState(epochLength), "incorrect state");
        _;
    }

    function getEpoch(uint32 epochLength) public view returns (uint32) {
        return (uint32(block.number) / (epochLength));
    }

    function getState(uint32 epochLength) public view returns (State) {
        uint8 state = uint8(((block.number) / (epochLength / NUM_STATES)) % (NUM_STATES));
        return State(state);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Random {
    // pseudo random number generator based on hash. returns 0 -> max-1
    function prng(uint256 max, bytes32 randHash) external pure returns (uint256) {
        uint256 sum = uint256(randHash);
        return (sum % max);
    }

    // pseudo random hash generator based on hashes.
    function prngHash(bytes32 seed, bytes32 salt) external pure returns (bytes32) {
        bytes32 prngHashVal = keccak256(abi.encodePacked(seed, salt));
        return (prngHashVal);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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
 * Forked from OZ's (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/b9125001f0a1c44d596ca3a47536f1a467e3a29d/contracts/proxy/utils/Initializable.sol)
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

    modifier initialized() {
        require(_initialized, "Contract should be initialized");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract ACL is AccessControl {
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Structs {
    struct Vote {
        uint32 epoch;
        uint48[] values;
    }

    struct Commitment {
        uint32 epoch;
        bytes32 commitmentHash;
    }
    struct Staker {
        bool acceptDelegation;
        uint8 commission;
        address _address;
        address tokenAddress;
        uint32 id;
        uint32 age;
        uint32 epochFirstStakedOrLastPenalized;
        uint256 stake;
    }

    struct Lock {
        uint256 amount; //amount in RZR
        uint256 commission;
        uint256 withdrawAfter;
    }

    struct BountyLock {
        address bountyHunter;
        uint256 amount; //amount in RZR
        uint256 redeemAfter;
    }

    struct Block {
        uint32 proposerId;
        uint32[] medians;
        uint256 iteration;
        uint256 biggestInfluence;
        bool valid;
    }

    struct Dispute {
        uint8 assetId;
        uint32 lastVisitedStaker;
        uint256 accWeight;
        uint256 accProd;
        // uint32 median;
    }

    struct Job {
        uint8 id;
        uint8 selectorType; // 0-1
        uint8 weight; // 1-100
        int8 power;
        string name;
        string selector;
        string url;
    }

    struct Collection {
        bool active;
        uint8 id;
        uint8 assetIndex;
        int8 power;
        uint32 aggregationMethod;
        uint8[] jobIDs;
        string name;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Constants {
    enum State {
        Commit,
        Reveal,
        Propose,
        Dispute,
        Confirm
    }

    enum StakeChanged {
        BlockReward,
        InactivityPenalty,
        Slashed
    }

    uint8 public constant NUM_STATES = 5;

    // keccak256("BLOCK_CONFIRMER_ROLE")
    bytes32 public constant BLOCK_CONFIRMER_ROLE = 0x18797bc7973e1dadee1895be2f1003818e30eae3b0e7a01eb9b2e66f3ea2771f;

    // keccak256("ASSET_CONFIRMER_ROLE")
    bytes32 public constant ASSET_CONFIRMER_ROLE = 0xed202a1bc048f9b31cb3937bc52e7c8fe76413f0674b9146ff4bcc15612ccbc2;

    // keccak256("STAKER_ACTIVITY_UPDATER_ROLE")
    bytes32 public constant STAKER_ACTIVITY_UPDATER_ROLE = 0x4cd3070aaa07d03ab33731cbabd0cb27eb9e074a9430ad006c96941d71b77ece;

    // keccak256("STAKE_MODIFIER_ROLE")
    bytes32 public constant STAKE_MODIFIER_ROLE = 0xdbaaaff2c3744aa215ebd99971829e1c1b728703a0bf252f96685d29011fc804;

    // keccak256("REWARD_MODIFIER_ROLE")
    bytes32 public constant REWARD_MODIFIER_ROLE = 0xcabcaf259dd9a27f23bd8a92bacd65983c2ebf027c853f89f941715905271a8d;

    // keccak256("ASSET_MODIFIER_ROLE")
    bytes32 public constant ASSET_MODIFIER_ROLE = 0xca0fffcc0404933256f3ec63d47233fbb05be25fc0eacc2cfb1a2853993fbbe4;

    // keccak256("VOTE_MODIFIER_ROLE")
    bytes32 public constant VOTE_MODIFIER_ROLE = 0xca0fffcc0404933256f3ec63d47233fbb05be25fc0eacc2cfb1a2853993fbbe5;

    // keccak256("DELEGATOR_MODIFIER_ROLE")
    bytes32 public constant DELEGATOR_MODIFIER_ROLE = 0x6b7da7a33355c6e035439beb2ac6a052f1558db73f08690b1c9ef5a4e8389597;
    // keccak256("SECRETS_MODIFIER_ROLE")
    bytes32 public constant SECRETS_MODIFIER_ROLE = 0x46aaf8a125792dfff6db03d74f94fe1acaf55c8cab22f65297c15809c364465c;

    address public constant BURN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}