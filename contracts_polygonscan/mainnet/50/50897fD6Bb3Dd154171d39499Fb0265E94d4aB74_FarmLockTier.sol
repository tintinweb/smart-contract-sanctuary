// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// PolyDefi farm with lock tier function : Stake Lps (or SAS), earn 1 native or partner token

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract FarmLockTier is Ownable, ReentrancyGuard  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lockedAmount;  // LP or token locked up.
        uint256 lockedUntil; // Locked until end time of actual IDO lock
    }

    // Info of the pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. REWARDTOKENs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that REWARDTOKENs distribution occurs.
        uint256 accRewardTPerShare; // Accumulated REWARDTOKENs per share, times 1e30. See below.
        uint16 withdrawalFeeBP;      // Withdrawal fee in basis points
        uint256 endBlock; // The block number when REWARDTOKEN pool ends.
        uint256 totalLockedAmount; // The sum of locked amount into the pool
    }
    
    // Info of IDO lockt times
    struct IDOLockTimes {
        uint256 start; // UNIX timestamp of the lock beginning
        uint256 max; // UNIX timestamp of the max time to lock
        uint256 end; // UNIX timestamp of the unlock
    }    

    IERC20 public lpOrToken;
    IERC20 public rewardToken;

    // REWARDTOKEN tokens created per block.
    uint256 public rewardPerBlock;
    
    // Withdrawal fee  address
    address public feeAddress;   
    
    // Maximum lock duration in sec (10 days)
    uint256 public constant MAX_LOCK_DURATION = 864000;
    
    // Maximum withdrawal fee in basis point (max 10%)
    uint256 public constant MAX_WITHDRAWAL_FEE = 1000;    

    // unique pool info
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    // The block number when REWARDTOKEN pool starts.
    uint256 public startBlock;
    
    IDOLockTimes public lockTimes;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event FeeAddressUpdated(address indexed user, address indexed newAddress);
    event LockedAmount(address indexed user, uint256 indexed amount);
    event StartLockTimeUpdated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event MaxLockTimeUpdated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event EndLockTimeUpdated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event StartBlockUpdated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event EndBlockUpdated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event WithdrawalFeeUpdated(address indexed user, uint16 previousAmount, uint16 newAmount);

    constructor(
        IERC20 _lpOrToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint16 _withdrawalFeeBP,
        uint256 _startBlock,
        uint256 _endBlock,
        address _feeAddress
    ) public {
        lpOrToken = _lpOrToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        feeAddress = _feeAddress;

        // Withdrawal fee limited to max 10%
        require(_withdrawalFeeBP <= 1000, "contract: invalid withdrawal fee basis points");

        // init staking pool
        poolInfo.lpToken = _lpOrToken;
        poolInfo.allocPoint = 1000;        
        poolInfo.lastRewardBlock = startBlock;
        poolInfo.accRewardTPerShare = 0;
        poolInfo.withdrawalFeeBP = _withdrawalFeeBP;
        poolInfo.endBlock = _endBlock;
        poolInfo.totalLockedAmount = 0;
        
        totalAllocPoint = 1000;

    }

    function stopReward() public onlyOwner {
        poolInfo.endBlock = block.number;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= poolInfo.endBlock) {
            return _to.sub(_from);
        } else if (_from >= poolInfo.endBlock) {
            return 0;
        } else {
            return poolInfo.endBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTPerShare = pool.accRewardTPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 rewardTReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardTPerShare = accRewardTPerShare.add(rewardTReward.mul(1e30).div(lpSupply));
        }
        return user.amount.mul(accRewardTPerShare).div(1e30).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rewardTReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accRewardTPerShare = pool.accRewardTPerShare.add(rewardTReward.mul(1e30).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Stake LP or token
    function deposit(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardTPerShare).div(1e30).sub(user.rewardDebt);
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }

        if(_amount > 0) {
            // Handle any token with transfer tax
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)).sub(balanceBefore);      
            user.amount = user.amount.add(_amount);
        }        

        user.rewardDebt = user.amount.mul(pool.accRewardTPerShare).div(1e30);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw LP or token
    function withdraw(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        
        uint256 _availableAmount;
        if (block.timestamp >= user.lockedUntil){
            pool.totalLockedAmount = pool.totalLockedAmount.sub(user.lockedAmount);
            user.lockedAmount = 0;
            _availableAmount = user.amount;
        } 
        else
        {
            _availableAmount = user.amount.sub(user.lockedAmount);
        }        
        
        require(_availableAmount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user.amount.mul(pool.accRewardTPerShare).div(1e30).sub(user.rewardDebt);
        if(pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }
        
        if(_amount > 0) {

            if(pool.withdrawalFeeBP > 0){
                uint256 withdrawalFee = _amount.mul(pool.withdrawalFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, withdrawalFee);
                user.amount = user.amount.sub(_amount);
                _amount = _amount.sub(withdrawalFee);
                pool.lpToken.safeTransfer(address(msg.sender), _amount);
            }else{
                user.amount = user.amount.sub(_amount);
                pool.lpToken.safeTransfer(address(msg.sender), _amount);
            }            

        }
        user.rewardDebt = user.amount.mul(pool.accRewardTPerShare).div(1e30);

        emit Withdraw(msg.sender, _amount);
    }
    
    // Return availabe amount per user for the UI
    function getAvailableAmount(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _availableAmount;
        if (block.timestamp >= user.lockedUntil){
            _availableAmount = user.amount;
        } 
        else
        {
            _availableAmount = user.amount.sub(user.lockedAmount);
        } 
        return _availableAmount;
    }    
    
    // Lock LP or token
    // To participate IDO, need locked amount for a duration
    function lock(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        
        require(block.timestamp > lockTimes.start, "lock : start : can't lock now");
        require(lockTimes.max > block.timestamp, "lock : max : can't lock now");
        require(_amount > 0, 'lock: amount too low');
        require(user.amount > 0, 'lock: nothing to lock');
        require(_amount <= user.amount, 'lock: not enough token');

        user.lockedAmount = user.lockedAmount.add(_amount);
        user.lockedUntil = lockTimes.end;
        pool.totalLockedAmount = pool.totalLockedAmount.add(_amount);
        
        emit LockedAmount(msg.sender, _amount);
    }    

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public nonReentrant {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        uint256 _availableAmount;
        if (block.timestamp >= user.lockedUntil){
            pool.totalLockedAmount = pool.totalLockedAmount.sub(user.lockedAmount);
            user.lockedAmount = 0;
            _availableAmount = user.amount;
        } 
        else
        {
            _availableAmount = user.amount.sub(user.lockedAmount);
        }         

        pool.lpToken.safeTransfer(address(msg.sender), _availableAmount);
        user.amount = user.amount.sub(_availableAmount);
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, _availableAmount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < rewardToken.balanceOf(address(this)), 'emergencyRewardWithdraw: not enough token');
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }
    
    // Add a function to update rewardPerBlock. Can only be called by the owner.
    function updateRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        //Automatically updatePool 0
        updatePool();        
    } 
    
    // Add a function to update bonusEndBlock. Can only be called by the owner.
    function updateEndBlock(uint256 _endBlock) public onlyOwner {
        emit EndBlockUpdated(msg.sender, poolInfo.endBlock, _endBlock);
        poolInfo.endBlock = _endBlock;
    }   
    
    // Update the given pool's withdrawal fee. Can only be called by the owner.
    function updateWithdrawalFeeBP(uint16 _withdrawalFeeBP) public onlyOwner {
        require(_withdrawalFeeBP <= MAX_WITHDRAWAL_FEE, "updateWithdrawalFeeBP: invalid withdrawal fee basis points");
        emit WithdrawalFeeUpdated(msg.sender, poolInfo.withdrawalFeeBP, _withdrawalFeeBP);
        poolInfo.withdrawalFeeBP = _withdrawalFeeBP;
    } 
    
    // Add a function to update startBlock. Can only be called by the owner.
    function updateStartBlock(uint256 _startBlock) public onlyOwner {
        //Can only be updated if the original startBlock is not minted
        require(block.number <= poolInfo.lastRewardBlock, "updateStartBlock: startblock already minted");
        poolInfo.lastRewardBlock = _startBlock;
        emit StartBlockUpdated(msg.sender, startBlock, _startBlock);
        startBlock = _startBlock;
    } 
    
    //Update fee address by the owner
    function setFeeAddress(address _feeAddress) public onlyOwner {
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
        emit FeeAddressUpdated(msg.sender, _feeAddress);
    }   

    // Set lock times for next IDO. Can only be called by the owner.
    function setLockTimes(uint256 _start, uint256 _max, uint256 _end) public onlyOwner {
        require(_start > lockTimes.end, "updateLockTimes : start time must come after end of last IDO");
        require(_start > 0, "updateLockTimes : start time 0");
        require(_start > block.timestamp, "updateLockTimes : can't set start before now");
        require(_end > _start, "updateLockTimes : end time lower than start");
        require(_end > _max, "updateLockTimes : end time lower than max");
        require(_max > _start, "updateLockTimes : max time lower than start");
        uint256 _totalduration = _end.sub(_start);
        require(_totalduration < MAX_LOCK_DURATION, "updateLockTimes : total lock duration too high");
        emit StartLockTimeUpdated(msg.sender, lockTimes.start, _start);
        emit MaxLockTimeUpdated(msg.sender, lockTimes.max, _max);
        emit EndLockTimeUpdated(msg.sender, lockTimes.end, _end);
        lockTimes.start = _start;
        lockTimes.max = _max;
        lockTimes.end = _end;    
    }  
    
    // Update max lock times in case IDO slitghly postpone. Can only be called by the owner.
    function updateMaxLockTime(uint256 _max) public onlyOwner {
        require(lockTimes.end > _max, "updateLockTimes : end time lower than max");
        require(_max > lockTimes.start, "updateLockTimes : max time lower than start");
        emit MaxLockTimeUpdated(msg.sender, lockTimes.max, _max);
        lockTimes.max = _max;
    }      

}