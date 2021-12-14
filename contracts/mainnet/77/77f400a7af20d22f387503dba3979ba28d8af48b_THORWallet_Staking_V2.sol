// SPDX-License-Identifier: MIT

// combined from
// https://github.com/Thorstarter/thorstarter-contracts/blob/main/contracts/Staking.sol
// and:
// https://github.com/goosedefi/goose-contracts/blob/master/contracts/MasterChefV2.sol
// which was audited

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Multicall.sol";
import "./ReentrancyGuard.sol";

contract THORWallet_Staking_V2 is Ownable, Multicall, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Info of each Staking user.
    /// `amount` LP token amount the user has provided.
    /// `rewardOffset` The amount of token which needs to be subtracted at the next harvesting event.
    struct UserInfo {
        uint256 amount;
        uint256 rewardOffset;
    }

    /// @notice Info of each Staking pool.
    /// `lpToken` The address of LP token contract.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    /// Also known as the amount of token to distribute per block.
    struct PoolInfo {
        IERC20 lpToken;
        uint256 accRewardPerShare;
        uint256 lastRewardBlock;
        uint256 allocPoint;
    }

    // The amount of rewardTokens entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardOffset
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardOffset` gets updated.

    /// @notice Address of token contract.
    IERC20 public rewardToken;
    address public rewardOwner;

    /// @notice Info of each Staking pool.
    PoolInfo[] public poolInfo;

    /// @notice Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    uint256 public rewardPerBlock = 0;
    uint256 private constant ACC_PRECISION = 1e12;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accRewardPerShare);

    /// @param _rewardToken The reward token contract address.
    constructor(IERC20 _rewardToken, address _rewardOwner, uint256 _rewardPerBlock) Ownable() {
        rewardToken = _rewardToken;
        rewardOwner = _rewardOwner;
        rewardPerBlock = _rewardPerBlock;
    }

    /// @notice Sets the reward token.
    function setRewardToken(IERC20 _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
    }

    /// @notice Sets the reward owner.
    function setRewardOwner(address _rewardOwner) public onlyOwner {
        rewardOwner = _rewardOwner;
    }

    /// @notice Adjusts the reward per block.
    function setRewardsPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
    }

    /// @notice Returns the number of Staking pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    /// @param _allocPoint AP of the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    function addPool(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        require(!poolExistence[_lpToken], "Staking: duplicated pool");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint + _allocPoint;

        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: block.number,
            accRewardPerShare: 0
        }));

        emit LogPoolAddition(poolInfo.length - 1, _allocPoint, _lpToken);
    }

    /// @notice Update the given pool's token allocation point. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;

        emit LogSetPool(_pid, _allocPoint);
    }

    /// @notice View function to see pending token reward on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending token reward for a given user.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blocks = block.number - pool.lastRewardBlock;
            uint256 reward = (blocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
            accRewardPerShare = accRewardPerShare + ((reward * ACC_PRECISION) / lpSupply);
        }
        uint256 accumulatedReward = (user.amount * accRewardPerShare) / ACC_PRECISION;
        return accumulatedReward - user.rewardOffset;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
        }
    }

    function massUpdatePoolsByIds(uint256[] calldata pids) external {
        for (uint256 i = 0; i < pids.length; ++i) {
            updatePool(pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param pid The index of the pool. See `poolInfo`.
    function updatePool(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blocks = block.number - pool.lastRewardBlock;
        uint256 reward = (blocks * rewardPerBlock * pool.allocPoint) / totalAllocPoint;
        pool.accRewardPerShare = pool.accRewardPerShare + ((reward * ACC_PRECISION) / lpSupply);
        pool.lastRewardBlock = block.number;

        emit LogUpdatePool(pid, pool.lastRewardBlock, lpSupply, pool.accRewardPerShare);
    }

    /// @notice Deposit LP tokens to Staking for reward token allocation.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to deposit.
    /// @param to The receiver of `amount` deposit benefit.
    function deposit(uint256 pid, uint256 amount, address to) public nonReentrant {
        updatePool(pid);
        PoolInfo memory pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        // harvest
        uint256 accumulatedReward = (user.amount * pool.accRewardPerShare) / ACC_PRECISION;
        uint256 pendingReward = accumulatedReward - user.rewardOffset;

        if (pendingReward > 0) {
            rewardToken.safeTransferFrom(rewardOwner, to, pendingReward);
        }

        if (amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), amount);
            user.amount = user.amount + amount;
        }
        user.rewardOffset = (user.amount * pool.accRewardPerShare) / ACC_PRECISION;

        emit Deposit(msg.sender, pid, amount, to);
    }

    /// @notice Withdraw LP tokens from Staking.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(uint256 pid, uint256 amount, address to) public nonReentrant {
        updatePool(pid);
        PoolInfo memory pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= amount, "withdraw: not good");

        // harvest
        uint256 accumulatedReward = (user.amount * pool.accRewardPerShare) / ACC_PRECISION;
        uint256 pendingReward = accumulatedReward - user.rewardOffset;
        if (pendingReward > 0) {
            rewardToken.safeTransferFrom(rewardOwner, to, pendingReward);
        }

        if (amount > 0) {
            user.amount = user.amount - amount;
            pool.lpToken.safeTransfer(to, amount);
        }
        user.rewardOffset = (user.amount * pool.accRewardPerShare) / ACC_PRECISION;

        emit Withdraw(msg.sender, pid, amount, to);
    }

    /// @notice Harvest proceeds for transaction sender to `to`.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of token rewards.
    function harvest(uint256 pid, address to) public {
        updatePool(pid);
        PoolInfo memory pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        uint256 accumulatedReward = (user.amount * pool.accRewardPerShare) / ACC_PRECISION;
        uint256 pendingReward = accumulatedReward - user.rewardOffset;
        user.rewardOffset = accumulatedReward;
        if (pendingReward > 0) {
            rewardToken.safeTransferFrom(rewardOwner, to, pendingReward);
        }

        emit Harvest(msg.sender, pid, pendingReward);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param pid The index of the pool. See `poolInfo`.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(uint256 pid, address to) public {
        PoolInfo memory pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        uint256 amount = user.amount;

        user.amount = 0;
        user.rewardOffset = 0;
        pool.lpToken.safeTransfer(to, amount);

        emit EmergencyWithdraw(msg.sender, pid, amount, to);
    }
}