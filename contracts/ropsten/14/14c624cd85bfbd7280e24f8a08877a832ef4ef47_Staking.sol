/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Staking.sol

contract Staking is Ownable {
    using SafeMath for uint256;

    struct StakeInfo {
        uint256 amount; // Stake amount in stakingToken (Rakucoin)
        uint256 depositTime;
    }

    struct PoolInfo {
        address stakeToken;
        uint256 rewardRate; // Reward rate multiplied by 10^6 (e.g. 0.03 * 10^6 = 30000 for 3%)
        uint256 lockupDuration;
        uint256 depositedAmount; // Deposited amount in stakingToken (Rakucoin)
        bool active;
    }

    address public rewardToken; // Rakugold
    PoolInfo[] public poolInfo;
    mapping(address => mapping(uint256 => StakeInfo[])) public userInfo;
    mapping(address => mapping(address => uint256)) public conversionRate; // conversationRate multiplied by 10^6
    mapping(address => uint256) public stakeAmount;

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        address indexed stakeToken,
        uint256 stakeAmount
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        address indexed stakeToken,
        uint256 stakeAmount
    );
    event Claim(
        address indexed user,
        uint256 indexed pid,
        address indexed rewardToken,
        uint256 rewardAmount
    );

    constructor(address _rewardToken) public {
        setRewardToken(_rewardToken);
    }

    /////////////// Write functions ////////////////

    function setRewardToken(address _rewardToken) public onlyOwner {
        rewardToken = _rewardToken;
    }

    function setConversionRate(
        address token1,
        address token2,
        uint256 _conversionRate
    ) public onlyOwner {
        conversionRate[token1][token2] = _conversionRate;
    }

    function emergencyWithdraw() external onlyOwner {
        require(
            IERC20(rewardToken).balanceOf(address(this)) >
                stakeAmount[rewardToken],
            "Not enough balance"
        );
        require(
            IERC20(rewardToken).transfer(
                msg.sender,
                IERC20(rewardToken).balanceOf(address(this)).sub(
                    stakeAmount[rewardToken]
                )
            ),
            "Emergency withdrawl failed"
        );
    }

    function addPool(
        address _stakeToken,
        uint256 _rewardRate,
        uint256 _lockupDuration
    ) external onlyOwner {
        poolInfo.push(
            PoolInfo({
                stakeToken: _stakeToken,
                rewardRate: _rewardRate,
                lockupDuration: _lockupDuration,
                depositedAmount: 0,
                active: true
            })
        );
    }

    function updatePool(
        uint256 pid,
        uint256 _rewardRate,
        uint256 _lockupDuration,
        bool _active
    ) external onlyOwner {
        require(pid < poolInfo.length, "Pool does not exist");
        PoolInfo storage pool = poolInfo[pid];
        pool.rewardRate = _rewardRate;
        pool.lockupDuration = _lockupDuration;
        pool.active = _active;
    }

    function deposit(uint256 pid, uint256 amount) external {
        require(pid < poolInfo.length, "Pool does not exist");
        require(poolInfo[pid].active, "Pool is not active");
        require(
            getAmountInRewardToken(poolInfo[pid].stakeToken, amount) <=
                getRemainingRewards(),
            "Not enough rewards remaining"
        );
        require(
            IERC20(poolInfo[pid].stakeToken).transferFrom(
                msg.sender,
                address(this),
                amount
            )
        );

        stakeAmount[poolInfo[pid].stakeToken] = stakeAmount[
            poolInfo[pid].stakeToken
        ]
        .add(amount);
        poolInfo[pid].depositedAmount = poolInfo[pid].depositedAmount.add(
            amount
        );
        userInfo[msg.sender][pid].push(
            StakeInfo({amount: amount, depositTime: block.timestamp})
        );

        emit Deposit(msg.sender, pid, poolInfo[pid].stakeToken, amount);
    }

    function withdraw(uint256 pid, uint256 stakeId) external {
        require(pid < poolInfo.length, "Pool does not exist");
        require(
            stakeId < userInfo[msg.sender][pid].length,
            "Stake info does not exist"
        );

        PoolInfo storage pool = poolInfo[pid];
        StakeInfo storage stakeInfo = userInfo[msg.sender][pid][stakeId];

        require(
            IERC20(pool.stakeToken).transfer(msg.sender, stakeInfo.amount),
            "Withdrawl failed"
        );
        emit Withdraw(msg.sender, pid, pool.stakeToken, stakeInfo.amount);

        stakeAmount[pool.stakeToken] = stakeAmount[pool.stakeToken].sub(
            stakeInfo.amount
        );
        pool.depositedAmount = pool.depositedAmount.sub(stakeInfo.amount);

        if (stakeInfo.depositTime.add(pool.lockupDuration) > block.timestamp) {
            uint256 rewardAmount = getRewardAmount(
                getAmountInRewardToken(pool.stakeToken, stakeInfo.amount),
                pool.rewardRate
            );
            if (
                rewardAmount.add(stakeAmount[rewardToken]) <=
                IERC20(rewardToken).balanceOf(address(this))
            ) {
                require(
                    IERC20(rewardToken).transfer(msg.sender, rewardAmount),
                    "Claim failed"
                );
                emit Claim(msg.sender, pid, rewardToken, rewardAmount);
            }
        }

        userInfo[msg.sender][pid][stakeId] = userInfo[msg.sender][pid][
            userInfo[msg.sender][pid].length - 1
        ];
        userInfo[msg.sender][pid].pop();
    }

    /////////////// Get functions ////////////////

    function getAmountInRewardToken(address token, uint256 amount)
        private
        view
        returns (uint256)
    {
        return amount.mul(10**6).div(conversionRate[token][rewardToken]);
    }

    function getRewardAmount(uint256 amount, uint256 rewardRate)
        private
        view
        returns (uint256)
    {
        return amount.mul(rewardRate).div(10**6);
    }

    function getPendingRewards() private view returns (uint256) {
        uint256 pendingRewards = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            pendingRewards = pendingRewards.add(
                getRewardAmount(
                    getAmountInRewardToken(
                        poolInfo[i].stakeToken,
                        poolInfo[i].depositedAmount
                    ),
                    poolInfo[i].rewardRate
                )
            );
        }
        return pendingRewards;
    }

    function getRemainingRewards() public view returns (uint256) {
        uint256 totalBalanceInStakeToken = IERC20(rewardToken).balanceOf(
            address(this)
        );
        uint256 pendingRewards = getPendingRewards();

        if (totalBalanceInStakeToken < pendingRewards) {
            return 0;
        }
        return totalBalanceInStakeToken.sub(pendingRewards);
    }
}