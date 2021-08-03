// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


import "./PolyWhale.sol";

// MasterChef is the master of Whale. He can make Whale and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once WHALE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        //
        // We do some fancy math here. Basically, any point in time, the amount of WHALEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accWhalePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accWhalePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. WHALEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that WHALEs distribution occurs.
        uint256 accWhalePerShare;   // Accumulated WHALEs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 hodlMultiplierTimer;  // Time required to reach max multiplier
    }

    // The WHALE TOKEN!
    WhaleToken public whale;
    // Dev address.
    address public devAddress;
    // Bonus muliplier for early whale makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
     // Initial reduce emission every 14,400 blocks ~ 12 hours.
    uint256 public emissionReductionPeriodBlocks = 14400;
    // Initial emission reduction rate per period in basis points: 15%.
    uint256 public constant EMISSION_REDUCTION_RATE_PER_PERIOD = 1500;
    // Initial emission extended period per epoch in basis points: 130%.
    uint256 public constant EMISSION_EXTENDED_PERIOD_EACH_EPOCH = 1300;
    // Last reduction period index
    uint256 public lastReductionPeriodIndex = 0;
    // Initial emission rate: 0.5 WHALE per block.
    uint256 public constant INITIAL_EMISSION_RATE = 0.5 ether;
    // Minimum emission rate: 0.05 WHALE per block.
    uint256 public constant MINIMUM_EMISSION_RATE = 50 finney;

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
   

    // Deposit Fee address
    address public feeAddress;
    // WHALE tokens created per block.
    uint256 public whalePerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping(address => mapping(uint256 => uint256)) public userWhale;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when WHALE mining starts.
    uint256 public startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    // Whale referral contract address.
    // IWhaleReferral public whaleReferral; 
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 0;
    // Max referral commission rate: 0%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 0;
    // Max deposit fee: 4%.
    uint16 public constant MAXIMUM_DEPOSIT_FEE_BP = 400;
    // Referral Mapping
    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint256) public referralsCount; // referrer address => referrals count
    mapping(address => uint256) public totalReferralCommissions; // referrer address => total referral commissions
    // Pool Exists Mapper
    mapping(IBEP20 => bool) public poolExistence;
    // Pool ID Tracker Mapper
    mapping(IBEP20 => uint256) public poolIdForLpAddress;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(address indexed referrer, uint256 commission);

    constructor(
        WhaleToken _whale,
        uint256 _startBlock
    ) public {
        whale = _whale;
        startBlock = _startBlock;
        whalePerBlock = INITIAL_EMISSION_RATE;
        devAddress = msg.sender;
        feeAddress = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    // Added a check for <= 4% deposit fee so as to ensure no fraud
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, uint256 _hodlMultiplierTimer, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE_BP, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accWhalePerShare: 0,
            depositFeeBP: _depositFeeBP,
            hodlMultiplierTimer: _hodlMultiplierTimer //time required to reach 200% (max) of multiplier 
        }));
    }

    // Update the given pool's WHALE allocation point and deposit fee. Can only be called by the owner.
    // Added a check for <= 4% deposit fee so as to ensure no fraud
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _hodlMultiplierTimer, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE_BP, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].hodlMultiplierTimer = _hodlMultiplierTimer;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending WHALEs on frontend.
    function pendingWhale(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accWhalePerShare = pool.accWhalePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 whaleReward = multiplier.mul(whalePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accWhalePerShare = accWhalePerShare.add(whaleReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accWhalePerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 whaleReward = multiplier.mul(whalePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        whale.mint(devAddress, whaleReward.div(10));
        whale.mint(address(this), whaleReward.mul(2));
        pool.accWhalePerShare = pool.accWhalePerShare.add(whaleReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for WHALE allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer, bool toHarvest) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && _referrer != address(0) && _referrer != msg.sender) {
            recordReferral(msg.sender, _referrer);
        }
        payOrLockupPendingWhale(_pid, toHarvest);
        if (_amount > 0) {
            //account for transfer tax
            uint256 previousAmount = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 afterAmount =  pool.lpToken.balanceOf(address(this));
            _amount = afterAmount.sub(previousAmount);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accWhalePerShare).div(1e12);
        updateEmissionRate();
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        payOrLockupPendingWhale(_pid, true);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accWhalePerShare).div(1e12);
        updateEmissionRate();
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending WHALEs.
    function payOrLockupPendingWhale(uint256 _pid, bool toHarvest) internal {
        uint256 hodlMultiplier = 1;
        uint256 MaxMultiplier = 200;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];


        //----------------------------------- HODL MULTIPLIER -----------------------------------------//
        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.hodlMultiplierTimer);
        }
        
        // We do some simple math here to calculate the multiplier
        uint256 timePerPercent = pool.hodlMultiplierTimer.div(200);
        if (user.nextHarvestUntil <= block.timestamp){ // To ensure no error from sub
            hodlMultiplier = MaxMultiplier; 
        } else {
            uint256 hodlMultiplierTimeLeft = pool.hodlMultiplierTimer.sub(user.nextHarvestUntil.sub(block.timestamp));
            hodlMultiplier = hodlMultiplierTimeLeft.div(timePerPercent).add(1); // HODL Multiplier starting from 1%
        }

        if (hodlMultiplier > MaxMultiplier ) {
            hodlMultiplier = MaxMultiplier; // Maximum HODL Multiplier of 200%
            }
        else if (hodlMultiplier < 1){
            hodlMultiplier = 1;// Minimum HODL Multiplier of 1%
        }
        //----------------------------------- HODL MULTIPLIER -----------------------------------------//

        uint256 pending = user.amount.mul(pool.accWhalePerShare).div(1e12).sub(user.rewardDebt);
        if (toHarvest) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.hodlMultiplierTimer); // counterReset

                // send rewards with multiplier
              
                uint256 totalRewardsMultiplier = totalRewards.mul(hodlMultiplier).div(100);
                uint256 totalRewardsMultiplierToBurn = totalRewards.mul(2).sub(totalRewardsMultiplier);
                safeWhaleTransfer(msg.sender, totalRewardsMultiplier);
                payReferralCommission(msg.sender, totalRewardsMultiplier);
                safeWhaleTransfer(BURN_ADDRESS, totalRewardsMultiplierToBurn); // Burning extra tokens that are not collected
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe whale transfer function, just in case if rounding error causes pool to not have enough WHALEs.
    function safeWhaleTransfer(address _to, uint256 _amount) internal {
        uint256 whaleBal = whale.balanceOf(address(this));
        if (_amount > whaleBal) {
            whale.transfer(_to, whaleBal);
        } else {
            whale.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    // Update startBlock by the owner (added this to ensure that dev can delay startBlock due to the congestion in BSC). Only used if required. 
    function setstartBlock(uint256 _startBlock ) public onlyOwner {
        startBlock = _startBlock;
    }

    // Update whale Address by the owner (Used when redeploying token for stealth launch ). Only used if required. 
    // Added a check to ensure that token address can only be changed before any pools added
    function setTokenAddress(WhaleToken _whale) public onlyOwner {
        require(poolInfo.length == 0, "setTokenAddress: FORBIDDEN"); //
            whale = _whale;
    }


    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate() public {
        // require(block.number > startBlock, "updateEmissionRate: Can only be called after mining starts");
        // require(whalePerBlock > MINIMUM_EMISSION_RATE, "updateEmissionRate: Emission rate has reached the minimum threshold");
        if(block.number <= startBlock){
            return;
        }
        if(whalePerBlock <= MINIMUM_EMISSION_RATE){
            return;
        }
        uint256 currentIndex = block.number.sub(startBlock).div(emissionReductionPeriodBlocks);
        if (currentIndex <= lastReductionPeriodIndex) {
            return;
        }

        uint256 newEmissionRate = whalePerBlock;
        for (uint256 index = lastReductionPeriodIndex; index < currentIndex; ++index) {
            newEmissionRate = newEmissionRate.mul(1e4 - EMISSION_REDUCTION_RATE_PER_PERIOD).div(1e4);
        }

        newEmissionRate = newEmissionRate < MINIMUM_EMISSION_RATE ? MINIMUM_EMISSION_RATE : newEmissionRate;
        if (newEmissionRate >= whalePerBlock) {
            return;
        }
        massUpdatePools();
        lastReductionPeriodIndex = currentIndex;
        whalePerBlock = newEmissionRate;
        emissionReductionPeriodBlocks = emissionReductionPeriodBlocks.mul(EMISSION_EXTENDED_PERIOD_EACH_EPOCH).div(1e3);
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (referralCommissionRate > 0) {
            address referrer = getReferral(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);
            if (referrer != address(0) && commissionAmount > 0) {
                whale.mint(referrer, commissionAmount);
                recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }    
    
    // Get Referral Address for a Account
    function getReferral(address _user) public view returns (address) {
        return referrers[_user];
    }

    //Record Referral Comission
    function recordReferralCommission(address _referrer, uint256 _commission) internal {
        if (_referrer != address(0) && _commission > 0) {
            totalReferralCommissions[_referrer] += _commission;
            emit ReferralCommissionRecorded(_referrer, _commission);
        }
    }

    //Record Referral
    function recordReferral(address _user, address _referrer) internal {
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;
            emit ReferralRecorded(_user, _referrer);
        }
    }
}