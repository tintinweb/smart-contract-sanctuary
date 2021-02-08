pragma solidity ^0.5.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

pragma solidity 0.5.15;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../libraries/Ownable.sol";


/**
 * @title BellaStaking
 * @dev stake btoken and get bella rewards, modified based on sushi swap's masterchef
 * delay rewards to get a boost:
 * dalay of: 0, 7, 15 and 30 days 
 */
contract BellaStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant NUM_TYPES = 4;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many btokens the user has provided.
        uint256 effectiveAmount; // amount*boost
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of BELLAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.effectiveAmount * pool.accBellaPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws btokens to a pool. Here's what happens:
        //   1. The pool's `accBellaPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` and `effectiveAmount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        uint256 earnedBella; // unclaimed bella
    }

    // bella under claiming
    struct ClaimingBella {
        uint256 amount;
        uint256 unlockTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 underlyingToken;   // Address of underlying token.
        uint256 allocPoint;       // How many allocation points assigned to this pool.
        uint256 lastRewardTime;  // Last block number that BELLAs distribution occurs.
        uint256 accBellaPerShare; // Accumulated BELLAs per share, times 1e12. See below.
        uint256 totalEffectiveAmount; // Sum of user's amount*boost
    }

    IERC20 public bella;

    PoolInfo[] public poolInfo;

    // 7, 15, 30 days delay boost, 3 digit = from 100% to 199%
    mapping (uint256 => uint256[3]) public boostInfo;  

    // Info of each user that stakes btokens.
    mapping (uint256 => mapping (address => UserInfo[NUM_TYPES])) public userInfos;

    // User's bella under claiming
    mapping (address => ClaimingBella[]) public claimingBellas;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The timestamp when BELLA mining starts.
    uint256 public startTime;
    // period to released currently locked bella rewards
    uint256 public currentUnlockCycle;
    // under current release cycle, the releasing speed per second
    uint256 public bellaPerSecond;
    // timestamp that current round of bella rewards ends
    uint256 public unlockEndTimestamp;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    modifier validPool(uint256 _pid) {
        require(_pid < poolInfo.length, "invalid pool id");
        _;
    }

    /**
    * @param _bella bella address
    * @param _startTime timestamp that starts reward distribution
    * @param governance governance address
    */
    constructor(
        IERC20 _bella,
        uint256 _startTime,
        address governance
    ) public Ownable(governance) {
        bella = _bella;
        startTime = _startTime;
    }

    /**
    * @return number of all the pools
    */
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    /**
    * @dev Add a new underlying token to the pool. Can only be called by the governance.
    * delay rewards to get a boost:
    * dalay of: 0, 7, 15 and 30 days 
    * @param _allocPoint weight of this pool
    * @param _underlyingToken underlying token address
    * @param boost boostInfo of this pool
    * @param _withUpdate if update all the pool informations
    */
    function add(uint256 _allocPoint, IERC20 _underlyingToken, uint256[3] memory boost, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        for (uint256 i=0; i<3; i++) {
            require((boost[i]>=100 && boost[i]<=200), "invalid boost");
        }

        uint256 lastRewardTime = now > startTime ? now : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        boostInfo[poolLength()] = boost;

        poolInfo.push(PoolInfo({
            underlyingToken: _underlyingToken,
            allocPoint: _allocPoint,
            lastRewardTime: lastRewardTime,
            accBellaPerShare: 0,
            totalEffectiveAmount: 0
        }));

    }

    /**
    * @dev Update the given pool's BELLA allocation point. Can only be called by the governance.
    * @param _pid id of the pool
    * @param _allocPoint weight of this pool
    */
    function set(uint256 _pid, uint256 _allocPoint) public validPool(_pid) onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @dev we will lock bella tokens on the begining every releasing cycle
     * @param amount the amount of bella token to lock
     * @param nextUnlockCycle next reward releasing cycle, unit=day
     */
    function lock(uint256 amount, uint256 nextUnlockCycle) external onlyOwner {
        massUpdatePools();

        currentUnlockCycle = nextUnlockCycle * 1 days;
        unlockEndTimestamp = now.add(currentUnlockCycle);
        bellaPerSecond = bella.balanceOf(address(this)).add(amount).div(currentUnlockCycle);
            
        require(
            bella.transferFrom(msg.sender, address(this), amount),
            "Additional bella transfer failed"
        );
    }

    /**
     * @dev user's total earned bella in all pools
     * @param _user user's address
     */
    function earnedBellaAllPool(address _user) external view returns  (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            sum = sum.add(earnedBellaAll(i, _user));
        }
        return sum;
    }

    /**
     * @dev user's total earned bella in a specific pool
     * @param _pid id of the pool
     * @param _user user's address
     */
    function earnedBellaAll(uint256 _pid, address _user) public view validPool(_pid) returns  (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < NUM_TYPES; i++) {
            sum = sum.add(earnedBella(_pid, _user, i));
        }
        return sum;
    }

    /**
     * @dev user's earned bella in a specific pool for a specific saving type
     * @param _pid id of the pool
     * @param _user user's address
     * @param savingType saving type
     */
    function earnedBella(uint256 _pid, address _user, uint256 savingType) public view validPool(_pid) returns (uint256) {
        require(savingType < NUM_TYPES, "invalid savingType");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfos[_pid][_user][savingType];
        uint256 accBellaPerShare = pool.accBellaPerShare;
        if (now > pool.lastRewardTime && pool.totalEffectiveAmount != 0 && pool.lastRewardTime != unlockEndTimestamp) {
            uint256 delta = now > unlockEndTimestamp ? unlockEndTimestamp.sub(pool.lastRewardTime) : now.sub(pool.lastRewardTime);
            uint256 bellaReward = bellaPerSecond.mul(delta).mul(pool.allocPoint).div(totalAllocPoint);
            accBellaPerShare = accBellaPerShare.add(bellaReward.mul(1e12).div(pool.totalEffectiveAmount));
        }
        return user.effectiveAmount.mul(accBellaPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @dev Update reward variables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     * @param _pid id of the pool
     */
    function updatePool(uint256 _pid) public validPool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (now <= pool.lastRewardTime || unlockEndTimestamp == pool.lastRewardTime) {
            return;
        }
        if (pool.totalEffectiveAmount == 0) {
            pool.lastRewardTime = now;
            return;
        }
        uint256 accBellaPerShare = pool.accBellaPerShare;

        // now > pool.lastRewardTime && pool.totalEffectiveAmount != 0
        if (now > unlockEndTimestamp) {
            uint256 delta = unlockEndTimestamp.sub(pool.lastRewardTime);
            uint256 bellaReward = bellaPerSecond.mul(delta).mul(pool.allocPoint).div(totalAllocPoint);
            pool.accBellaPerShare = accBellaPerShare.add(bellaReward.mul(1e12).div(pool.totalEffectiveAmount));

            pool.lastRewardTime = unlockEndTimestamp;
        } else {
            uint256 delta = now.sub(pool.lastRewardTime);
            uint256 bellaReward = bellaPerSecond.mul(delta).mul(pool.allocPoint).div(totalAllocPoint);
            pool.accBellaPerShare = accBellaPerShare.add(bellaReward.mul(1e12).div(pool.totalEffectiveAmount));

            pool.lastRewardTime = now;
        }

    }

    /**
     * @dev Deposit underlying token for bella allocation
     * @param _pid id of the pool
     * @param _amount amount of underlying token to deposit
     * @param savingType saving type
     */
    function deposit(uint256 _pid, uint256 _amount, uint256 savingType) public validPool(_pid) nonReentrant {
        require(savingType < NUM_TYPES, "invalid savingType");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfos[_pid][msg.sender][savingType];
        updatePool(_pid);
        if (user.effectiveAmount > 0) {
            uint256 pending = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                user.earnedBella = user.earnedBella.add(pending);
            }
        }
        if(_amount > 0) {
            pool.underlyingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            uint256 effectiveAmount = toEffectiveAmount(_pid, _amount, savingType);
            user.effectiveAmount = user.effectiveAmount.add(effectiveAmount);
            pool.totalEffectiveAmount = pool.totalEffectiveAmount.add(effectiveAmount);
        }
        user.rewardDebt = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12); /// 初始的奖励为0
        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw underlying token
     * @param _pid id of the pool
     * @param _amount amount of underlying token to withdraw
     * @param savingType saving type
     */
    function withdraw(uint256 _pid, uint256 _amount, uint256 savingType) public validPool(_pid) nonReentrant {
        require(savingType < NUM_TYPES, "invalid savingType");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfos[_pid][msg.sender][savingType];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            user.earnedBella = user.earnedBella.add(pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            uint256 effectiveAmount = toEffectiveAmount(_pid, _amount, savingType);

            /// round errors?
            pool.totalEffectiveAmount = pool.totalEffectiveAmount.sub(effectiveAmount);
            user.effectiveAmount = toEffectiveAmount(_pid, user.amount, savingType);

            pool.underlyingToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @dev Withdraw all underlying token in one pool
     * @param _pid id of the pool
     */
    function withdrawAll(uint256 _pid) public validPool(_pid) {
        for (uint256 i=0; i<NUM_TYPES; i++) {
            uint256 amount = userInfos[_pid][msg.sender][i].amount;
            if (amount != 0) {
                withdraw(_pid, amount, i);
            }
        }
    }

    /**
     * @dev Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param _pid id of the pool
     * @param savingType saving type
     */
    function emergencyWithdraw(uint256 _pid, uint256 savingType) public validPool(_pid) nonReentrant {
        require(savingType < NUM_TYPES, "invalid savingType");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfos[_pid][msg.sender][savingType];
        uint256 amount = user.amount;

        pool.totalEffectiveAmount = pool.totalEffectiveAmount.sub(user.effectiveAmount);
        user.amount = 0;
        user.effectiveAmount = 0;
        user.rewardDebt = 0;
        user.earnedBella = 0;

        pool.underlyingToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);

    }

    /**
     * @dev claim earned bella to collect for a specific saving type
     * @param _pid id of the pool
     * @param savingType saving type
     */
    function claimBella(uint256 _pid, uint256 savingType) public {
        require(savingType < NUM_TYPES, "invalid savingType");
        UserInfo storage user = userInfos[_pid][msg.sender][savingType];

        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];

        uint256 pending = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            user.earnedBella = user.earnedBella.add(pending);
        }
        user.rewardDebt = user.effectiveAmount.mul(pool.accBellaPerShare).div(1e12);

        uint256 delay = getDelayFromType(savingType);

        if (delay == 0) {
            uint256 amount = user.earnedBella;
            user.earnedBella = 0;
            safeBellaTransfer(msg.sender, amount);
        } else {
            uint256 amount = user.earnedBella;
            user.earnedBella = 0;
            ClaimingBella[] storage claimingBella = claimingBellas[msg.sender];
            claimingBella.push(ClaimingBella({amount: amount, unlockTime: now.add(delay * 1 days)}));       
        }
    }

    /**
     * @dev claim all earned bella to collect
     * @param _pid id of the pool
     */
    function claimAllBella(uint256 _pid) public validPool(_pid) {
        for (uint256 i=0; i<NUM_TYPES; i++) {
            claimBella(_pid, i);
        }
    }

    /**
     * @dev collect claimed bella (instant and delayed)
     */
    function collectBella() public {
        uint256 sum = 0;
        ClaimingBella[] storage claimingBella = claimingBellas[msg.sender];
        for (uint256 i = 0; i < claimingBella.length; i++) {
            ClaimingBella storage claim = claimingBella[i];
            if (claimingBella[i].amount !=0 && claimingBella[i].unlockTime <= now) {
                sum = sum.add(claim.amount);
                delete claimingBella[i];
            }
        }
        safeBellaTransfer(msg.sender, sum);

        // clean array if len > 15 and have more than 4 zeros
        if (claimingBella.length > 15) {
            uint256 zeros = 0;
            for (uint256 i=0; i < claimingBella.length; i++) {
                if (claimingBella[i].amount == 0) {
                    zeros++;
                }
            }
            if (zeros < 5)
                return;

            uint256 i = 0;
            while (i < claimingBella.length) {
                if (claimingBella[i].amount == 0) {
                    claimingBella[i].amount = claimingBella[claimingBella.length-1].amount;
                    claimingBella[i].unlockTime = claimingBella[claimingBella.length-1].unlockTime;
                    claimingBella.pop();
                } else {
                    i++;
                }
            }         
        }
    }

    /**
     * @dev Get user's total staked btoken in on pool
     * @param _pid id of the pool
     * @param user user address
     */
    function getBtokenStaked(uint256 _pid, address user) external view validPool(_pid) returns (uint256) {
        uint256 sum = 0;
        for (uint256 i=0; i<NUM_TYPES; i++) {
           sum = sum.add(userInfos[_pid][user][i].amount);
        }
        return sum;
    }

    /**
     * @dev view function to see user's collectiable bella
     */
    function collectiableBella() external view returns (uint256) {
        uint256 sum = 0;
        ClaimingBella[] memory claimingBella = claimingBellas[msg.sender];
        for (uint256 i = 0; i < claimingBella.length; i++) {
            ClaimingBella memory claim = claimingBella[i];
            if (claim.amount !=0 && claim.unlockTime <= now) {
                sum = sum.add(claim.amount);
            }
        }
        return sum;
    }

    /**
     * @dev view function to see user's delayed bella
     */
    function delayedBella() external view returns (uint256) {
        uint256 sum = 0;
        ClaimingBella[] memory claimingBella = claimingBellas[msg.sender];
        for (uint256 i = 0; i < claimingBella.length; i++) {
            ClaimingBella memory claim = claimingBella[i];
            if (claim.amount !=0 && claim.unlockTime > now) {
                sum = sum.add(claim.amount);
            }
        }
        return sum;
    }

    /**
     * @dev view function to check boost*amount of each saving type 
     * @param pid id of the pool
     * @param amount amount of underlying token
     * @param savingType saving type
     * @return boost*amount
     */
    function toEffectiveAmount(uint256 pid, uint256 amount, uint256 savingType) internal view returns (uint256) {

        if (savingType == 0) {
            return amount;
        } else if (savingType == 1) {
            return amount * boostInfo[pid][0] / 100;
        } else if (savingType == 2) {
            return amount * boostInfo[pid][1] / 100;
        } else if (savingType == 3) {
            return amount * boostInfo[pid][2] / 100;
        } else {
            revert("toEffectiveAmount: invalid savingType");
        }
    }

    /**
     * @dev pure function to check delay of each saving type 
     * @param savingType saving type
     * @return delay of the input saving type
     */
    function getDelayFromType(uint256 savingType) internal pure returns (uint256) {
        if (savingType == 0) {
            return 0;
        } else if (savingType == 1) {
            return 7;
        } else if (savingType == 2) {
            return 15;
        } else if (savingType == 3) {
            return 30;
        } else {
            revert("getDelayFromType: invalid savingType");
        }
    }

    /**
     * @dev Safe bella transfer function, just in case if rounding error causes pool to not have enough BELLAs.
     * @param _to Target address to send bella
     * @param _amount Amount of bella to send
     */
    function safeBellaTransfer(address _to, uint256 _amount) internal {
        uint256 bellaBal = bella.balanceOf(address(this));
        if (_amount > bellaBal) {
            bella.transfer(_to, bellaBal);
        } else {
            bella.transfer(_to, _amount);
        }
    }

}

pragma solidity 0.5.15;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the a
     * specified account.
     * @param initalOwner The address of the inital owner.
     */
    constructor(address initalOwner) internal {
        _owner = initalOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Only owner can call");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Owner should not be 0 address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}