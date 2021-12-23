// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../Manageable.sol";
import "../../Staking/Manager.sol";
import "../../Epochs/Manager.sol";
import "../../Utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

/**
 * @notice Handles epoch based reward pools that are incremented from redeeming tickets.
 * Nodes use this contract to set up their reward pool for the next epoch,
 * and stakers use this contract to track and claim staking rewards.
 * @dev After deployment, the SyloTicketing contract should be
 * set up as a manager to be able to call certain restricted functions.
*/
contract RewardsManager is Initializable, OwnableUpgradeable, Manageable {
    uint256 internal constant ONE_SYLO = 1 ether;
    // 64x64 Fixed point representation of 1 SYLO (10**18 >> 64)
    int128 internal constant ONE_SYLO_FIXED = 18446744073709551616000000000000000000;

    /** ERC20 Sylo token contract. */
    IERC20 public _token;

    /** Sylo Staking Manager contract. */
    StakingManager public _stakingManager;

    /** Sylo Epochs Manager. */
    EpochsManager public _epochsManager;

    /**
     * @notice Tracks each Nodes total unclaimed rewards in SOLOs. This value
     * accumulated as Node's redeem tickets, and tracks the portion of the
     * reward which is allocated to the Node as payment for operating
     * a Sylo Node.
     */
    mapping (address => uint256) public unclaimedNodeRewards;

    /**
     * @notice Tracks each Nodes total unclaimed staking rewards in SOLOs. This
     * value is accumulated as Node's redeem tickets, and tracks the portion of
     * the reward which is allocated to its delegated stakers.
     */
    mapping (address => uint256) public unclaimedStakeRewards;

    /**
     * @notice Tracks each Node's most recently initialized reward pool
     */
    mapping (address => uint256) public latestActiveRewardPools;

    /**
     * @notice Tracks the last epoch a delegated staker made a reward claim in.
     * The key to this mapping is a hash of the Node's address and the delegated
     * stakers address.
     */
    mapping (bytes32 => uint256) public lastClaims;

    /**
     * @dev This type will hold the necessary information for delegated stakers
     * to make reward claims against their Node. Every Node will initialize
     * and store a new Reward Pool for each they participate in.
     */
    struct RewardPool {
        // Tracks the balance of the reward pool owed to the stakers
        uint256 stakersRewardTotal;

        // Tracks the block number this reward pool was initialized
        uint256 initializedAt;

        // The total active stake for the node for will be the sum of the
        // stakes owned by its delegators plus the value of the unclaimed
        // staker rewards at the time this pool was initialized
        uint256 totalActiveStake;

        // track the cumulative reward factor as of the time the pool was initialized
        int128 initialCumulativeRewardFactor;

        // track the cumulative reward factor as a 64x64 fixed-point value
        int128 cumulativeRewardFactor;
    }

    /**
     * @notice Tracks each reward pool initialized by a Node. The key to this map
     * is derived from the epochId and the Node's address.
     */
    mapping (bytes32 => RewardPool) public rewardPools;

    function initialize(
        IERC20 token,
        StakingManager stakingManager,
        EpochsManager epochsManager
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        _token = token;
        _epochsManager = epochsManager;
        _stakingManager = stakingManager;
    }

    /**
     * @notice Returns the key used to index a reward pool. The key is a hash of
     * the epochId and Node's address.
     * @param epochId The epoch ID the reward pool was created in.
     * @param stakee The address of the Node.
     * @return A byte-array representing the reward pool key.
     */
    function getRewardPoolKey(uint256 epochId, address stakee) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(epochId, stakee));
    }

    /**
     * @notice Returns the key used to index staking claims. The key is a hash of
     * the Node's address and the staker's address.
     * @param stakee The address of the Node.
     * @param staker The address of the stake.
     * @return A byte-array representing the key.
     */
    function getStakerKey(address stakee, address staker) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(stakee, staker));
    }

    /**
     * @notice Retrieves the ID of the epoch in which a staker last made their
     * staking claim.
     * @param stakee The address of the Node.
     * @param staker The address of the staker.
     * @return The ID of the epoch.
     */
    function getLastClaim(address stakee, address staker) external view returns(uint256) {
        return lastClaims[getStakerKey(stakee, staker)];
    }

    /**
     * @notice Retrieve the reward pool initialized by the given node, at the specified
     * epoch.
     * @param epochId The ID of the epoch the reward pool was initialized in.
     * @param stakee The address of the Node.
     * @return The reward pool.
     */
    function getRewardPool(uint256 epochId, address stakee) external view returns (RewardPool memory) {
        return rewardPools[getRewardPoolKey(epochId, stakee)];
    }

    /**
     * @notice Retrieve the total accumulated reward that will be distributed to a Node's
     * delegated stakers for a given epoch.
     * @param epochId The ID of the epoch the reward pool was initialized in.
     * @param stakee The address of the Node.
     * @return The total accumulated staker reward in SOLO.
     */
    function getRewardPoolStakersTotal(uint256 epochId, address stakee) external view returns (uint256) {
        return rewardPools[getRewardPoolKey(epochId, stakee)].stakersRewardTotal;
    }

    /**
     * @notice Retrieve the total active stake that will be used for a Node's reward
     * pool in a given epoch.
     * @param epochId The ID of the epoch the reward pool was initialized in.
     * @param stakee The address of the Node.
     * @return The total active stake for that reward pool in SOLO.
     */
    function getRewardPoolActiveStake(uint256 epochId, address stakee) external view returns (uint256) {
        return rewardPools[getRewardPoolKey(epochId, stakee)].totalActiveStake;
    }

    /**
     * @notice Retrieve the total unclaimed reward allocated to a Node as payment
     * for providing a service.
     * @param stakee The address of the Node.
     * @return The total unclaimed Node reward in SOLO.
     */
    function getUnclaimedNodeReward(address stakee) external view returns (uint256) {
        return unclaimedNodeRewards[stakee];
    }

    /**
     * @notice Retrieve the total unclaimed staking reward allocated to a Node's
     * delegated stakers.
     * @param stakee The address of the Node.
     * @return The total unclaimed staking reward in SOLO.
     */
    function getUnclaimedStakeReward(address stakee) external view returns (uint256) {
        return unclaimedStakeRewards[stakee];
    }

    /**
     * @notice This is used by Nodes to initialize their reward pool for
     * the next epoch. This function will revert if the caller has no stake, or
     * if the reward pool has already been initialized. The total active stake
     * for the next reward pool is calculated by summing up the total managed
     * stake held by the RewardsManager contract, plus any unclaimed staking rewards.
     */
    function initializeNextRewardPool(address stakee) external onlyManager {
        uint256 nextEpochId = _epochsManager.getNextEpochId();

        RewardPool storage nextRewardPool = rewardPools[getRewardPoolKey(nextEpochId, stakee)];
        require(
            nextRewardPool.initializedAt == 0,
            "The next reward pool has already been initialized"
        );

        uint256 totalStake = _stakingManager.getStakeeTotalManagedStake(stakee);
        require(totalStake > 0, "Must have stake to initialize a reward pool");

        nextRewardPool.initializedAt = block.number;

        // Any unclaimed staker rewards will automatically be added to the
        // active stake total
        nextRewardPool.totalActiveStake = totalStake + unclaimedStakeRewards[stakee];

        nextRewardPool.initialCumulativeRewardFactor = rewardPools[getRewardPoolKey(
            latestActiveRewardPools[stakee],
            stakee
        )].cumulativeRewardFactor;

        latestActiveRewardPools[stakee] = nextEpochId;
    }

    /**
     * @dev This function should be called by the Ticketing contract when a
     * ticket is successfully redeemed. The face value of the ticket
     * should be split between incrementing the node's reward balance,
     * and the reward balance for the node's delegated stakers. The face value
     * will be added to the current reward pool's balance. This function will
     * fail if the Ticketing contract has not been set as a manager.
     * @param stakee The address of the Node.
     * @param amount The face value of the ticket in SOLO.
     */
    function incrementRewardPool(
        address stakee,
        uint256 amount
    ) external onlyManager {
        EpochsManager.Epoch memory currentEpoch = _epochsManager.getCurrentActiveEpoch();

        RewardPool storage rewardPool = rewardPools[getRewardPoolKey(currentEpoch.iteration, stakee)];
        require(
            rewardPool.totalActiveStake > 0,
            "Reward pool has not been initialized for the current epoch"
        );

        uint256 stakersReward = SyloUtils.percOf(
            uint128(amount),
            currentEpoch.defaultPayoutPercentage
        );

        // update the value of the reward owed to the node
        unclaimedNodeRewards[stakee] += (amount - stakersReward);

        // update the value of the reward owed to the delegated stakers
        unclaimedStakeRewards[stakee] += stakersReward;

        rewardPool.stakersRewardTotal += stakersReward;

        // if this is the first epoch the node is ever active
        // then we can't rely on the previous crf to calculate the current crf
        if (rewardPool.initialCumulativeRewardFactor == 0) {
            rewardPool.cumulativeRewardFactor =
                ABDKMath64x64.div(
                    toFixedPointSYLO(rewardPool.stakersRewardTotal),
                    toFixedPointSYLO(rewardPool.totalActiveStake)
                );
        } else {
            rewardPool.cumulativeRewardFactor = calculatateUpdatedCumulativeRewardFactor(
                rewardPool.initialCumulativeRewardFactor,
                rewardPool.stakersRewardTotal,
                rewardPool.totalActiveStake
            );
        }
    }

    function calculatateUpdatedCumulativeRewardFactor(
        int128 previousCumulativeRewardFactor,
        uint256 rewardTotal,
        uint256 stakeTotal
    ) internal pure returns (int128) {
        return ABDKMath64x64.add(
            previousCumulativeRewardFactor,
            ABDKMath64x64.mul(
                previousCumulativeRewardFactor,
                ABDKMath64x64.div(
                    toFixedPointSYLO(rewardTotal),
                    toFixedPointSYLO(stakeTotal)
                )
            )
        );
    }

    /**
     * @notice Call this function to calculate the total portion of staking reward
     * that a delegated staker is owed. This value will include all epochs since the
     * last claim was made.
     * @dev This function will utilize the cumulative reward factor to perform the
     * calculation, keeping the gas cost scaling of this function to a constant value.
     * @param stakee The address of the Node.
     * @param staker The address of the staker.
     * @return The value of the reward owed to the staker in SOLO.
     */
    function calculateStakerClaim(address stakee, address staker) public view returns (uint256) {
        // The staking manager will track the initial stake that was available prior
        // to becoming active
        StakingManager.StakeEntry memory stakeEntry = _stakingManager.getStakeEntry(stakee, staker);
        if (stakeEntry.amount == 0) {
            return 0;
        }

        // find the first reward pool where their stake was active and had
        // generated rewards
        uint256 activeAt = 0;
        for (uint i = lastClaims[getStakerKey(stakee, staker)] + 1; i < _epochsManager.getNextEpochId(); i++) {
            RewardPool storage rewardPool = rewardPools[getRewardPoolKey(i, stakee)];
            // check if node initialized a reward pool for this epoch and
            // gained rewards
            if (rewardPool.initializedAt > 0 && rewardPool.stakersRewardTotal > 0) {
                activeAt = i;
                break;
            }
        }

        if (activeAt == 0) {
            return 0;
        }

        RewardPool storage initialActivePool = rewardPools[getRewardPoolKey(activeAt, stakee)];

        // We convert the staker amount to SYLO as the maximum uint256 value that
        // can be used for the fixed point representation is 2^64-1.
        int128 initialStake = toFixedPointSYLO(stakeEntry.amount);
        int128 initialCumulativeRewardFactor = initialActivePool.initialCumulativeRewardFactor;

        // if the staker started staking prior to the node generating any
        // rewards (initial crf == 0), then we have to manually calculate the proportion of reward
        // for the first epoch, and use that value as the initial stake instead
        if (initialCumulativeRewardFactor == int128(0)) {
            initialStake = ABDKMath64x64.add(
                initialStake,
                ABDKMath64x64.mul(
                    toFixedPointSYLO(initialActivePool.stakersRewardTotal),
                    ABDKMath64x64.div(
                        initialStake,
                        toFixedPointSYLO(initialActivePool.totalActiveStake)
                    )
                )
            );
            initialCumulativeRewardFactor = initialActivePool.cumulativeRewardFactor;
        }

        RewardPool storage latestRewardPool = rewardPools[getRewardPoolKey(
            latestActiveRewardPools[stakee], stakee
        )];

        // utilize the cumulative reward factor to calculate their updated stake amount
        uint256 updatedStake = fromFixedPointSYLO(
            ABDKMath64x64.mul(
                initialStake,
                ABDKMath64x64.div(
                    latestRewardPool.cumulativeRewardFactor,
                    initialCumulativeRewardFactor
                )
            )
        );

        // this is the actual amount of rewards generated by their stake
        // since their stake became active
        return updatedStake - stakeEntry.amount;
    }

    /**
     * Helper function to convert a uint256 value in SOLOs to a 64.64 fixed point
     * representation in SYLOs while avoiding any possibility of overflow.
     * Any remainders from converting SOLO to SYLO is explicitly handled to mitigate
     * precision loss. The error when using this function is [-1/2^64, 0].
     */
    function toFixedPointSYLO(uint256 amount) internal pure returns (int128) {
        int128 fullSylos = ABDKMath64x64.fromUInt(amount / ONE_SYLO);
        int128 fracSylos = ABDKMath64x64.fromUInt(amount % ONE_SYLO); // remainder

        return ABDKMath64x64.add(fullSylos, ABDKMath64x64.div(fracSylos, ONE_SYLO_FIXED));
    }

    /**
     * Helper function to convert a 64.64 fixed point value in SYLOs to a uint256
     * representation in SOLOs while avoiding any possibility of overflow.
     */
    function fromFixedPointSYLO(int128 amount) internal pure returns (uint256) {
        uint256 fullSylos = ABDKMath64x64.toUInt(amount);
        uint256 fullSolos = fullSylos * ONE_SYLO;

         // calculate the value lost when converting the fixed point amount to a uint
        int128 fracSylos = ABDKMath64x64.sub(amount, ABDKMath64x64.fromUInt(fullSylos));
        uint256 fracSolos = ABDKMath64x64.toUInt(ABDKMath64x64.mul(fracSylos, ONE_SYLO_FIXED));

        return fullSolos + fracSolos;
    }

    /**
     * @notice Call this function to claim rewards as a delegated staker. The
     * SYLO tokens will be transferred to the caller's account. This function will
     * fail if there exists no reward to claim. Note: Calling this will remove
     * the current unclaimed reward from being used as stake in the next round.
     * @param stakee The address of the Node to claim against.
     */
    function claimStakingRewards(address stakee) external {
        uint256 rewardClaim = calculateStakerClaim(stakee, msg.sender);
        require(rewardClaim > 0, "Nothing to claim");
        unclaimedStakeRewards[stakee] -= rewardClaim;
        lastClaims[getStakerKey(stakee, msg.sender)] = latestActiveRewardPools[stakee];
        _token.transfer(msg.sender, rewardClaim);
    }

    /**
     * @notice This function should be called to automatically claim rewards
     * when a staker wishes to update their stake. This is only callable
     * by the StakingManager contract.
     * @dev This function will revert if the StakingManager contract has
     * not been set as a manager.
     * @param stakee The address of the Node to claim against.
     * @param staker The address of the staker.
     */
    function claimStakingRewardsAsManager(address stakee, address staker) external onlyManager {
        uint256 rewardClaim = calculateStakerClaim(stakee, staker);
        lastClaims[getStakerKey(stakee, staker)] = latestActiveRewardPools[stakee];
        if (rewardClaim == 0) {
            return;
        }
        unclaimedStakeRewards[stakee] -= rewardClaim;
        _token.transfer(staker, rewardClaim);
    }

    /**
     * @notice Call this function as a Node operator to claim the accumulated
     * reward for operating a Sylo Node.
     */
    function claimNodeRewards() external {
        uint256 claim = unclaimedNodeRewards[msg.sender];

        // Also add any unclaimed staker rewards that can no longer be claimed
        // by the node's delegated stakers.
        // This situation can arise if the node redeemed tickets in the
        // after a staker claimed their reward but in the same epoch.
        uint256 stake = _stakingManager.getStakeeTotalManagedStake(msg.sender);
        // All stakers unstaked, we can safely claim any remaining staker rewards
        if (stake == 0) {
            claim += unclaimedStakeRewards[msg.sender];
            unclaimedStakeRewards[msg.sender] = 0;
        }

        require(claim > 0, "Nothing to claim");

        unclaimedNodeRewards[msg.sender] = 0;
        _token.transfer(msg.sender, claim);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an list of public managers who may be added or removed.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * other contracts which have explicitly been added.
 */
abstract contract Manageable is OwnableUpgradeable {
    /**
     * @dev Tracks the managers added to this contract, where they key is the
     * address of the managing contract, and the value is the block the manager was added in.
     * We use this mapping to restrict access to those functions in a similar
     * fashion to the onlyOwner construct.
     */
    mapping (address => uint256) public managers;

    /**
     * @notice Adds a manager to this contract. Only callable by the owner.
     * @param manager The address of the manager contract.
     */
    function addManager(address manager) external onlyOwner {
      managers[manager] = block.number;
    }

    /**
     * @notice Removes a manager from this contract. Only callable by the owner.
     * @param manager The address of the manager contract.
     */
    function removeManager(address manager) external onlyOwner {
      delete managers[manager];
    }

    /**
     * @dev This modifier allows us to specify that certain contracts have
     * special privileges to call restricted functions.
     */
    modifier onlyManager() {
      require(managers[msg.sender] > 0, "Only managers of this contract can call this function");
      _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../Token.sol";
import "../Payments/Ticketing/RewardsManager.sol";
import "../Epochs/Manager.sol";
import "../Utils.sol";

/**
 * @notice Manages stakes and delegated stakes for Nodes. Holding
 * staked Sylo is necessary for a Node to participate in the
 * Sylo Network. The stake is used in stake-weighted scan function,
 * and delegated stakers are rewarded on a pro-rata basis.
 */
contract StakingManager is Initializable, OwnableUpgradeable {
    /** ERC 20 compatible token we are dealing with */
    IERC20 public _token;

    /**
     * @notice Rewards Manager contract. Any changes to stake will automatically
     * trigger a claim to any outstanding rewards.
     */
    RewardsManager public _rewardsManager;

    EpochsManager public _epochsManager;

    /**
     * For every Node, there will be a mapping of the staker to a
     * StakeEntry. The stake entry tracks the amount of stake in SOLO,
     * and also when the stake was updated.
     */
    struct StakeEntry {
        uint256 amount;

        // Block number this entry was updated at
        uint256 updatedAt;

        // Epoch this entry was updated. The stake will become active
        // in the following epoch
        uint256 epochId;
    }

    /**
     * Every Node must have stake in order to participate in the Epoch.
     * Stake can be provided by the Node itself or by other accounts in
     * the network.
     */
    struct Stake {
        // Track each stake entry associated to a node
        mapping (address => StakeEntry) stakeEntries;

        // The total stake held by this contract for a node,
        // which will be the sum of all addStake and unlockStake calls
        uint256 totalManagedStake;
    }

    /**
     * This struct will track stake that is in the process of unlocking.
     */
    struct Unlock {
        uint256 amount; // Amount of stake unlocking
        uint256 unlockAt; // Block number the stake becomes withdrawable
    }

    /**
     * @notice Tracks the managed stake for every Node.
     */
    mapping (address => Stake) public stakes;

    /** @notice Tracks overall total stake held by this contract */
    uint256 public totalManagedStake;

    /**
     * @notice Tracks funds that are in the process of being unlocked. This
     * is indexed by a key that hashes both the address of the staked Node and
     * the address of the staker.
     */
    mapping(bytes32 => Unlock) public unlockings;

    event UnlockDurationUpdated(uint256 unlockDuration);
    event MinimumStakeProportionUpdated(uint256 minimumStakeProportion);

    /**
     * @notice The number of blocks a user must wait after calling "unlock"
     * before they can withdraw their stake
     */
    uint256 public unlockDuration;

    /**
     * @notice Minimum amount of stake that a Node needs to stake
     * against itself in order to participate in the network. This is
     * represented as a percentage of the Node's total stake, where
     * the value is a ratio of 10000.
     */
    uint16 public minimumStakeProportion;

    function initialize(
        IERC20 token,
        RewardsManager rewardsManager,
        EpochsManager epochsManager,
        uint256 _unlockDuration,
        uint16 _minimumStakeProportion
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        _token = token;
        _rewardsManager = rewardsManager;
        _epochsManager = epochsManager;
        unlockDuration = _unlockDuration;
        minimumStakeProportion = _minimumStakeProportion;
    }

    /**
     * @notice Sets the unlock duration for stakes. Only callable by
     * the owner.
     * @param _unlockDuration The unlock duration in number of blocks.
     */
    function setUnlockDuration(uint256 _unlockDuration) external onlyOwner {
        unlockDuration = _unlockDuration;
        emit UnlockDurationUpdated(_unlockDuration);
    }

    /**
     * @notice Sets the minimum stake proportion for Nodes. Only callable by
     * the owner.
     * @param _minimumStakeProportion The minimum stake proportion in SOLO.
     */
    function setMinimumStakeProportion(uint16 _minimumStakeProportion) external onlyOwner {
        minimumStakeProportion = _minimumStakeProportion;
        emit MinimumStakeProportionUpdated(_minimumStakeProportion);
    }

    /**
     * @notice Called by Nodes and delegated stakers to add stake. Calling
     * this will trigger an automatic claim of any outstanding staking
     * rewards. This function will fail under the following conditions:
     *   - If the Node address is invalid
     *   - If the specified stake value is zero
     *   - If the additional stake causes the Node to fail to meet the
     *     minimum stake proportion requirement.
     * @param amount The amount of stake to add in SOLO.
     * @param stakee The address of the staked Node.
     */
    function addStake(uint256 amount, address stakee) external {
        addStake_(amount, stakee);
        _token.transferFrom(msg.sender, address(this), amount);
    }

    function addStake_(uint256 amount, address stakee) internal {
        require(stakee != address(0), "Address is null");
        require(amount != 0, "Cannot stake nothing");

        Stake storage stake = stakes[stakee];

        uint256 currentStake = getCurrentStakerAmount(stakee, msg.sender);

        // automatically claim any outstanding rewards generated by their existing stake
        _rewardsManager.claimStakingRewardsAsManager(stakee, msg.sender);

        uint256 currentEpochId = _epochsManager.currentIteration();

        stake.stakeEntries[msg.sender] = StakeEntry(
            currentStake + amount,
            block.number,
            currentEpochId
        );

        stake.totalManagedStake += amount;
        totalManagedStake += amount;

        // ensure that the node's own stake is still at the minimum amount
        if (msg.sender != stakee) {
            require(
                checkMinimumStakeProportion(stakee),
                "Can not add more stake until stakee adds more stake itself"
            );
        }
    }

    /**
     * @notice Call this function to begin the unlocking process. Calling this
     * will trigger an automatic claim of any outstanding staking rewards. Any
     * stake that was already in the unlocking phase will have the specified
     * amount added to it, and its duration refreshed. This function will fail
     * under the following conditions:
     *   - If no stake exists for the caller
     *   - If the unlock amount is zero
     *   - If the unlock amount is more than what is staked
     * Note: If calling as a Node, this function will *not* revert if it causes
     * the Node to fail to meet the minimum stake proportion. However it will still
     * prevent the Node from participating in the network until the minimum is met
     * again.
     * @param amount The amount of stake to unlock in SOLO.
     * @param stakee The address of the staked Node.
     */
    function unlockStake(uint256 amount, address stakee) external returns (uint256) {
        Stake storage stake = stakes[stakee];

        uint256 currentStake = getCurrentStakerAmount(stakee, msg.sender);

        require(currentStake > 0, "Nothing to unstake");
        require(amount > 0, "Cannot unlock with zero amount");
        require(currentStake >= amount, "Cannot unlock more than staked");

        // automatically claim any outstanding rewards generated by their existing stake
        _rewardsManager.claimStakingRewardsAsManager(stakee, msg.sender);

        uint256 currentEpochId = _epochsManager.currentIteration();

        stake.stakeEntries[msg.sender] = StakeEntry(
            currentStake - amount,
            block.number,
            currentEpochId
        );

        stake.totalManagedStake -= amount;
        totalManagedStake -= amount;

        bytes32 key = getKey(stakee, msg.sender);

        // Keep track of when the stake can be withdrawn
        Unlock storage unlock = unlockings[key];

        uint256 unlockAt = block.number + unlockDuration;
        if (unlock.unlockAt < unlockAt) {
            unlock.unlockAt = unlockAt;
        }

        unlock.amount += amount;

        return unlockAt;
    }

    /**
     * @notice Call this function to withdraw stake that has finished unlocking.
     * This will fail if the stake has not yet unlocked.
     * @param stakee The address of the staked Node.
     */
    function withdrawStake(address stakee) external {
        bytes32 key = getKey(stakee, msg.sender);

        Unlock storage unlock = unlockings[key];

        require(unlock.unlockAt < block.number, "Stake not yet unlocked");

        uint256 amount = unlock.amount;

        delete unlockings[key];

        _token.transfer(msg.sender, amount);
    }

    /**
     * @notice Call this function to cancel any stake that is in the process
     * of unlocking. As this essentially adds back stake to the Node, this
     * will trigger an automatic claim of any outstanding staking rewards.
     * If the specified amount to cancel is greater than the stake that is
     * currently being unlocked, it will cancel the maximum stake possible.
     * @param amount The amount of unlocking stake to cancel in SOLO.
     * @param stakee The address of the staked Node.
     */
    function cancelUnlocking(uint256 amount, address stakee) external {
        bytes32 key = getKey(stakee, msg.sender);

        Unlock storage unlock = unlockings[key];

        if (amount >= unlock.amount) {
            amount = unlock.amount;
            delete unlockings[key];
        } else {
            unlock.amount -= amount;
        }

        addStake_(amount, stakee);
    }

    /**
     * @notice Retrieve the key used to index a stake entry. The key is a hash
     * which takes both address of the Node and the staker as input.
     * @param stakee The address of the staked Node.
     * @param staker The address of the staker.
     * @return A byte-array representing the key.
     */
    function getKey(address stakee, address staker) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(stakee, staker));
    }

    /**
     * @notice Retrieve the total stake being managed by this contract.
     * @return The total amount of managed stake in SOLO.
     */
    function getTotalManagedStake() external view returns (uint256) {
        return totalManagedStake;
    }

    /**
     * @notice Retrieve a stake entry.
     * @param stakee The address of the staked Node.
     * @param staker The address of the staker.
     * @return The stake entry.
     */
    function getStakeEntry(address stakee, address staker) external view returns (StakeEntry memory) {
        return stakes[stakee].stakeEntries[staker];
    }

    /**
     * @notice Retrieve the current amount of SOLO staked against a Node by
     * a specified staker.
     * @param stakee The address of the staked Node.
     * @param staker The address of the staker.
     * @return The amount of staked SOLO.
     */
    function getCurrentStakerAmount(address stakee, address staker) public view returns (uint256) {
        return stakes[stakee].stakeEntries[staker].amount;
    }

    /**
     * @notice Retrieve the total amount of SOLO staked against a Node.
     * @param stakee The address of the staked Node.
     * @return The amount of staked SOLO.
     */
    function getStakeeTotalManagedStake(address stakee) external view returns (uint256) {
        return stakes[stakee].totalManagedStake;
    }

    /**
     * @notice Check if a Node is meeting the minimum stake proportion requirement.
     * @param stakee The address of the staked Node.
     * @return True if the Node is meeting minimum stake proportion requirement.
     */
    function checkMinimumStakeProportion(address stakee) public view returns (bool) {
        Stake storage stake = stakes[stakee];

        uint256 currentlyOwnedStake = stake.stakeEntries[stakee].amount;
        uint16 ownedStakeProportion = SyloUtils.asPerc(uint128(currentlyOwnedStake), stake.totalManagedStake);

        return ownedStakeProportion >= minimumStakeProportion;
    }

    /**
     * @notice This function should be called by clients to determine how much
     * additional delegated stake can be allocated to a Node via an addStake or
     * cancelUnlocking call. This is useful to avoid a revert due to
     * the minimum stake proportion requirement not being met from the additional stake.
     * @param stakee The address of the staked Node.
     */
    function calculateMaxAdditionalDelegatedStake(address stakee) external view returns (uint256) {
        Stake storage stake = stakes[stakee];

        uint256 currentlyOwnedStake = stake.stakeEntries[stakee].amount;
        uint256 totalMaxStake = currentlyOwnedStake * SyloUtils.PERCENTAGE_DENOMINATOR / minimumStakeProportion;

        require(
            totalMaxStake >= stake.totalManagedStake,
            "Can not add more delegated stake to this stakee"
        );

        return totalMaxStake - stake.totalManagedStake;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../Payments/Ticketing/Parameters.sol";
import "../Listings.sol";
import "../Staking/Directory.sol";

contract EpochsManager is Initializable, OwnableUpgradeable {

    /**
     * @dev This struct will hold all network parameters that will be static
     * for the entire epoch. This value will be stored in a mapping, where the
     * key is also the epoch's iteration value.
     */
    struct Epoch {
        uint256 iteration;

        // time related variables
        uint256 startBlock; // Block the epoch was initialized
        uint256 duration; // Minimum time epoch will be alive measured in number of blocks
        uint256 endBlock; // Block the epoch ended (and when the next epoch was initialized)
                          // Zero here represents the epoch has not yet ended.

        // listing variables
        uint16 defaultPayoutPercentage;

        // ticketing variables
        uint256 faceValue;
        uint128 baseLiveWinProb;
        uint128 expiredWinProb;
        uint256 ticketDuration;
        uint16 decayRate;
    }

    Directory public _directory;

    Listings public _listings;

    TicketingParameters public _ticketingParameters;

    // Define all Epoch specific parameters here.
    // When initializing an epoch, these parameters are read,
    // along with parameters from the other contracts to create the
    // new epoch.

    /**
     * @notice The duration in blocks an epoch will last for.
     */
    uint256 public epochDuration;

    /**
     * @notice The value of the integer used as the current
     * epoch's identifier. This value is incremented as each epoch
     * is initialized.
     */
    uint256 public currentIteration;

    /**
     * @notice A mapping of all epochs that have been initialized.
     */
    mapping (uint256 => Epoch) public epochs;

    event NewEpoch(uint256 epochId);

    function initialize(
        Directory directory,
        Listings listings,
        TicketingParameters ticketingParameters,
        uint256 _epochDuration
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        _directory = directory;
        _listings = listings;
        _ticketingParameters = ticketingParameters;
        epochDuration = _epochDuration;
        currentIteration = 0;
    }

    /**
     * @notice Call this to initialize the next epoch. This is only callable
     * by the owner of the Sylo contracts. On success, a `NewEpoch` event
     * will be emitted.
     * @dev The function will read the current set of network parameters, and store
     * the parameters in a new Epoch struct. The end block of the current epoch
     * will also be set to a non-zero value.
     */
    function initializeEpoch() external returns (uint256) {
        Epoch storage current = epochs[currentIteration];

        uint256 end = current.startBlock + current.duration;
        require(end <= block.number, "Current epoch has not yet ended");

        uint256 nextIteration = currentIteration + 1;

        Epoch memory nextEpoch = Epoch(
            nextIteration,
            block.number,
            epochDuration,
            0,
            _listings.defaultPayoutPercentage(),
            _ticketingParameters.faceValue(),
            _ticketingParameters.baseLiveWinProb(),
            _ticketingParameters.expiredWinProb(),
            _ticketingParameters.ticketDuration(),
            _ticketingParameters.decayRate()
        );

        uint256 epochId = getNextEpochId();

        _directory.setCurrentDirectory(epochId);

        epochs[epochId] = nextEpoch;
        current.endBlock = block.number;

        currentIteration = nextIteration;

        emit NewEpoch(epochId);

        return epochId;
    }

    /**
     * @notice Retrieve the parameters for the current epoch.
     * @return The current Epoch parameters.
     */
    function getCurrentActiveEpoch() external view returns (Epoch memory) {
        return epochs[currentIteration];
    }

    /**
     * @notice Nodes should call this to join the next epoch. It will
     * initialize the next reward pool and set the stake for the next directory.
     * @dev This is a proxy function for `initalizeNextRewardPool` and
     * `joinNextDirectory`.
     */
    function joinNextEpoch() external {
        _directory._rewardsManager().initializeNextRewardPool(msg.sender);
        _directory.joinNextDirectory(msg.sender);
    }

    /**
     * @notice Retrieve the integer value that will be used for the
     * next epoch id.
     * @return The next epoch id identifier.
     */
    function getNextEpochId() public view returns (uint256) {
        return currentIteration + 1;
    }

    /**
     * @notice Retrieve the epoch parameter for the given id.
     * @param epochId The id of the epoch to retrieve.
     * @return The epoch parameters associated with the id.
     */
    function getEpoch(uint256 epochId) external view returns (Epoch memory) {
        return epochs[epochId];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library SyloUtils {
    /**
     * @dev Percentages are expressed as a ratio where 10000 is the denominator.
     * A large denominator allows for more precision, e.g representing 12.5%
     * can be done as 1250 / 10000
     */
    uint16 constant public PERCENTAGE_DENOMINATOR = 10000;

    /**
     * @dev Multiply a value by a given percentage. Converts the provided
     * uint128 value to uint256 to avoid any reverts on overflow.
     * @param value The value to multiply.
     * @param percentage The percentage, as a ratio of 10000.
     */
    function percOf(uint128 value, uint16 percentage) internal pure returns (uint256) {
        return uint256(value) * percentage / PERCENTAGE_DENOMINATOR;
    }

    /**
     * @dev Return a fraction as a percentage.
     * @param numerator The numerator limited to a uint128 value to prevent
     * phantom overflow.
     * @param denominator The denominator.
     * @return The percentage, as a ratio of 10000.
     */
    function asPerc(uint128 numerator, uint256 denominator) internal pure returns(uint16) {
        return uint16(uint256(numerator) * PERCENTAGE_DENOMINATOR / denominator);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SyloToken is ERC20 {
    constructor() ERC20("Sylo", "SYLO") {
        _mint(msg.sender, 10_000_000_000 ether);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Persists the parameters for the ticketing mechanism. This contract is
 * read by the EpochManager. Extracting the parameters into another
 * contract is necessary to avoid a cyclic dependency between the ticketing
 * and epoch contracts.
 */
contract TicketingParameters is Initializable, OwnableUpgradeable {

    event FaceValueUpdated(uint256 faceValue);
    event BaseLiveWinProbUpdated(uint128 baseLiveWinprob);
    event ExpiredWinProbUpdated(uint128 expiredWinProb);
    event TicketDurationUpdated(uint256 ticketDuration);
    event DecayRateUpdated(uint16 decayRate);

    /** @notice The value of a winning ticket in SOLO. */
    uint256 public faceValue;

    /**
     * @notice The probability of a ticket winning during the start of its lifetime.
     * This is a uint128 value representing the numerator in the probability
     * ratio where 2^128 - 1 is the denominator.
     */
    uint128 public baseLiveWinProb;

    /**
     * @notice The probability of a ticket winning after it has expired.
     * This is a uint128 value representing the numerator in the probability
     * ratio where 2^128 - 1 is the denominator. Note: Redeeming expired
     * tickets is currently not supported.
     */
    uint128 public expiredWinProb;

    /**
     * @notice The length in blocks before a ticket is considered expired.
     * The default initialization value is 80,000. This equates
     * to roughly two weeks (15s per block).
     */
    uint256 public ticketDuration;

    /**
     * @notice A percentage value representing the proportion of the base win
     * probability that will be decayed once a ticket has expired.
     * Example: 80% decayRate indicates that a ticket will decay down to 20% of its
     * base win probability upon reaching the block before its expiry.
     * The value is expressed as a fraction of 10000.
     */
    uint16 public decayRate;

    function initialize(
        uint256 _faceValue,
        uint128 _baseLiveWinProb,
        uint128 _expiredWinProb,
        uint16 _decayRate,
        uint256 _ticketDuration
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        faceValue = _faceValue;
        baseLiveWinProb = _baseLiveWinProb;
        expiredWinProb = _expiredWinProb;
        decayRate = _decayRate;

        require(_ticketDuration > 0, "Ticket duration cannot be 0");
        ticketDuration = _ticketDuration;
    }

    /**
     * @notice Set the face value for tickets in SOLO. Only callable by
     * the contract owner.
     * @param _faceValue The face value to set in SOLO.
     */
    function setFaceValue(uint256 _faceValue) external onlyOwner {
        faceValue = _faceValue;
        emit FaceValueUpdated(_faceValue);
    }

    /**
     * @notice Set the base live win probability of a ticket. Only callable by
     * the contract owner.
     * @param _baseLiveWinProb The probability represented as a value
     * between 0 to 2**128 - 1.
     */
    function setBaseLiveWinProb(uint128 _baseLiveWinProb) external onlyOwner {
        baseLiveWinProb = _baseLiveWinProb;
        emit BaseLiveWinProbUpdated(_baseLiveWinProb);
    }

    /**
     * @notice Set the expired win probability of a ticket. Only callable by
     * the contract owner.
     * @param _expiredWinProb The probability represented as a value
     * between 0 to 2**128 - 1.
     */
    function setExpiredWinProb(uint128 _expiredWinProb) external onlyOwner {
        expiredWinProb = _expiredWinProb;
        emit ExpiredWinProbUpdated(_expiredWinProb);
    }

    /**
     * @notice Set the decay rate of a ticket. Only callable by the
     * the contract owner.
     * @param _decayRate The decay rate as a percentage, where the
     * denominator is 10000.
     */
    function setDecayRate(uint16 _decayRate) external onlyOwner {
        decayRate = _decayRate;
        emit DecayRateUpdated(_decayRate);
    }

    /**
     * @notice Set the ticket duration of a ticket. Only callable by the
     * contract owner.
     * @param _ticketDuration The duration of a ticket in number of blocks.
     */
    function setTicketDuration(uint256 _ticketDuration) external onlyOwner {
        require(_ticketDuration > 0, "Ticket duration cannot be 0");
        ticketDuration = _ticketDuration;
        emit TicketDurationUpdated(_ticketDuration);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice This contract manages Listings for Nodes. A Listing is a
 * set of parameters configured by the Node itself. A Node is required
 * to have a valid Listing to be able to participate in the network.
 */
contract Listings is Initializable, OwnableUpgradeable {

    struct Listing {
        // MultiAddr to connect to the account
        string multiAddr;

        // Percentage of a tickets value that will be rewarded to
        // delegated stakers expressed as a fraction of 10000.
        // This value is currently locked to the default payout percentage
        // until epochs are implemented.
        uint16 payoutPercentage;

        // The minimum amount of stake that is required to
        // add a delegated stake against this node
        uint256 minDelegatedStake;

        // Explicit property to check if an instance of this struct actually exists
        bool initialized;
    }

    /**
     * @notice Tracks each Node's listing.
     */
    mapping(address => Listing) public listings;

    event DefaultPayoutPercentageUpdated(uint16 defaultPayoutPercentage);

    /**
     * @notice Payout percentage refers to the portion of a tickets reward
     * that will be allocated to the Node's stakers. This is global, and is
     * currently set for all Nodes.
     */
    uint16 public defaultPayoutPercentage;

    function initialize(uint16 _defaultPayoutPercentage) external initializer {
        OwnableUpgradeable.__Ownable_init();
        require(
            _defaultPayoutPercentage <= 10000,
            "The payout percentage can not exceed 100 percent"
        );
        defaultPayoutPercentage = _defaultPayoutPercentage;
    }

    /**
     * @notice Set the global default payout percentage value. Only callable
     * by the owner.
     * @param _defaultPayoutPercentage The payout percentage as a value where the
     * denominator is 10000.
     */
    function setDefaultPayoutPercentage(uint16 _defaultPayoutPercentage) external onlyOwner {
        require(
            _defaultPayoutPercentage <= 10000,
            "The payout percentage can not exceed 100 percent"
        );
        defaultPayoutPercentage = _defaultPayoutPercentage;
        emit DefaultPayoutPercentageUpdated(_defaultPayoutPercentage);
    }

    /**
     * @notice Call this as a Node to set or update your Listing entry.
     * @param multiAddr The libp2p multiAddr of your Node. Essential for
     * clients to be able to establish a p2p connection.
     * @param minDelegatedStake The minimum amount of stake in SOLO that
     * a staker must add when calling StakingManager.addStake.
     */
    function setListing(string memory multiAddr, uint256 minDelegatedStake) external {
        require(bytes(multiAddr).length != 0, "Multiaddr string is empty");

        // TODO Remove defaultPayoutPercentage once epochs are introduced
        Listing memory listing = Listing(multiAddr, defaultPayoutPercentage, minDelegatedStake, true);
        listings[msg.sender] = listing;
    }

    /**
     * @notice Retrieve the listing associated with a Node.
     * @param account The address of the Node.
     * @return The Node's Listing.
     */
    function getListing(address account) external view returns (Listing memory) {
        return listings[account];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Manager.sol";
import "../Payments/Ticketing/RewardsManager.sol";
import "../Utils.sol";
import "../Manageable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice The Directory contract constructs and manages a structure holding the current stakes,
 * which is queried against using the scan function. The scan function allows submitting
 * random points which will return a staked node's address in proportion to the stake it has.
 */
contract Directory is Initializable, OwnableUpgradeable, Manageable {
    /** Sylo Staking Manager contract */
    StakingManager public _stakingManager;

    /** Sylo Rewards Manager contract */
    RewardsManager public _rewardsManager;

    struct DirectoryEntry {
        address stakee;
        uint256 boundary;
    }

    /**
     * @dev A Directory will be stored for every epoch. The directory will be
     * constructed piece by piece as Nodes join, each adding their own
     * directory entry based on their current stake value.
     */
    struct Directory {
        DirectoryEntry[] entries;

        mapping (address => uint256) stakes;

        uint256 totalStake;
    }

    event CurrentDirectoryUpdated(uint256 currentDirectory);

    /**
     * @notice The epoch ID of the current directory.
     */
    uint256 public currentDirectory;

    /**
     * @notice Tracks every directory, which will be indexed by an epoch ID
     */
    mapping (uint256 => Directory) public directories;

    function initialize(
        StakingManager stakingManager,
        RewardsManager rewardsManager
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        _stakingManager = stakingManager;
        _rewardsManager = rewardsManager;
    }

    /**
     * @notice This function should be called when a new epoch is initialized.
     * This will set the current directory to the specified epoch. This is only
     * callable by the owner of this contract, which should be the EpochsManager
     * contract.
     * @dev After deployment, the EpochsManager should immediately be set as
     * the owner.
     * @param epochId The ID of the specified epoch.
     */
    function setCurrentDirectory(uint256 epochId) external onlyManager {
        currentDirectory = epochId;
        emit CurrentDirectoryUpdated(epochId);
    }

    /**
     * @notice This function is called by a node as a prerequisite to participate in the next epoch.
     * @dev This will construct the directory as nodes join. The directory is constructed
     * by creating a boundary value which is a sum of the current directory's total stake, and
     * the current stakee's total stake, and pushing the new boundary into the entries array.
     * The previous boundary and the current boundary essentially create a range, where if a
     * random point were to fall within that range, it would belong to the respective stakee.
     * The boundary value grows in size as each stakee joins, thus the directory array
     * always remains sorted. This allows us to perform a binary search on the directory.
     *
     * Example
     *
     * Stakes: [ Alice/20, Bob/10, Carl/40, Dave/25 ]
     * TotalStake: 95
     *
     * Directory:
     *
     *  |-----------|------|----------------|--------|
     *     Alice/20  Bob/30     Carl/70      Dave/95
     */
    function joinNextDirectory(address stakee) external onlyManager {
        uint256 managedStake = _stakingManager.getStakeeTotalManagedStake(stakee);
        uint256 stakeReward = _rewardsManager.unclaimedStakeRewards(stakee);
        uint256 totalStake = managedStake + stakeReward;
        require(totalStake > 0, "Can not join directory for next epoch without any stake");
        require(
            _stakingManager.checkMinimumStakeProportion(stakee),
            "Can not join directory without owning minimum amount of stake"
        );

        uint256 epochId = currentDirectory + 1;

        require(
            directories[epochId].stakes[stakee] == 0,
            "Can only join the directory once per epoch"
        );

        uint256 nextBoundary = directories[epochId].totalStake + totalStake;

        directories[epochId].entries.push(DirectoryEntry(stakee, nextBoundary));
        directories[epochId].stakes[stakee] = totalStake;
        directories[epochId].totalStake = nextBoundary;
    }

    /**
     * @notice Call this to perform a stake-weighted scan to find the Node assigned
     * to the given point.
     * @dev The current implementation will perform a binary search through
     * the directory. This can allow gas costs to be low if this needs to be
     * used in a transaction.
     * @param point The point, which will usually be a hash of a public key.
     */
    function scan(uint128 point) external view returns (address stakee) {
        if (directories[currentDirectory].entries.length == 0) {
            return address(0);
        }

        // Staking all the Sylo would only be 94 bits, so multiplying this with
        // a uint128 cannot overflow a uint256.
        uint256 expectedVal = directories[currentDirectory].totalStake * uint256(point) >> 128;

        uint256 left = 0;
        uint256 right = directories[currentDirectory].entries.length - 1;

        // perform a binary search through the directory
        while (left <= right) {
            uint index = (left + right) / 2;

            uint lower = index == 0 ? 0 : directories[currentDirectory].entries[index - 1].boundary;
            uint upper = directories[currentDirectory].entries[index].boundary;

            if (expectedVal >= lower && expectedVal < upper) {
                return directories[currentDirectory].entries[index].stakee;
            } else if (expectedVal < lower) {
                right = index - 1;
            } else {  // expectedVal >= upper
                left = index + 1;
            }
        }
    }

    /**
     * @notice Retrieve the total stake a Node has for the directory in the
     * specified epoch.
     * @param epochId The ID of the epoch.
     * @param stakee The address of the Node.
     * @return The amount of stake the Node has for the given directory in SOLO.
     */
    function getTotalStakeForStakee(uint256 epochId, address stakee) external view returns (uint256) {
        return directories[epochId].stakes[stakee];
    }

    /**
     * @notice Retrieve the total stake for a directory in the specified epoch, which
     * will be the sum of the stakes for all Nodes participating in that epoch.
     * @param epochId The ID of the epoch.
     * @return The total amount of stake in SOLO.
     */
    function getTotalStake(uint256 epochId) external view returns (uint256) {
        return directories[epochId].totalStake;
    }

    /**
     * @notice Retrieve all entries for a directory in a specified epoch.
     * @return An array of all the directory entries.
     */
    function getEntries(uint256 epochId) external view returns (address[] memory, uint256[] memory) {
        address[] memory stakees = new address[](directories[epochId].entries.length);
        uint256[] memory boundaries = new uint256[](directories[epochId].entries.length);
        for (uint i = 0; i < directories[epochId].entries.length; i++) {
            DirectoryEntry memory entry = directories[epochId].entries[i];
            stakees[i] = entry.stakee;
            boundaries[i] = entry.boundary;
        }
        return (stakees, boundaries);
    }
}