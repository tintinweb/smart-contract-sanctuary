// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./SGIRLn.sol";

// FutureMasterChef is the master of Sgirl. He can make Sgirl and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SGIRL is sufficiently
//
// Have fun reading it. Hopefully it's bug-free. God bless.


contract FutureMasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SGIRLs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSgirlPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSgirlPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SGIRLs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SGIRLs distribution occurs.
        uint256 accSgirlPerShare;   // Accumulated SGIRLs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The SGIRL TOKEN!
    SuperGirlion public sgirl;
    
    // Dev address.
    address public devAddress = 0x4C137a6d83E9cd8cdcb6aE28FBb86999A62bA83C;
    
     // Promo address.
    address public promoAddress = 0x28AF9a485f9040794dd44D80530BA147edB51927;
    
    // Deposit Fee address
    address public feeAddress = 0x40db3C9070b28F8FAC4E6abeB999568d8A792824;

    // SGIRL tokens created per block.
    uint256 public sgirlPerBlock;
    
    // Bonus muliplier for early sgirl makers.
    uint256 public constant BONUS_MULTIPLIER = 1;

    // Initial emission rate: 1 SGIRL per block.
    uint256 public constant INITIAL_EMISSION_RATE = 1000 finney;
    
    // Minimum emission rate: 0.00 SGIRL per block.
    uint256 public constant MINIMUM_EMISSION_RATE = 0 finney;
    
    // Reduce emission every 28800 blocks ~ 24 hours.
    uint256 public constant EMISSION_REDUCTION_PERIOD_BLOCKS = 28800;
    
    // Emission reduction rate per period in basis points: 10%.
    uint256 public constant EMISSION_REDUCTION_RATE_PER_PERIOD = 1000;
    
    // Last reduction period index
    uint256 public lastReductionPeriodIndex = 0;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    
    // The block number when SGIRL mining starts.
    uint256 public startBlock;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);


    constructor(
        SuperGirlion _sgirl,
        uint256 _startBlock
        
    ) public {
        sgirl = _sgirl;
        startBlock = _startBlock;
        sgirlPerBlock = INITIAL_EMISSION_RATE;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 400, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accSgirlPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's SGIRL allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 400, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending SGIRLs on frontend.
    function pendingSgirl(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSgirlPerShare = pool.accSgirlPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sgirlReward = multiplier.mul(sgirlPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSgirlPerShare = accSgirlPerShare.add(sgirlReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accSgirlPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 sgirlReward = multiplier.mul(sgirlPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        sgirl.mint(devAddress, sgirlReward.mul(9).div(100));
        sgirl.mint(promoAddress, sgirlReward.mul(1).div(100));
        sgirl.mint(address(this), sgirlReward);
        pool.accSgirlPerShare = pool.accSgirlPerShare.add(sgirlReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to FutureMasterChef for SGIRL allocation.
    // Take care of adding the RIGHT transfetrax of SGIRL token!
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSgirlPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeSgirlTransfer(msg.sender, pending);
            }
        }
        
        if (_amount > 0) {
            // Thanks for RugDoc advice for correct accounting of token with transfetax!
            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 _after = pool.lpToken.balanceOf(address(this));
            _amount = _after.sub(before); // Real amount of LP transfer to this address
            
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        
        user.rewardDebt = user.amount.mul(pool.accSgirlPerShare).div(1e12);
        updateEmissionRate();
        emit Deposit(msg.sender, _pid, _amount);
    }
        
    // Withdraw LP tokens from FutureMasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSgirlPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeSgirlTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSgirlPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe sgirl transfer function, just in case if rounding error causes pool to not have enough SGIRLs.
    function safeSgirlTransfer(address _to, uint256 _amount) internal {
        uint256 sgirlBal = sgirl.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > sgirlBal) {
            transferSuccess = sgirl.transfer(_to, sgirlBal);
        } else {
            transferSuccess = sgirl.transfer(_to, _amount);
        }
        require(transferSuccess, "safeSgirlTransfer: Transfer failed");
    }


    // Reduce emission rate by 10% every 28800 blocks ~ 24hours. This function can be called publicly.
    function updateEmissionRate() public {
        
        if(block.number <= startBlock){
            return;
        }
        if(sgirlPerBlock <= MINIMUM_EMISSION_RATE){
            return;
        }

        uint256 currentIndex = block.number.sub(startBlock).div(EMISSION_REDUCTION_PERIOD_BLOCKS);
        if (currentIndex <= lastReductionPeriodIndex) {
            return;
        }

        uint256 newEmissionRate = sgirlPerBlock;
        for (uint256 index = lastReductionPeriodIndex; index < currentIndex; ++index) {
            newEmissionRate = newEmissionRate.mul(1e4 - EMISSION_REDUCTION_RATE_PER_PERIOD).div(1e4);
        }

        newEmissionRate = newEmissionRate < MINIMUM_EMISSION_RATE ? MINIMUM_EMISSION_RATE : newEmissionRate;
        if (newEmissionRate >= sgirlPerBlock) {
            return;
        }

        massUpdatePools();
        lastReductionPeriodIndex = currentIndex;
        uint256 previousEmissionRate = sgirlPerBlock;
        sgirlPerBlock = newEmissionRate;
        emit EmissionRateUpdated(msg.sender, previousEmissionRate, newEmissionRate);
    }

}