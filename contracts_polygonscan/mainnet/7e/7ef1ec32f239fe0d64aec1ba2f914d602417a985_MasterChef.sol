// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//  _ __   ___  __ _ _ __ ______ _ _ __  
// | '_ \ / _ \/ _` | '__|_  / _` | '_ \ 
// | |_) |  __/ (_| | |   / / (_| | |_) |
// | .__/ \___|\__,_|_|  /___\__,_| .__/ 
// | |                            | |    
// |_|                            |_|    

// https://pearzap.com/

import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IReferral.sol";
import "./ILocker.sol";
import "./Address.sol";
import "./SafeBEP20.sol";
import "./SafeMath.sol";
import "./BEP20.sol";
import "./PEARToken.sol";



// File: contracts/MasterChef.sol

pragma solidity 0.6.12;


// MasterChef is the master of Pear. He can make Pear and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once PEAR is sufficiently
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
        uint256 noWithdrawalFeeAfter; //No withdrawal fee after this duration
        //
        // We do some fancy math here. Basically, any point in time, the amount of PEARs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPearPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPearPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. PEARs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that PEARs distribution occurs.
        uint256 accPearPerShare;   // Accumulated PEARs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 harvestInterval;  // Harvest interval in seconds
        uint256 withdrawalFeeInterval; // Withdrawal fee minimum interval in seconds
        uint256 withdrawalFeeBP; // Withdrawal fee in basis points when the withdrawal occurs before the minimum interval
    }

    // PEAR token
    PearToken public pear;
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    // Deposit Charity address
    address public charityAddress;    
    // Lottery contract address : default address is the burn address and will be updated when lottery release
    address public lotteryAddress;
    // PEAR tokens created per block.
    uint256 public pearPerBlock;
    // Bonus muliplier for early pear makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_WITHDRAWFEE_INTERVAL = 5 days;    
    // Max deposit fee : 10% (in basis point)
    uint256 public constant MAXIMUM_DEPOSIT_FEE = 1000;
    // Max withdrawal fee : 10% (in basis point)
    uint256 public constant MAXIMUM_WITHDRAWAL_FEE = 1000;   
    // Lottery mint rate : maximum 5% (in basis point) :  default rate is 0 and will be updated when lottery release
    uint16 public lotteryMintRate;
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;  
    // Charity fee is a part of deposit fee (in basis point)
    uint16 public charityFeeBP;
    // Locker interface
    ILocker pearLocker;
    // Locker adresse
    address public pearLockerAddress;
    // Locker rate (in basis point) if = 0 locker desactivated
    uint16 public lockerRate;
    

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when PEAR mining starts.
    uint256 public startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    // Pear referral contract address.
    IReferral public pearReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 100;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 newAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 newAmount);
    event FeeAddressUpdated(address indexed user, address indexed newAddress);
    event CharityAddressUpdated(address indexed user, address indexed newAddress);
    event CharityFeeRateUpdated(address indexed user, uint256 previousAmount, uint16 newAmount);
    event DevAddressUpdated(address indexed user, address indexed newAddress);
    event PearReferralUpdated(address indexed user, IReferral newAddress);
    event PearLockerUpdated(address indexed user, ILocker newAddress);
    event LockerRateUpdated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event ReferralRateUpdated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event LotteryAddressUpdated(address indexed user, address indexed newAddress);
    event LotteryMintRateUpdated(address indexed user, uint256 previousAmount, uint16 newAmount);

    constructor(
        PearToken _pear,
        uint256 _startBlock,
        uint256 _pearPerBlock,
        address _pearLockerAddress
    ) public {
        pear = _pear;
        startBlock = _startBlock;
        pearPerBlock = _pearPerBlock;
        lotteryAddress = BURN_ADDRESS;
        lotteryMintRate = 0;
        charityFeeBP = 1000;
        lockerRate = 5000;

        devAddress = msg.sender;
        feeAddress = msg.sender;
        charityAddress = msg.sender;
        pearLockerAddress = _pearLockerAddress;
        pearLocker = ILocker(_pearLockerAddress);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
	// add a check for avoid duplicate lptoken
    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }    

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, uint256 _harvestInterval, uint256 _withdrawalFeeInterval, uint256 _withdrawalFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        // deposit fee can't excess more than 10%
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE, "add: invalid deposit fee basis points");
        // withdrawal fee can't excess more than 10%
        require(_withdrawalFeeBP <= MAXIMUM_WITHDRAWAL_FEE, "add: invalid deposit fee basis points");      
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        require(_withdrawalFeeInterval <= MAXIMUM_WITHDRAWFEE_INTERVAL, "add: invalid withdrawal fee interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPearPerShare: 0,
            depositFeeBP: _depositFeeBP,
            harvestInterval: _harvestInterval,
            withdrawalFeeInterval: _withdrawalFeeInterval,
            withdrawalFeeBP: _withdrawalFeeBP
        }));
    }

    // Update the given pool's PEAR allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _harvestInterval, uint256 _withdrawalFeeInterval, uint256 _withdrawalFeeBP, bool _withUpdate) public onlyOwner {
        // deposit fee can't excess more than 10%
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE, "set: invalid deposit fee basis points");
        // withdrawal fee can't excess more than 10%
        require(_withdrawalFeeBP <= MAXIMUM_WITHDRAWAL_FEE, "add: invalid deposit fee basis points");         
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].withdrawalFeeInterval = _withdrawalFeeInterval;
        poolInfo[_pid].withdrawalFeeBP = _withdrawalFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending PEARs on frontend.
    function pendingPear(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPearPerShare = pool.accPearPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 pearReward = multiplier.mul(pearPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accPearPerShare = accPearPerShare.add(pearReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accPearPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest PEARs.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }
    
    // View function to see if user withdrawal fees apply to the harvest
    function noWithdrawFee(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.noWithdrawalFeeAfter;
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
        uint256 pearReward = multiplier.mul(pearPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pear.mint(devAddress, pearReward.mul(100).div(1000));
        // Automatically burn 2% of minted tokens
        pear.mint(BURN_ADDRESS, pearReward.mul(20).div(1000));
        // Automatically mint some PEAR for the lottery pot
        if (address(lotteryAddress) != address(0) && lotteryMintRate > 0) {
            pear.mint(lotteryAddress, pearReward.mul(lotteryMintRate).div(10000));
        }        
        pear.mint(address(this), pearReward);
        pool.accPearPerShare = pool.accPearPerShare.add(pearReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for PEAR allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && address(pearReferral) != address(0) && address(pearReferral) != BURN_ADDRESS && _referrer != address(0) && _referrer != BURN_ADDRESS && _referrer != msg.sender) {
            pearReferral.recordReferral(msg.sender, _referrer);
        }
        payOrLockupPendingPear(_pid,false);
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (address(pool.lpToken) == address(pear)) {
                uint256 burnTax = _amount.mul(pear.burnRateTax()).div(10000);
                _amount = _amount.sub(burnTax);
            }
            if (pool.depositFeeBP > 0) {
                if (charityFeeBP > 0) {
                    uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                    uint256 charityFee = depositFee.mul(charityFeeBP).div(10000);
                    user.amount = user.amount.add(_amount).sub(depositFee);
                    pool.lpToken.safeTransfer(feeAddress, depositFee.sub(charityFee));
                    pool.lpToken.safeTransfer(charityAddress, charityFee);                    
                } else {
                    uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                    user.amount = user.amount.add(_amount).sub(depositFee);
                    pool.lpToken.safeTransfer(feeAddress, depositFee);
                }  
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accPearPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        payOrLockupPendingPear(_pid,true);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accPearPerShare).div(1e12);
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
        user.noWithdrawalFeeAfter = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }


    // Pay or lockup pending PEARs.
    function payOrLockupPendingPear(uint256 _pid, bool _isWithdrawal) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }
        
        if (user.noWithdrawalFeeAfter == 0) {
            user.noWithdrawalFeeAfter = block.timestamp.add(pool.withdrawalFeeInterval);
        }        

        // pending reward for user
        uint256 pending = user.amount.mul(pool.accPearPerShare).div(1e12).sub(user.rewardDebt);

        if (_isWithdrawal) {
             // if user withdrawal before the interval, user get X% less of pending reward               
            if (noWithdrawFee(_pid, msg.sender)==false) {
                uint256 withdrawalfeeamount = pending.mul(pool.withdrawalFeeBP).div(10000);
                pending = pending.sub(withdrawalfeeamount);
                // tax on withdrawal is send to the burn address
                safePearTransfer(BURN_ADDRESS, withdrawalfeeamount);     
            }
            // reset timer at each withdrawal
            user.noWithdrawalFeeAfter = block.timestamp.add(pool.withdrawalFeeInterval);                
        }        
        
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
                
                if (address(pearLocker) != address(0)){
                    uint256 startReleaseBlock = ILocker(pearLocker).getStartReleaseBlock();
                    if (lockerRate > 0 && block.number < startReleaseBlock) {
                        uint256 _lockerAmount = totalRewards.mul(lockerRate).div(10000);
                        totalRewards = totalRewards.sub(_lockerAmount);
                        IBEP20(pear).safeIncreaseAllowance(address(pearLockerAddress), _lockerAmount);
                        ILocker(pearLocker).lock(msg.sender, _lockerAmount); 
                    }
                }
                    

                // send rewards 
                safePearTransfer(msg.sender, totalRewards);
                payReferralCommission(msg.sender, totalRewards); // extra mint for referral
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe pear transfer function, just in case if rounding error causes pool to not have enough PEARs.
    function safePearTransfer(address _to, uint256 _amount) internal {
        uint256 pearBal = pear.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > pearBal) {
            transferSuccess = pear.transfer(_to, pearBal);
        } else {
            transferSuccess = pear.transfer(_to, _amount);
        }
        require(transferSuccess, "safePearTransfer: transfer failed");
    }

    // Update dev address by the previous dev address
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
        emit DevAddressUpdated(msg.sender, _devAddress);
    }

    //Update fee address by the previous fee address
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
        emit FeeAddressUpdated(msg.sender, _feeAddress);
    }
    
    //Update charity address by the previous charity address
    function setCharityAddress(address _charityAddress) public {
        require(msg.sender == charityAddress, "setCharityAddress: FORBIDDEN");
        require(_charityAddress != address(0), "setCharityAddress: ZERO");
        charityAddress = _charityAddress;
        emit CharityAddressUpdated(msg.sender, _charityAddress);
    }    

    //Update lottery address by the owner
    function setLotteryAddress(address _lotteryAddress) public onlyOwner {
        require(_lotteryAddress != address(0), "setLotteryAddress: ZERO");
        lotteryAddress = _lotteryAddress;
        emit LotteryAddressUpdated(msg.sender, _lotteryAddress);
    }    

    // Update emission rate by the owner
    function updateEmissionRate(uint256 _pearPerBlock) public onlyOwner {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, pearPerBlock, _pearPerBlock);
        pearPerBlock = _pearPerBlock;
    }

    // Update the pear referral contract address by the owner
    function setPearReferral(IReferral _pearReferral) public onlyOwner {
        pearReferral = _pearReferral;
        emit PearReferralUpdated(msg.sender, _pearReferral);
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        // Max referral commission rate: 10%.
        require(_referralCommissionRate <= 1000, "setReferralCommissionRate: invalid referral commission rate basis points");
        emit ReferralRateUpdated(msg.sender, referralCommissionRate, _referralCommissionRate);
        referralCommissionRate = _referralCommissionRate;

    }

    // Update lottery mint rate by the owner
    function setLotteryMintRate(uint16 _lotteryMintRate) public onlyOwner {
        // Max lottery mint rate: 5%.
        require(_lotteryMintRate <= 500, "setLotteryMintRate: invalid lottery mint rate basis points");
        emit LotteryMintRateUpdated(msg.sender, lotteryMintRate, _lotteryMintRate);
        lotteryMintRate = _lotteryMintRate;
    }  

    // Update charity fee rate by the owner
    function setCharityFeeRate(uint16 _charityFeeBP) public onlyOwner {
        // Max charity fee rate: 50%
        // charity fee is a part of deposit fee and not added fee
        require(_charityFeeBP <= 5000, "setCharityFeeRate: invalid charity fee rate basis points");
        emit CharityFeeRateUpdated(msg.sender, charityFeeBP, _charityFeeBP);
        charityFeeBP = _charityFeeBP;
    }     

    // Update the pear locker contract address by the owner
    function setPearLocker(ILocker _pearLocker) public onlyOwner {
        pearLocker = _pearLocker;
        emit PearLockerUpdated(msg.sender, _pearLocker);
    }   

    // Update locker rate by the owner
    function setLockerRate(uint16 _lockerRate) public onlyOwner {
        // Max locker rate: 50%.
        require(_lockerRate <= 5000, "setLockerRate: invalid locker rate basis points");
        emit LockerRateUpdated(msg.sender, lockerRate, _lockerRate);
        lockerRate = _lockerRate;
    }     
    

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(pearReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = pearReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && referrer != BURN_ADDRESS && commissionAmount > 0) {
                pear.mint(referrer, commissionAmount);
                pearReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }
}