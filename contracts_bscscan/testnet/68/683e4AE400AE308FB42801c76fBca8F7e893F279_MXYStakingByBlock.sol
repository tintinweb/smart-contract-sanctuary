// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./pool/AllocationPool.sol";

contract MXYStakingByBlock is AllocationPool {
    /**
     * @notice Initialize the contract, get called in the first time deploy
     * @param _rewardToken the reward token address
     * @param _rewardPerBlock the number of reward tokens that got unlocked each block
     * @param _startBlock the block number when farming start
     * @param _globalAllocPoint global allocation point
     */
    constructor(
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint64 _globalAllocPoint
    ) AllocationPool(_rewardToken, _rewardPerBlock, _startBlock, _globalAllocPoint) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AllocationPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    uint64 private constant ACCUMULATED_MULTIPLIER = 1e12;

    uint64 public constant ALLOC_MAXIMUM_DELAY_DURATION = 35 days; // maximum 35 days delay

    // Info of each user.
    struct AllocUserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 pendingReward; // Reward but not harvest
        uint256 joinTime;
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct AllocPoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 lpSupply; // Total lp tokens deposited to this pool.
        uint64 allocPoint; // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardBlock; // Last block number that rewards distribution occurs.
        uint256 accRewardPerShare; // Accumulated rewards per share, times 1e12. See below.
        uint256 delayDuration; // The duration user need to wait when withdraw.
        uint256 lockDuration;
    }

    struct AllocPendingWithdrawal {
        uint256 amount;
        uint256 applicableAt;
    }

    // The reward token!
    IERC20 public allocRewardToken;

    // Total rewards for each block.
    uint256 public allocRewardPerBlock;

    // The reward distribution address
    address public allocRewardDistributor;

    // Allow emergency withdraw feature
    bool public allocAllowEmergencyWithdraw;

    // Info of each pool.
    AllocPoolInfo[] public allocPoolInfo;

    // A record status of LP pool.
    mapping(IERC20 => bool) public allocIsAdded;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => AllocUserInfo)) public allocUserInfo;

    // Global allocation points across chains
    uint64 public globalAllocPoint;

    // The block number when rewards mining starts.
    uint256 public allocStartBlockNumber;

    // The block number when rewards mining ends.
    uint64 public allocEndBlockNumber;

    // Info of pending withdrawals.
    mapping(uint256 => mapping(address => AllocPendingWithdrawal))
        public allocPendingWithdrawals;

    event AllocPoolCreated(
        uint256 indexed pid,
        address indexed token,
        uint256 allocPoint
    );
    event AllocDeposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AllocWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AllocPendingWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AllocEmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AllocRewardsHarvested(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /**
     * @notice Initialize the contract, get called in the first time deploy
     * @param _rewardToken the reward token address
     * @param _rewardPerBlock the number of reward tokens that got unlocked each block
     * @param _startBlock the block number when farming start
     * @param _globalAllocPoint global allocation point
     */
    constructor(
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint64 _globalAllocPoint
    ) Ownable() {
        require(
            address(_rewardToken) != address(0),
            "AllocStakingPool: invalid reward token address"
        );
        allocRewardToken = _rewardToken;
        allocRewardPerBlock = _rewardPerBlock;
        allocStartBlockNumber = _startBlock;

        globalAllocPoint = _globalAllocPoint;
    }

    /**
     * @notice Validate pool by pool ID
     * @param _pid id of the pool
     */
    modifier allocValidatePoolById(uint256 _pid) {
        require(
            _pid < allocPoolInfo.length,
            "AllocStakingPool: pool are not exist"
        );
        _;
    }

    /**
     * @notice Return total number of pools
     */
    function allocPoolLength() external view returns (uint256) {
        return allocPoolInfo.length;
    }

    /**
     * @notice Add a new lp to the pool. Can only be called by the owner.
     * @param _allocPoint the allocation point of the pool, used when calculating total reward the whole pool will receive each block
     * @param _lpToken the token which this pool will accept
     * @param _delayDuration the time user need to wait when withdraw
     */
    function allocAddPool(
        uint64 _allocPoint,
        IERC20 _lpToken,
        uint256 _delayDuration,
        uint256 _lockDuration
    ) external onlyOwner {
        require(
            !allocIsAdded[_lpToken],
            "AllocStakingPool: pool already is added"
        );
        require(
            _delayDuration <= ALLOC_MAXIMUM_DELAY_DURATION,
            "AllocStakingPool: delay duration is too long"
        );
        allocMassUpdatePools();

        uint256 lastRewardBlock = block.number > allocStartBlockNumber
            ? block.number
            : allocStartBlockNumber;

        allocPoolInfo.push(
            AllocPoolInfo({
                lpToken: _lpToken,
                lpSupply: 0,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                delayDuration: _delayDuration,
                lockDuration: _lockDuration
            })
        );
        allocIsAdded[_lpToken] = true;
        emit AllocPoolCreated(
            allocPoolInfo.length - 1,
            address(_lpToken),
            _allocPoint
        );
    }

    /**
     * @notice Update the given pool's reward allocation point. Can only be called by the owner.
     * @param _pid id of the pool
     * @param _allocPoint the allocation point of the pool, used when calculating total reward the whole pool will receive each block
     * @param _delayDuration the time user need to wait when withdraw
     */
    function allocSetPool(
        uint256 _pid,
        uint64 _allocPoint,
        uint256 _delayDuration,
        uint256 _lockDuration
    ) external onlyOwner allocValidatePoolById(_pid) {
        require(
            _delayDuration <= ALLOC_MAXIMUM_DELAY_DURATION,
            "AllocStakingPool: delay duration is too long"
        );
        allocMassUpdatePools();

        allocPoolInfo[_pid].allocPoint = _allocPoint;
        allocPoolInfo[_pid].delayDuration = _delayDuration;
        allocPoolInfo[_pid].lockDuration = _lockDuration;
    }

    /**
     * @notice Set the approval amount of distributor. Can only be called by the owner.
     * @param _amount amount of approval
     */
    function allocApproveSelfDistributor(uint256 _amount) external onlyOwner {
        require(
            allocRewardDistributor == address(this),
            "AllocStakingPool: distributor is difference pool"
        );
        allocRewardToken.safeApprove(allocRewardDistributor, _amount);
    }

    /**
     * @notice Set the reward distributor. Can only be called by the owner.
     * @param _allocRewardDistributor the reward distributor
     */
    function allocSetRewardDistributor(address _allocRewardDistributor)
        external
        onlyOwner
    {
        require(
            _allocRewardDistributor != address(0),
            "AllocStakingPool: invalid reward distributor"
        );
        allocRewardDistributor = _allocRewardDistributor;
    }

    /**
     * @notice Set the end block number. Can only be called by the owner.
     */
    function allocSetEndBlock(uint64 _endBlockNumber) external onlyOwner {
        require(
            _endBlockNumber > block.number,
            "AllocStakingPool: invalid reward distributor"
        );
        allocEndBlockNumber = _endBlockNumber;
    }

    /**
     * @notice Set the global allocation point of this master pool contract.
     */
    function allocSetGlobalAllocPoint(uint64 _globalAllocPoint)
        external
        onlyOwner
    {
        globalAllocPoint = _globalAllocPoint;
    }

    /**
     * @notice Return time multiplier over the given _from to _to block.
     * @param _from the number of starting block
     * @param _to the number of ending block
     */
    function allocTimeMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (allocEndBlockNumber > 0 && _to > allocEndBlockNumber) {
            return
                allocEndBlockNumber > _from ? allocEndBlockNumber - _from : 0;
        }
        return _to - _from;
    }

    /**
     * @notice Update number of reward per block
     * @param _rewardPerBlock the number of reward tokens that got unlocked each block
     */
    function allocSetRewardPerBlock(uint256 _rewardPerBlock)
        external
        onlyOwner
    {
        allocMassUpdatePools();
        allocRewardPerBlock = _rewardPerBlock;
    }

    /**
     * @notice View function to see pending rewards on frontend.
     * @param _pid id of the pool
     * @param _user the address of the user
     */
    function allocPendingReward(uint256 _pid, address _user)
        public
        view
        allocValidatePoolById(_pid)
        returns (uint256)
    {
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        AllocUserInfo storage user = allocUserInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = allocTimeMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 poolReward = (multiplier *
                allocRewardPerBlock *
                pool.allocPoint) / globalAllocPoint;
            accRewardPerShare =
                accRewardPerShare +
                ((poolReward * ACCUMULATED_MULTIPLIER) / lpSupply);
        }
        return
            user.pendingReward +
            (((user.amount * accRewardPerShare) / ACCUMULATED_MULTIPLIER) -
                user.rewardDebt);
    }

    /**
     * @notice Update reward vairables for all pools. Be careful of gas spending!
     */
    function allocMassUpdatePools() public {
        uint256 length = allocPoolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            allocUpdatePool(pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @param _pid id of the pool
     */
    function allocUpdatePool(uint256 _pid) public allocValidatePoolById(_pid) {
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = allocTimeMultiplier(
            pool.lastRewardBlock,
            block.number
        );
        uint256 poolReward = (multiplier *
            allocRewardPerBlock *
            pool.allocPoint) / globalAllocPoint;
        pool.accRewardPerShare = (pool.accRewardPerShare +
            ((poolReward * ACCUMULATED_MULTIPLIER) / lpSupply));
        pool.lastRewardBlock = block.number;
    }

    /**
     * @notice Deposit LP tokens to the farm for reward allocation.
     * @param _pid id of the pool
     * @param _amount amount to deposit
     */
    function allocDeposit(uint256 _pid, uint256 _amount)
        external
        nonReentrant
        allocValidatePoolById(_pid)
    {
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        AllocUserInfo storage user = allocUserInfo[_pid][msg.sender];
        allocUpdatePool(_pid);
        uint256 pending = ((user.amount * pool.accRewardPerShare) /
            ACCUMULATED_MULTIPLIER) - user.rewardDebt;
        user.joinTime = block.timestamp;
        user.pendingReward = user.pendingReward + pending;
        user.amount = user.amount + _amount;
        user.rewardDebt =
            (user.amount * pool.accRewardPerShare) /
            ACCUMULATED_MULTIPLIER;
        pool.lpSupply = pool.lpSupply + _amount;
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit AllocDeposit(msg.sender, _pid, _amount);
    }

    /**
     * @notice Withdraw LP tokens from Pool.
     * @param _pid id of the pool
     * @param _amount amount to withdraw
     * @param _harvestReward whether the user want to claim the rewards or not
     */
    function allocWithdraw(
        uint256 _pid,
        uint256 _amount,
        bool _harvestReward
    ) external nonReentrant allocValidatePoolById(_pid) {
        _allocWithdraw(_pid, _amount, _harvestReward);

        AllocPoolInfo storage pool = allocPoolInfo[_pid];

        if (pool.delayDuration == 0) {
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            emit AllocWithdraw(msg.sender, _pid, _amount);
            return;
        }

        AllocPendingWithdrawal
            storage pendingWithdraw = allocPendingWithdrawals[_pid][msg.sender];
        pendingWithdraw.amount = pendingWithdraw.amount + _amount;
        pendingWithdraw.applicableAt = block.timestamp + pool.delayDuration;
    }

    /**
     * @notice Claim pending withdrawal
     * @param _pid id of the pool
     */
    function allocClaimPendingWithdraw(uint256 _pid)
        external
        nonReentrant
        allocValidatePoolById(_pid)
    {
        AllocPoolInfo storage pool = allocPoolInfo[_pid];

        AllocPendingWithdrawal
            storage pendingWithdraw = allocPendingWithdrawals[_pid][msg.sender];
        uint256 amount = pendingWithdraw.amount;
        require(amount > 0, "AllocStakingPool: nothing is currently pending");
        require(
            pendingWithdraw.applicableAt <= block.timestamp,
            "AllocStakingPool: not released yet"
        );
        delete allocPendingWithdrawals[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit AllocWithdraw(msg.sender, _pid, amount);
    }

    /**
     * @notice Update allowance for emergency withdraw
     * @param _shouldAllow should allow emergency withdraw or not
     */
    function allocSetAllowEmergencyWithdraw(bool _shouldAllow)
        external
        onlyOwner
    {
        allocAllowEmergencyWithdraw = _shouldAllow;
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param _pid id of the pool
     */
    function allocEmergencyWithdraw(uint256 _pid)
        external
        nonReentrant
        allocValidatePoolById(_pid)
    {
        require(
            allocAllowEmergencyWithdraw,
            "AllocStakingPool: emergency withdrawal is not allowed yet"
        );
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        AllocUserInfo storage user = allocUserInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpSupply = pool.lpSupply - amount;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit AllocEmergencyWithdraw(msg.sender, _pid, amount);
    }

    /**
     * @notice Compound rewards to reward pool
     * @param _rewardPoolId id of the reward pool
     */
    function allocCompoundReward(uint256 _rewardPoolId)
        external
        nonReentrant
        allocValidatePoolById(_rewardPoolId)
    {
        AllocPoolInfo storage pool = allocPoolInfo[_rewardPoolId];
        AllocUserInfo storage user = allocUserInfo[_rewardPoolId][msg.sender];
        require(
            pool.lpToken == allocRewardToken,
            "AllocStakingPool: invalid reward pool"
        );

        uint256 totalPending = allocPendingReward(_rewardPoolId, msg.sender);

        require(totalPending > 0, "AllocStakingPool: invalid reward amount");

        user.pendingReward = 0;
        allocSafeRewardTransfer(address(this), totalPending);
        emit AllocRewardsHarvested(msg.sender, _rewardPoolId, totalPending);

        allocUpdatePool(_rewardPoolId);

        user.amount = user.amount + totalPending;
        user.rewardDebt =
            (user.amount * pool.accRewardPerShare) /
            ACCUMULATED_MULTIPLIER;
        pool.lpSupply = pool.lpSupply + totalPending;

        emit AllocDeposit(msg.sender, _rewardPoolId, totalPending);
    }

    /**
     * @notice Harvest proceeds msg.sender
     * @param _pid id of the pool
     */
    function allocClaimReward(uint256 _pid)
        public
        nonReentrant
        allocValidatePoolById(_pid)
        returns (uint256)
    {
        return _allocClaimReward(_pid);
    }

    /**
     * @notice Harvest proceeds of all pools for msg.sender
     * @param _pids ids of the pools
     */
    function allocClaimAll(uint256[] memory _pids) external nonReentrant {
        uint256 length = _pids.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _allocClaimReward(pid);
        }
    }

    /**
     * @notice Safe reward transfer function, just in case if reward distributor dose not have enough reward tokens.
     * @param _to address of the receiver
     * @param _amount amount of the reward token
     */
    function allocSafeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 bal = allocRewardToken.balanceOf(allocRewardDistributor);

        require(_amount <= bal, "AllocStakingPool: not enough reward token");

        allocRewardToken.safeTransferFrom(allocRewardDistributor, _to, _amount);
    }

    /**
     * @notice Withdraw LP tokens from Pool.
     * @param _pid id of the pool
     * @param _amount amount to withdraw
     * @param _harvestReward whether the user want to claim the rewards or not
     */
    function _allocWithdraw(
        uint256 _pid,
        uint256 _amount,
        bool _harvestReward
    ) internal {
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        AllocUserInfo storage user = allocUserInfo[_pid][msg.sender];
        require(user.amount >= _amount, "AllocStakingPool: invalid amount");

        require(
            block.timestamp >= user.joinTime + pool.lockDuration,
            "LinearStakingPool: still locked"
        );

        if (_harvestReward || user.amount == _amount) {
            _allocClaimReward(_pid);
        } else {
            allocUpdatePool(_pid);
            uint256 pending = ((user.amount * pool.accRewardPerShare) /
                ACCUMULATED_MULTIPLIER) - user.rewardDebt;
            if (pending > 0) {
                user.pendingReward = user.pendingReward + pending;
            }
        }
        user.amount -= _amount;
        user.rewardDebt =
            (user.amount * pool.accRewardPerShare) /
            ACCUMULATED_MULTIPLIER;
        pool.lpSupply = pool.lpSupply - _amount;
    }

    function _allocClaimReward(uint256 _pid) internal returns (uint256) {
        allocUpdatePool(_pid);
        AllocPoolInfo storage pool = allocPoolInfo[_pid];
        AllocUserInfo storage user = allocUserInfo[_pid][msg.sender];
        uint256 totalPending = allocPendingReward(_pid, msg.sender);

        user.pendingReward = 0;
        user.rewardDebt =
            (user.amount * pool.accRewardPerShare) /
            (ACCUMULATED_MULTIPLIER);
        if (totalPending > 0) {
            allocSafeRewardTransfer(msg.sender, totalPending);
        }
        emit AllocRewardsHarvested(msg.sender, _pid, totalPending);
        return totalPending;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}