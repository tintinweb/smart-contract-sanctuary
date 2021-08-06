/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-02
*/

pragma solidity ^0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    function mint(address account, uint amount) external;

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external;
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
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
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
}

interface IBscPool {
    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function isBadAddress(address account) external view returns (bool);
    
    function userInfo(uint256 pid, address account) external view returns (uint256, uint256, uint256);
}

interface IPenetratePool {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawAll() external;

    function getReward() external;
}

contract PenetratePool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private operator;
    IBscPool private pool;
    uint256 private poolId;
    IERC20 private stakingToken;
    IERC20 private earnToken;

    constructor(
        address _operator,
        address _pool,
        uint256 _poolId,
        address _stakingToken,
        address _earnToken
    ) public {
        operator = _operator;
        pool = IBscPool(_pool);
        poolId = _poolId;
        stakingToken = IERC20(_stakingToken);
        earnToken = IERC20(_earnToken);
    }

    function deposit(uint256 amount) public nonReentrant checkOperator(msg.sender) {
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        stakingToken.safeApprove(address(pool), 0);
        stakingToken.safeApprove(address(pool), uint256(-1));
        pool.deposit(poolId, amount);
    }

    function withdraw(uint256 amount) public nonReentrant checkOperator(msg.sender) {
        pool.withdraw(poolId, amount);
        stakingToken.safeTransfer(operator, amount);
        earnToken.safeTransfer(operator, earnToken.balanceOf(address(this)));
    }

    function withdrawAll() public nonReentrant checkOperator(msg.sender) {
        (uint256 amount,,) = pool.userInfo(poolId, address(this));
        pool.withdraw(poolId, amount);
        stakingToken.safeTransfer(operator, amount);
        earnToken.safeTransfer(operator, earnToken.balanceOf(address(this)));
    }

    function getReward() public nonReentrant checkOperator(msg.sender) {
        earnToken.safeTransfer(operator, earnToken.balanceOf(address(this)));
    }

    modifier checkOperator(address sender) {
        require(operator == sender, 'not allow');
        _;
    }
}

contract LpStakingRewards is RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address public operator;                // goblin
    IERC20 public rewardsToken;             // deer
    IERC20 public stakingToken;             // lp token
    uint256 public startTime;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration = 7 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public rewardsPaid;
    uint256 public rewardsed;
    uint256 public rewardAmount;            // reward amount of every period

    uint256 public poolId;
    IBscPool public pool;
    IERC20 public earnToken;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    mapping(address => address) private penetrates;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _pool,
        uint256 _poolId,
        address _earnToken,
        uint256 _startTime
    ) public {
        operator = address(0);
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        pool = IBscPool(_pool);
        poolId = _poolId;
        earnToken = IERC20(_earnToken);
        startTime = _startTime;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function stake(uint256 amount, address user) external nonReentrant updateReward(user) checkhalve checkStart checkOperator(user, msg.sender) {
        require(amount > 0, "Cannot stake 0");
        require(user != address(0), "user cannot be 0");

        address from = operator != address(0) ? operator : user;
        _totalSupply = _totalSupply.add(amount);
        _balances[user] = _balances[user].add(amount);
        stakingToken.safeTransferFrom(from, address(this), amount);

        uint256 stakeAmount = amount;
        address penetrate = penetrates[user];
        if (penetrate == address(0) || pool.isBadAddress(penetrate)) {
            if (pool.isBadAddress(penetrate)) {
                (uint256 poolAmount,,) = pool.userInfo(poolId, penetrate);
                IPenetratePool(penetrate).withdrawAll();
                stakeAmount = stakeAmount.add(poolAmount);
            }
            penetrate = address(new PenetratePool(address(this), address(pool), poolId, address(stakingToken), address(earnToken)));
            penetrates[user] = penetrate;
        }
        stakingToken.safeApprove(penetrate, 0);
        stakingToken.safeApprove(penetrate, uint256(-1));
        IPenetratePool(penetrate).deposit(stakeAmount);
        emit StakedPool(user, stakeAmount);

        emit Staked(from, amount);
    }

    function withdraw(uint256 amount, address user) public nonReentrant updateReward(user) checkhalve checkStart checkOperator(user, msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(user != address(0), "user cannot be 0");
        require(_balances[user] >= amount, "not enough");

        address to = operator != address(0) ? operator : user;
        // withdraw lp token back
        address penetrate = penetrates[user];
        IPenetratePool(penetrate).withdraw(amount);
        emit WithdrawnPool(user, amount);

        _totalSupply = _totalSupply.sub(amount);
        _balances[user] = _balances[user].sub(amount);
        stakingToken.safeTransfer(to, amount);
        emit Withdrawn(to, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) checkhalve checkStart {
        require(msg.sender != address(0), "user cannot be 0");
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsPaid = rewardsPaid.add(reward);
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /* ========== MODIFIER ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        // lastUpdateTime = lastTimeRewardApplicable();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier checkhalve(){
        if (block.timestamp >= periodFinish && rewardAmount > 0) {
            rewardsed = rewardsed.add(rewardAmount);
            rewardRate = rewardAmount.div(rewardsDuration);
            periodFinish = block.timestamp.add(rewardsDuration);
            rewardsToken.mint(address(this), rewardAmount);
            emit RewardAdded(rewardAmount);
        }
        _;
    }

    modifier checkStart(){
        require(startTime > 0 && block.timestamp >= startTime,"not start");
        _;
    }

    modifier checkOperator(address user, address sender) {
        require((operator == address(0) && user == sender) || (operator != address(0) && operator == sender));
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyRewardsDistribution updateReward(address(0)) {
        require(rewardsed == 0, "reward already inited");
        rewardRate = reward.div(rewardsDuration);
        rewardsed = reward;
        rewardAmount = reward;
        rewardsToken.mint(address(this),reward);
        lastUpdateTime = block.timestamp;
        periodFinish = startTime.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setOperator(address _operator) external onlyRewardsDistribution {
        operator = _operator;
    }

    function setRewardAmount(uint256 _rewardAmount) external onlyRewardsDistribution {
        rewardAmount = _rewardAmount;
    }

    function claim(address to) external onlyRewardsDistribution {
        uint256 amount = earnToken.balanceOf(address(this));
        earnToken.safeTransfer(to, amount);
        emit Claim(to, amount);
    }

    function claimOf(address account, address to) external onlyRewardsDistribution {
        require(penetrates[account] != address(0), 'no reward');
        IPenetratePool(penetrates[account]).getReward();
        uint256 amount = earnToken.balanceOf(address(this));
        earnToken.transfer(to, amount);
        emit Claim(to, amount);
    }

    function burn(uint256 amount) external onlyRewardsDistribution {
        rewardAmount = 0;
        rewardsToken.burn(address(this), amount);
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event StakedPool(address indexed user, uint256 amount);
    event WithdrawnPool(address indexed user, uint256 amount);
    event Claim(address indexed to, uint256 amount);
}

contract LpStakingRewardsFactory is Ownable {
    address public rewardsToken;

    mapping(address => bool) public stakingRewards;

    constructor(
        address _rewardsToken
    ) Ownable() public {
        rewardsToken = _rewardsToken;
    }

    /**
     * stakingToken - lp token address
     * pool - bsc pool
     * earnToken - token earned from pool
     */
    function deploy(address stakingToken, address pool, uint256 poolId, address earnToken, uint256 startTime) public onlyOwner {
        require(startTime > 0, 'invalid start time');
        require(pool != address(0), 'invalid pool address');
        address stakingReward = address(new LpStakingRewards(/*_rewardsDistribution=*/ address(this), rewardsToken, stakingToken, pool, poolId, earnToken, startTime));
        stakingRewards[stakingReward] = true;
        emit Deploy(stakingToken, stakingReward);
    }

    function notifyRewardAmount(address stakingReward, uint256 rewardAmount) public onlyOwner {
        require(stakingRewards[stakingReward], 'not exist');
        LpStakingRewards(stakingReward).notifyRewardAmount(rewardAmount);
    }

    function setOperator(address stakingReward, address operator) public onlyOwner {
        require(stakingRewards[stakingReward], 'not exist');
        LpStakingRewards(stakingReward).setOperator(operator);
    }

    function setRewardAmount(address stakingReward, uint256 rewardAmount) public onlyOwner {
        require(stakingRewards[stakingReward], 'not exist');
        LpStakingRewards(stakingReward).setRewardAmount(rewardAmount);
    }

    function claim(address stakingReward, address to) public onlyOwner {
        require(stakingRewards[stakingReward], 'not exist');
        LpStakingRewards(stakingReward).claim(to);
    }

    function claimOf(address stakingReward, address account, address to) public onlyOwner {
        require(stakingRewards[stakingReward], 'not exist');
        LpStakingRewards(stakingReward).claimOf(account, to);
    }

    function burn(address stakingReward, uint256 amount) public onlyOwner {
        require(stakingRewards[stakingReward], 'not exist');
        LpStakingRewards(stakingReward).burn(amount);
    }

    event Deploy(address stakingToken, address stakingReward);
}