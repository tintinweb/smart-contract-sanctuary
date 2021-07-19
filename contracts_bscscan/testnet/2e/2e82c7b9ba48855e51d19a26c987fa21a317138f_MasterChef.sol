// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './SafeMath.sol';
import './IBEP20.sol';
import './SafeBEP20.sol';
import './Ownable.sol';

import './MandarkToken.sol';
import './IMandarkReferral.sol';

// MasterChef is the core engine of Mandark's laboratory. It can make MANDARK tokens for him so that he continue making plans on how to impress DeeDee.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once MANDARK is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 boost; // current user boost for this pool.
        //
        // We do some fancy math here. Basically, any point in time, the amount of MANDARKs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMANDARKPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accMANDARKPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. MANDARKs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that MANDARKs distribution occurs.
        uint256 accMANDARKPerShare;   // Accumulated MANDARKs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 harvestInterval;  // Harvest interval in seconds
        bool isBoostEnabled;      // Is boost enabled for this Pool
    }

    // The MANDARK TOKEN!
    Mandark public MANDARK;
    // Dev address.
    address public devaddr;
    // Lab address - to support deflationary token.
    address public labaddr;
    // MANDARK tokens created per block.
    uint256 public mandarkPerBlock;
    // final MANDARK per block after emission reduction.
    uint256 public targetMandarkPerBlock;
    // emission halving time
    uint256 public mandarkPerBlockHalvingTime = block.timestamp;
    // emission halving interval (default 12h)
    uint256 public mandarkHalvingInterval = 43200;
    // emission decrease percentage (default 3%)
    uint256 public emissionRateDecreasePerBlock = 3;

    // Bonus muliplier for early MANDARK makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    //Amount to be added to the boost on every click of the boost button. 100 means 1% increase
    uint256 public userBoostAmount = 10000;
    //Amount % to be paid for doing Boost on a Farm/Pool
    uint256 public constant POOL_BOOST_FEE = 50;
    //max boost per pool
    uint256 public maxBoostAmount = 30000;
    // total amount of tokens minted due to boost
    uint256 public totalBoostedtokens = 0;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when MANDARK mining starts.
    uint256 public startBlock;

    // Total locked up rewards
    uint256 public totalLockedUpRewards;
    // Total MANDARK in MANDARK Pools (can be multiple pools)
    uint256 public totalMANDARKInPools = 0;

    // referral contract address.
    IMandarkReferral public mandarkReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 500;
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;

    // Maximum deposit fee rate: 10%
    uint16 public constant MAXIMUM_DEPOSIT_FEE_RATE = 1000;
    // Min Havest interval: 1 hour
    uint256 public constant MINIMUM_HARVEST_INTERVAL = 3600;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    //DEAD TOKENS ADDRESS
    address public constant DEAD_TOKENS = 0x000000000000000000000000000000000000dEaD;



    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amountHarvest);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event Boost(address indexed user, uint256 indexed pid, uint256 userBoost);

    constructor(
        Mandark _MANDARK,
        address _devaddr,
        address _labaddr,
        address _feeAddress,
        uint256 _mandarkPerBlock,
        uint256 _targetMandarkPerBlock,
        uint256 _startBlock
    ) public {
        MANDARK = _MANDARK;
        devaddr = _devaddr;
        labaddr = _labaddr;
        feeAddress = _feeAddress;
        mandarkPerBlock = _mandarkPerBlock;
        targetMandarkPerBlock = _targetMandarkPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function remainRewards() external view returns (uint256) {
        return MANDARK.balanceOf(address(this)).sub(totalMANDARKInPools);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE, "add: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accMANDARKPerShare: 0,
            depositFeeBP: _depositFeeBP,
            harvestInterval : _harvestInterval,
            isBoostEnabled : false
        }));
    }

    // Update the given pool's MANDARK allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE, "set: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending MANDARKs on frontend.
    function pendingMANDARK(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMANDARKPerShare = pool.accMANDARKPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 mandarkReward = multiplier.mul(mandarkPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accMANDARKPerShare = accMANDARKPerShare.add(mandarkReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accMANDARKPerShare).div(1e12).sub(user.rewardDebt);

        if (pool.isBoostEnabled && user.boost > 0) {
            uint256 boostAmount = pending.mul(user.boost).div(10000);
            pending = pending.add(boostAmount);
        }

        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // View function to calc current Harvest Tax %
    function harvestTax(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        if (block.timestamp >= user.nextHarvestUntil) {
            return 0;
        } else {
            uint256 remainingBlocks = user.nextHarvestUntil.sub(block.timestamp);
            uint256 harvestTaxAmount = remainingBlocks.mul(100).div(pool.harvestInterval);

            if (harvestTaxAmount < 2) {
                return 0;
            } else {
                return harvestTaxAmount;
            }
        }

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

        autoReduceEmissionRate();

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 mandarkReward = multiplier.mul(mandarkPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        MANDARK.mint(devaddr, mandarkReward.div(20));
        MANDARK.mint(labaddr, mandarkReward.div(20));
        MANDARK.mint(address(this), mandarkReward);
        pool.accMANDARKPerShare = pool.accMANDARKPerShare.add(mandarkReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for MANDARK allocation.
    function deposit(uint256 _pid, uint256 _amount, bool _boost, address _referrer) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (_amount > 0 && address(mandarkReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            mandarkReferral.recordReferral(msg.sender, _referrer);
        }

        if (_boost) {
            require(pool.isBoostEnabled, "deposit:BOOST NOT ENABlED");
            require(canHarvest(_pid, msg.sender),'deposit:boost:BOOSTNOTREADY');
        }

        payOrLockupPendingMANDARK(_pid, _boost, _amount);

        if(!_boost && _amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);

                if (address(pool.lpToken) == address(MANDARK)) {
                    totalMANDARKInPools = totalMANDARKInPools.add(_amount).sub(depositFee);
                }
            } else {
                user.amount = user.amount.add(_amount);

                if (address(pool.lpToken) == address(MANDARK)) {
                    totalMANDARKInPools = totalMANDARKInPools.add(_amount);
                }
            }
        }
        user.rewardDebt = user.amount.mul(pool.accMANDARKPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        payOrLockupPendingMANDARK(_pid, false, _amount);
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);

            if (address(pool.lpToken) == address(MANDARK)) {
                totalMANDARKInPools = totalMANDARKInPools.sub(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accMANDARKPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.nextHarvestUntil = 0;
        user.rewardLockedUp = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        if (address(pool.lpToken) == address(MANDARK)) {
            totalMANDARKInPools = totalMANDARKInPools.sub(amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending MANDARK.
    function payOrLockupPendingMANDARK(uint256 _pid, bool _boost, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accMANDARKPerShare).div(1e12).sub(user.rewardDebt);

        if (pending > 0 || user.rewardLockedUp > 0) {

            if (_boost || _amount == 0) { // User wanna boost or harvest

                uint256 totalRewards = pending.add(user.rewardLockedUp);

                //Check if pool boost is enabled and add to total rewards
                if (pool.isBoostEnabled && user.boost > 0) {
                    uint256 boostAmount = totalRewards.mul(user.boost).div(10000);
                    totalRewards = totalRewards.add(boostAmount);
                    MANDARK.mint(address(this), boostAmount);
                }

                if (_boost) {
                    //add to poolBoost
                    user.boost = user.boost.add(userBoostAmount);
                    if (user.boost > maxBoostAmount) {
                        user.boost = maxBoostAmount;
                    }
                    //discount POOL_BOOST_FEE=50%
                    uint256 halfRewards = totalRewards.mul(POOL_BOOST_FEE).div(100);
                    safeMANDARKTransfer(DEAD_TOKENS, halfRewards);
                    safeMANDARKTransfer(msg.sender, halfRewards);
                    payReferralCommission(msg.sender, halfRewards);
                    //user.nextHarvestUntil = user.nextHarvestUntil.add(pool.harvestInterval);
                    emit Boost(msg.sender, _pid, user.boost);

                } else {

                    //Check Harvest Tax
                    uint256 harvestTaxAmount = harvestTax(_pid, msg.sender);
                    uint256 taxRewards = totalRewards.mul(harvestTaxAmount).div(100);
                    uint256 netRewards = totalRewards.sub(taxRewards);

                    // send rewards
                    safeMANDARKTransfer(DEAD_TOKENS, taxRewards);
                    safeMANDARKTransfer(msg.sender, netRewards);
                    payReferralCommission(msg.sender, netRewards);
                    emit Harvest(msg.sender, _pid, netRewards);
                }

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

            } else { // User is making another deposit or withdrawal & has some pending

                user.rewardLockedUp = user.rewardLockedUp.add(pending);
                totalLockedUpRewards = totalLockedUpRewards.add(pending);
                emit RewardLockedUp(msg.sender, _pid, pending);

            }

        }

    }

    // Safe MANDARK transfer function, just in case if rounding error causes pool to not have enough MANDARKs.
    function safeMANDARKTransfer(address _to, uint256 _amount) internal {
        uint256 mandarkBal = MANDARK.balanceOf(address(this)).sub(totalMANDARKInPools);
        if (_amount > mandarkBal) {
            MANDARK.transfer(_to, mandarkBal);
        } else {
            MANDARK.transfer(_to, _amount);
        }
    }

    function setBoostAmounts (uint256 _maxBoostAmount, uint256 _userBoostAmount) public onlyOwner {
        maxBoostAmount = _maxBoostAmount;
        userBoostAmount = _userBoostAmount;
    }

    function setPoolBoost (uint256 _pid, bool _isBoostEnabled) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.isBoostEnabled = _isBoostEnabled;
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public{
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _mandarkPerBlock) public onlyOwner {
        massUpdatePools();
        mandarkPerBlock = _mandarkPerBlock;
    }

    //Update emission halving settings
    function updateEmissionHalving(uint256 _mandarkHalvingInterval, uint256 _emissionRateDecreasePerBlock, uint256 _targetMandarkPerBlock) public onlyOwner {
        massUpdatePools();
        mandarkHalvingInterval = _mandarkHalvingInterval;
        emissionRateDecreasePerBlock = _emissionRateDecreasePerBlock;
        targetMandarkPerBlock = _targetMandarkPerBlock;
    }

    //auto-reduce emission
    function autoReduceEmissionRate() internal returns (bool) {
        uint mandarkPerBlockCurrentTime = block.timestamp;
        // if 12h passed and mandarkPerBlock > 0.03
        if((mandarkPerBlockCurrentTime.sub(mandarkPerBlockHalvingTime) >= mandarkHalvingInterval) && (mandarkPerBlock > targetMandarkPerBlock)){
            if(mandarkPerBlock.sub(mandarkPerBlock.mul(emissionRateDecreasePerBlock).div(100)) < targetMandarkPerBlock) mandarkPerBlock = targetMandarkPerBlock;
            else mandarkPerBlock = mandarkPerBlock.sub(mandarkPerBlock.mul(emissionRateDecreasePerBlock).div(100));

            mandarkPerBlockHalvingTime = mandarkPerBlockCurrentTime;
        }
        return true;
    }

    // Update start reward block
    function setStartRewardBlock(uint256 _block) public onlyOwner {
        startBlock = _block;
    }

    // Update the referral contract address by the owner
    function setReferralContract(IMandarkReferral _mandarkReferral) public onlyOwner {
        mandarkReferral = _mandarkReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(mandarkReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = mandarkReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {

                MANDARK.mint(referrer, commissionAmount);
                mandarkReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);

            }
        }
    }

}