// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ILiquidityMining.sol";
import "./IMigrator.sol";

contract LiquidityMining is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user per pool.
    struct UserPoolInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 accruedReward; // Reward accrued.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        uint256 accRewardPerShare; // Accumulated reward token per share, times 1e12. See below.
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardBlock; // Last block number that reward token distribution occurs.
    }

    struct UnlockInfo {
        uint256 block;
        uint256 quota;
    }

    // The reward token token
    IERC20 public rewardToken;
    // Reservoir address.
    address public reservoir;
    // rewardToken tokens created per block.
    uint256 public rewardPerBlock;

    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigrator public migrator;

    // Blocks and quotas of rewards unlocks
    UnlockInfo[] public unlocks;
    uint256 public unlocksTotalQuotation;
    // Accumulated rewards
    mapping(address => uint256) public rewards;
    // Claimed rewards
    mapping(address => uint256) public claimedRewards;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Pid of each pool by its address
    mapping(address => uint256) public poolPidByAddress;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserPoolInfo)) public userPoolInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when rewardToken mining starts.
    uint256 public startBlock;
    // The block number when rewardToken mining end.
    uint256 public endBlock;

    event TokenAdded(
        address indexed token,
        uint256 indexed pid,
        uint256 allocPoint
    );
    event Claimed(address indexed user, uint256 amount);
    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdrawn(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event TokenMigrated(
        address indexed oldtoken,
        address indexed newToken,
        uint256 indexed pid
    );
    event RewardPerBlockSet(uint256 rewardPerBlock);
    event TokenSet(
        address indexed token,
        uint256 indexed pid,
        uint256 allocPoint
    );
    event MigratorSet(address indexed migrator);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _rewardToken,
        address _reservoir,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) {
        rewardToken = _rewardToken;
        reservoir = _reservoir;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;

        emit RewardPerBlockSet(_rewardPerBlock);
    }

    // Add a new token to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate
    ) external onlyOwner {
        require(!isTokenAdded(_token), "add: token already added");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        uint256 pid = poolInfo.length;
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0
            })
        );
        poolPidByAddress[address(_token)] = pid;

        emit TokenAdded(address(_token), pid, _allocPoint);
    }

    function accrueReward(uint256 _pid) internal {
        UserPoolInfo memory userPool = userPoolInfo[_pid][msg.sender];
        if (userPool.amount == 0) {
            return;
        }
        rewards[msg.sender] = rewards[msg.sender].add(
            calcReward(poolInfo[_pid], userPool).sub(userPool.accruedReward)
        );
    }

    function calcReward(PoolInfo memory pool, UserPoolInfo memory userPool) internal returns(uint256){
        return userPool.amount.mul(pool.accRewardPerShare).div(1e12);
    }

    function getPendingReward(uint256 _pid, address _user)
        external view
        returns(uint256 total, uint256 unlocked) {

        PoolInfo memory pool = poolInfo[_pid];

        uint256 currentBlock = block.number;
        if (currentBlock < startBlock) {
            return (0, 0);
        }
        if (currentBlock > endBlock) {
            currentBlock = endBlock;
        }

        uint256 lpSupply = pool.token.balanceOf(address(this));
        if (lpSupply == 0) {
            return (0, 0);
        }
        uint256 blockLasted = currentBlock.sub(pool.lastRewardBlock);
        uint256 reward = blockLasted.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 accRewardPerShare = pool.accRewardPerShare.add(
            reward.mul(1e12).div(lpSupply)
        );

        UserPoolInfo memory userPool = userPoolInfo[_pid][_user];
        total = userPool.amount
            .mul(accRewardPerShare)
            .div(1e12)
            .sub(userPool.accruedReward);

        unlocked = calcUnlocked(total);
    }

    function calcUnlocked(uint256 reward) public view returns(uint256 claimable) {
        uint256 i;
        for (i = 0; i < unlocks.length; ++i) {
            if (block.number < unlocks[i].block) {
                continue;
            }
            claimable = claimable.add(
                reward.mul(unlocks[i].quota)
                .div(unlocksTotalQuotation)
            );
        }
    }

    // claim rewards
    function claim() external{
        uint256 i;
        for (i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
            accrueReward(i);
            UserPoolInfo storage userPool = userPoolInfo[i][msg.sender];
            userPool.accruedReward = calcReward(poolInfo[i], userPool);
        }
        uint256 unlocked = calcUnlocked(rewards[msg.sender]).sub(claimedRewards[msg.sender]);
        if (unlocked > 0) {
            _safeRewardTransfer(msg.sender, unlocked);
        }
        claimedRewards[msg.sender] = claimedRewards[msg.sender].add(unlocked);
        emit Claimed(msg.sender, unlocked);
    }

    // Deposit tokens to liquidity mining for reward token allocation.
    function deposit(uint256 _pid, uint256 _amount) external {
        require(block.number <= endBlock, "LP mining has ended.");
        updatePool(_pid);
        accrueReward(_pid);

        UserPoolInfo storage userPool = userPoolInfo[_pid][msg.sender];

        if (_amount > 0) {
            poolInfo[_pid].token.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );

            userPool.amount = userPool.amount.add(_amount);
        }

        userPool.accruedReward = calcReward(poolInfo[_pid], userPoolInfo[_pid][msg.sender]);
        emit Deposited(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function withdrawEmergency(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserPoolInfo storage userPool = userPoolInfo[_pid][msg.sender];
        pool.token.safeTransfer(address(msg.sender), userPool.amount);
        emit EmergencyWithdrawn(msg.sender, _pid, userPool.amount);
        userPool.amount = 0;
        userPool.accruedReward = 0;
    }

    // Update the given pool's reward token allocation point. Can only be called by the owner.
    function reallocatePool(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;

        emit TokenSet(address(poolInfo[_pid].token), _pid, _allocPoint);
    }

    // Set reward per block. Can only be called by the owner.
    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;

        emit RewardPerBlockSet(_rewardPerBlock);
    }

    // Set unlocks infos - block number and quota.
    function setUnlocks(uint256[] calldata _blocks, uint256[] calldata _quotas) external onlyOwner {
        require(_blocks.length == _quotas.length, "Should be same length");
        for (uint256 i = 0; i < _blocks.length; ++i) {
            unlocks.push(UnlockInfo(_blocks[i], _quotas[i]));
            unlocksTotalQuotation = unlocksTotalQuotation.add(_quotas[i]);
        }
    }

    // Withdraw tokens from rewardToken liquidity mining.
    function withdraw(uint256 _pid, uint256 _amount) external {
        require(userPoolInfo[_pid][msg.sender].amount >= _amount, "withdraw: not enough amount");
        updatePool(_pid);
        accrueReward(_pid);
        UserPoolInfo storage userPool = userPoolInfo[_pid][msg.sender];
        if (_amount > 0) {
            userPool.amount = userPool.amount.sub(_amount);
            poolInfo[_pid].token.safeTransfer(address(msg.sender), _amount);
        }

        userPool.accruedReward = calcReward(poolInfo[_pid], userPoolInfo[_pid][msg.sender]);
        emit Withdrawn(msg.sender, _pid, _amount);
    }

    // Number of pools.
    function poolCount() external view returns (uint256) {
        return poolInfo.length;
    }

    function unlockCount() external view returns (uint256) {
        return unlocks.length;
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
        uint256 currentBlock = block.number;
        if (currentBlock > endBlock) {
            currentBlock = endBlock;
        }
        if (currentBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.token.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = currentBlock;
            return;
        }

        uint256 blockLasted = currentBlock.sub(pool.lastRewardBlock);
        uint256 reward =
            blockLasted.mul(rewardPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        rewardToken.transferFrom(reservoir, address(this), reward);
        pool.accRewardPerShare = pool.accRewardPerShare.add(
            reward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = currentBlock;
    }

    // Return bool - is token added or not
    function isTokenAdded(IERC20 _token) public view returns (bool) {
        uint256 pid = poolPidByAddress[address(_token)];
        return
            poolInfo.length > pid &&
            address(poolInfo[pid].token) == address(_token);
    }

    // Safe rewardToken transfer function.
    function _safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (_amount > balance) {
            rewardToken.transfer(_to, balance);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigrator _migrator) external onlyOwner {
        migrator = _migrator;
        emit MigratorSet(address(_migrator));
    }

    // Migrate token to another lp contract. Can be called by anyone.
    function migrate(uint256 _pid) external {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 token = pool.token;
        uint256 bal = token.balanceOf(address(this));
        token.safeApprove(address(migrator), bal);
        IERC20 newToken = migrator.migrate(token);
        require(bal == newToken.balanceOf(address(this)), "migrate: bad");
        pool.token = newToken;

        delete poolPidByAddress[address(token)];
        poolPidByAddress[address(newToken)] = _pid;

        emit TokenMigrated(address(token), address(newToken), _pid);
    }

    function getAllPools() external view returns (PoolInfo[] memory) {
        return poolInfo;
    }

    function getAllUnlocks() external view returns (UnlockInfo[] memory) {
        return unlocks;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface ILiquidityMining {
    struct UnlockInfo {
        uint256 block;
        uint256 quota;
    }
    function getAllUnlocks() external view returns (UnlockInfo[] memory);
    function unlocksTotalQuotation() external view returns(uint256);

    struct PoolInfo {
        address token;
        uint256 accRewardPerShare;
        uint256 allocPoint;
        uint256 lastRewardBlock;
    }
    function getAllPools() external view returns (PoolInfo[] memory);
    function totalAllocPoint() external returns(uint256);

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function claim() external;
    function getPendingReward(uint256 _pid, address _user)
    external view
    returns(uint256 total, uint256 available);

    function rewardToken() external view returns(address);
    function reservoir() external view returns(address);
    function rewardPerBlock() external view returns(uint256);
    function startBlock() external view returns(uint256);
    function endBlock() external view returns(uint256);

    function rewards(address) external view returns(uint256);
    function claimedRewards(address) external view returns(uint256);
    function poolPidByAddress(address) external view returns(uint256);
    function isTokenAdded(address _token) external view returns (bool);
    function calcUnlocked(uint256 reward) external view returns(uint256 claimable);

    struct UserPoolInfo {
        uint256 amount;
        uint256 accruedReward;
    }
    function userPoolInfo(uint256, address) external view returns(UserPoolInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMigrator {
    // Perform LP token migration from legacy LPMining CompliFi to newer version.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to CompliFi LP tokens.
    // CompliFi must mint EXACTLY the same amount of ComplFi LP tokens or
    // else something bad will happen.
    function migrate(IERC20 token) external returns (IERC20);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

