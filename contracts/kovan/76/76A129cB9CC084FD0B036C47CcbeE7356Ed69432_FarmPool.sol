/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




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

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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

// File: contracts/interfaces/IXHalfLife.sol

pragma solidity 0.5.17;

interface IXHalfLife {
    function createStream(
        address token,
        address recipient,
        uint256 depositAmount,
        uint256 startBlock,
        uint256 kBlock,
        uint256 unlockRatio,
        bool cancelable
    ) external returns (uint256);

    function createEtherStream(
        address recipient,
        uint256 startBlock,
        uint256 kBlock,
        uint256 unlockRatio,
        bool cancelable
    ) external payable returns (uint256);

    function hasStream(uint256 streamId) external view returns (bool);

    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            address token,
            uint256 depositAmount,
            uint256 startBlock,
            uint256 kBlock,
            uint256 remaining,
            uint256 withdrawable,
            uint256 unlockRatio,
            uint256 lastRewardBlock,
            bool cancelable
        );

    function balanceOf(uint256 streamId)
        external
        view
        returns (uint256 withdrawable, uint256 remaining);

    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        returns (bool);

    function cancelStream(uint256 streamId) external returns (bool);

    function singleFundStream(uint256 streamId, uint256 amount)
        external
        payable
        returns (bool);

    function lazyFundStream(
        uint256 streamId,
        uint256 amount,
        uint256 blockHeightDiff
    ) external payable returns (bool);

    function getVersion() external pure returns (bytes32);
}

// File: contracts/interfaces/IFarmRegister.sol

pragma solidity 0.5.17;

contract IFarmRegister {
    function xdex() external view returns (address);

    function xProxy() external view returns (address);

    function halflife() external view returns (address);

    function farmFactory() external view returns (address);

    function farmPool() external view returns (address);
}

// File: contracts/FarmPool.sol

pragma solidity 0.5.17;








contract FarmPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant MAX = 2**256 - 1;

    /* ========== STATE VARIABLES ========== */
    struct FarmPoolInfo {
        IERC20 rewardsToken;
        IERC20 stakingToken;
        uint256 rewardsTokenPrecision;
        address creater;
        // farm pool configs
        uint256 startBlock;
        uint256 endBlock;
        uint256 rewardsDuration; // duration = start - block
        uint256 rewardRatio;
        uint256 lastUpdateBlockNumber;
        uint256 rewardPerTokenStored;
        uint256 totalSupply;
        // halflife configs
        uint256 unlockRatio;
        uint256 halflifeK;
        uint256 halflifeRatio;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
        mapping(address => uint256) balances;
    }

    address public register;
    IXHalfLife public halflife;

    uint256 public nextPoolId = 1;

    // key: farm pool id
    mapping(uint256 => FarmPoolInfo) private pools;

    // key: farm pool id
    mapping(uint256 => mapping(address => uint256)) private rewardStream;

    /* ========== EVENTS ========== */
    event LogCreatFarmPool(uint256 indexed poolId, address indexed creator);
    event LogRewardAdded(uint256 indexed poolId, uint256 reward);
    event LogStaked(
        uint256 indexed poolId,
        address indexed user,
        uint256 amount
    );
    event LogWithdrawn(
        uint256 indexed poolId,
        address indexed user,
        uint256 amount
    );
    event LogRewardPaid(
        uint256 indexed poolId,
        address indexed user,
        uint256 reward
    );
    event LogRewardToStream(
        uint256 indexed poolId,
        address indexed user,
        uint256 indexed streamId,
        uint256 reward
    );

    /* ========== CONSTRUCTOR ========== */
    constructor(address _register) public {
        require(_register != address(0), "ERR_ZERO_ADDR");
        register = _register;

        halflife = IXHalfLife(IFarmRegister(register).halflife());
        require(address(halflife) != address(0), "ERR_ZERO_ADDR");
    }

    /* ========== MODIFIERS ========== */
    modifier onlyFactory() {
        require(
            msg.sender == IFarmRegister(register).farmFactory(),
            "ERR_NOT_FACTORY"
        );
        _;
    }

    modifier updateReward(uint256 poolId, address account) {
        require(poolId > 0 && poolId < nextPoolId, "ERR_POOL_NOT_EXIST");
        FarmPoolInfo storage pool = pools[poolId];

        pool.rewardPerTokenStored = rewardPerToken(poolId);
        pool.lastUpdateBlockNumber = lastTimeRewardApplicable(poolId);
        if (account != address(0)) {
            pool.rewards[account] = earned(poolId, account);
            pool.userRewardPerTokenPaid[account] = pool.rewardPerTokenStored;
        }
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 poolId, uint256 amount)
        public
        nonReentrant
        updateReward(poolId, msg.sender)
    {
        require(poolId > 0 && poolId < nextPoolId, "ERR_POOL_NOT_EXIST");
        require(block.number < pools[poolId].endBlock, "ERR_FARM_FINISHED");
        require(amount > 0, "ERR_STAKE_0");

        FarmPoolInfo storage pool = pools[poolId];

        pool.totalSupply = pool.totalSupply.add(amount);
        pool.balances[msg.sender] = pool.balances[msg.sender].add(amount);
        pool.stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit LogStaked(poolId, msg.sender, amount);
    }

    function withdraw(uint256 poolId, uint256 amount)
        public
        nonReentrant
        updateReward(poolId, msg.sender)
    {
        require(poolId > 0 && poolId < nextPoolId, "ERR_POOL_NOT_EXIST");
        require(amount > 0, "ERR_WITHDRAW_0");

        FarmPoolInfo storage pool = pools[poolId];
        require(amount <= pool.totalSupply, "amount should <= totalSupply");
        require(
            amount <= pool.balances[msg.sender],
            "amount should <= self amount"
        );

        //lock 3 monthes if user is creator
        if (pool.creater == msg.sender) {
            if (block.number < pool.startBlock + 5760 * 30 * 3) {
                require(pool.balances[msg.sender].sub(amount) >= 100 * 10**18);
            }
        }

        pool.totalSupply = pool.totalSupply.sub(amount);
        pool.balances[msg.sender] = pool.balances[msg.sender].sub(amount);
        pool.stakingToken.safeTransfer(msg.sender, amount);

        emit LogWithdrawn(poolId, msg.sender, amount);
    }

    function getReward(uint256 poolId)
        public
        nonReentrant
        updateReward(poolId, msg.sender)
    {
        require(poolId > 0 && poolId < nextPoolId, "ERR_POOL_NOT_EXIST");

        FarmPoolInfo storage pool = pools[poolId];
        uint256 reward = pool.rewards[msg.sender];
        if (reward > 0) {
            pool.rewards[msg.sender] = 0;

            uint256 unlockReward = reward.mul(pool.unlockRatio).div(100);
            pool.rewardsToken.safeTransfer(msg.sender, unlockReward);
            _rewardsToStream(poolId, msg.sender, reward.sub(unlockReward));

            emit LogRewardPaid(poolId, msg.sender, unlockReward);
        }
    }

    function exit(uint256 poolId) public {
        withdraw(poolId, pools[poolId].balances[msg.sender]);
        getReward(poolId);
    }

    // create farm pool
    function createPool(
        address _rewardToken,
        address _stakeToken,
        uint256 _startBlock,
        uint256 _rewardsDuration,
        uint256 _rewardRatio,
        uint256 _lockRatio,
        uint256 _halflifeK,
        uint256 _halflifeRatio,
        address _creator
    ) external onlyFactory returns (uint256 poolId) {
        require(_rewardToken != address(0), "ERR_INVALID_REWARD_TOKEN");

        require(_startBlock > block.number, "ERR_INVALID_START_BLOCK");
        require(_rewardsDuration > 0, "ERR_INVALID_DURATION");
        // check _rewardRatio
        // check _lockRatio
        require(_halflifeK > 0, "ERR_INVALID_HALFLIFE_K");
        require(_halflifeRatio < 1000, "ERR_INVALID_HALFLIFE_R");
        require(_halflifeRatio > 0, "ERR_INVALID_HALFLIFE_R");
        require(_creator != address(0), "ERR_ZERO_ADDRESS");

        uint256 totalRewards = _rewardRatio.mul(_rewardsDuration);
        IERC20(_rewardToken).safeTransferFrom(
            _creator,
            address(this),
            totalRewards
        );

        // create open farm pool
        FarmPoolInfo memory pool =
            FarmPoolInfo(
                IERC20(_rewardToken),
                IERC20(_stakeToken),
                uint256(10)**ERC20Detailed(_rewardToken).decimals(),
                _creator,
                _startBlock,
                _startBlock.add(_rewardsDuration),
                _rewardsDuration,
                _rewardRatio,
                _startBlock,
                0,
                0,
                _lockRatio,
                _halflifeK,
                _halflifeRatio
            );

        // add pool
        poolId = nextPoolId;
        nextPoolId = nextPoolId.add(1);

        pools[poolId] = pool;

        emit LogCreatFarmPool(poolId, _creator);

        // stake(poolId,100*10**18);
        FarmPoolInfo storage poolR = pools[poolId];
        poolR.totalSupply = poolR.totalSupply.add(100 * 10**18);
        poolR.balances[_creator] = 100 * 10**18;
        // poolR.stakingToken.safeTransferFrom(msg.sender, address(this), 100*10**18);

        emit LogStaked(poolId, _creator, 100 * 10**18);
    }

    /* ========== VIEWS ========== */
    function totalSupply(uint256 poolId) public view returns (uint256) {
        return pools[poolId].totalSupply;
    }

    function balanceOf(uint256 poolId, address account)
        public
        view
        returns (uint256)
    {
        return pools[poolId].balances[account];
    }

    function lastTimeRewardApplicable(uint256 poolId)
        public
        view
        returns (uint256)
    {
        return
            Math.max(
                Math.min(block.number, pools[poolId].endBlock),
                pools[poolId].startBlock
            );
    }

    function rewardPerToken(uint256 poolId) public view returns (uint256) {
        FarmPoolInfo memory pool = pools[poolId];

        if (block.number <= pool.startBlock) {
            return 0;
        }

        if (pool.totalSupply == 0) {
            return pool.rewardPerTokenStored;
        }

        return
            pool.rewardPerTokenStored.add(
                lastTimeRewardApplicable(poolId)
                    .sub(pool.lastUpdateBlockNumber)
                    .mul(pool.rewardRatio)
                    .mul(pool.rewardsTokenPrecision)
                    .div(pool.totalSupply)
            );
    }

    function earned(uint256 poolId, address account)
        public
        view
        returns (uint256)
    {
        FarmPoolInfo storage pool = pools[poolId];
        return
            pool.balances[account]
                .mul(
                rewardPerToken(poolId).sub(pool.userRewardPerTokenPaid[account])
            )
                .div(1e18)
                .add(pool.rewards[account]);
    }

    function getPoolInfo(uint256 poolId)
        public
        view
        returns (
            address rewardsToken,
            address stakingToken,
            address poolCreater,
            uint256 startBlock,
            uint256 rewardsDuration,
            uint256 rewardRatio,
            uint256 unlockRatio,
            uint256 halflifeK,
            uint256 halflifeRatio
        )
    {
        FarmPoolInfo memory pool = pools[poolId];
        rewardsToken = address(pool.rewardsToken);
        stakingToken = address(pool.stakingToken);
        poolCreater = pool.creater;
        startBlock = pool.startBlock;
        rewardsDuration = pool.rewardsDuration;
        rewardRatio = pool.rewardRatio;
        unlockRatio = pool.unlockRatio;
        halflifeK = pool.halflifeK;
        halflifeRatio = pool.halflifeRatio;
    }

    function _rewardsToStream(
        uint256 poolId,
        address account,
        uint256 amount
    ) internal {
        FarmPoolInfo memory pool = pools[poolId];
        IERC20 token = pool.rewardsToken;

        if (token.allowance(address(this), address(halflife)) < amount) {
            token.safeApprove(address(halflife), 0);
            token.safeApprove(address(halflife), MAX);
        }

        uint256 streamId = rewardStream[poolId][account];
        if (streamId == 0 || !halflife.hasStream(streamId)) {
            streamId = halflife.createStream(
                address(token),
                account,
                amount,
                block.number + 1,
                pool.halflifeK,
                pool.halflifeRatio,
                false
            );
            rewardStream[poolId][account] = streamId;
        } else {
            //TODO: should be lazyFund?
            halflife.singleFundStream(streamId, amount);
        }

        emit LogRewardToStream(poolId, account, streamId, amount);
    }
}