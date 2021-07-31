// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./Math.sol";
import "./ERC20.sol";

import "./Ownable.sol";

import "./ReentrancyGuard.sol";

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./IMintable.sol";
import "./IPolyMasterCorn.sol";
import "./IStrategy.sol";


contract PolyMasterCorn is Ownable, ReentrancyGuard, IPolyMasterCorn  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 lastDepositTime;
        uint256 startLockTime;
        uint256 endLockTime;
        //
        // We do some fancy math here. Basically, any point in time, the amount of YCorns
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSinkPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSinkPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;                        // Address of LP token contract.
        uint256 allocPoint;                    // How many allocation points assigned to this pool. YCorns to distribute per block.
        uint256 lastRewardBlock;               // Last block number that YCorns distribution occurs.
        uint256 accSinkPerShare;               // Accumulated YCorns per share, times 1e6. See below.
        uint256 maxDepositAmount;              // Maximum deposit quota (0 means no limit)
        bool canDeposit;                       // Can deposit in this pool
        uint256 currentDepositAmount;          // Current total deposit amount in this pool
        address strat;                                      
        bool stratDepositFee;
        // lockable reward
        bool hasLockedReward; 
        uint256 lockedRewardPercent;
        uint256 toLockedPid; 
    }

    // Lock info of each pool.
    struct PoolLockInfo {
        bool isLocked; 
        bool hasFixedLockBaseFee; 
        uint256 lockBaseFee;
        uint256 lockBaseTime;
    }

    // The reward token
    IMintable public yCorn;
    // Dev address
    address public devAddress;
    address public govAddress;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    // Lottery address
    address public lotteryAddress;
    // YCorn tokens created per block.
    uint256 public yCornPerBlock;
    // Lottery reward ratio
    uint256 public lotteryPercent = 0;
    // Bonus multiplier for early yCorn makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    uint256 public constant REWARD_MULTIPLIER = 1e12;

    // Info of each pool.
    PoolInfo[] public poolInfo;    
    // Lock info of each pool.
    PoolLockInfo[] public poolLockInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when YCorn mining starts.
    uint256 public startBlock;
    // Du to the unstable block duration on Polygon we put a setter to initialize the deposit
    bool public initStacking = false;

    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event SetLotteryAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 yCornPerBlock);
    event UpdateLotteryRewardRate(address indexed user, uint256 lotteryPercent);
    event LockedReward(address indexed user, uint256 indexed pidPoolLocked, uint256 amountLocked);
    modifier onlyOwnerOrGov()
    {
        require(msg.sender == owner() || msg.sender == govAddress ,"onlyOwnerOrGov");
        _;
    }
    constructor(
        IMintable _yCorn,
        address _devAddress,
        address _govAddress,
        uint256 _yCornPerBlock,
        uint256 _startBlock
    ) public {
        yCorn = _yCorn;
        devAddress = _devAddress;
        govAddress = _govAddress;
        yCornPerBlock = _yCornPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint256 _maxDepositAmount,
        bool _canDeposit,
        address _strat,
        bool _stratDepositFee,
        bool _isLocked,
        bool _hasLockedReward,
        uint256 _toLockedPid,
        bool _withUpdate
    ) override external onlyOwner {
        if (_withUpdate) {
            _massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accSinkPerShare: 0,
            maxDepositAmount: _maxDepositAmount,
            currentDepositAmount: 0,
            canDeposit: _canDeposit,
            strat: _strat,
            stratDepositFee: _stratDepositFee,
            hasLockedReward: _hasLockedReward,
            lockedRewardPercent: 5000,
            toLockedPid: _toLockedPid
        }));

        poolLockInfo.push(PoolLockInfo({
            isLocked: _isLocked,
            hasFixedLockBaseFee: false,
            lockBaseFee: 7500,
            lockBaseTime: 30 days
        }));
    }

    // Update the given pool's YCorn allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IERC20 _lpToken,
        uint256 _maxDepositAmount,
        bool _canDeposit,
        address _strat,
        bool _stratDepositFee,
        bool _withUpdate
    ) override external onlyOwner {
        if (_withUpdate) {
            _massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].lpToken = _lpToken;
        poolInfo[_pid].maxDepositAmount = _maxDepositAmount;
        poolInfo[_pid].canDeposit = _canDeposit;
        poolInfo[_pid].strat = poolInfo[_pid].currentDepositAmount > 0 ? poolInfo[_pid].strat : _strat;
        poolInfo[_pid].stratDepositFee = _stratDepositFee;   
    }

    function setCanDeposit(
        uint256 _pid,
        bool _canDeposit,
        bool _withUpdate
    ) override external onlyOwner {
        if (_withUpdate) {
            _massUpdatePools();
        }
        poolInfo[_pid].canDeposit = _canDeposit;
    }

    function setLock(
        uint256 _pid,
        bool _isLocked,
        bool _hasFixedLockBaseFee,
        uint256 _lockBaseFee,
        uint256 _lockBaseTime,
        bool _withUpdate
    ) override external onlyOwner {
        require(_lockBaseFee <= 10000, "Max lockBaseFee is 100%");

        if (_withUpdate) {
            _massUpdatePools();
        }
        poolLockInfo[_pid].isLocked = _isLocked;
        poolLockInfo[_pid].hasFixedLockBaseFee = _hasFixedLockBaseFee;
        poolLockInfo[_pid].lockBaseFee = _lockBaseFee;
        poolLockInfo[_pid].lockBaseTime = _lockBaseTime;
    }

    function setLockableReward(
        uint256 _pid,
        bool _hasLockedReward,
        uint256 _toLockedPid,
        uint256 _lockedRewardPercent,
        bool _withUpdate
    ) override external onlyOwner {
        require(_lockedRewardPercent <= 10000, "Max lockedRewardPercent is 100%");

        if (_withUpdate) {
            _massUpdatePools();
        }
        
        poolInfo[_pid].hasLockedReward = _hasLockedReward;
        poolInfo[_pid].toLockedPid = _toLockedPid;        
        poolInfo[_pid].lockedRewardPercent = _lockedRewardPercent;        
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending YCorns on frontend.
    function pendingYCorn(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSinkPerShare = pool.accSinkPerShare;
        uint256 lpSupply = 0;
        if(pool.strat != address(0)) {
            lpSupply = IStrategy(pool.strat).wantLockedTotal();
        } else {
            lpSupply = pool.currentDepositAmount;
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 yCornReward = multiplier.mul(yCornPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSinkPerShare = accSinkPerShare.add(yCornReward.mul(REWARD_MULTIPLIER).div(lpSupply));
        }
        return user.amount.mul(accSinkPerShare).div(REWARD_MULTIPLIER).sub(user.rewardDebt);
    }

    function massUpdatePools() override external {
        _massUpdatePools();
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function _massUpdatePools() private {
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
        uint256 lpSupply = 0;
        if(pool.strat != address(0)) {
            lpSupply = IStrategy(pool.strat).wantLockedTotal();
        } else {
            lpSupply = pool.currentDepositAmount;
        }
        if (lpSupply == 0 || pool.allocPoint == 0 || yCornPerBlock == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if (multiplier <= 0) {
            return;
        }
        uint256 yCornReward = multiplier.mul(yCornPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 devReward = yCornReward.div(10);
        uint256 lotteryReward = yCornReward.mul(lotteryPercent).div(10000);
        yCorn.mint(address(this), yCornReward);
        yCorn.mint(devAddress, devReward);
        if(lotteryReward > 0) {
            yCorn.mint(lotteryAddress, lotteryReward);
        }
        
        pool.accSinkPerShare = pool.accSinkPerShare.add(yCornReward.mul(REWARD_MULTIPLIER).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit tokens to chef for YCorn allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        require(initStacking, "NOT INITIALISED");
        require(block.number >= startBlock, "NOT STARTED");

        PoolInfo storage pool = poolInfo[_pid];
        PoolLockInfo storage poolLock = poolLockInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(pool.canDeposit, "deposit: can't deposit in this pool");

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER).sub(user.rewardDebt);
            if (pending > 0) {
                if(pool.hasLockedReward) { 
                    _lockReward(pool, msg.sender, pending);
                } else {
                    safeYCornTransfer(msg.sender, pending);
                }
            }
        }
        if (_amount > 0) {
            
            uint256 depositFee = 0;
            if(pool.strat != address(0)) {
                if(pool.stratDepositFee) {
                    uint256 stratDepositFee = IStrategy(pool.strat).fetchDepositFee();
                    depositFee = _amount.mul(stratDepositFee).div(10000);
                }
            }   
            uint256 depositAmount = _amount.sub(depositFee);

            //Ensure adequate deposit quota if there is a max cap
            if(pool.maxDepositAmount > 0){
                uint256 remainingQuota = pool.maxDepositAmount.sub(pool.currentDepositAmount);
                require(remainingQuota >= depositAmount, "deposit: reached maximum limit");
            }

            if (user.amount == 0 && poolLock.isLocked) {
                user.startLockTime = block.timestamp;
                user.endLockTime = block.timestamp + poolLock.lockBaseTime;
            }

            uint256 balanceBefore =  pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 tokenBalance =  pool.lpToken.balanceOf(address(this)).sub(balanceBefore);
            
            uint256 rAmount = tokenBalance.sub(depositFee);
            pool.currentDepositAmount = pool.currentDepositAmount.add(rAmount);

            if(pool.strat != address(0)) {
                require(_amount == tokenBalance, 'Taxed tokens not ALLOWED');
                pool.lpToken.safeIncreaseAllowance(pool.strat, tokenBalance);
                uint256 amountDeposit = IStrategy(pool.strat).deposit(tokenBalance);
                user.amount = user.amount.add(amountDeposit);
            } else {
                user.amount = user.amount.add(rAmount);
            }
            user.lastDepositTime = block.timestamp;
        }
        user.rewardDebt = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        PoolLockInfo storage poolLock = poolLockInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(pool.currentDepositAmount > 0, "pool.currentDepositAmount is 0");
        
        if(pool.strat != address(0)) {
            uint256 total = IStrategy(pool.strat).wantLockedTotal();
            require(total > 0, "Total is 0");
        }

        require(user.amount >= _amount, "withdraw: not good");

        uint256 pending = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER).sub(user.rewardDebt);
        if (pending > 0) {
            if(pool.hasLockedReward) { 
                _lockReward(pool, msg.sender, pending);
            } else {
                safeYCornTransfer(msg.sender, pending);
            }
        }
        // Withdraw want tokens
        uint256 userAmount = user.amount;
        if (_amount > userAmount) {
            _amount = userAmount;
        }
        if (_amount > 0) {
            uint256 amountRemove = _amount;

            if(pool.strat != address(0)) {
               amountRemove = IStrategy(pool.strat).withdraw(_amount);
            }

            if (amountRemove > user.amount) {
                user.amount = 0;
            } else {
                user.amount = user.amount.sub(amountRemove);
            }

            pool.currentDepositAmount = pool.currentDepositAmount.sub(amountRemove);

            if (pool.lpToken == IERC20(yCorn) && poolLock.isLocked && poolLock.lockBaseFee > 0) {
                user.endLockTime = user.startLockTime + poolLock.lockBaseTime;
                if (block.timestamp < user.endLockTime) {
                    uint256 lockedAmount = 0;
                    if(poolLock.hasFixedLockBaseFee) {
                        lockedAmount = amountRemove.mul(poolLock.lockBaseFee).div(10000);
                    } else {
                        uint256 PRECISION = 1e3;
                        uint256 lockTotalTime = user.endLockTime.sub(user.startLockTime);
                        uint256 lockCurrentTime = block.timestamp.sub(user.startLockTime);

                        uint256 lockProgress = lockCurrentTime.mul(PRECISION).div(lockTotalTime);
                        uint256 lockRate = PRECISION.sub(lockProgress);

                        uint256 lockFee = poolLock.lockBaseFee.mul(lockRate).div(PRECISION);

                        lockedAmount = amountRemove.mul(lockFee).div(10000);
                    }

                    amountRemove = amountRemove.sub(lockedAmount);
                    
                    if(lockedAmount > 0) {    
                        safeYCornTransfer(burnAddress, lockedAmount);
                    }
                    
                    user.startLockTime = block.timestamp;
                    user.endLockTime = block.timestamp + poolLock.lockBaseTime;
                }
            }

            uint256 wantBal = IERC20(pool.lpToken).balanceOf(address(this));
            if (wantBal < amountRemove) {
                amountRemove = wantBal;
            }
            pool.lpToken.safeTransfer(address(msg.sender), amountRemove);
        }
        if(user.amount == 0) {
            user.startLockTime = 0;
            user.endLockTime = 0;
        }
        user.rewardDebt = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function _lockReward(PoolInfo storage pool, address user, uint256 pending) private {
        PoolInfo storage targetPool = poolInfo[pool.toLockedPid];
        PoolLockInfo storage targetLockPool = poolLockInfo[pool.toLockedPid];
        UserInfo storage userPoolLocked = userInfo[pool.toLockedPid][user];

        if(targetLockPool.isLocked) {
            uint256 lockedAmount = pending.mul(pool.lockedRewardPercent).div(10000); // 50% (default) pending rewards to locked pool
            uint256 unlockedAmount = pending.sub(lockedAmount); // 50% pending rewards left to user
            if(unlockedAmount > 0) {    
                safeYCornTransfer(user, unlockedAmount);
            }

            updatePool(pool.toLockedPid);

            targetPool.currentDepositAmount = targetPool.currentDepositAmount.add(lockedAmount);
            if (userPoolLocked.amount == 0) {
                userPoolLocked.startLockTime = block.timestamp;
                userPoolLocked.endLockTime = block.timestamp + targetLockPool.lockBaseTime;
            } else {
                uint256 pendingOfLockedPool = userPoolLocked.amount.mul(targetPool.accSinkPerShare).div(REWARD_MULTIPLIER).sub(userPoolLocked.rewardDebt);
                if (pendingOfLockedPool > 0) {
                    safeYCornTransfer(user, pendingOfLockedPool);
                }
            }
            userPoolLocked.amount = userPoolLocked.amount.add(lockedAmount);
            userPoolLocked.lastDepositTime = block.timestamp;
            userPoolLocked.rewardDebt = userPoolLocked.amount.mul(targetPool.accSinkPerShare).div(REWARD_MULTIPLIER);
            emit LockedReward(user, pool.toLockedPid, lockedAmount);
        } else {
            safeYCornTransfer(user, pending);
        }
    } 

    function _burnReward(PoolInfo storage pool, address user, uint256 pending) private {
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        PoolLockInfo storage poolLock = poolLockInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amountRemove = user.amount;

        if(pool.strat != address(0)) {
           amountRemove = IStrategy(pool.strat).withdraw(amountRemove);
        }

        if(poolLock.isLocked) { 
           amountRemove = 0;
        } else {
           user.amount = 0;
           user.rewardDebt = 0;
        }

        pool.currentDepositAmount = pool.currentDepositAmount.sub(amountRemove);
        pool.lpToken.safeTransfer(address(msg.sender), amountRemove);
        emit EmergencyWithdraw(msg.sender, _pid, amountRemove);
    }
    
    receive() external payable {}

    function safeTransferMATIC(address to, uint value) external  {
        require(msg.sender == govAddress, "safeTransferMATIC : FORBIDDEN");
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: MATIC_TRANSFER_FAILED');
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) external
    {
        require(msg.sender == govAddress, "inCaseTokensGetStuck : FORBIDDEN");
        require(_token != address(yCorn), "!safe");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
    
    // Safe yCorn transfer function, just in case if rounding error causes pool to not have enough YCorns.
    function safeYCornTransfer(address _to, uint256 _amount) internal {
        uint256 yCornBal = yCorn.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > yCornBal) {
            transferSuccess = yCorn.transfer(_to, yCornBal);
        } else {
            transferSuccess = yCorn.transfer(_to, _amount);
        }
        require(transferSuccess, "safeYCornTransfer: transfer failed");
    }

    function setDevAddress(address _devAddress) external {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        devAddress = _devAddress;
        emit SetDevAddress(msg.sender, _devAddress);
    }

    function setLotteryAddress(address _lotteryAddress) override external onlyOwner {
        lotteryAddress = _lotteryAddress;
        emit SetLotteryAddress(msg.sender, _lotteryAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _yCornPerBlock) external onlyOwner {
        _massUpdatePools();
        yCornPerBlock = _yCornPerBlock;
        emit UpdateEmissionRate(msg.sender, _yCornPerBlock);
    }

    function updateLotteryRewardRate(uint256 _lotteryPercent) external onlyOwner {
        require(_lotteryPercent <= 500, "Max lottery percent is 50%");
        lotteryPercent = _lotteryPercent;
        emit UpdateLotteryRewardRate(msg.sender, _lotteryPercent);
    }

    //New function to trigger harvest for a specific user and pool
    //A specific user address is provided to facilitate aggregating harvests on multiple chefs
    //Also, it is harmless monetary-wise to help someone else harvests
    function harvestFor(uint256 _pid, address _user) public nonReentrant {
        //Limit to self or delegated harvest to avoid unnecessary confusion
        require(msg.sender == _user || tx.origin == _user, "harvestFor: FORBIDDEN");

        updatePool(_pid);

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        require(pool.currentDepositAmount > 0, "pool.currentDepositAmount is 0");
        
        if(pool.strat != address(0)) {
            uint256 total = IStrategy(pool.strat).wantLockedTotal();
            require(total > 0, "Total is 0");
        }

        require(user.amount > 0, "user.amount is 0");
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER).sub(user.rewardDebt);
            if (pending > 0) {
                if(pool.hasLockedReward) { 
                    _lockReward(pool, _user, pending);
                } else {
                    safeYCornTransfer(_user, pending);
                }
                user.rewardDebt = user.amount.mul(pool.accSinkPerShare).div(REWARD_MULTIPLIER);
                emit Harvest(_user, _pid, pending);
            }
        }
    }
    
    function setInitStackingTrue() external onlyOwnerOrGov {
        require(!initStacking, "ALREADY INITIALIZED");
        initStacking = true;
    }

    function bulkHarvestFor(uint256[] calldata pidArray, address _user) external {
        uint256 length = pidArray.length;
        for (uint256 index = 0; index < length; ++index) {
            uint256 _pid = pidArray[index];
            harvestFor(_pid, _user);
        }
    }
}