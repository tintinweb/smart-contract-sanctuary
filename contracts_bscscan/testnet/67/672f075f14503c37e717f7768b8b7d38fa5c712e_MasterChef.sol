// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./SafeBEP20.sol";
import "./IBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


// MasterChef is the master of Agt. He can make Agt and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once AGT is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of AGTs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accAgtPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accAgtPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. AGTs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that AGTs distribution occurs.
        uint256 accAgtPerShare; // Accumulated AGTs per share, times 1e12. See below.
        uint256 poolLimitPerUser; // The pool limit (0 if none)
        bool hasUserLimit;
        uint256 bonusEndBlock; // The block number when Agt mining ends.
    }

    // The AGT TOKEN!
    IBEP20 public agt;

    // AGT tokens created per block.
    uint256 public agtPerBlock;
    
    // Bonus muliplier for early agt makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when AGT mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event PoolRewardsStop(uint pid, uint256 blockNumber);
    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event NewEndBlocks(uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);

    constructor(
        IBEP20 _agt,
        uint256 _agtPerBlock,
        uint256 _startBlock
    ) public {

        agtPerBlock = _agtPerBlock;
        startBlock = _startBlock;
        agt = _agt;
        // staking pool allocPoint set 0
        poolInfo.push(PoolInfo({
            lpToken: _agt,
            allocPoint: 0,
            lastRewardBlock: startBlock,
            accAgtPerShare: 0,
            poolLimitPerUser: 0,
            hasUserLimit: true,
            bonusEndBlock: block.number
        }));
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, bool _withUpdate, uint256 _poolLimitPerUser, uint256 _bonusEndBlock) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        bool _hasUserLimit = false;
            if (_poolLimitPerUser > 0) {
            _hasUserLimit = true;
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accAgtPerShare: 0,
            poolLimitPerUser: _poolLimitPerUser,
            hasUserLimit: _hasUserLimit,
            bonusEndBlock: _bonusEndBlock
        }));
    }

    // Update the given pool's AGT allocation point and pool limit per user. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _poolLimitPerUser, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        if (_poolLimitPerUser > 0) {
            poolInfo[_pid].hasUserLimit = true;
            poolInfo[_pid].poolLimitPerUser = _poolLimitPerUser;
        }
        
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to, uint256 bonusEndBlock) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER);
        }
    }

    // View function to see pending AGTs on frontend.
    function pendingCake(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accAgtPerShare = pool.accAgtPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, pool.bonusEndBlock);
            uint256 agtReward = multiplier.mul(agtPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accAgtPerShare = accAgtPerShare.add(agtReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accAgtPerShare).div(1e12).sub(user.rewardDebt);
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
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number, pool.bonusEndBlock);
        uint256 agtReward = multiplier.mul(agtPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        pool.accAgtPerShare = pool.accAgtPerShare.add(agtReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for AGT allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        require (_pid != 0, "deposit AGT by staking");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (pool.hasUserLimit) {
            require(_amount.add(user.amount) <= pool.poolLimitPerUser, "User amount above limit");
        }

        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accAgtPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                agt.safeTransfer(address(msg.sender), pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accAgtPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, "withdraw AGT by unstaking");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accAgtPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            agt.safeTransfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accAgtPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    /*
     * @notice Withdraw rewards token
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw() external onlyOwner {
        uint256 rewardsAmount = agt.balanceOf(address(this));
        agt.safeTransfer(address(msg.sender), rewardsAmount);
    }

     /*
     * @notice Stop pid rewards
     * @dev Only callable by owner
     */
    function stopReward(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.bonusEndBlock = block.number;
        emit PoolRewardsStop(_pid, block.number);
    }

    // It allows the admin to recover wrong tokens sent to the contract, This function is only callable by admin
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(agt), "Cannot be reward token");

        IBEP20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    // Update reward per block, Only callable by owner
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        agtPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    // It allows the admin to update pool end blocks, only callable by owner
    function updateEndBlocks(uint256 _pid, uint256 _bonusEndBlock) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.bonusEndBlock < _bonusEndBlock, "New endBlock must be greater than endBlock");
        pool.bonusEndBlock = _bonusEndBlock;
        emit NewEndBlocks(_bonusEndBlock);
    }
}