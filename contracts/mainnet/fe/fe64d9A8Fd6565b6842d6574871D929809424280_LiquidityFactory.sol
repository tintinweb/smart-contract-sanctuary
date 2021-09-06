/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;


library SafeMathLib {
  function times(uint a, uint b) public pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b, 'Overflow detected');
    return c;
  }

  function minus(uint a, uint b) public pure returns (uint) {
    require(b <= a, 'Underflow detected');
    return a - b;
  }

  function plus(uint a, uint b) public pure returns (uint) {
    uint c = a + b;
    require(c>=a && c>=b, 'Overflow detected');
    return c;
  }

}



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


// This contract is inspired by the harberger tax idea, it rewards people with FVT for burning their liquidity provider
// tokens.
contract LiquidityFactory {
    using SafeMathLib for uint;

    // this represents a single recipient of token rewards on a fixed schedule that does not depend on deposit or burn rate
    // it specifies an id (key to a map below) an marker for the last time it was updated, a deposit (of LP tokens) and a
    // burn rate of those LP tokens per block, and finally, the owner of the slot, who will receive the rewards
    struct Slot {
        uint id;
        uint lastUpdatedBlock;
        uint vacatedBlock;
        uint depositWei;
        uint burnRateWei;
        address owner;
    }

    // rewardToken: the token that the rewards are made in
    // liquidityToken: the liquidity provider (LP) token
    // taxAddress: address to which taxes are sent
    struct Pool {
        uint id;
        address liquidityToken;
        address taxAddress;
        address poolOwner;
        uint maxStakers;
        uint minimumDepositWei;
        uint maximumDepositWei;
        uint minimumBurnRateWeiPerBlock;
        uint maximumBurnRateWeiPerBlock;
        mapping (uint => Slot) slots;
    }

    struct Metadata {
        bytes32 name;
        bytes32 ipfsHash;
    }

    struct Pulse {
        address rewardToken1;
        address rewardToken2;
        uint pulseStartBlock;
        uint pulseWavelengthBlocks;
        uint pulseAmplitudeWei;
        uint pulseIntegral;
        uint pulseConstant;
        uint reward2WeiPerBlock;
    }

    struct PoolStats {
        uint totalStakedWei;
        uint totalRewardsWei;
        uint totalBurnedWei;
        uint depositDecayWeiPerBlock; // decay only applies to vacated slots
        uint burnRateDecayWeiPerBlock; // decay only applies to vacated slots
        bool paused;
        uint pausedBlock;
        uint unpausedBlock;
        uint pausedStakers;
        uint numSynced; // only used while paused
        uint numStakers;
        mapping (address => uint) totalStakedWeiFor;
        mapping (address => uint) totalRewardsWeiFor;
        mapping (address => uint) totalBurnedWeiFor;
        mapping (uint => uint) rewards1WeiForSession;
    }

    uint public numPools;
    mapping (uint => Pool) public pools;
    mapping (uint => Metadata) public metadatas;
    mapping (uint => PoolStats) public poolStats;
    mapping (uint => Pulse) public pulses;

    // privileged key that can change key parameters, will change to dao later
    address public management;

    event SlotChangedHands(uint indexed poolId, address indexed newOwner, address indexed previousOwner, uint slotId, uint depositWei, uint burnRateWei, uint rewards1WeiForSession);
    event PoolAdded(uint indexed poolId, bytes32 indexed name, address indexed depositToken);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    modifier poolOwnerOnly(uint poolId) {
        Pool storage pool = pools[poolId];
        require (msg.sender == pool.poolOwner, 'Only pool owner may call this');
        _;
    }

    modifier initializedPoolOnly(uint poolId) {
        Pool storage pool = pools[poolId];
        require(pool.id == poolId && poolId > 0, 'Uninitialized pool');
        _;
    }

    modifier pausedAndSynced(uint poolId) {
        PoolStats storage stats = poolStats[poolId];
        require (stats.paused, 'Must be paused');
        require (stats.numSynced == stats.pausedStakers, 'Must sync all users');
        _;
    }

    constructor(address mgmt) {
        management = mgmt;
    }

    function addPool(
        address rewardToken1Addr,
        address rewardToken2Addr,
        address liquidityTokenAddr,
        address taxAddr,
        address poolOwner,
        uint rewardPerBlock2Wei,
        uint pulseStartDelayBlocks,
        bytes32 ipfsHash,
        bytes32 name) managementOnly external {
        numPools = numPools.plus(1);
        {
            Pool storage pool = pools[numPools];
            pool.id = numPools;
            pool.liquidityToken = liquidityTokenAddr;
            pool.taxAddress = taxAddr;
            pool.poolOwner = poolOwner;
        }
        {
            Metadata storage metadata = metadatas[numPools];
            metadata.ipfsHash = ipfsHash;
            metadata.name = name;
        }
        {
            Pulse storage pulse = pulses[numPools];
            pulse.rewardToken1 = rewardToken1Addr;
            pulse.rewardToken2 = rewardToken2Addr;
            pulse.pulseStartBlock = block.number + pulseStartDelayBlocks;
            pulse.reward2WeiPerBlock = rewardPerBlock2Wei;
        }
        {
            PoolStats storage stats = poolStats[numPools];
            stats.paused = true;
            stats.pausedBlock = block.number;
//            stats.pausedStakers = 0;
//            stats.unpausedBlock = 0;
        }

        emit PoolAdded(numPools, name, liquidityTokenAddr);
    }

    function getRewards(uint poolId, uint slotId) public view returns (uint, uint) {
        Slot storage slot = pools[poolId].slots[slotId];

        // unoccupied slots have no rewards
        if (slot.owner == address(0)) {
            return (0, 0);
        }

        return (getRewards1(poolId, slotId), getRewards2(poolId, slotId));
    }

    function getRewards2(uint poolId, uint slotId) internal view returns (uint) {
        Pulse storage pulse = pulses[poolId];

        (uint referenceBlock1, uint referenceBlock2) = getReferenceBlocks(poolId, slotId);
        // rewards2 is linear with time, probably very small amount as advertising
        uint rewards2 = referenceBlock2.minus(referenceBlock1).times(pulse.reward2WeiPerBlock);
        return rewards2;
    }

    // compute the undistributed rewards for a slot
    function getRewards1(uint poolId, uint slotId) internal view initializedPoolOnly(poolId) returns (uint) {

        (uint referenceBlock1, uint referenceBlock2) = getReferenceBlocks(poolId, slotId);

        // three parts, incomplete beginning, incomplete end and complete middle
        Pulse storage pulse = pulses[poolId];
        uint rewards1;

        // complete middle
        // trim off overhang on both ends
        uint startPhase = referenceBlock1.minus(pulse.pulseStartBlock) % pulse.pulseWavelengthBlocks;
        uint startOverhang = pulse.pulseWavelengthBlocks.minus(startPhase);

        uint blocksDiffTotal = referenceBlock2.minus(referenceBlock1);

        uint endPhase = referenceBlock2.minus(pulse.pulseStartBlock) % pulse.pulseWavelengthBlocks;
        uint endingBlocks = pulse.pulseWavelengthBlocks.minus(endPhase);
        uint leftoverSum = pulseSum(pulse.pulseConstant, endingBlocks);
        // if we haven't made it to phase 0 yet
        if (blocksDiffTotal < startOverhang) {
            uint startSum = pulseSum(pulse.pulseConstant, startOverhang);
            rewards1 = startSum.minus(leftoverSum);
        } else {
            uint blocksDiff = blocksDiffTotal.minus(endPhase).minus(startOverhang);
            uint wavelengths = blocksDiff / pulse.pulseWavelengthBlocks;
            rewards1 = wavelengths.times(pulse.pulseIntegral);

            // incomplete beginning of reward cycle, end of pulse
            if (startPhase > 0) {
                rewards1 = rewards1.plus(pulseSum(pulse.pulseConstant, startOverhang));
            }

            // incomplete ending of reward cycle, beginning of pulse
            if (endPhase > 0) {
                rewards1 = rewards1.plus(pulse.pulseIntegral.minus(leftoverSum));
            }
        }

        return rewards1;
    }

    // compute the unapplied burn to the deposit
    function getBurn(uint poolId, uint slotId) public view initializedPoolOnly(poolId) returns (uint) {
        Slot storage slot = pools[poolId].slots[slotId];
        (uint referenceBlock1, uint referenceBlock2) = getReferenceBlocks(poolId, slotId);
        uint burn = slot.burnRateWei.times(referenceBlock2.minus(referenceBlock1));
        if (burn > slot.depositWei) {
            burn = slot.depositWei;
        }
        return burn;
    }

    // this must be idempotent, it syncs both the rewards and the deposit burn atomically, and updates lastUpdatedBlock
    function updateSlot(uint poolId, uint slotId) public initializedPoolOnly(poolId) {
        Pool storage pool = pools[poolId];
        PoolStats storage stats = poolStats[poolId];
        Slot storage slot = pool.slots[slotId];
        require(slot.owner != address(0), 'Unoccupied slot');

        // prevent multiple updates on same slot while paused
        if (stats.paused) {
            // these two requires prevent weird double updates that might make numSynced too high
            // it also means that if someone updates you while paused you cannot withdraw...
            require(block.number > stats.pausedBlock, 'Do not call this in the same block that you paused');
            require(slot.lastUpdatedBlock <= stats.pausedBlock, 'If pool is paused, can only update slot once');
            require(msg.sender == pool.poolOwner || msg.sender == slot.owner, 'If pool is paused, only pool owner or slot owner may call this');
            stats.numSynced = stats.numSynced.plus(1);
        }

        Pulse storage pulse = pulses[poolId];
        (uint rewards1, uint rewards2) = getRewards(poolId, slotId);

        // burn and rewards always have to update together, since they both depend on lastUpdatedBlock
        uint burn = getBurn(poolId, slotId);

        // update this first to make burn and reward zero in the case of re-entrance
        // this must happen after getting rewards and burn since they depend on this var
        slot.lastUpdatedBlock = block.number;

        if (rewards1 > 0) {
            // bookkeeping
            stats.totalRewardsWei = stats.totalRewardsWei.plus(rewards1);
            stats.totalRewardsWeiFor[slot.owner] = stats.totalRewardsWeiFor[slot.owner].plus(rewards1);
            stats.rewards1WeiForSession[slotId] = stats.rewards1WeiForSession[slotId].plus(rewards1);

            // transfer the rewards
            require(IERC20(pulse.rewardToken1).transfer(slot.owner, rewards1), 'Token transfer failed');
        }

        if (rewards2 > 0) {
            require(IERC20(pulse.rewardToken2).transfer(slot.owner, rewards2), 'Token transfer failed');
        }

        if (burn > 0) {
            // adjust deposit first
            slot.depositWei = slot.depositWei.minus(burn);

            // bookkeeping
            stats.totalBurnedWei = stats.totalBurnedWei.plus(burn);
            stats.totalBurnedWeiFor[slot.owner] = stats.totalBurnedWeiFor[slot.owner].plus(burn);

            // pay the tax!
            require(IERC20(pool.liquidityToken).transfer(pool.taxAddress, burn), 'Token transfer failed');
        }
    }

    // most important function for users, allows them to start receiving rewards
    function claimSlot(uint poolId, uint slotId, uint newBurnRate, uint newDeposit) external {
        Pool storage pool = pools[poolId];
        PoolStats storage stats = poolStats[poolId];
        require(slotId > 0, 'Slot id must be positive');
        require(slotId <= pool.maxStakers, 'Slot id out of range');
        require(newBurnRate >= pool.minimumBurnRateWeiPerBlock, 'Burn rate must meet or exceed minimum');
        require(newBurnRate <= pool.maximumBurnRateWeiPerBlock, 'Burn rate must not exceed maximum');
        require(newDeposit >= pool.minimumDepositWei, 'Deposit must meet or exceed minimum');
        require(newDeposit <= pool.maximumDepositWei, 'Deposit must not exceed maximum');
        require(stats.paused == false, 'Must be unpaused');
        require(pool.id == poolId && poolId > 0, 'Uninitialized pool');
        {
            Pulse storage pulse = pulses[poolId];
            require(pulse.pulseStartBlock <= block.number, 'Pool has not started yet');
        }
        Slot storage slot = pool.slots[slotId];

        // count the stakers
        if (slot.owner == address(0)) {
            // assign id since this may be the first time
            slot.id = slotId;

            // set last updated block, this happens in updateSlot but that's the other branch
            slot.lastUpdatedBlock = block.number;

            // check that we meet-or-exceed the linearly-decayed deposit and burn rates
            (uint depositMin, uint burnRateMin) = getClaimMinimums(poolId, slotId);
            bool betterDeal = newBurnRate >= burnRateMin && newDeposit >= depositMin;
            require(betterDeal, 'You must meet or exceed the current burn rate and deposit');

            // increment counter
            stats.numStakers = stats.numStakers.plus(1);

        } else {
            updateSlot(poolId, slotId);

            //  this must go after updateSlot to sync the deposit variable
            bool betterDeal = newBurnRate > slot.burnRateWei && (newDeposit > slot.depositWei || newDeposit == pool.maximumDepositWei);
            require(betterDeal || slot.depositWei == 0, 'You must outbid the current owner');

            // bookkeeping
            stats.totalStakedWei = stats.totalStakedWei.minus(slot.depositWei);
            stats.totalStakedWeiFor[slot.owner] = stats.totalStakedWeiFor[slot.owner].minus(slot.depositWei);

            // this is probably not necessary, but we do it to be tidy
            slot.vacatedBlock = 0;

            // if there's any deposit left,
            if (slot.depositWei > 0) {
                require(IERC20(pool.liquidityToken).transfer(slot.owner, slot.depositWei), 'Token transfer failed');
            }
        }

        emit SlotChangedHands(poolId, msg.sender, slot.owner, slotId, newDeposit, newBurnRate, stats.rewards1WeiForSession[slotId]);
        stats.rewards1WeiForSession[slotId] = 0;

        // set new owner, burn rate and deposit
        slot.owner = msg.sender;
        slot.burnRateWei = newBurnRate;
        slot.depositWei = newDeposit;

        // bookkeeping
        stats.totalStakedWei = stats.totalStakedWei.plus(newDeposit);
        stats.totalStakedWeiFor[msg.sender] = stats.totalStakedWeiFor[msg.sender].plus(newDeposit);

        // transfer the tokens!
        if (newDeposit > 0) {
            require(IERC20(pool.liquidityToken).transferFrom(msg.sender, address(this), newDeposit), 'Token transfer failed');
        }
    }

    // separates user from slot, if either voluntary or delinquent
    function withdrawFromSlot(uint poolId, uint slotId) external initializedPoolOnly(poolId) {
        Pool storage pool = pools[poolId];

        PoolStats storage stats = poolStats[poolId];
        Slot storage slot = pool.slots[slotId];

        // prevent double-withdrawals
        require(slot.owner != address(0), 'Slot unoccupied');

        // sync deposit variable (this increments numSynced)
        updateSlot(poolId, slotId);

        // anyone can withdraw delinquents, but non-delinquents can only be withdrawn by themselves
        bool withdrawable = slot.owner == msg.sender || slot.depositWei == 0;
        require(withdrawable, 'Only owner can call this unless user is delinquent');

        // must do this before rewards1WeiForSession gets zeroed out
        emit SlotChangedHands(poolId, address(0), slot.owner, slotId, 0, 0, stats.rewards1WeiForSession[slotId]);
        stats.rewards1WeiForSession[slotId] = 0;

        // decrement the number of stakers
        stats.numStakers = stats.numStakers.minus(1);

        // record what block we vacated in to compute linear decay
        slot.vacatedBlock = block.number;

        // zero out owner, closing re-entrance gate
        address owner = slot.owner;
        slot.owner = address(0);

        // don't set deposit or burn rate to 0 so we can compute linear decay

        // if there's any deposit left,
        if (slot.depositWei > 0) {
            require(IERC20(pool.liquidityToken).transfer(owner, slot.depositWei), 'Token transfer failed');
        }
    }

    // ======================== PAUSE =============================

    function pausePool(uint poolId) external poolOwnerOnly(poolId) initializedPoolOnly(poolId) {
        PoolStats storage stats = poolStats[poolId];
        require(stats.paused == false, 'Already paused');
        stats.paused = true;
        stats.pausedBlock = block.number;
        stats.pausedStakers = stats.numStakers;
        stats.unpausedBlock = 0;
    }

    function unpausePool(uint poolId) external poolOwnerOnly(poolId) pausedAndSynced(poolId) {
        PoolStats storage stats = poolStats[poolId];
        stats.paused = false;
        stats.pausedBlock = 0;
        stats.numSynced = 0;
        stats.pausedStakers = 0;
        stats.unpausedBlock = block.number;
    }

    // ======================== GETTERS =============================

    function getClaimMinimums(uint poolId, uint slotId) public view returns (uint, uint) {
        Slot memory slot = pools[poolId].slots[slotId];
        if (slot.owner != address(0)) {
            return (slot.depositWei, slot.burnRateWei);
        } else {
            PoolStats storage stats = poolStats[poolId];
            uint blocksDiff = block.number.minus(slot.vacatedBlock);
            uint depositDecay = blocksDiff.times(stats.depositDecayWeiPerBlock);
            if (depositDecay > slot.depositWei) {
                depositDecay = slot.depositWei;
            }

            uint burnRateDecay = blocksDiff.times(stats.burnRateDecayWeiPerBlock);
            if (burnRateDecay > slot.burnRateWei) {
                burnRateDecay = slot.burnRateWei;
            }

            return (slot.depositWei.minus(depositDecay), slot.burnRateWei.minus(burnRateDecay));
        }
    }

    function getSlot(uint poolId, uint slotId) external view returns (uint, uint, uint, uint, uint, address) {
        Slot memory slot = pools[poolId].slots[slotId];
        PoolStats storage stats = poolStats[poolId];
        return (slot.lastUpdatedBlock, slot.depositWei, slot.burnRateWei, stats.rewards1WeiForSession[slotId], slot.vacatedBlock, slot.owner);
    }

    function getUserStats(uint poolId, address user) external view returns (uint, uint, uint) {
        PoolStats storage stats = poolStats[poolId];
        return (stats.totalStakedWeiFor[user], stats.totalRewardsWeiFor[user], stats.totalBurnedWeiFor[user]);
    }

    function getReferenceBlocks(uint poolId, uint slotId) internal view returns (uint, uint) {
        Pool storage pool = pools[poolId];
        PoolStats storage stats = poolStats[poolId];
        Slot memory slot = pool.slots[slotId];

        uint referenceBlock1 = slot.lastUpdatedBlock;
        uint referenceBlock2 = block.number;
        if (stats.paused) {
            referenceBlock2 = stats.pausedBlock;
        } else if (slot.lastUpdatedBlock < stats.unpausedBlock) {
            referenceBlock1 = stats.unpausedBlock;
        }

        return (referenceBlock1, referenceBlock2);
    }

    // compute the sum of the rewards per pulse
    function pulseSum(uint coeff, uint wavelength) public pure returns (uint) {
        // sum of squares formula
        return coeff.times(wavelength.times(wavelength.plus(1))).times(wavelength.times(2).plus(1)) / 6;
    }

    // ======================== SETTERS =============================

    function setConfig(
        uint poolId,
        uint newMaxStakers,
        uint newMinDeposit,
        uint newMaxDeposit,
        uint newMinBurnRate,
        uint newMaxBurnRate,
        uint newWavelength,
        uint newAmplitude) external poolOwnerOnly(poolId) pausedAndSynced(poolId) {
        Pool storage pool = pools[poolId];
        pool.maxStakers = newMaxStakers;
        pool.minimumDepositWei = newMinDeposit;
        pool.maximumDepositWei = newMaxDeposit;
        pool.minimumBurnRateWeiPerBlock = newMinBurnRate;
        pool.maximumBurnRateWeiPerBlock = newMaxBurnRate;

        Pulse storage pulse = pulses[poolId];
        pulse.pulseWavelengthBlocks = newWavelength;
        pulse.pulseAmplitudeWei = newAmplitude;
        pulse.pulseConstant = pulse.pulseAmplitudeWei / pulse.pulseWavelengthBlocks.times(pulse.pulseWavelengthBlocks);
        pulse.pulseIntegral = pulseSum(pulse.pulseConstant, newWavelength);
    }

    // only management can reset management key
    function setManagement(address newMgmt) managementOnly external {
        management = newMgmt;
    }

    // only management can change tax address
    function setTaxAddress(uint poolId, address newTaxAddress) managementOnly external {
        Pool storage pool = pools[poolId];
        pool.taxAddress = newTaxAddress;
    }

    function setReward2PerBlock(uint poolId, uint newReward) managementOnly external {
        Pulse storage pulse = pulses[poolId];
        pulse.reward2WeiPerBlock = newReward;
    }

    // only management can change pool owner key
    function setPoolOwner(uint poolId, address newOwner) managementOnly external {
        Pool storage pool = pools[poolId];
        pool.poolOwner = newOwner;
    }

    function setDecays(uint poolId, uint burnRateDecayWeiPerBlock, uint depositDecayWeiPerBlock) external poolOwnerOnly(poolId) initializedPoolOnly(poolId)  {
        PoolStats storage stats = poolStats[poolId];
        stats.burnRateDecayWeiPerBlock = burnRateDecayWeiPerBlock;
        stats.depositDecayWeiPerBlock = depositDecayWeiPerBlock;
    }

}