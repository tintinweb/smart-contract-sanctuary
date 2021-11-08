/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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
interface IVoteStaking {
    function set(
        uint256 _pid,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        bool _withUpdate
    ) external;

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, address _who, uint256 _amount) external;

    function withdraw(uint256 _pid, address _who) external returns(uint256);

    function claim(uint256 _pid, address _who) external returns(uint256);

    function getUserStakedAmount(uint256 _pid, address _who) external view returns(uint256);
}
// File: contracts/interfaces/IVoteStaking.sol
interface IStaking {
  function userInfo(uint256 pid,  address who) external view returns(uint256, uint256, uint256);
}
// VoteStaking is a small pool that provides extra staking reward, and should be called by Staking.
contract VoteStaking is Ownable, IVoteStaking {

    using SafeMath for uint256;

    uint256 constant PER_SHARE_SIZE = 1e12;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardAmount;
        uint256 rewardDebt; // Reward debt.
    }

    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Info of the pool.
    struct PoolInfo {
        uint256 totalBalance;
        uint256 rewardPerBlock;
        uint256 startBlock;
        uint256 endBlock;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare; // Accumulated BLES per share, times PER_SHARE_SIZE.
    }

    // Info of the pool.
    mapping(uint256 => PoolInfo) public poolInfo;

    address public stakingAddress;

    event Deposit(uint256 indexed pid, address indexed user, uint256 amount);
    event Withdraw(uint256 indexed pid, address indexed user, uint256 amount);
    event Claim(uint256 indexed pid, address indexed user, uint256 amount);

    constructor(
        address _stakingAddress
    ) public {
        stakingAddress = _stakingAddress;
    }

    function changeStakingAddress(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }

    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        bool _withUpdate
    ) external override {
        require(msg.sender == stakingAddress, "Only staking address can call");

        if (_withUpdate) {
            updatePool(_pid);
        }

        poolInfo[_pid].rewardPerBlock = _rewardPerBlock;
        poolInfo[_pid].startBlock = _startBlock;
        poolInfo[_pid].endBlock = _endBlock;
    }

    // Return reward multiplier over the given _from to _to block.
    function getReward(uint256 _pid, uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= _from || _from > poolInfo[_pid].endBlock || _to < poolInfo[_pid].startBlock) {
            return 0;
        }

        uint256 startBlock = _from < poolInfo[_pid].startBlock ? poolInfo[_pid].startBlock : _from;
        uint256 endBlock = _to < poolInfo[_pid].endBlock ? _to : poolInfo[_pid].endBlock;
        return endBlock.sub(startBlock).mul(poolInfo[_pid].rewardPerBlock);
    }

    // View function to see pending BLES on frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        override
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accRewardPerShare = poolInfo[_pid].accRewardPerShare;

        if (block.number > poolInfo[_pid].lastRewardBlock && poolInfo[_pid].totalBalance > 0) {
            uint256 reward = getReward(_pid, poolInfo[_pid].lastRewardBlock, block.number);
            accRewardPerShare = accRewardPerShare.add(
                reward.mul(PER_SHARE_SIZE).div(poolInfo[_pid].totalBalance)
            );
        }

        return user.amount.mul(accRewardPerShare).div(
            PER_SHARE_SIZE).sub(user.rewardDebt).add(user.rewardAmount);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public override {
        if (block.number <= poolInfo[_pid].lastRewardBlock) {
            return;
        }

        if (poolInfo[_pid].totalBalance == 0) {
            poolInfo[_pid].lastRewardBlock = block.number;
            return;
        }

        uint256 reward = getReward(_pid, poolInfo[_pid].lastRewardBlock, block.number);

        poolInfo[_pid].accRewardPerShare = poolInfo[_pid].accRewardPerShare.add(
            reward.mul(PER_SHARE_SIZE).div(poolInfo[_pid].totalBalance)
        );

        poolInfo[_pid].lastRewardBlock = block.number;
    }

    // Deposit tokens for BLES allocation.
    function deposit(uint256 _pid, address _who, uint256 _amount) external override {
        require(msg.sender == stakingAddress, "Only staking address can call");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_who];

        (uint256 stakingAmount,,) = IStaking(stakingAddress).userInfo(_pid, _who);
        require(stakingAmount >= user.amount.add(_amount), "Not enough staking amount");

        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accRewardPerShare).div(PER_SHARE_SIZE).sub(
                    user.rewardDebt
                );

            user.rewardAmount = user.rewardAmount.add(pending);
        }

        pool.totalBalance = pool.totalBalance.add(_amount);

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(PER_SHARE_SIZE);
        emit Deposit(_pid, _who, _amount);
    }

    // Withdraw all tokens.
    function withdraw(uint256 _pid, address _who) external override returns(uint256) {
        require(msg.sender == stakingAddress, "Only staking address can call");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_who];

        uint256 userAmount = user.amount;

        if (userAmount == 0) {
            return 0;
        }

        updatePool(_pid);

        uint256 pending = userAmount.mul(pool.accRewardPerShare).div(
            PER_SHARE_SIZE).sub(user.rewardDebt);
        user.rewardAmount = user.rewardAmount.add(pending);

        user.amount = 0;
        user.rewardDebt = 0;

        pool.totalBalance = pool.totalBalance.sub(userAmount);

        emit Withdraw(_pid, _who, userAmount);

        return userAmount;
    }

    // claim all reward.
    function claim(uint256 _pid, address _who) external override returns(uint256) {
        require(msg.sender == stakingAddress, "Only staking address can call");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_who];

        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(
            PER_SHARE_SIZE).sub(user.rewardDebt);
        uint256 rewardTotal = user.rewardAmount.add(pending);

        user.rewardAmount = 0;
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(PER_SHARE_SIZE);

        emit Claim(_pid, _who, rewardTotal);

        return rewardTotal;
    }

    function getUserStakedAmount(uint256 _pid, address _who) external override view returns(uint256) {
        UserInfo storage user = userInfo[_pid][_who];
        return user.amount;
    }
}