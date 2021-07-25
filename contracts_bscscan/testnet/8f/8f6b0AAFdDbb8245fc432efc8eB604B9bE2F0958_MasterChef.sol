// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Aladin.sol";

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


// MasterChef is the Master of Aladin. He can make Aladin and he is a fair guy.
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ALADIN is sufficiently
// Have fun reading it. Hopefully it's bug-free. God bless.


contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ALADINs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accAladinPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accAladinPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ALADINs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that ALADINs distribution occurs.
        uint256 accAladinPerShare;   // Accumulated ALADINs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The ALADIN TOKEN!
    Aladin public aladin;
    
    // Dev address.
    address public devAddress = 0x31fB16419e710603D45DfB8aCAFdF651d8aa71Bd;
    
    // Deposit Fee address
    address public feeAddress = 0x0FC6b15ab41db1064C901A9E1C233c5Ffd40C535;
    
    // FEE Token
    address public BUSD = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    
    uint256 public feeAmount = 3 * 10**17;

    // ALADIN tokens created per block.
    uint256 public aladinPerBlock;
    
    // Bonus muliplier for early aladin makers.
    uint256 public constant BONUS_MULTIPLIER = 1;

    // Initial emission rate: 0.5 ALADIN per block.
    uint256 public constant INITIAL_EMISSION_RATE = 500 finney;
    
    // Minimum emission rate: 0.00 ALADIN per block.
    uint256 public constant MINIMUM_EMISSION_RATE = 0 finney;
    
    // Reduce emission every 28800 blocks ~ 24 hours.
    uint256 public constant EMISSION_REDUCTION_PERIOD_BLOCKS = 14400;
    
    // Emission reduction rate per period in basis points: 9%.
    uint256 public constant EMISSION_REDUCTION_RATE_PER_PERIOD = 900;
    
    // Last reduction period index
    uint256 public lastReductionPeriodIndex = 0;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    
    // The block number when ALADIN mining starts.
    uint256 public startBlock;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);


    constructor(
        Aladin _aladin,
        uint256 _startBlock
        
    ) public {
        aladin = _aladin;
        startBlock = _startBlock;
        aladinPerBlock = INITIAL_EMISSION_RATE;
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
            accAladinPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's ALADIN allocation point and deposit fee. Can only be called by the owner.
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

    // View function to see pending ALADINs on frontend.
    function pendingAladin(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accAladinPerShare = pool.accAladinPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 aladinReward = multiplier.mul(aladinPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accAladinPerShare = accAladinPerShare.add(aladinReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accAladinPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 aladinReward = multiplier.mul(aladinPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        // Both MasterChef and Token can not Mint! 
        //This is the commented "regular" mint function: "aladin.mint(address(this), aladinReward);""
        pool.accAladinPerShare = pool.accAladinPerShare.add(aladinReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to FutureMasterChef for ALADIN allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        if (user.amount > 0) {

            uint256 pending = user.amount.mul(pool.accAladinPerShare).div(1e12).sub(user.rewardDebt);
            uint256 feeShare = pending.div(100);
            
            if (pending > 0) {
              
                IBEP20(BUSD).safeTransferFrom(address(msg.sender), feeAddress, feeAmount);
                safeAladinTransfer(msg.sender, pending);
                safeAladinTransfer(feeAddress, feeShare);
                }
        }
        
        if (_amount > 0) {      
            // Correct amount of LP calculation.
            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            IBEP20(BUSD).safeTransferFrom(address(msg.sender), feeAddress, feeAmount);
            uint256 _after = pool.lpToken.balanceOf(address(this));
            _amount = _after.sub(before); 
            // Correct amount of LP calculation.
            
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        
        user.rewardDebt = user.amount.mul(pool.accAladinPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }
        
    // Withdraw LP tokens from FutureMasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accAladinPerShare).div(1e12).sub(user.rewardDebt);
        uint256 feeShare = pending.div(100);
         
        if (pending > 0) {
            safeAladinTransfer(msg.sender, pending);
            safeAladinTransfer(feeAddress, feeShare);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accAladinPerShare).div(1e12);
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

    // Safe ALADIN transfer function, just in case if rounding error causes pool to not have enough ALADINs.
    function safeAladinTransfer(address _to, uint256 _amount) internal {
        uint256 aladinBal = aladin.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > aladinBal) {
            transferSuccess = aladin.transfer(_to, aladinBal);
        } else {
            transferSuccess = aladin.transfer(_to, _amount);
        }
        require(transferSuccess, "safeAladinTransfer: Transfer failed");
    }


    // Reduce emission rate by 10% every 28800 blocks ~ 24 hours. This function can be called publicly.
    function updateEmissionRate() public {
        
        if(block.number <= startBlock){
            return;
        }
        if(aladinPerBlock <= MINIMUM_EMISSION_RATE){
            return;
        }

        uint256 currentIndex = block.number.sub(startBlock).div(EMISSION_REDUCTION_PERIOD_BLOCKS);
        if (currentIndex <= lastReductionPeriodIndex) {
            return;
        }

        uint256 newEmissionRate = aladinPerBlock;
        for (uint256 index = lastReductionPeriodIndex; index < currentIndex; ++index) {
            newEmissionRate = newEmissionRate.mul(1e4 - EMISSION_REDUCTION_RATE_PER_PERIOD).div(1e4);
        }

        newEmissionRate = newEmissionRate < MINIMUM_EMISSION_RATE ? MINIMUM_EMISSION_RATE : newEmissionRate;
        if (newEmissionRate >= aladinPerBlock) {
            return;
        }

        massUpdatePools();
        lastReductionPeriodIndex = currentIndex;
        uint256 previousEmissionRate = aladinPerBlock;
        aladinPerBlock = newEmissionRate;
        emit EmissionRateUpdated(msg.sender, previousEmissionRate, newEmissionRate);
    }

}