// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Aladdin.sol";
import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";



// FutureMasterChef is the master of Aladdin. He can make Aladdin and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ALADDIN is sufficiently
//
// Have fun reading it. Hopefully it's bug-free. God bless.


contract MasterChefAladdin is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ALADDINs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that ALADDINs distribution occurs.
        uint256 accAladdinPerShare;   // Accumulated ALADDINs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The ALADDIN TOKEN!
    Aladdin public aladdin;
    
    // Dev address.
    address public devAddress = 0xb0BcBf02f9E890888EdB469B73817CbB183C19c3;
    
    // Deposit Fee address
    address public feeAddress = 0x0B096F5e39e527F70fa3333c36B198A05c7B749E;


    // ALADDIN tokens created per block.
    uint256 public aladdinPerBlock;
    
    // Bonus muliplier for early aladdin makers.
    uint256 public constant BONUS_MULTIPLIER = 1;

    // Initial emission rate: 0.7 ALADDIN per block.
    uint256 public constant INITIAL_EMISSION_RATE = 700 finney;
    
    // Minimum emission rate: 0.00 ALADDIN per block.
    uint256 public constant MINIMUM_EMISSION_RATE = 0 finney;
    
    // Reduce emission every 57600 blocks ~ 48 hours.
    uint256 public constant EMISSION_REDUCTION_PERIOD_BLOCKS = 57600;
    
    // Emission reduction rate per period in basis points: 20%.
    uint256 public constant EMISSION_REDUCTION_RATE_PER_PERIOD = 2000;
    
    // Last reduction period index
    uint256 public lastReductionPeriodIndex = 0;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    
    // The block number when ALADDIN mining starts.
    uint256 public startBlock;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event SetEmissionRate(address indexed user, uint256 _emission);


    constructor(
        Aladdin _aladdin,
        uint256 _startBlock
        
    ) public {
        aladdin = _aladdin;
        startBlock = _startBlock;
        aladdinPerBlock = INITIAL_EMISSION_RATE;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 400, "add: invalid deposit fee");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accAladdinPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's ALADDIN allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 400, "set: invalid deposit fee");
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

    // View function to see pending ALADDINs on frontend.
    function pendingAladdin(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accAladdinPerShare = pool.accAladdinPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 aladdinReward = multiplier.mul(aladdinPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accAladdinPerShare = accAladdinPerShare.add(aladdinReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accAladdinPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 aladdinReward = multiplier.mul(aladdinPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        aladdin.mint(address(this), aladdinReward);
        aladdin.mint(feeAddress, aladdinReward.div(10));
        pool.accAladdinPerShare = pool.accAladdinPerShare.add(aladdinReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to FutureMasterChef for ALADDIN allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accAladdinPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeAladdinTransfer(msg.sender, pending);
            }
        }
        
        if (_amount > 0) {
             // Correct arrival amount calculation of transfertax token.
            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 _after = pool.lpToken.balanceOf(address(this));
            _amount = _after.sub(before); 
             // Correct arrival amount calculation of transfertax token.
            
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accAladdinPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }
        
    // Withdraw LP tokens from FutureMasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accAladdinPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeAladdinTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accAladdinPerShare).div(1e12);
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

    // Safe ALADDIN transfer function, just in case if rounding error causes pool to not have enough ALADDINs.
    function safeAladdinTransfer(address _to, uint256 _amount) internal {
        uint256 aladdinBal = aladdin.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > aladdinBal) {
            transferSuccess = aladdin.transfer(_to, aladdinBal);
        } else {
            transferSuccess = aladdin.transfer(_to, _amount);
        }
        require(transferSuccess, "safeAladdinTransfer: Transfer failed");
    }

    // Reduce emission rate by 20% every 57600 blocks ~ 24hours. This function can be called publicly.
    function updateEmissionRate() public {
        
        if(block.number <= startBlock){
            return;
        }
        if(aladdinPerBlock <= MINIMUM_EMISSION_RATE){
            return;
        }

        uint256 currentIndex = block.number.sub(startBlock).div(EMISSION_REDUCTION_PERIOD_BLOCKS);
        if (currentIndex <= lastReductionPeriodIndex) {
            return;
        }

        uint256 newEmissionRate = aladdinPerBlock;
        for (uint256 index = lastReductionPeriodIndex; index < currentIndex; ++index) {
            newEmissionRate = newEmissionRate.mul(1e4 - EMISSION_REDUCTION_RATE_PER_PERIOD).div(1e4);
        }

        newEmissionRate = newEmissionRate < MINIMUM_EMISSION_RATE ? MINIMUM_EMISSION_RATE : newEmissionRate;
        if (newEmissionRate >= aladdinPerBlock) {
            return;
        }

        massUpdatePools();
        lastReductionPeriodIndex = currentIndex;
        uint256 previousEmissionRate = aladdinPerBlock;
        aladdinPerBlock = newEmissionRate;
        emit EmissionRateUpdated(msg.sender, previousEmissionRate, newEmissionRate);
    }

}