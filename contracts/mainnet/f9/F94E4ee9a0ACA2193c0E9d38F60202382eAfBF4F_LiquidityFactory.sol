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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

import "./SafeMathLib.sol";


contract Token {
    using SafeMathLib for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    mapping (uint => FrozenTokens) public frozenTokensMap;

    event Transfer(address indexed sender, address indexed receiver, uint value);
    event Approval(address approver, address spender, uint value);
    event TokensFrozen(address indexed freezer, uint amount, uint id, uint lengthFreezeDays);
    event TokensUnfrozen(address indexed unfreezer, uint amount, uint id);
    event TokensBurned(address burner, uint amount);
    event TokensMinted(address recipient, uint amount);
    event BankUpdated(address oldBank, address newBank);

    uint8 constant public decimals = 18;
    string constant public symbol = "FVT";
    string constant public name = "Finance.Vote Token";
    uint public totalSupply;
    uint numFrozenStructs;
    address public bank;

    struct FrozenTokens {
        uint id;
        uint dateFrozen;
        uint lengthFreezeDays;
        uint amount;
        bool frozen;
        address owner;
    }

    // simple initialization, giving complete token supply to one address
    constructor(address _bank) {
        bank = _bank;
        require(bank != address(0), 'Must initialize with nonzero address');
        uint totalInitialBalance = 1e9 * 1 ether;
//        uint totalInitialBalance = 0;
        balances[bank] = totalInitialBalance;
        totalSupply = totalInitialBalance;
        emit Transfer(address(0), bank, totalInitialBalance);
    }

    modifier bankOnly() {
        require (msg.sender == bank, 'Only bank address may call this');
        _;
    }

    function setBank(address newBank) public bankOnly {
        address oldBank = bank;
        bank = newBank;
        emit BankUpdated(oldBank, newBank);
    }

    // freeze tokens for a certain number of days
    function freeze(uint amount, uint freezeDays) public {
        require(amount > 0, 'Cannot freeze 0 tokens');
        // move tokens into this contract's address from sender
        balances[msg.sender] = balances[msg.sender].minus(amount);
        balances[address(this)] = balances[address(this)].plus(amount);
        numFrozenStructs = numFrozenStructs.plus(1);
        frozenTokensMap[numFrozenStructs] = FrozenTokens(numFrozenStructs, block.timestamp, freezeDays, amount, true, msg.sender);
        emit Transfer(msg.sender, address(this), amount);
        emit TokensFrozen(msg.sender, amount, numFrozenStructs, freezeDays);
    }

    // unfreeze frozen tokens
    function unFreeze(uint id) public {
        FrozenTokens storage f = frozenTokensMap[id];
        require(f.dateFrozen + (f.lengthFreezeDays * 1 days) < block.timestamp, 'May not unfreeze until freeze time is up');
        require(f.frozen, 'Can only unfreeze frozen tokens');
        f.frozen = false;
        // move tokens back into owner's address from this contract's address
        balances[f.owner] = balances[f.owner].plus(f.amount);
        balances[address(this)] = balances[address(this)].minus(f.amount);
        emit Transfer(address(this), msg.sender, f.amount);
        emit TokensUnfrozen(f.owner, f.amount, id);
    }

    // burn tokens, taking them out of supply
    function burn(uint amount) public {
        balances[msg.sender] = balances[msg.sender].minus(amount);
        totalSupply = totalSupply.minus(amount);
        emit Transfer(msg.sender, address(0), amount);
        emit TokensBurned(msg.sender, amount);
    }

    function mint(address recipient, uint amount) public bankOnly {
        uint totalAmount = amount * 1 ether;
        balances[recipient] = balances[recipient].plus(totalAmount);
        totalSupply = totalSupply.plus(totalAmount);
        emit Transfer(address(0), recipient, totalAmount);
        emit TokensMinted(recipient, totalAmount);
    }

    // burn tokens for someone else, subject to approval
    function burnFor(address burned, uint amount) public {
        uint currentAllowance = allowed[burned][msg.sender];

        // deduct
        balances[burned] = balances[burned].minus(amount);

        // adjust allowance
        allowed[burned][msg.sender] = currentAllowance.minus(amount);

        totalSupply = totalSupply.minus(amount);

        emit Transfer(burned, address(0), amount);
        emit TokensBurned(burned, amount);
    }

    // transfer tokens
    function transfer(address to, uint value) public returns (bool success)
    {
        if (to == address(0)) {
            burn(value);
        } else {
            // deduct
            balances[msg.sender] = balances[msg.sender].minus(value);
            // add
            balances[to] = balances[to].plus(value);

            emit Transfer(msg.sender, to, value);
        }
        return true;
    }

    // transfer someone else's tokens, subject to approval
    function transferFrom(address from, address to, uint value) public returns (bool success)
    {
        if (to == address(0)) {
            burnFor(from, value);
        } else {
            uint currentAllowance = allowed[from][msg.sender];

            // deduct
            balances[from] = balances[from].minus(value);

            // add
            balances[to] = balances[to].plus(value);

            // adjust allowance
            allowed[from][msg.sender] = currentAllowance.minus(value);

            emit Transfer(from, to, value);
        }
        return true;
    }

    // retrieve the balance of address
    function balanceOf(address owner) public view returns (uint balance) {
        return balances[owner];
    }

    // approve another address to transfer a specific amount of tokens
    function approve(address spender, uint value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // incrementally increase approval, see https://github.com/ethereum/EIPs/issues/738
    function increaseApproval(address spender, uint value) public returns (bool success) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].plus(value);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    // incrementally decrease approval, see https://github.com/ethereum/EIPs/issues/738
    function decreaseApproval(address spender, uint decreaseValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][spender];
        // allow decreasing too much, to prevent griefing via front-running
        if (decreaseValue >= oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.minus(decreaseValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    // retrieve allowance for a given owner, spender pair of addresses
    function allowance(address owner, address spender) public view returns (uint remaining) {
        return allowed[owner][spender];
    }

    function numCoinsFrozen() public view returns (uint) {
        return balances[address(this)];
    }}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

import "../SafeMathLib.sol";
import "../Token.sol";

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
        Token liquidityToken;
        address taxAddress;
        address poolOwner;
        bool paused;
        uint pausedBlock;
        uint unpausedBlock;
        uint pausedStakers;
        uint maxStakers;
        uint numStakers;
        uint numSynced; // only used while paused
        uint minimumDepositWei;
        uint maximumDepositWei;
        uint minimumBurnRateWeiPerBlock;
        mapping (uint => Slot) slots;
    }

    struct Metadata {
        bytes32 name;
        bytes32 ipfsHash;
    }

    struct Pulse {
        Token rewardToken1;
        Token rewardToken2;
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
        Pool storage pool = pools[poolId];
        require (pool.paused, 'Must be paused');
        require (pool.numSynced == pool.pausedStakers, 'Must sync all users');
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
        uint pulseLengthBlocks,
        uint pulseAmplitudeWei,
        uint mxStkrs,
        uint minBurnRateWei,
        uint minDepositWei,
        uint maxDepositWei,
        bytes32 ipfsHash,
        bytes32 name) managementOnly external {
        numPools = numPools.plus(1);
        {
            Pool storage pool = pools[numPools];
            pool.id = numPools;
            pool.liquidityToken = Token(liquidityTokenAddr);
            pool.taxAddress = taxAddr;
            pool.poolOwner = poolOwner;
            pool.maxStakers = mxStkrs;
            pool.minimumDepositWei = minDepositWei;
            pool.maximumDepositWei = maxDepositWei;
            pool.minimumBurnRateWeiPerBlock = minBurnRateWei;
        }
        {
            Metadata storage metadata = metadatas[numPools];
            metadata.ipfsHash = ipfsHash;
            metadata.name = name;
        }
        {
            Pulse storage pulse = pulses[numPools];
            pulse.rewardToken1 = Token(rewardToken1Addr);
            pulse.rewardToken2 = Token(rewardToken2Addr);
            pulse.pulseStartBlock = block.number + pulseStartDelayBlocks;
            pulse.pulseWavelengthBlocks = pulseLengthBlocks;
            pulse.pulseAmplitudeWei = pulseAmplitudeWei;
            pulse.pulseConstant = pulseAmplitudeWei / pulseLengthBlocks.times(pulseLengthBlocks);
            pulse.pulseIntegral = pulseSum(pulse.pulseConstant, pulse.pulseWavelengthBlocks);
            pulse.reward2WeiPerBlock = rewardPerBlock2Wei;
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
        if (pool.paused) {
            // these two requires prevent weird double updates that might make numSynced too high
            // it also means that if someone updates you while paused you cannot withdraw...
            require(block.number > pool.pausedBlock, 'Do not call this in the same block that you paused');
            require(slot.lastUpdatedBlock <= pool.pausedBlock, 'If pool is paused, can only update slot once');
            require(msg.sender == pool.poolOwner || msg.sender == slot.owner, 'If pool is paused, only pool owner or slot owner may call this');
            pool.numSynced = pool.numSynced.plus(1);
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
            pulse.rewardToken1.transfer(slot.owner, rewards1);
        }

        if (rewards2 > 0) {
            pulse.rewardToken2.transfer(slot.owner, rewards2);
        }

        if (burn > 0) {
            // adjust deposit first
            slot.depositWei = slot.depositWei.minus(burn);

            // bookkeeping
            stats.totalBurnedWei = stats.totalBurnedWei.plus(burn);
            stats.totalBurnedWeiFor[slot.owner] = stats.totalBurnedWeiFor[slot.owner].plus(burn);

            // pay the tax!
            pool.liquidityToken.transfer(pool.taxAddress, burn);
        }
    }

    // most important function for users, allows them to start receiving rewards
    function claimSlot(uint poolId, uint slotId, uint newBurnRate, uint newDeposit) external {
        Pool storage pool = pools[poolId];
        PoolStats storage stats = poolStats[poolId];
        require(slotId > 0, 'Slot id must be positive');
        require(slotId <= pool.maxStakers, 'Slot id out of range');
        require(newBurnRate >= pool.minimumBurnRateWeiPerBlock, 'Burn rate must meet or exceed minimum');
        require(newDeposit >= pool.minimumDepositWei, 'Deposit must meet or exceed minimum');
        require(newDeposit <= pool.maximumDepositWei, 'Deposit must not exceed maximum');
        require(pool.paused == false, 'Must be unpaused');
        require(pool.id == poolId && poolId > 0, 'Uninitialized pool');

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
            pool.numStakers = pool.numStakers.plus(1);

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
                pool.liquidityToken.transfer(slot.owner, slot.depositWei);
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
            pool.liquidityToken.transferFrom(msg.sender, address(this), newDeposit);
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
        pool.numStakers = pool.numStakers.minus(1);

        // record what block we vacated in to compute linear decay
        slot.vacatedBlock = block.number;

        // zero out owner, closing re-entrance gate
        slot.owner = address(0);

        // don't set deposit or burn rate to 0 so we can compute linear decay

        // if there's any deposit left,
        if (slot.depositWei > 0) {
            pool.liquidityToken.transfer(slot.owner, slot.depositWei);
        }
    }

    // ======================== PAUSE =============================

    function pausePool(uint poolId) external poolOwnerOnly(poolId) initializedPoolOnly(poolId) {
        Pool storage pool = pools[poolId];
        require(pool.paused == false, 'Already paused');
        pool.paused = true;
        pool.pausedBlock = block.number;
        pool.pausedStakers = pool.numStakers;
        pool.unpausedBlock = 0;
    }

    function unpausePool(uint poolId) external poolOwnerOnly(poolId) pausedAndSynced(poolId) {
        Pool storage pool = pools[poolId];
        pool.paused = false;
        pool.pausedBlock = 0;
        pool.numSynced = 0;
        pool.pausedStakers = 0;
        pool.unpausedBlock = block.number;
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
        Slot memory slot = pool.slots[slotId];

        uint referenceBlock1 = slot.lastUpdatedBlock;
        uint referenceBlock2 = block.number;
        if (pool.paused) {
            referenceBlock2 = pool.pausedBlock;
        } else if (slot.lastUpdatedBlock < pool.unpausedBlock) {
            referenceBlock1 = pool.unpausedBlock;
        }

        return (referenceBlock1, referenceBlock2);
    }

    // compute the sum of the rewards per pulse
    function pulseSum(uint coeff, uint wavelength) public pure returns (uint) {
        // sum of squares formula
        return coeff.times(wavelength.times(wavelength.plus(1))).times(wavelength.times(2).plus(1)) / 6;
    }

    // ======================== SETTERS =============================

    function setMaxStakers(uint poolId, uint newMaxStakers) external poolOwnerOnly(poolId)  {
        Pool storage pool = pools[poolId];
        pool.maxStakers = newMaxStakers;
    }

    // change the minimum deposit to acquire a slot
    function setMinDeposit(uint poolId, uint newMinDeposit) external poolOwnerOnly(poolId)  {
        Pool storage pool = pools[poolId];
        pool.minimumDepositWei = newMinDeposit;
    }

    // change the maximum deposit
    function setMaxDeposit(uint poolId, uint newMaxDeposit) external poolOwnerOnly(poolId)  {
        Pool storage pool = pools[poolId];
        pool.maximumDepositWei = newMaxDeposit;
    }

    // change the minimum burn rate to acquire a slot
    function setMinBurnRate(uint poolId, uint newMinBurnRate) external poolOwnerOnly(poolId)  {
        Pool storage pool = pools[poolId];
        pool.minimumBurnRateWeiPerBlock = newMinBurnRate;
    }

    // change the length of a pulse, should be done with care, probably should update all slots simultaneously
    function setPulseWavelength(uint poolId, uint newWavelength) external poolOwnerOnly(poolId)  {
        Pulse storage pulse = pulses[poolId];
        pulse.pulseWavelengthBlocks = newWavelength;
        pulse.pulseConstant = pulse.pulseAmplitudeWei / pulse.pulseWavelengthBlocks.times(pulse.pulseWavelengthBlocks);
        pulse.pulseIntegral = pulseSum(pulse.pulseConstant, newWavelength);
    }

    // change the maximum height of the reward curve
    function setPulseAmplitude(uint poolId, uint newAmplitude) external poolOwnerOnly(poolId) pausedAndSynced(poolId) {
        Pulse storage pulse = pulses[poolId];
        pulse.pulseAmplitudeWei = newAmplitude;
        pulse.pulseConstant = pulse.pulseAmplitudeWei / pulse.pulseWavelengthBlocks.times(pulse.pulseWavelengthBlocks);
        pulse.pulseIntegral = pulseSum(pulse.pulseConstant, pulse.pulseWavelengthBlocks);
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

    // only pool owner can change pool owner key
    function setPoolOwner(uint poolId, address newOwner) external poolOwnerOnly(poolId)  {
        Pool storage pool = pools[poolId];
        pool.poolOwner = newOwner;
    }

    function setDecays(uint poolId, uint burnRateDecayWeiPerBlock, uint depositDecayWeiPerBlock) external poolOwnerOnly(poolId) initializedPoolOnly(poolId)  {
        PoolStats storage stats = poolStats[poolId];
        stats.burnRateDecayWeiPerBlock = burnRateDecayWeiPerBlock;
        stats.depositDecayWeiPerBlock = depositDecayWeiPerBlock;
    }

}

