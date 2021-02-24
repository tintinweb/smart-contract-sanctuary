// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IMasterChef.sol";
import "./interfaces/IVault.sol";
import "./interfaces/ILockManager.sol";
import "./lib/SafeMath.sol";
import "./lib/SafeERC20.sol";
import "./lib/ReentrancyGuard.sol";

/**
 * @title RewardsManager
 * @dev Controls rewards distribution for network
 */
contract RewardsManager is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Current owner of this contract
    address public owner;

    /// @notice Info of each user.
    struct UserInfo {
        uint256 amount;          // How many tokens the user has provided.
        uint256 rewardTokenDebt; // Reward debt for reward token. See explanation below.
        uint256 sushiRewardDebt; // Reward debt for Sushi rewards. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of reward tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    /// @notice Info of each pool.
    struct PoolInfo {
        IERC20 token;               // Address of token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. Reward tokens to distribute per block.
        uint256 lastRewardBlock;    // Last block number where reward tokens were distributed.
        uint256 accRewardsPerShare; // Accumulated reward tokens per share, times 1e12. See below.
        uint32 vestingPercent;      // Percentage of rewards that vest (measured in bips: 500,000 bips = 50% of rewards)
        uint16 vestingPeriod;       // Vesting period in days for vesting rewards
        uint16 vestingCliff;        // Vesting cliff in days for vesting rewards
        uint256 totalStaked;        // Total amount of token staked via Rewards Manager
        bool vpForDeposit;          // Do users get voting power for deposits of this token?
        bool vpForVesting;          // Do users get voting power for vesting balances?
    }

    /// @notice Reward token
    IERC20 public rewardToken;

    /// @notice SUSHI token
    IERC20 public sushiToken;

    /// @notice Sushi Master Chef
    IMasterChef public masterChef;

    /// @notice Vault for vesting tokens
    IVault public vault;

    /// @notice LockManager contract
    ILockManager public lockManager;

    /// @notice Reward tokens rewarded per block.
    uint256 public rewardTokensPerBlock;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;
    
    /// @notice Mapping of Sushi tokens to MasterChef pids 
    mapping (address => uint256) public sushiPools;

    /// @notice Info of each user that stakes tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    
    /// @notice Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    /// @notice The block number when rewards start.
    uint256 public startBlock;

    /// @notice The block number when rewards end.
    uint256 public endBlock;

    /// @notice only owner can call function
    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    /// @notice Event emitted when a user deposits funds in the rewards manager
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when a user withdraws their original funds + rewards from the rewards manager
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when a user withdraws their original funds from the rewards manager without claiming rewards
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Event emitted when new pool is added to the rewards manager
    event PoolAdded(uint256 indexed pid, address indexed token, uint256 allocPoints, uint256 totalAllocPoints, uint256 rewardStartBlock, uint256 sushiPid, bool vpForDeposit, bool vpForVesting);
    
    /// @notice Event emitted when pool allocation points are updated
    event PoolUpdated(uint256 indexed pid, uint256 oldAllocPoints, uint256 newAllocPoints, uint256 newTotalAllocPoints);

    /// @notice Event emitted when the owner of the rewards manager contract is updated
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);

    /// @notice Event emitted when the amount of reward tokens per block is updated
    event ChangedRewardTokensPerBlock(uint256 indexed oldRewardTokensPerBlock, uint256 indexed newRewardTokensPerBlock);

    /// @notice Event emitted when the rewards start block is set
    event SetRewardsStartBlock(uint256 indexed startBlock);

    /// @notice Event emitted when the rewards end block is updated
    event ChangedRewardsEndBlock(uint256 indexed oldEndBlock, uint256 indexed newEndBlock);

    /// @notice Event emitted when contract address is changed
    event ChangedAddress(string indexed addressType, address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Create a new Rewards Manager contract
     * @param _owner owner of contract
     * @param _lockManager address of LockManager contract
     * @param _vault address of Vault contract
     * @param _rewardToken address of token that is being offered as a reward
     * @param _sushiToken address of SUSHI token
     * @param _masterChef address of SushiSwap MasterChef contract
     * @param _startBlock block number when rewards will start
     * @param _rewardTokensPerBlock initial amount of reward tokens to be distributed per block
     */
    constructor(
        address _owner, 
        address _lockManager,
        address _vault,
        address _rewardToken,
        address _sushiToken,
        address _masterChef,
        uint256 _startBlock,
        uint256 _rewardTokensPerBlock
    ) {
        owner = _owner;
        emit ChangedOwner(address(0), _owner);

        lockManager = ILockManager(_lockManager);
        emit ChangedAddress("LOCK_MANAGER", address(0), _lockManager);

        vault = IVault(_vault);
        emit ChangedAddress("VAULT", address(0), _vault);

        rewardToken = IERC20(_rewardToken);
        emit ChangedAddress("REWARD_TOKEN", address(0), _rewardToken);

        sushiToken = IERC20(_sushiToken);
        emit ChangedAddress("SUSHI_TOKEN", address(0), _sushiToken);

        masterChef = IMasterChef(_masterChef);
        emit ChangedAddress("MASTER_CHEF", address(0), _masterChef);

        startBlock = _startBlock == 0 ? block.number : _startBlock;
        emit SetRewardsStartBlock(startBlock);

        rewardTokensPerBlock = _rewardTokensPerBlock;
        emit ChangedRewardTokensPerBlock(0, _rewardTokensPerBlock);

        rewardToken.safeIncreaseAllowance(address(vault), uint256(-1));
    }

    /**
     * @notice View function to see current poolInfo array length
     * @return pool length
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice Add a new reward token to the pool
     * @dev Can only be called by the owner. DO NOT add the same token more than once. Rewards will be messed up if you do.
     * @param allocPoint Number of allocation points to allot to this token/pool
     * @param token The token that will be staked for rewards
     * @param vestingPercent The percentage of rewards from this pool that will vest
     * @param vestingPeriod The number of days for the vesting period
     * @param vestingCliff The number of days for the vesting cliff
     * @param withUpdate if specified, update all pools before adding new pool
     * @param sushiPid The pid of the Sushiswap pool in the Masterchef contract (if exists, otherwise provide zero)
     * @param vpForDeposit If true, users get voting power for deposits
     * @param vpForVesting If true, users get voting power for vesting balances
     */
    function add(
        uint256 allocPoint, 
        address token,
        uint32 vestingPercent,
        uint16 vestingPeriod,
        uint16 vestingCliff,
        bool withUpdate,
        uint256 sushiPid,
        bool vpForDeposit,
        bool vpForVesting
    ) external onlyOwner {
        if (withUpdate) {
            massUpdatePools();
        }
        uint256 rewardStartBlock = block.number > startBlock ? block.number : startBlock;
        if (totalAllocPoint == 0) {
            _setRewardsEndBlock();
        }
        totalAllocPoint = totalAllocPoint.add(allocPoint);
        poolInfo.push(PoolInfo({
            token: IERC20(token),
            allocPoint: allocPoint,
            lastRewardBlock: rewardStartBlock,
            accRewardsPerShare: 0,
            vestingPercent: vestingPercent,
            vestingPeriod: vestingPeriod,
            vestingCliff: vestingCliff,
            totalStaked: 0,
            vpForDeposit: vpForDeposit,
            vpForVesting: vpForVesting
        }));
        if (sushiPid != uint256(0)) {
            sushiPools[token] = sushiPid;
            IERC20(token).safeIncreaseAllowance(address(masterChef), uint256(-1));
        }
        IERC20(token).safeIncreaseAllowance(address(vault), uint256(-1));
        emit PoolAdded(poolInfo.length - 1, token, allocPoint, totalAllocPoint, rewardStartBlock, sushiPid, vpForDeposit, vpForVesting);
    }

    /**
     * @notice Update the given pool's allocation points
     * @dev Can only be called by the owner
     * @param pid The RewardManager pool id
     * @param allocPoint New number of allocation points for pool
     * @param withUpdate if specified, update all pools before setting allocation points
     */
    function set(
        uint256 pid, 
        uint256 allocPoint, 
        bool withUpdate
    ) external onlyOwner {
        if (withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[pid].allocPoint).add(allocPoint);
        emit PoolUpdated(pid, poolInfo[pid].allocPoint, allocPoint, totalAllocPoint);
        poolInfo[pid].allocPoint = allocPoint;
    }

    /**
     * @notice Returns true if rewards are actively being accumulated
     */
    function rewardsActive() public view returns (bool) {
        return block.number >= startBlock && block.number <= endBlock && totalAllocPoint > 0 ? true : false;
    }

    /**
     * @notice Return reward multiplier over the given from to to block.
     * @param from From block number
     * @param to To block number
     * @return multiplier
     */
    function getMultiplier(uint256 from, uint256 to) public view returns (uint256) {
        uint256 toBlock = to > endBlock ? endBlock : to;
        return toBlock > from ? toBlock.sub(from) : 0;
    }

    /**
     * @notice View function to see pending reward tokens on frontend.
     * @param pid pool id
     * @param account user account to check
     * @return pending rewards
     */
    function pendingRewardTokens(uint256 pid, address account) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][account];
        uint256 accRewardsPerShare = pool.accRewardsPerShare;
        uint256 tokenSupply = pool.totalStaked;
        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 totalReward = multiplier.mul(rewardTokensPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardsPerShare = accRewardsPerShare.add(totalReward.mul(1e12).div(tokenSupply));
        }

        uint256 accumulatedRewards = user.amount.mul(accRewardsPerShare).div(1e12);
        
        if (accumulatedRewards < user.rewardTokenDebt) {
            return 0;
        }

        return accumulatedRewards.sub(user.rewardTokenDebt);
    }

    /**
     * @notice View function to see pending SUSHI on frontend.
     * @param pid pool id
     * @param account user account to check
     * @return pending SUSHI rewards
     */
    function pendingSushi(uint256 pid, address account) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][account];
        uint256 sushiPid = sushiPools[address(pool.token)];
        if (sushiPid == uint256(0)) {
            return 0;
        }
        IMasterChef.PoolInfo memory sushiPool = masterChef.poolInfo(sushiPid);
        uint256 sushiPerBlock = masterChef.sushiPerBlock();
        uint256 totalSushiAllocPoint = masterChef.totalAllocPoint();
        uint256 accSushiPerShare = sushiPool.accSushiPerShare;
        uint256 lpSupply = sushiPool.lpToken.balanceOf(address(masterChef));
        if (block.number > sushiPool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = masterChef.getMultiplier(sushiPool.lastRewardBlock, block.number);
            uint256 sushiReward = multiplier.mul(sushiPerBlock).mul(sushiPool.allocPoint).div(totalSushiAllocPoint);
            accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        }
        
        uint256 accumulatedSushi = user.amount.mul(accSushiPerShare).div(1e12);
        
        if (accumulatedSushi < user.sushiRewardDebt) {
            return 0;
        }

        return accumulatedSushi.sub(user.sushiRewardDebt);
        
    }

    /**
     * @notice Update reward variables for all pools
     * @dev Be careful of gas spending!
     */
    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date
     * @param pid pool id
     */
    function updatePool(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 tokenSupply = pool.totalStaked;
        if (tokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 totalReward = multiplier.mul(rewardTokensPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accRewardsPerShare = pool.accRewardsPerShare.add(totalReward.mul(1e12).div(tokenSupply));
        pool.lastRewardBlock = block.number;
    }

    /**
     * @notice Deposit tokens to RewardsManager for rewards allocation.
     * @param pid pool id
     * @param amount number of tokens to deposit
     */
    function deposit(uint256 pid, uint256 amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        _deposit(pid, amount, pool, user);
    }

    /**
     * @notice Deposit tokens to RewardsManager for rewards allocation, using permit for approval
     * @dev It is up to the frontend developer to ensure the pool token implements permit - otherwise this will fail
     * @param pid pool id
     * @param amount number of tokens to deposit
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function depositWithPermit(
        uint256 pid, 
        uint256 amount,
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        pool.token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        _deposit(pid, amount, pool, user);
    }

    /**
     * @notice Withdraw tokens from RewardsManager, claiming rewards.
     * @param pid pool id
     * @param amount number of tokens to withdraw
     */
    function withdraw(uint256 pid, uint256 amount) external nonReentrant {
        require(amount > 0, "RM::withdraw: amount must be > 0");
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        _withdraw(pid, amount, pool, user);
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param pid pool id
     */
    function emergencyWithdraw(uint256 pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        if (user.amount > 0) {
            uint256 sushiPid = sushiPools[address(pool.token)];
            if (sushiPid != uint256(0)) {
                masterChef.withdraw(sushiPid, user.amount);
            }

            if (pool.vpForDeposit) {
                lockManager.removeVotingPower(msg.sender, address(pool.token), user.amount);
            }

            pool.totalStaked = pool.totalStaked.sub(user.amount);
            pool.token.safeTransfer(msg.sender, user.amount);

            emit EmergencyWithdraw(msg.sender, pid, user.amount);

            user.amount = 0;
            user.rewardTokenDebt = 0;
            user.sushiRewardDebt = 0;
        }
    }

    /**
     * @notice Set approvals for external addresses to use contract tokens
     * @dev Can only be called by the owner
     * @param tokensToApprove the tokens to approve
     * @param approvalAmounts the token approval amounts
     * @param spender the address to allow spending of token
     */
    function tokenAllow(
        address[] memory tokensToApprove, 
        uint256[] memory approvalAmounts, 
        address spender
    ) external onlyOwner {
        require(tokensToApprove.length == approvalAmounts.length, "RM::tokenAllow: not same length");
        for(uint i = 0; i < tokensToApprove.length; i++) {
            IERC20 token = IERC20(tokensToApprove[i]);
            if (token.allowance(address(this), spender) != uint256(-1)) {
                token.safeApprove(spender, approvalAmounts[i]);
            }
        }
    }

    /**
     * @notice Rescue (withdraw) tokens from the smart contract
     * @dev Can only be called by the owner
     * @param tokens the tokens to withdraw
     * @param amounts the amount of each token to withdraw.  If zero, withdraws the maximum allowed amount for each token
     * @param receiver the address that will receive the tokens
     * @param updateRewardsEndBlock if true, update the rewards end block after performing transfers
     */
    function rescueTokens(
        address[] calldata tokens, 
        uint256[] calldata amounts, 
        address receiver,
        bool updateRewardsEndBlock
    ) external onlyOwner {
        require(tokens.length == amounts.length, "RM::rescueTokens: not same length");
        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 withdrawalAmount;
            uint256 tokenBalance = token.balanceOf(address(this));
            uint256 tokenAllowance = token.allowance(address(this), receiver);
            if (amounts[i] == 0) {
                if (tokenBalance > tokenAllowance) {
                    withdrawalAmount = tokenAllowance;
                } else {
                    withdrawalAmount = tokenBalance;
                }
            } else {
                require(tokenBalance >= amounts[i], "RM::rescueTokens: contract balance too low");
                require(tokenAllowance >= amounts[i], "RM::rescueTokens: increase token allowance");
                withdrawalAmount = amounts[i];
            }
            token.safeTransferFrom(address(this), receiver, withdrawalAmount);
        }

        if (updateRewardsEndBlock) {
            _setRewardsEndBlock();
        }
    }

    /**
     * @notice Set new rewards per block
     * @dev Can only be called by the owner
     * @param newRewardTokensPerBlock new amount of reward token to reward each block
     */
    function setRewardsPerBlock(uint256 newRewardTokensPerBlock) external onlyOwner {
        emit ChangedRewardTokensPerBlock(rewardTokensPerBlock, newRewardTokensPerBlock);
        rewardTokensPerBlock = newRewardTokensPerBlock;
        _setRewardsEndBlock();
    }

    /**
     * @notice Set new reward token address
     * @param newToken address of new reward token
     * @param newRewardTokensPerBlock new amount of reward token to reward each block
     */
    function setRewardToken(address newToken, uint256 newRewardTokensPerBlock) external onlyOwner {
        emit ChangedAddress("REWARD_TOKEN", address(rewardToken), newToken);
        rewardToken = IERC20(newToken);
        rewardTokensPerBlock = newRewardTokensPerBlock;
        _setRewardsEndBlock();
    }

    /**
     * @notice Set new SUSHI token address
     * @dev Can only be called by the owner
     * @param newToken address of new SUSHI token
     */
    function setSushiToken(address newToken) external onlyOwner {
        emit ChangedAddress("SUSHI_TOKEN", address(sushiToken), newToken);
        sushiToken = IERC20(newToken);
    }

    /**
     * @notice Set new MasterChef address
     * @dev Can only be called by the owner
     * @param newAddress address of new MasterChef
     */
    function setMasterChef(address newAddress) external onlyOwner {
        emit ChangedAddress("MASTER_CHEF", address(masterChef), newAddress);
        masterChef = IMasterChef(newAddress);
    }
        
    /**
     * @notice Set new Vault address
     * @param newAddress address of new Vault
     */
    function setVault(address newAddress) external onlyOwner {
        emit ChangedAddress("VAULT", address(vault), newAddress);
        vault = IVault(newAddress);
    }

    /**
     * @notice Set new LockManager address
     * @param newAddress address of new LockManager
     */
    function setLockManager(address newAddress) external onlyOwner {
        emit ChangedAddress("LOCK_MANAGER", address(lockManager), newAddress);
        lockManager = ILockManager(newAddress);
    }

    /**
     * @notice Add rewards to contract
     * @dev Can only be called by the owner
     * @param amount amount of tokens to add
     */
    function addRewardsBalance(uint256 amount) external onlyOwner {
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        _setRewardsEndBlock();
    }

    /**
     * @notice Reset rewards end block manually based on new balances
     */
    function resetRewardsEndBlock() external onlyOwner {
        _setRewardsEndBlock();
    }

    /**
     * @notice Change owner of vesting contract
     * @dev Can only be called by the owner
     * @param newOwner New owner address
     */
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0) && newOwner != address(this), "RM::changeOwner: not valid address");
        emit ChangedOwner(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice Internal implementation of deposit
     * @param pid pool id
     * @param amount number of tokens to deposit
     * @param pool the pool info
     * @param user the user info 
     */
    function _deposit(
        uint256 pid, 
        uint256 amount, 
        PoolInfo storage pool, 
        UserInfo storage user
    ) internal {
        updatePool(pid);

        uint256 sushiPid = sushiPools[address(pool.token)];
        uint256 pendingSushiTokens = 0;

        if (user.amount > 0) {
            uint256 pendingRewards = user.amount.mul(pool.accRewardsPerShare).div(1e12).sub(user.rewardTokenDebt);

            if (pendingRewards > 0) {
                _distributeRewards(msg.sender, pendingRewards, pool.vestingPercent, pool.vestingPeriod, pool.vestingCliff, pool.vpForVesting);
            }

            if (sushiPid != uint256(0)) {
                masterChef.updatePool(sushiPid);
                pendingSushiTokens = user.amount.mul(masterChef.poolInfo(sushiPid).accSushiPerShare).div(1e12).sub(user.sushiRewardDebt);
            }
        }
       
        pool.token.safeTransferFrom(msg.sender, address(this), amount);
        pool.totalStaked = pool.totalStaked.add(amount);
        user.amount = user.amount.add(amount);
        user.rewardTokenDebt = user.amount.mul(pool.accRewardsPerShare).div(1e12);

        if (sushiPid != uint256(0)) {
            masterChef.updatePool(sushiPid);
            user.sushiRewardDebt = user.amount.mul(masterChef.poolInfo(sushiPid).accSushiPerShare).div(1e12);
            masterChef.deposit(sushiPid, amount);
        }

        if (amount > 0 && pool.vpForDeposit) {
            lockManager.grantVotingPower(msg.sender, address(pool.token), amount);
        }

        if (pendingSushiTokens > 0) {
            _safeSushiTransfer(msg.sender, pendingSushiTokens);
        }

        emit Deposit(msg.sender, pid, amount);
    }

    /**
     * @notice Internal implementation of withdraw
     * @param pid pool id
     * @param amount number of tokens to withdraw
     * @param pool the pool info
     * @param user the user info 
     */
    function _withdraw(
        uint256 pid, 
        uint256 amount,
        PoolInfo storage pool, 
        UserInfo storage user
    ) internal {
        require(user.amount >= amount, "RM::_withdraw: amount > user balance");

        updatePool(pid);

        uint256 sushiPid = sushiPools[address(pool.token)];

        if (sushiPid != uint256(0)) {
            masterChef.updatePool(sushiPid);
            uint256 pendingSushiTokens = user.amount.mul(masterChef.poolInfo(sushiPid).accSushiPerShare).div(1e12).sub(user.sushiRewardDebt);
            masterChef.withdraw(sushiPid, amount);
            user.sushiRewardDebt = user.amount.sub(amount).mul(masterChef.poolInfo(sushiPid).accSushiPerShare).div(1e12);
            if (pendingSushiTokens > 0) {
                _safeSushiTransfer(msg.sender, pendingSushiTokens);
            }
        }

        uint256 pendingRewards = user.amount.mul(pool.accRewardsPerShare).div(1e12).sub(user.rewardTokenDebt);
        user.amount = user.amount.sub(amount);
        user.rewardTokenDebt = user.amount.mul(pool.accRewardsPerShare).div(1e12);

        if (pendingRewards > 0) {
            _distributeRewards(msg.sender, pendingRewards, pool.vestingPercent, pool.vestingPeriod, pool.vestingCliff, pool.vpForVesting);
        }
        
        if (pool.vpForDeposit) {
            lockManager.removeVotingPower(msg.sender, address(pool.token), amount);
        }

        pool.totalStaked = pool.totalStaked.sub(amount);
        pool.token.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, pid, amount);
    }

    /**
     * @notice Internal function used to distribute rewards, optionally vesting a %
     * @param account account that is due rewards
     * @param amount amount of rewards to distribute
     * @param vestingPercent percent of rewards to vest in bips
     * @param vestingPeriod number of days over which to vest rewards
     * @param vestingCliff number of days for vesting cliff
     * @param vestingVotingPower if true, grant voting power for vesting balance
     */
    function _distributeRewards(
        address account, 
        uint256 amount, 
        uint32 vestingPercent, 
        uint16 vestingPeriod, 
        uint16 vestingCliff,
        bool vestingVotingPower
    ) internal {
        uint256 rewardAmount = amount > rewardToken.balanceOf(address(this)) ? rewardToken.balanceOf(address(this)) : amount;
        uint256 vestingRewards = rewardAmount.mul(vestingPercent).div(1000000);
        vault.lockTokens(address(rewardToken), address(this), account, 0, vestingRewards, vestingPeriod, vestingCliff, vestingVotingPower);
        _safeRewardsTransfer(msg.sender, rewardAmount.sub(vestingRewards));
    }

    /**
     * @notice Safe reward transfer function, just in case if rounding error causes pool to not have enough reward token.
     * @param to account that is receiving rewards
     * @param amount amount of rewards to send
     */
    function _safeRewardsTransfer(address to, uint256 amount) internal {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if (amount > rewardTokenBalance) {
            rewardToken.safeTransfer(to, rewardTokenBalance);
        } else {
            rewardToken.safeTransfer(to, amount);
        }
    }

    /**
     * @notice Safe SUSHI transfer function, just in case if rounding error causes pool to not have enough SUSHI.
     * @param to account that is receiving SUSHI
     * @param amount amount of SUSHI to send
     */
    function _safeSushiTransfer(address to, uint256 amount) internal {
        uint256 sushiBalance = sushiToken.balanceOf(address(this));
        if (amount > sushiBalance) {
            sushiToken.safeTransfer(to, sushiBalance);
        } else {
            sushiToken.safeTransfer(to, amount);
        }
    }

    /**
     * @notice Internal function that updates rewards end block based on tokens per block and the token balance of the contract
     */
    function _setRewardsEndBlock() internal {
        if(rewardTokensPerBlock > 0) {
            uint256 rewardFromBlock = block.number >= startBlock ? block.number : startBlock;
            uint256 newEndBlock = rewardFromBlock.add(rewardToken.balanceOf(address(this)).div(rewardTokensPerBlock));
            if(newEndBlock > rewardFromBlock && newEndBlock != endBlock) {
                emit ChangedRewardsEndBlock(endBlock, newEndBlock);
                endBlock = newEndBlock;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface ILockManager {
    struct LockedStake {
        uint256 amount;
        uint256 votingPower;
    }

    function getAmountStaked(address staker, address stakedToken) external view returns (uint256);
    function getStake(address staker, address stakedToken) external view returns (LockedStake memory);
    function calculateVotingPower(address token, uint256 amount) external view returns (uint256);
    function grantVotingPower(address receiver, address token, uint256 tokenAmount) external returns (uint256 votingPowerGranted);
    function removeVotingPower(address receiver, address token, uint256 tokenAmount) external returns (uint256 votingPowerRemoved);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

interface IMasterChef {
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12.
    }
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
    function updatePool(uint256 _pid) external;
    function sushiPerBlock() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IVault {
    
    struct Lock {
        address token;
        address receiver;
        uint48 startTime;
        uint16 vestingDurationInDays;
        uint16 cliffDurationInDays;
        uint256 amount;
        uint256 amountClaimed;
        uint256 votingPower;
    }

    struct LockBalance {
        uint256 id;
        uint256 claimableAmount;
        Lock lock;
    }

    struct TokenBalance {
        uint256 totalAmount;
        uint256 claimableAmount;
        uint256 claimedAmount;
        uint256 votingPower;
    }

    function lockTokens(address token, address locker, address receiver, uint48 startTime, uint256 amount, uint16 lockDurationInDays, uint16 cliffDurationInDays, bool grantVotingPower) external;
    function lockTokensWithPermit(address token, address locker, address receiver, uint48 startTime, uint256 amount, uint16 lockDurationInDays, uint16 cliffDurationInDays, bool grantVotingPower, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function claimUnlockedTokenAmounts(uint256[] memory lockIds, uint256[] memory amounts) external;
    function claimAllUnlockedTokens(uint256[] memory lockIds) external;
    function tokenLocks(uint256 lockId) external view returns(Lock memory);
    function allActiveLockIds() external view returns(uint256[] memory);
    function allActiveLocks() external view returns(Lock[] memory);
    function allActiveLockBalances() external view returns(LockBalance[] memory);
    function activeLockIds(address receiver) external view returns(uint256[] memory);
    function allLocks(address receiver) external view returns(Lock[] memory);
    function activeLocks(address receiver) external view returns(Lock[] memory);
    function activeLockBalances(address receiver) external view returns(LockBalance[] memory);
    function totalTokenBalance(address token) external view returns(TokenBalance memory balance);
    function tokenBalance(address token, address receiver) external view returns(TokenBalance memory balance);
    function lockBalance(uint256 lockId) external view returns (LockBalance memory);
    function claimableBalance(uint256 lockId) external view returns (uint256);
    function extendLock(uint256 lockId, uint16 vestingDaysToAdd, uint16 cliffDaysToAdd) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}