// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./../refs/CoreRef.sol";
import "./IRewarder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/// @notice migration functionality has been removed as this is only going to be used to distribute staking rewards

/// @notice The idea for this TribalChief contract is to be the owner of tribe token
/// that is deposited into this contract.
/// @notice This contract was forked from sushiswap and has been modified to distribute staking rewards in tribe.
/// All legacy code that relied on MasterChef V1 has been removed so that this contract will pay out staking rewards in tribe.
/// The assumption this code makes is that this MasterChief contract will be funded before going live and offering staking rewards.
/// This contract will not have the ability to mint tribe.
contract TribalChief is CoreRef, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice Info of each users's reward debt and virtual amount
    /// stored in a single pool
    /// `virtualAmount` The virtual amount deposited. Calculated like so (multiplier * amount) / scale_factor
    /// assumption here is that we will never go over 2^256 -1
    /// on any user deposits
    /// 'rewardDebt' tracks the tribe per share when the user entered the pool
    /// and is used to determine how much Tribe rewards a user is entitled to
    struct UserInfo {
        int256 rewardDebt;
        uint256 virtualAmount;
    }

    /// @notice Info for a deposit
    /// `amount` amount of tokens the user has provided.
    /// assumption here is that we will never go over 2^256 -1
    /// on any user deposits
    /// `unlockBlock` is when a users lockup period ends and they are free to withdraw
    /// `multiplier` is the multiplier users received on their locked amount.
    /// This is used to calculate virtual liquidity deltas.
    struct DepositInfo {
        uint256 amount;
        uint128 unlockBlock;
        uint128 multiplier;
    }

    /// @notice Info of each pool.
    /// `virtualTotalSupply` The total virtual supply in this pool
    /// `accTribePerShare` The amount of tribe each share is entitled to.
    /// Users entering a pool have their reward debt start at current tribe per share and 
    /// then they get the delta between where the tribe per share goes to and where they started.
    /// `lastRewardBlock` The last block where rewards were paid for this pool
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of Tribe to distribute per block.
    /// `unlocked` Whether or not the pool has been unlocked by an admin
    /// this will allow an admin to unlock the pool if need be.
    /// This value defaults to false so that users have to respect the lockup period.
    struct PoolInfo {
        uint256 virtualTotalSupply;
        uint256 accTribePerShare;
        uint128 lastRewardBlock;
        uint120 allocPoint;
        bool unlocked;
    }

    /// @notice Info of each pool rewards multipliers available.
    /// map a pool id to a block lock time to a rewards multiplier
    mapping (uint256 => mapping (uint128 => uint128)) public rewardMultipliers;

    /// @notice Data needed for governor to create a new lockup period
    /// and associated reward multiplier
    struct RewardData {
        uint128 lockLength;
        uint128 rewardMultiplier;
    }

    /// @notice Address of Tribe contract.
    /// Cannot be immutable due to limitations of proxies
    IERC20 public TRIBE;
    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the token you can stake in each pool.
    IERC20[] public stakedToken;
    /// @notice Address of each `IRewarder` contract.
    IRewarder[] public rewarder;
    
    /// @notice Info of each users reward debt and virtual amount.
    /// One object is instantiated per user per pool
    mapping (uint256 => mapping(address => UserInfo)) public userInfo;
    /// @notice Info of each user that stakes tokens.
    mapping (uint256 => mapping (address => DepositInfo[])) public depositInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;


    /// @notice these variables cannot be initialized with a constant value 
    /// because of the way that upgradeable contracts work, their initial write
    // to storage doesn't happen as the logic contract doesn't run the constructor

    /// the amount of tribe distributed per block
    uint256 private tribalChiefTribePerBlock;
    /// variable has been made constant to cut down on gas costs
    uint256 private ACC_TRIBE_PRECISION;
    /// decimals for rewards multiplier
    uint256 public SCALE_FACTOR;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 indexed depositID);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed stakedToken, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogPoolMultiplier(uint256 indexed pid, uint128 indexed lockLength, uint256 indexed multiplier);
    event LogUpdatePool(uint256 indexed pid, uint128 indexed lastRewardBlock, uint256 lpSupply, uint256 accTribePerShare);
    /// @notice tribe withdraw event
    event TribeWithdraw(uint256 amount);
    event NewTribePerBlock(uint256 indexed amount);
    event PoolLocked(bool indexed locked, uint256 indexed pid);

    /// @notice The way this function is constructed, you will not be able to 
    /// call initialize after this function is constructed, effectively 
    /// only allowing TribalChief to be used through delegate calls.
    /// @param coreAddress The Core contract address.
    constructor(address coreAddress) CoreRef(coreAddress) {}

    /// @param _core The Core contract address.
    /// @param _tribe The TRIBE token contract address.
    function initialize(address _core, IERC20 _tribe) external initializer {        
        CoreRef._initialize(_core);    
        
        TRIBE = _tribe;
        _setContractAdminRole(keccak256("TRIBAL_CHIEF_ADMIN_ROLE"));

        // set constant values here as we cannot use constants with proxies
        tribalChiefTribePerBlock = 75e18;
        ACC_TRIBE_PRECISION = 1e23;
        SCALE_FACTOR = 1e4;
    }

    /// @notice Allows governor to change the amount of tribe per block
    /// make sure to call the update pool function before hitting this function
    /// this will ensure that all of the rewards a user earned previously get paid out
    /// @param newBlockReward The new amount of tribe per block to distribute
    function updateBlockReward(uint256 newBlockReward) external onlyGovernorOrAdmin {
        if (isContractAdmin(msg.sender)) {
            require(newBlockReward < tribalChiefTribePerBlock, "TribalChief: admin can only lower reward rate");
        }

        tribalChiefTribePerBlock = newBlockReward;
        emit NewTribePerBlock(newBlockReward);
    }

    /// @notice Allows governor to lock the pool so the users cannot withdraw
    /// until their lockup period is over
    /// @param _pid pool ID
    function lockPool(uint256 _pid) external onlyGovernorOrAdmin {
        PoolInfo storage pool = poolInfo[_pid];
        pool.unlocked = false;

        emit PoolLocked(true, _pid);
    }

    /// @notice Allows governor to unlock the pool so that users can withdraw 
    /// before their tokens have been locked for the entire lockup period
    /// @param _pid pool ID
    function unlockPool(uint256 _pid) external onlyGovernorOrAdmin {
        PoolInfo storage pool = poolInfo[_pid];
        pool.unlocked = true;

        emit PoolLocked(false, _pid);
    }

    /// @notice Allows governor to change the pool multiplier
    /// Unlocks the pool if the new multiplier is greater than the old one
    /// @param _pid pool ID
    /// @param lockLength lock length to change
    /// @param newRewardsMultiplier updated rewards multiplier
    function governorAddPoolMultiplier(
        uint256 _pid,
        uint64 lockLength,
        uint64 newRewardsMultiplier
    ) external onlyGovernorOrAdmin {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 currentMultiplier = rewardMultipliers[_pid][lockLength];
        // if the new multplier is greater than the current multiplier,
        // then, you need to unlock the pool to allow users to withdraw
        // so they can receive this larger reward
        if (newRewardsMultiplier > currentMultiplier) {
            pool.unlocked = true;
            // emit this event if we end up unlocking this pool
            emit PoolLocked(false, _pid);
        }
        rewardMultipliers[_pid][lockLength] = newRewardsMultiplier;

        emit LogPoolMultiplier(_pid, lockLength, newRewardsMultiplier);
    }

    /// @notice sends tokens back to governance treasury. Only callable by governance
    /// @param amount the amount of tokens to send back to treasury
    function governorWithdrawTribe(uint256 amount) external onlyGovernor {
        TRIBE.safeTransfer(address(core()), amount);
        emit TribeWithdraw(amount);
    }

    /// @notice Returns the number of pools.
    function numPools() public view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Returns the number of user deposits in a single pool.
    function openUserDeposits(uint256 pid, address user) public view returns (uint256) {
        return depositInfo[pid][user].length;
    }

    /// @notice Returns the amount a user deposited in a single pool.
    function getTotalStakedInPool(uint256 pid, address user) public view returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < depositInfo[pid][user].length; i++) {
            DepositInfo storage poolDeposit = depositInfo[pid][user][i];
            amount += poolDeposit.amount;
        }

        return amount;
    }


    /// @notice Add a new pool. Can only be called by the governor.
    /// @param allocPoint AP of the new pool.
    /// @param _stakedToken Address of the ERC-20 token to stake.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param rewardData Reward Multiplier data 
    function add(
        uint120 allocPoint,
        IERC20 _stakedToken,
        IRewarder _rewarder,
        RewardData[] calldata rewardData
    ) external onlyGovernorOrAdmin {
        require(allocPoint > 0, "pool must have allocation points to be created");
        uint128 lastRewardBlock = block.number.toUint128();
        totalAllocPoint += allocPoint;
        stakedToken.push(_stakedToken);
        rewarder.push(_rewarder);

        uint256 pid = poolInfo.length;

        require(rewardData.length != 0, "must specify rewards");
        // loop over all of the arrays of lock data and add them to the rewardMultipliers mapping
        for (uint256 i = 0; i < rewardData.length; i++) {
            // if locklength is 0 and multiplier is not equal to scale factor, revert
            if (rewardData[i].lockLength == 0) {
                require(rewardData[i].rewardMultiplier == SCALE_FACTOR, "invalid multiplier for 0 lock length");
            } else {
                // else, assert that multplier is greater than or equal to scale factor
                require(rewardData[i].rewardMultiplier >= SCALE_FACTOR, "invalid multiplier, must be above scale factor");
            }

            rewardMultipliers[pid][rewardData[i].lockLength] = rewardData[i].rewardMultiplier;
            emit LogPoolMultiplier(
                pid,
                rewardData[i].lockLength,
                rewardData[i].rewardMultiplier
            );
        }

        poolInfo.push(PoolInfo({
            allocPoint: allocPoint,
            virtualTotalSupply: 0, // virtual total supply starts at 0 as there is 0 initial supply
            lastRewardBlock: lastRewardBlock,
            accTribePerShare: 0,
            unlocked: false
        }));
        emit LogPoolAddition(pid, allocPoint, _stakedToken, _rewarder);
    }

    /// @notice Update the given pool's TRIBE allocation point and `IRewarder` contract.
    /// Can only be called by the governor.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    function set(uint256 _pid, uint120 _allocPoint, IRewarder _rewarder, bool overwrite) public onlyGovernorOrAdmin {
        // we must update the pool before applying set so that all previously accrued rewards
        // are paid out before alloc points change
        updatePool(_pid);
        totalAllocPoint = (totalAllocPoint - poolInfo[_pid].allocPoint) + _allocPoint;
        require(totalAllocPoint > 0, "total allocation points cannot be 0");

        poolInfo[_pid].allocPoint = _allocPoint;
        if (overwrite) {
            rewarder[_pid] = _rewarder;
        }

        emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
    }

    /// @notice Reset the given pool's TRIBE allocation to 0 and unlock the pool.
    /// Can only be called by the governor or guardian.
    /// @param _pid The index of the pool. See `poolInfo`.    
    function resetRewards(uint256 _pid) public onlyGuardianOrGovernor {
        // we must update the pool before resetting rewards so that all previously accrued rewards
        // are paid out before alloc points go to 0 in this pool
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        // set the pool's allocation points to zero
        totalAllocPoint = (totalAllocPoint - pool.allocPoint);
        pool.allocPoint = 0;
        
        // unlock all staked tokens in the pool
        pool.unlocked = true;

        // erase any IRewarder mapping
        rewarder[_pid] = IRewarder(address(0));

        emit PoolLocked(false, _pid);
        emit LogSetPool(_pid, 0, IRewarder(address(0)), false);
    }

    /// @notice View function to see all pending TRIBE on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending TRIBE reward for a given user.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accTribePerShare = pool.accTribePerShare;

        if (block.number > pool.lastRewardBlock && pool.virtualTotalSupply != 0) {
            // this is the block delta
            uint256 blocks = block.number - pool.lastRewardBlock;
            // this is the amount of tribe this pool is entitled to for the last n blocks
            uint256 tribeReward = (blocks * tribePerBlock() * pool.allocPoint) / totalAllocPoint;
            // this is the new tribe per each pool share
            accTribePerShare = accTribePerShare + ((tribeReward * ACC_TRIBE_PRECISION) / pool.virtualTotalSupply);
        }

        // use the virtual amount to calculate the users share of the pool and their pending rewards
        return (((user.virtualAmount * accTribePerShare) / ACC_TRIBE_PRECISION).toInt256() - user.rewardDebt).toUint256();
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata pids) external {
        uint256 len = pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Calculates and returns the `amount` of TRIBE per block.
    function tribePerBlock() public view returns (uint256) {
        return tribalChiefTribePerBlock;
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    function updatePool(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        if (block.number > pool.lastRewardBlock) {
            uint256 virtualSupply = pool.virtualTotalSupply;
            if (virtualSupply > 0 && totalAllocPoint != 0) {
                uint256 blocks = block.number - pool.lastRewardBlock;
                uint256 tribeReward = (blocks * tribePerBlock() * pool.allocPoint) / totalAllocPoint;
                pool.accTribePerShare = pool.accTribePerShare + ((tribeReward * ACC_TRIBE_PRECISION) / virtualSupply);
            }
            pool.lastRewardBlock = block.number.toUint128();
            emit LogUpdatePool(pid, pool.lastRewardBlock, virtualSupply, pool.accTribePerShare);
        }
    }

    /// @notice Deposit tokens to earn TRIBE allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount The token amount to deposit.
    /// @param lockLength The length of time you would like to lock tokens
    function deposit(uint256 pid, uint256 amount, uint64 lockLength) public nonReentrant whenNotPaused {
        // we have to update the pool before we allow a user to deposit so that we can correctly calculate their reward debt
        // if we didn't do this, it would allow users to steal from us by calling deposits and gaining rewards they aren't entitled to
        updatePool(pid);
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage userPoolData = userInfo[pid][msg.sender];
        DepositInfo memory poolDeposit;

        uint128 multiplier = rewardMultipliers[pid][lockLength];
        require(multiplier >= SCALE_FACTOR, "invalid lock length");

        // Effects
        poolDeposit.amount = amount;
        poolDeposit.unlockBlock = (lockLength + block.number).toUint128();
        // set the multiplier here so that on withdraw we can easily reset the
        // multiplier and remove the appropriate amount of virtual liquidity
        poolDeposit.multiplier = multiplier;

        // virtual amount is calculated by taking the users total deposited balance and multiplying
        // it by the multiplier then adding it to the aggregated virtual amount
        uint256 virtualAmountDelta = (amount * multiplier) / SCALE_FACTOR;
        userPoolData.virtualAmount += virtualAmountDelta;
        // update reward debt after virtual amount is set by multiplying virtual amount delta by tribe per share
        // this tells us when the user deposited and allows us to calculate their rewards later
        userPoolData.rewardDebt += ((virtualAmountDelta * pool.accTribePerShare) / ACC_TRIBE_PRECISION).toInt256();

        // pool virtual total supply needs to increase here
        pool.virtualTotalSupply += virtualAmountDelta;

        // add the new user struct into storage
        depositInfo[pid][msg.sender].push(poolDeposit);

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onSushiReward(pid, msg.sender, msg.sender, 0, userPoolData.virtualAmount);
        }

        stakedToken[pid].safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, pid, amount, depositInfo[pid][msg.sender].length - 1);
    }

    /// @notice Withdraw staked tokens from pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the tokens.
    function withdrawAllAndHarvest(uint256 pid, address to) external nonReentrant {
        // update the pool, so that accTribePerShare is accurate, then harvest
        updatePool(pid);
        _harvest(pid, to);

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 unlockedTotalAmount = 0;
        uint256 virtualLiquidityDelta = 0;

        // iterate over all deposits this user has and aggregate the deltas
        uint256 processedDeposits = 0;
        for (uint256 i = 0; i < depositInfo[pid][msg.sender].length; i++) {
            DepositInfo storage poolDeposit = depositInfo[pid][msg.sender][i];
            // if the user has locked the tokens for at least the 
            // lockup period or the pool has been unlocked, allow 
            // user to withdraw their principle from this deposit, otherwise skip this action
            if (poolDeposit.unlockBlock > block.number && pool.unlocked == false) {
                continue;
            }

            // if we get past continue, it means that we are going to process this deposit
            // and send these tokens back to the user
            processedDeposits++;

            // gather the virtual and regular amount delta
            unlockedTotalAmount += poolDeposit.amount;
            virtualLiquidityDelta += (poolDeposit.amount * poolDeposit.multiplier) / SCALE_FACTOR;

            // zero out the user object as their amount will be withdrawn and all pending tribe will be paid out
            poolDeposit.unlockBlock = 0;
            poolDeposit.multiplier = 0;
            poolDeposit.amount = 0;
        }

        // Effects
        if (processedDeposits == depositInfo[pid][msg.sender].length) {
            // Remove the array of deposits and userInfo struct if we were able to withdraw from all deposits.
            // If we removed all liquidity, then we can just delete all the data we stored on this user
            // in both depositinfo and userinfo, which means that their reward debt, and virtual liquidity
            // are all zero'd.
            delete depositInfo[pid][msg.sender];
            delete userInfo[pid][msg.sender];
        } else {
            // If we didn't end up being able to withdraw all of the liquidity from all of our deposits
            // then we will just update the userInfo object for the amounts that we did remove.
            // Batched changes are done at the end of the function so that we don't
            // write to these storage slots multiple times
            user.virtualAmount -= virtualLiquidityDelta;
            // Set the reward debt to the new virtual amount
            // we don't have to worry about increasing the reward debt here as the harvest function
            // has already paid out all pending tribe the users deserves.
            // Here, we just have to make the reward debt equal to:
            // (current tribe per share * the virtual liquidity) / ACC_TRIBE_PRECISION
            // of that user so that it is accurate.
            user.rewardDebt = (user.virtualAmount * pool.accTribePerShare / ACC_TRIBE_PRECISION).toInt256();
        }

        // regardless of whether or not we removed all of this users liquidity from the pool, we will need to
        // subtract the virtual liquidity delta from the pool virtual total supply
        pool.virtualTotalSupply -= virtualLiquidityDelta;

        // Interactions
        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onSushiReward(pid, msg.sender, to, 0, user.virtualAmount);
        }

        if (unlockedTotalAmount != 0) {
            stakedToken[pid].safeTransfer(to, unlockedTotalAmount);
        }

        emit Withdraw(msg.sender, pid, unlockedTotalAmount, to);
    }

    /// @notice Withdraw tokens from pool.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount Token amount to withdraw.
    /// @param to Receiver of the tokens.
    function withdrawFromDeposit(
        uint256 pid,
        uint256 amount,
        address to,
        uint256 index
    ) public nonReentrant {
        require(depositInfo[pid][msg.sender].length > index, "invalid index");
        updatePool(pid);
        PoolInfo storage pool = poolInfo[pid];
        DepositInfo storage poolDeposit = depositInfo[pid][msg.sender][index];
        UserInfo storage user = userInfo[pid][msg.sender];

        // if the user has locked the tokens for at least the 
        // lockup period or the pool has been unlocked by the governor,
        // allow user to withdraw their principle
        require(poolDeposit.unlockBlock <= block.number || pool.unlocked == true, "tokens locked");

        uint256 virtualAmountDelta = ( amount * poolDeposit.multiplier ) / SCALE_FACTOR;

        // Effects
        poolDeposit.amount -= amount;
        user.rewardDebt = user.rewardDebt - ((virtualAmountDelta * pool.accTribePerShare) / ACC_TRIBE_PRECISION).toInt256();
        user.virtualAmount -= virtualAmountDelta;
        pool.virtualTotalSupply -= virtualAmountDelta;

        // Interactions
        stakedToken[pid].safeTransfer(to, amount);

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /// @notice Helper function to harvest users tribe rewards
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of TRIBE rewards.
    function _harvest(uint256 pid, address to) private {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        // assumption here is that we will never go over 2^256 -1
        int256 accumulatedTribe = ( (user.virtualAmount * pool.accTribePerShare ) / ACC_TRIBE_PRECISION ).toInt256();

        // this should never happen
        assert(accumulatedTribe >= 0 && accumulatedTribe - user.rewardDebt >= 0);

        uint256 pendingTribe = (accumulatedTribe - user.rewardDebt).toUint256();

        // if pending tribe is ever negative, revert as this can cause an underflow when we turn this number to a uint
        assert(pendingTribe.toInt256() >= 0);

        // Effects
        user.rewardDebt = accumulatedTribe;

        // Interactions
        if (pendingTribe != 0) {
            TRIBE.safeTransfer(to, pendingTribe);
        }

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onSushiReward( pid, msg.sender, to, pendingTribe, user.virtualAmount);
        }

        emit Harvest(msg.sender, pid, pendingTribe);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of TRIBE rewards.
    function harvest(uint256 pid, address to) public nonReentrant {
        updatePool(pid);
        _harvest(pid, to);
    }

    //////////////////////////////////////////////////////////////////////////////
    // ----> if you call emergency withdraw, you are forfeiting your rewards <----
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the deposited tokens.
    function emergencyWithdraw(uint256 pid, address to) public nonReentrant {
        updatePool(pid);
        PoolInfo storage pool = poolInfo[pid];

        uint256 totalUnlocked = 0;
        uint256 virtualLiquidityDelta = 0;
        for (uint256 i = 0; i < depositInfo[pid][msg.sender].length; i++) {
            DepositInfo storage poolDeposit = depositInfo[pid][msg.sender][i];

            // if the user has locked the tokens for at least the 
            // lockup period or the pool has been unlocked, allow 
            // user to withdraw their principle
            require(poolDeposit.unlockBlock <= block.number || pool.unlocked == true, "tokens locked");

            totalUnlocked += poolDeposit.amount;

            // update the aggregated deposit virtual amount
            // update the virtualTotalSupply
            virtualLiquidityDelta += (poolDeposit.amount * poolDeposit.multiplier) / SCALE_FACTOR;
        }

        // subtract virtualLiquidity Delta from the virtual total supply of this pool
        pool.virtualTotalSupply -= virtualLiquidityDelta;

        // remove the array of deposits and userInfo struct
        delete depositInfo[pid][msg.sender];
        delete userInfo[pid][msg.sender];

        IRewarder _rewarder = rewarder[pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onSushiReward(pid, msg.sender, to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        stakedToken[pid].safeTransfer(to, totalUnlocked);
        emit EmergencyWithdraw(msg.sender, pid, totalUnlocked, to);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./ICoreRef.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title A Reference to Core
/// @author Fei Protocol
/// @notice defines some modifiers and utilities around interacting with Core
abstract contract CoreRef is ICoreRef, Pausable {
    ICore private _core;

    /// @notice a role used with a subset of governor permissions for this contract only
    bytes32 public override CONTRACT_ADMIN_ROLE;

    /// @notice boolean to check whether or not the contract has been initialized.
    /// cannot be initialized twice.
    bool private _initialized;

    constructor(address coreAddress) {
        _initialize(coreAddress);
    }

    /// @notice CoreRef constructor
    /// @param coreAddress Fei Core to reference
    function _initialize(address coreAddress) internal {
        require(!_initialized, "CoreRef: already initialized");
        _initialized = true;

        _core = ICore(coreAddress);
        _setContractAdminRole(_core.GOVERN_ROLE());
    }

    modifier ifMinterSelf() {
        if (_core.isMinter(address(this))) {
            _;
        }
    }

    modifier onlyMinter() {
        require(_core.isMinter(msg.sender), "CoreRef: Caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(_core.isBurner(msg.sender), "CoreRef: Caller is not a burner");
        _;
    }

    modifier onlyPCVController() {
        require(
            _core.isPCVController(msg.sender),
            "CoreRef: Caller is not a PCV controller"
        );
        _;
    }

    modifier onlyGovernorOrAdmin() {
        require(
            _core.isGovernor(msg.sender) ||
            isContractAdmin(msg.sender),
            "CoreRef: Caller is not a governor or contract admin"
        );
        _;
    }

    modifier onlyGovernor() {
        require(
            _core.isGovernor(msg.sender),
            "CoreRef: Caller is not a governor"
        );
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || 
            _core.isGuardian(msg.sender),
            "CoreRef: Caller is not a guardian or governor"
        );
        _;
    }

    modifier onlyFei() {
        require(msg.sender == address(fei()), "CoreRef: Caller is not FEI");
        _;
    }

    /// @notice set new Core reference address
    /// @param newCore the new core address
    function setCore(address newCore) external override onlyGovernor {
        require(newCore != address(0), "CoreRef: zero address");
        address oldCore = address(_core);
        _core = ICore(newCore);
        emit CoreUpdate(oldCore, newCore);
    }

    /// @notice sets a new admin role for this contract
    function setContractAdminRole(bytes32 newContractAdminRole) external override onlyGovernor {
        _setContractAdminRole(newContractAdminRole);
    }

    /// @notice returns whether a given address has the admin role for this contract
    function isContractAdmin(address _admin) public view override returns (bool) {
        return _core.hasRole(CONTRACT_ADMIN_ROLE, _admin);
    }

    /// @notice set pausable methods to paused
    function pause() public override onlyGuardianOrGovernor {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    function unpause() public override onlyGuardianOrGovernor {
        _unpause();
    }

    /// @notice address of the Core contract referenced
    /// @return ICore implementation address
    function core() public view override returns (ICore) {
        return _core;
    }

    /// @notice address of the Fei contract referenced by Core
    /// @return IFei implementation address
    function fei() public view override returns (IFei) {
        return _core.fei();
    }

    /// @notice address of the Tribe contract referenced by Core
    /// @return IERC20 implementation address
    function tribe() public view override returns (IERC20) {
        return _core.tribe();
    }

    /// @notice fei balance of contract
    /// @return fei amount held
    function feiBalance() public view override returns (uint256) {
        return fei().balanceOf(address(this));
    }

    /// @notice tribe balance of contract
    /// @return tribe amount held
    function tribeBalance() public view override returns (uint256) {
        return tribe().balanceOf(address(this));
    }

    function _burnFeiHeld() internal {
        fei().burn(feiBalance());
    }

    function _mintFei(uint256 amount) internal {
        fei().mint(address(this), amount);
    }

    function _setContractAdminRole(bytes32 newContractAdminRole) internal {
        bytes32 oldContractAdminRole = CONTRACT_ADMIN_ROLE;
        CONTRACT_ADMIN_ROLE = newContractAdminRole;
        emit ContractAdminRoleUpdate(oldContractAdminRole, newContractAdminRole);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "../core/ICore.sol";

/// @title CoreRef interface
/// @author Fei Protocol
interface ICoreRef {
    // ----------- Events -----------

    event CoreUpdate(address indexed oldCore, address indexed newCore);

    event ContractAdminRoleUpdate(bytes32 indexed oldContractAdminRole, bytes32 indexed newContractAdminRole);

    // ----------- Governor only state changing api -----------

    function setCore(address newCore) external;

    function setContractAdminRole(bytes32 newContractAdminRole) external;

    // ----------- Governor or Guardian only state changing api -----------

    function pause() external;

    function unpause() external;

    // ----------- Getters -----------

    function core() external view returns (ICore);

    function fei() external view returns (IFei);

    function tribe() external view returns (IERC20);

    function feiBalance() external view returns (uint256);

    function tribeBalance() external view returns (uint256);

    function CONTRACT_ADMIN_ROLE() external view returns (bytes32);

    function isContractAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPermissions.sol";
import "../token/IFei.sol";

/// @title Core Interface
/// @author Fei Protocol
interface ICore is IPermissions {
    // ----------- Events -----------

    event FeiUpdate(address indexed _fei);
    event TribeUpdate(address indexed _tribe);
    event GenesisGroupUpdate(address indexed _genesisGroup);
    event TribeAllocation(address indexed _to, uint256 _amount);
    event GenesisPeriodComplete(uint256 _timestamp);

    // ----------- Governor only state changing api -----------

    function init() external;

    // ----------- Governor only state changing api -----------

    function setFei(address token) external;

    function setTribe(address token) external;

    function allocateTribe(address to, uint256 amount) external;

    // ----------- Getters -----------

    function fei() external view returns (IFei);

    function tribe() external view returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Permissions interface
/// @author Fei Protocol
interface IPermissions is IAccessControl {
    // ----------- Governor only state changing api -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantMinter(address minter) external;

    function grantBurner(address burner) external;

    function grantPCVController(address pcvController) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function revokeMinter(address minter) external;

    function revokeBurner(address burner) external;

    function revokePCVController(address pcvController) external;

    function revokeGovernor(address governor) external;

    function revokeGuardian(address guardian) external;

    // ----------- Revoker only state changing api -----------

    function revokeOverride(bytes32 role, address account) external;

    // ----------- Getters -----------

    function isBurner(address _address) external view returns (bool);

    function isMinter(address _address) external view returns (bool);

    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isPCVController(address _address) external view returns (bool);

    function GUARDIAN_ROLE() external view returns (bytes32);

    function GOVERN_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    function MINTER_ROLE() external view returns (bytes32);

    function PCV_CONTROLLER_ROLE() external view returns (bytes32);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FEI stablecoin interface
/// @author Fei Protocol
interface IFei is IERC20 {
    // ----------- Events -----------

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(
        address indexed _to,
        address indexed _burner,
        uint256 _amount
    );

    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    // ----------- State changing api -----------

    function burn(uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ----------- Burner only state changing api -----------

    function burnFrom(address account, uint256 amount) external;

    // ----------- Minter only state changing api -----------

    function mint(address account, uint256 amount) external;

    // ----------- Governor only state changing api -----------

    function setIncentiveContract(address account, address incentive) external;

    // ----------- Getters -----------

    function incentiveContract(address account) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
    function onSushiReward(uint256 pid, address user, address recipient, uint256 sushiAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 sushiAmount) external view returns (IERC20[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}