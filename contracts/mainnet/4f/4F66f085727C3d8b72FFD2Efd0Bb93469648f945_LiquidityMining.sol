/**
 *Submitted for verification at Etherscan.io on 2021-05-17
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
interface Token {
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
contract LiquidityMining {
    using SafeMathLib for uint;

    // this represents a single recipient of token rewards on a fixed schedule that does not depend on deposit or burn rate
    // it specifies an id (key to a map below) an marker for the last time it was updated, a deposit (of LP tokens) and a
    // burn rate of those LP tokens per block, and finally, the owner of the slot, who will receive the rewards
    struct Slot {
        uint id;
        uint lastUpdatedBlock;
        uint deposit;
        uint burnRate;
        address owner;
    }

    // privileged key that can change key parameters, will change to dao later
    address public management;

    // the token that the rewards are made in
    Token public rewardToken;

    // the liquidity provider (LP) token
    Token public liquidityToken;

    // address to which taxes are sent
    address public taxAddress;

    // is the contract paused?
    bool public paused = false;

    // when was the contract paused?
    uint public pausedBlock = 0;

    // maximum number of slots, changeable by management key
    uint public maxStakers = 0;

    // current number of stakers
    uint public numStakers = 0;

    // minimum deposit allowable to claim a slot
    uint public minimumDeposit = 0;

    // maximum deposit allowable (used to limit risk)
    uint public maximumDeposit = 1000 ether;

    // minimum burn rate allowable to claim a slot
    uint public minimumBurnRate = 0;

    // total liquidity tokens staked
    uint public totalStaked = 0;

    // total rewards distributed
    uint public totalRewards = 0;

    // total LP tokens burned
    uint public totalBurned = 0;

    // start block used to compute rewards
    uint public pulseStartBlock;

    // the length of a single pulse of rewards, in blocks
    uint public pulseWavelengthBlocks = 0;

    // the amount of the highest per-block reward, in FVT
    uint public pulseAmplitudeFVT = 0;

    // computed constants for deferred computation
    uint public pulseIntegral = 0;
    uint public pulseConstant = 0;

    // map of slot ids to slots
    mapping (uint => Slot) public slots;

    // map of addresses to amount staked
    mapping (address => uint) public totalStakedFor;

    // map of total rewards by address
    mapping (address => uint) public totalRewardsFor;

    // map of rewards for session slotId -> rewardsForThisSession
    mapping (uint => uint) public rewardsForSession;

    // map of total burned by address
    mapping (address => uint) public totalBurnedFor;

    event ManagementUpdated(address oldMgmt, address newMgmt);
    event ContractPaused();
    event ContractUnpaused();
    event WavelengthUpdated(uint oldWavelength, uint newWavelength);
    event AmplitudeUpdated(uint oldAmplitude, uint newAmplitude);
    event MaxStakersUpdated(uint oldMaxStakers, uint newMaxStakers);
    event MinDepositUpdated(uint oldMinDeposit, uint newMinDeposit);
    event MaxDepositUpdated(uint oldMaxDeposit, uint newMaxDeposit);
    event MinBurnRateUpdated(uint oldMinBurnRate, uint newMinBurnRate);
    event SlotChangedHands(uint slotId, uint deposit, uint burnRate, address owner);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(
        address rewardTokenAddr,
        address liquidityTokenAddr,
        address mgmt,
        address taxAddr,
        uint pulseLengthBlocks,
        uint pulseAmplitude,
        uint mxStkrs) {
        rewardToken = Token(rewardTokenAddr);
        liquidityToken = Token(liquidityTokenAddr);
        management = mgmt;
        pulseStartBlock = block.number;
        pulseWavelengthBlocks = pulseLengthBlocks;
        pulseAmplitudeFVT = pulseAmplitude;
        pulseConstant = pulseAmplitudeFVT / pulseWavelengthBlocks.times(pulseWavelengthBlocks);
        pulseIntegral = pulseSum(pulseWavelengthBlocks);
        maxStakers = mxStkrs;
        taxAddress = taxAddr;
    }

    // only management can reset management key
    function setManagement(address newMgmt) public managementOnly {
        address oldMgmt = management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }

    function pauseContract() public managementOnly {
        require(paused == false, 'Already paused');
        paused = true;
        pausedBlock = block.number;
        emit ContractPaused();
    }

    function unpauseContract() public managementOnly {
        require(paused == true, 'Already unpaused');
        require(numStakers == 0, 'Must kick everyone out before unpausing');
        paused = false;
        pausedBlock = 0;
        emit ContractUnpaused();
    }

    // change the number of slots, should be done with care
    function setMaxStakers(uint newMaxStakers) public managementOnly {
        uint oldMaxStakers = maxStakers;
        maxStakers = newMaxStakers;
        emit MaxStakersUpdated(oldMaxStakers, maxStakers);
    }

    // change the minimum deposit to acquire a slot
    function setMinDeposit(uint newMinDeposit) public managementOnly {
        uint oldMinDeposit = minimumDeposit;
        minimumDeposit = newMinDeposit;
        emit MinDepositUpdated(oldMinDeposit, newMinDeposit);
    }

    // change the maximum deposit
    function setMaxDeposit(uint newMaxDeposit) public managementOnly {
        uint oldMaxDeposit = maximumDeposit;
        maximumDeposit = newMaxDeposit;
        emit MaxDepositUpdated(oldMaxDeposit, newMaxDeposit);
    }

    // change the minimum burn rate to acquire a slot
    function setMinBurnRate(uint newMinBurnRate) public managementOnly {
        uint oldMinBurnRate = minimumBurnRate;
        minimumBurnRate = newMinBurnRate;
        emit MinBurnRateUpdated(oldMinBurnRate, newMinBurnRate);
    }

    // change the length of a pulse, should be done with care, probably should update all slots simultaneously
    function setPulseWavelength(uint newWavelength) public managementOnly {
        uint oldWavelength = pulseWavelengthBlocks;
        pulseWavelengthBlocks = newWavelength;
        pulseConstant = pulseAmplitudeFVT / pulseWavelengthBlocks.times(pulseWavelengthBlocks);
        pulseIntegral = pulseSum(newWavelength);
        emit WavelengthUpdated(oldWavelength, newWavelength);
    }

    // change the maximum height of the reward curve
    function setPulseAmplitude(uint newAmplitude) public managementOnly {
        uint oldAmplitude = pulseAmplitudeFVT;
        pulseAmplitudeFVT = newAmplitude;
        pulseConstant = pulseAmplitudeFVT / pulseWavelengthBlocks.times(pulseWavelengthBlocks);
        pulseIntegral = pulseSum(pulseWavelengthBlocks);
        emit AmplitudeUpdated(oldAmplitude, newAmplitude);
    }

    // compute the sum of the rewards per pulse
    function pulseSum(uint wavelength) public view returns (uint) {
        // sum of squares formula
        return pulseConstant.times(wavelength.times(wavelength.plus(1))).times(wavelength.times(2).plus(1)) / 6;
    }

    // compute the undistributed rewards for a slot
    function getRewards(uint slotId) public view returns (uint) {
        Slot storage slot = slots[slotId];
        if (slot.owner == address(0)) {
            return 0;
        }
        uint referenceBlock = block.number;
        if (paused) {
            referenceBlock = pausedBlock;
        }
        // three parts, incomplete beginning, incomplete end and complete middle
        uint rewards;

        // complete middle
        // trim off overhang on both ends
        uint startPhase = slot.lastUpdatedBlock.minus(pulseStartBlock) % pulseWavelengthBlocks;
        uint startOverhang = pulseWavelengthBlocks.minus(startPhase);
        uint startSum = pulseSum(startOverhang);

        uint blocksDiffTotal = referenceBlock.minus(slot.lastUpdatedBlock);

        uint endPhase = referenceBlock.minus(pulseStartBlock) % pulseWavelengthBlocks;
        uint endingBlocks = pulseWavelengthBlocks.minus(endPhase);
        uint leftoverSum = pulseSum(endingBlocks);

        // if we haven't made it to phase 0 yet
        if (blocksDiffTotal < startOverhang) {
            rewards = startSum.minus(leftoverSum);
        } else {
            uint blocksDiff = blocksDiffTotal.minus(endPhase).minus(startOverhang);
            uint wavelengths = blocksDiff / pulseWavelengthBlocks;
            rewards = wavelengths.times(pulseIntegral);

            // incomplete beginning of reward cycle, end of pulse
            if (startPhase > 0) {
                rewards = rewards.plus(pulseSum(startOverhang));
            }

            // incomplete ending of reward cycle, beginning of pulse
            if (endPhase > 0) {
                rewards = rewards.plus(pulseIntegral.minus(leftoverSum));
            }
        }

        return rewards;
    }

    // compute the unapplied burn to the deposit
    function getBurn(uint slotId) public view returns (uint) {
        Slot storage slot = slots[slotId];
        uint referenceBlock = block.number;
        if (paused) {
            referenceBlock = pausedBlock;
        }
        uint burn = slot.burnRate * (referenceBlock - slot.lastUpdatedBlock);
        if (burn > slot.deposit) {
            burn = slot.deposit;
        }
        return burn;
    }

    // this must be idempotent, it syncs both the rewards and the deposit burn atomically, and updates lastUpdatedBlock
    function updateSlot(uint slotId) public {
        Slot storage slot = slots[slotId];

        // burn and rewards always have to update together, since they both depend on lastUpdatedBlock
        uint burn = getBurn(slotId);
        uint rewards = getRewards(slotId);

        // update this first to make burn and reward zero in the case of re-entrance
        slot.lastUpdatedBlock = block.number;

        if (burn > 0) {
            // adjust deposit first
            slot.deposit = slot.deposit.minus(burn);

            // bookkeeping
            totalBurned = totalBurned.plus(burn);
            totalBurnedFor[slot.owner] = totalBurnedFor[slot.owner].plus(burn);

            // burn them!
            liquidityToken.transfer(taxAddress, burn);
        }

        if (rewards > 0) {
            // bookkeeping
            totalRewards = totalRewards.plus(rewards);
            totalRewardsFor[slot.owner] = totalStakedFor[slot.owner].plus(rewards);
            rewardsForSession[slotId] = rewardsForSession[slotId].plus(rewards);

            rewardToken.transfer(slot.owner, rewards);
        }
    }

    // most important function for users, allows them to start receiving rewards
    function claimSlot(uint slotId, uint newBurnRate, uint deposit) external {
        require(slotId > 0, 'Slot id must be positive');
        require(slotId <= maxStakers, 'Slot id out of range');
        require(newBurnRate >= minimumBurnRate, 'Burn rate must meet or exceed minimum');
        require(deposit >= minimumDeposit, 'Deposit must meet or exceed minimum');
        require(deposit <= maximumDeposit, 'Deposit must not exceed maximum');
        require(paused == false, 'Must be unpaused');

        Slot storage slot = slots[slotId];

        // count the stakers
        if (slot.owner == address(0)) {
            // assign id since this may be the first time
            slot.id = slotId;
            numStakers = numStakers.plus(1);
            slot.lastUpdatedBlock = block.number;
        } else {
            updateSlot(slotId);

            bool betterDeal = newBurnRate > slot.burnRate && (deposit > slot.deposit || deposit == maximumDeposit);
            require(betterDeal || slot.deposit == 0, 'You must outbid the current owner');

            // bookkeeping
            totalStaked = totalStaked.minus(slot.deposit);
            totalStakedFor[slot.owner] = totalStakedFor[slot.owner].minus(slot.deposit);

            // withdraw current owner
            withdrawFromSlotInternal(slotId);
        }

        // set new owner, burn rate
        slot.owner = msg.sender;
        slot.burnRate = newBurnRate;
        slot.deposit = deposit;

        // bookkeeping
        totalStaked = totalStaked.plus(deposit);
        totalStakedFor[msg.sender] = totalStakedFor[msg.sender].plus(deposit);

        // transfer the tokens!
        if (deposit > 0) {
            liquidityToken.transferFrom(msg.sender, address(this), deposit);
        }

        emit SlotChangedHands(slotId, deposit, newBurnRate, msg.sender);
    }

    // separates user from slot, if either voluntary or delinquent
    function withdrawFromSlot(uint slotId) external {
        Slot storage slot = slots[slotId];
        bool withdrawable = slot.owner == msg.sender || slot.deposit == 0;
        require(withdrawable || paused, 'Only owner can call this unless user is delinquent or contract is paused');
        updateSlot(slotId);
        withdrawFromSlotInternal(slotId);

        // zero out owner and burn rate
        slot.owner = address(0);
        slot.burnRate = 0;
        numStakers = numStakers.minus(1);
        emit SlotChangedHands(slotId, 0, 0, address(0));
    }

    // internal function for withdrawing from a slot
    function withdrawFromSlotInternal(uint slotId) internal {
        Slot storage slot = slots[slotId];

        rewardsForSession[slotId] = 0;

        // if there's any deposit left,
        if (slot.deposit > 0) {
            uint deposit = slot.deposit;
            slot.deposit = 0;
            liquidityToken.transfer(slot.owner, deposit);
        }
    }

}