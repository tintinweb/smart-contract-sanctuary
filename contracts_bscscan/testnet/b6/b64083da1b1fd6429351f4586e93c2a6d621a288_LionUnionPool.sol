/**
 *Submitted for verification at BscScan.com on 2021-11-07
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-23
*/

// File: @openzeppelin/contracts/math/Math.sol

pragma solidity 0.5.16;

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

pragma solidity 0.5.16;

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

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity 0.5.16;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity 0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _factory;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FactoryTransferred(address indexed previousFactory, address indexed newFactory);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        _factory = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function factory() public view returns (address) {
        return _factory;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyFactory() {
        require(isFactory(), "Ownable: caller is not the factory");
        _;
    }

    modifier onlyFactoryOrOwner() {
        require(isFactory() || isOwner(), "Ownable: caller is not the factory");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function isFactory() public view returns (bool) {
        return _msgSender() == _factory;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function renounceFactory() public onlyFactory {
        emit FactoryTransferred(_owner, address(0));
        _factory = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function setOwnerOnce(address newOwner) public onlyFactory {
        _owner = newOwner;
    }

    function setFactory(address newFactory) public onlyOwner {
        _factory = newFactory;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity 0.5.16;

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
    function mint(address account, uint amount) external;

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

pragma solidity 0.5.16;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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

pragma solidity 0.5.16;




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


/**
 * Reward Amount Interface
 */
pragma solidity 0.5.16;

contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(address _stakeToken, uint256 _startTime, uint256 _duration, uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyFactoryOrOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

/**
 * Staking Token Wrapper
 */
pragma solidity 0.5.16;

contract FrogTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakeToken = IERC20(0x0);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount, bool transfer) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        if(transfer) stakeToken.safeTransfer(msg.sender, amount);
    }
}

pragma solidity 0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IStats {
    function incrIIStats(uint256 k, uint256 v) external returns (uint256);
    function decrIIStats(uint256 k, uint256 v) external returns (uint256);
    function incrAIStats(address k, uint256 v) external returns (uint256);
    function decrAIStats(address k, uint256 v) external returns (uint256);
    function incrAIIStats(address addr, uint256 k, uint256 v) external returns (uint256);
    function decrAIIStats(address addr, uint256 k, uint256 v) external returns (uint256);
    function incrAAIStats(address addr0, address addr1, uint256 v) external returns (uint256);
    function decrAAIStats(address addr0, address addr1, uint256 v) external returns (uint256);
    function incrIAIStats(uint256 k, address addr1, uint256 v) external returns (uint256);
    function decrIAIStats(uint256 k, address addr1, uint256 v) external returns (uint256);
    function setIAAStats(uint256 k, address addr1, address addr2) external returns (address);
    function getIIStats(uint256 k) external view returns (uint256);
    function getAIStats(address addr) external view returns (uint256);
    function getAAIStats(address addr0, address addr1) external view returns (uint256);
    function getAIIStats(address addr, uint256 k) external view returns (uint256);
    function getIAIStats(uint256 k, address addr) external view returns (uint256);
    function getIAAStats(uint256 k, address addr) external view returns (address);
    function addMinter(address _minter) external;
    function removeMinter(address _minter) external;
}

contract LionUnionPool is FrogTokenWrapper, IRewardDistributionRecipient {
    IERC20 public frog = IERC20(0x4fEe21439F2b95b72da2F9f901b3956f27fE91D5);
    IStats public stats = IStats(0xFbDeb2f79d890cebA6E6DF5067E6B248c872D053);
    address public devPool = address(0x96eD0b21d024b82A430386A3A1477324f25f0143);
    address public rewardPool = address(0xC81acf050fa511FBA998b394a6087c569d3D103A);
    bool private open = true;
    bool private emergency = false;
    bool private enableInvite = false;
    
    uint256 public totalSupplyWrapper = 0;
    mapping(address => uint256) public balancesWrapper;
    mapping(address => uint256) public accumulateStake;
    mapping(address => uint256) public accumulateWithdraw;
    uint256 public stakeBurn = 0;
    uint256 public feeStake = 0;
    uint256 public feeWithdraw = 0;
    uint256 public feePunish = 0;
    uint256 public firstMinStakeValue = 0;
    uint256 public minStakeValue = 0;
    uint256 private constant _gunit = 1e18;

    uint256 public constant STATS_TYPE_REWARD_BURN = 1;
    uint256 public constant STATS_TYPE_REWARD_FEE = 2;
    uint256 public constant STATS_TYPE_REWARD_PUNISH = 3;
    uint256 public constant STATS_TYPE_REWARD_TOTAL = 4;

    uint256 public constant STATS_TYPE_INVITE_RELATION = 5;
    uint256 public constant STATS_TYPE_INVITE_1ST_COUNT = 6;
    uint256 public constant STATS_TYPE_INVITE_2ND_COUNT = 7;
    uint256 public constant STATS_TYPE_INVITE_1ST_REWARD_AMOUNT = 8;
    uint256 public constant STATS_TYPE_INVITE_2ND_REWARD_AMOUNT = 9;
    uint256 public constant STATS_TYPE_INVITE_ZERO_REWARD_AMOUNT = 10;
    uint256 public constant STATS_TYPE_INVITE_1ST_TOTAL_REWARD = 11;
    uint256 public constant STATS_TYPE_INVITE_2ND_TOTAL_REWARD = 12;
    uint256 public constant STATS_TYPE_INVITE_ZERO_TOTAL_REWARD = 13;
    uint256 public constant STATS_TYPE_INVITE_1ST_TODAY_REWARD = 14 * 10 ** 18;
    uint256 public constant STATS_TYPE_INVITE_2ND_TODAY_REWARD = 15 * 10 ** 18;
    uint256 public constant STATS_TYPE_INVITE_ZERO_TODAY_REWARD = 16 * 10 ** 18;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each pool.
    struct PoolInfo {
        uint256 totalSupply;
        mapping(address => uint256) balances;
        uint256 DURATION;
        uint256 startTime;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 maxReward;
        uint256 claimedReward;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards; // Unclaimed rewards
        mapping(address => uint256) claimedRewards; // claimed rewards
        mapping(address => uint256) punishedFees;
        mapping(address => uint256) accumulateStake;
        mapping(address => uint256) accumulateWithdraw;
    }

    event RewardAdded(uint256 reward);
    event FeeUpdated(uint256 fee1, uint256 fee2, uint256 fee3, uint256 fee4);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event PunishedFeePaid(address indexed user, uint256 reward);
    event SetOpen(bool _open);
    event SetEmergency(bool _emergency);

    constructor() public {
        frog = IERC20(0x4fEe21439F2b95b72da2F9f901b3956f27fE91D5);
        stats = IStats(0xFbDeb2f79d890cebA6E6DF5067E6B248c872D053);
        stakeToken = IERC20(0xB70835D7822eBB9426B56543E391846C107bd32C);
    }

    function initialize(IERC20 _frogToken, address _stakeToken, IStats _stats) external onlyFactoryOrOwner{
        frog = IERC20(_frogToken);
        stakeToken = IERC20(_stakeToken);
        stats = _stats;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function balanceOfByPID(uint256 _pid, address account) public view returns (uint256) {
        return poolInfo[_pid].balances[account];
    }

    function totalSupplyByPID(uint256 _pid) public view returns (uint256) {
        return poolInfo[_pid].totalSupply;
    }

    function getPoolInfoByPID(uint256 _pid) public view returns (uint256,uint256,uint256,uint256) {
        return (poolInfo[_pid].startTime, poolInfo[_pid].periodFinish, poolInfo[_pid].maxReward, poolInfo[_pid].claimedReward);
    }

    function getUserClaimedRewardByPID(uint256 _pid, address account) public view returns (uint256) {
        return poolInfo[_pid].claimedRewards[account];
    }

    function getUserAccumulateStakeByPID(uint256 _pid, address account) public view returns (uint256) {
        return poolInfo[_pid].accumulateStake[account];
    }

    function getUserAccumulateWithdrawByPID(uint256 _pid, address account) public view returns (uint256) {
        return poolInfo[_pid].accumulateWithdraw[account];
    }

    function lastTimeRewardApplicableByPID(uint256 _pid) public view returns (uint256) {
        return Math.min(block.timestamp, poolInfo[_pid].periodFinish);
    }

    /**
     * Calculate the rewards for each token
     */
    function rewardPerTokenByPID(uint256 _pid) public view returns (uint256) {
        if (totalSupplyByPID(_pid) == 0) {
            return poolInfo[_pid].rewardPerTokenStored;
        }
        return
            poolInfo[_pid].rewardPerTokenStored.add(
                lastTimeRewardApplicableByPID(_pid)
                    .sub(poolInfo[_pid].lastUpdateTime)
                    .mul(poolInfo[_pid].rewardRate)
                    .mul(_gunit)
                    .div(totalSupplyByPID(_pid))
            );
    }

    function earnedByPID(uint256 _pid, address account) public view returns (uint256) {
        return
            balanceOfByPID(_pid, account)
                .mul(rewardPerTokenByPID(_pid).sub(poolInfo[_pid].userRewardPerTokenPaid[account]))
                .div(_gunit)
                .add(poolInfo[_pid].rewards[account]);
    }

    function stakeByPID(uint256 _pid, uint256 amount, address invitedBy) public checkOpen checkStartByPID(_pid) checkNotEndByPID(_pid) checkStakeToken updateRewardByPID(_pid, msg.sender){
        // if(accumulateStake[msg.sender] > 0){
        setInvitedBy(invitedBy);
        if(firstMinStakeValue > 0 && poolInfo[_pid].accumulateStake[msg.sender] == 0){
            require(amount >= firstMinStakeValue, "FROG-POOL: Cannot stake 0");
        } else{
            require(amount > 0 && amount >= minStakeValue, "FROG-POOL: Cannot stake lower than min stake value");
        }
        poolInfo[_pid].totalSupply = poolInfo[_pid].totalSupply.add(amount);
        poolInfo[_pid].balances[msg.sender] = poolInfo[_pid].balances[msg.sender].add(amount);
        totalSupplyWrapper = totalSupplyWrapper.add(amount);
        balancesWrapper[msg.sender] = balancesWrapper[msg.sender].add(amount);
        accumulateStake[msg.sender] = accumulateStake[msg.sender].add(amount);
        poolInfo[_pid].accumulateStake[msg.sender] = poolInfo[_pid].accumulateStake[msg.sender].add(amount);
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        if(feeStake > 0){
            frog.safeTransferFrom(msg.sender, rewardPool, feeStake);
            stats.incrIAIStats(STATS_TYPE_REWARD_FEE, address(frog), feeStake);
            stats.incrIAIStats(STATS_TYPE_REWARD_TOTAL, address(frog), feeStake);
        }
        if(stakeBurn > 0){
            stakeToken.safeTransfer(rewardPool, amount);
            stats.incrIAIStats(STATS_TYPE_REWARD_BURN, address(stakeToken), amount);
            stats.incrIAIStats(STATS_TYPE_REWARD_TOTAL, address(stakeToken), amount);
        }
        emit Staked(msg.sender, amount);
    }

    function withdrawByPID(uint256 _pid, uint256 amount, address invitedBy) external{
        require(amount > 0, "FROG-POOL: Cannot withdraw 0");
        require(feePunish == 0, "FROG-POOL: FeePunish > 0");
        if(feeWithdraw > 0){
            frog.safeTransferFrom(msg.sender, rewardPool, feeWithdraw);
            stats.incrIAIStats(STATS_TYPE_REWARD_FEE, address(frog), feeWithdraw);
            stats.incrIAIStats(STATS_TYPE_REWARD_TOTAL, address(frog), feeWithdraw);
        }
        withdrawStakeTokenByPID(_pid, amount, invitedBy);
    }

    function withdrawStakeTokenByPID(uint256 _pid, uint256 amount, address invitedBy) internal checkOpen checkStakeToken checkStartByPID(_pid) updateRewardByPID(_pid, msg.sender){
        require(amount > 0, "FROG-POOL: Cannot withdraw 0");
        setInvitedBy(invitedBy);
        poolInfo[_pid].totalSupply = poolInfo[_pid].totalSupply.sub(amount);
        poolInfo[_pid].balances[msg.sender] = poolInfo[_pid].balances[msg.sender].sub(amount);
        totalSupplyWrapper = totalSupplyWrapper.sub(amount);
        balancesWrapper[msg.sender] = balancesWrapper[msg.sender].sub(amount);
        accumulateWithdraw[msg.sender] = accumulateWithdraw[msg.sender].add(amount);
        poolInfo[_pid].accumulateWithdraw[msg.sender] = poolInfo[_pid].accumulateWithdraw[msg.sender].add(amount);
        if(stakeBurn == 0){
            stakeToken.safeTransfer(msg.sender, amount);
        }
        emit Withdrawn(msg.sender, amount);
    }

    function getRewardByPID(uint256 _pid, address invitedBy) public checkOpen checkStakeToken checkStartByPID(_pid) updateRewardByPID(_pid, msg.sender){
        setInvitedBy(invitedBy);
        if(feeWithdraw > 0){
            frog.safeTransferFrom(msg.sender, rewardPool, feeWithdraw);
            stats.incrIAIStats(STATS_TYPE_REWARD_FEE, address(frog), feeWithdraw);
            stats.incrIAIStats(STATS_TYPE_REWARD_TOTAL, address(frog), feeWithdraw);
        }
        uint256 reward = earnedByPID(_pid, msg.sender);
        uint256 userClaimedReward = poolInfo[_pid].claimedRewards[msg.sender];
        if (reward > 0 && poolInfo[_pid].claimedReward.add(reward) <= poolInfo[_pid].maxReward) {
            poolInfo[_pid].rewards[msg.sender] = 0;
            poolInfo[_pid].claimedReward = poolInfo[_pid].claimedReward.add(reward);
            frog.safeTransfer(msg.sender, reward);
            poolInfo[_pid].claimedRewards[msg.sender] = userClaimedReward.add(reward);
            emit RewardPaid(msg.sender, reward);
            handleInviteReward(msg.sender, reward);
        }
    }

    function exitByPID(uint256 _pid, address invitedBy) external{
        withdrawStakeTokenByPID(_pid, balanceOfByPID(_pid, msg.sender), invitedBy);
        getRewardByPID(_pid, invitedBy);
        if(block.timestamp < poolInfo[_pid].periodFinish && feePunish > 0){
            uint256 userClaimedReward = poolInfo[_pid].claimedRewards[msg.sender];
            uint256 needFrogFee = userClaimedReward.mul(feePunish+100).div(100);
            if(needFrogFee > poolInfo[_pid].punishedFees[msg.sender]){
                needFrogFee = needFrogFee.sub(poolInfo[_pid].punishedFees[msg.sender]);
                frog.safeTransferFrom(msg.sender, rewardPool, needFrogFee);
                poolInfo[_pid].punishedFees[msg.sender] = poolInfo[_pid].punishedFees[msg.sender].add(needFrogFee);
                emit PunishedFeePaid(msg.sender, needFrogFee);
                stats.incrIAIStats(STATS_TYPE_REWARD_PUNISH, address(frog), needFrogFee);
                stats.incrIAIStats(STATS_TYPE_REWARD_TOTAL, address(frog), needFrogFee);
            }
        }
    }

    function configFeeEdit(uint256 _stakeBurn, uint256 _feeStake, uint256 _feeWithdraw, uint256 _punishPart, uint256 _1stMinStakeValue, uint256 _minStakeValue) 
        external 
        onlyFactoryOrOwner
    {
        stakeBurn = _stakeBurn;
        feeStake = _feeStake;
        feeWithdraw = _feeWithdraw;
        feePunish = _punishPart;
        firstMinStakeValue = _1stMinStakeValue;
        minStakeValue = _minStakeValue;
    }

    function configRewardAdd(uint256 _startTime, uint256 _duration, uint256 reward)
        external
        onlyFactoryOrOwner
        checkOpen
    {
        poolInfo.push(PoolInfo({
            totalSupply:0, 
            startTime: _startTime,
            DURATION: _duration,
            rewardRate: reward.div(_duration),
            periodFinish: _startTime.add(_duration),
            lastUpdateTime: _startTime,
            claimedReward: 0,
            maxReward: reward,
            rewardPerTokenStored:0
        }));

        emit RewardAdded(reward);

        // avoid overflow to lock assets
        _checkRewardRateByPID(poolInfo.length-1);
    }

    function setInvitedBy(address invitedBy) public{
        if(!enableInvite){
            return;
        }
        if(invitedBy == address(0x0)){
            return;
        }
        if(invitedBy == msg.sender){
            return;
        }
        if(stats.getIAAStats(STATS_TYPE_INVITE_RELATION, msg.sender) != address(0x0)){
            return;
        }
        if(stats.getIAAStats(STATS_TYPE_INVITE_RELATION, invitedBy) == msg.sender){
            return;
        }
        stats.setIAAStats(STATS_TYPE_INVITE_RELATION, msg.sender, invitedBy);
        stats.incrIAIStats(STATS_TYPE_INVITE_1ST_COUNT, invitedBy, 1);
        uint256 user1STCount = stats.getIAIStats(STATS_TYPE_INVITE_1ST_COUNT, msg.sender);
        if(user1STCount > 0){
            stats.incrIAIStats(STATS_TYPE_INVITE_2ND_COUNT, invitedBy, user1STCount);
        }
        address topInviter = stats.getIAAStats(STATS_TYPE_INVITE_RELATION, invitedBy);
        if(topInviter != address(0x0)){
            stats.incrIAIStats(STATS_TYPE_INVITE_2ND_COUNT, topInviter, 1);
        }
    }

    function handleInviteReward(address user, uint256 amount) internal returns (uint256, uint256, uint256){
        uint256 amount1;
        uint256 amount2;
        uint256 amount3;
        if(!enableInvite){
            return (amount1,amount2,amount3);
        }
        address _1stInvitedBy = address(0x0);//stats.getIAAStats(STATS_TYPE_INVITE_RELATION, user);
        address _2ndInvitedBy = address(0x0);//stats.getIAAStats(STATS_TYPE_INVITE_RELATION, 0x0);
        _1stInvitedBy = stats.getIAAStats(STATS_TYPE_INVITE_RELATION, user);
        if(_1stInvitedBy == address(0x0)){
            return (amount1,amount2,amount3);
        }
        amount3 = amount.div(100);
        if(amount3 > 0){
            frog.safeTransfer(user, amount3);
            stats.incrIAIStats(STATS_TYPE_INVITE_ZERO_REWARD_AMOUNT, user, amount3);
            stats.incrIAIStats(STATS_TYPE_INVITE_ZERO_TODAY_REWARD + block.timestamp.div(86400), user, amount3);
            stats.incrIIStats(STATS_TYPE_INVITE_ZERO_TOTAL_REWARD, amount3);
        }

        amount1 = amount.div(10);
        if(amount1 > 0){
            frog.safeTransfer(_1stInvitedBy, amount1);
            stats.incrIAIStats(STATS_TYPE_INVITE_1ST_REWARD_AMOUNT, _1stInvitedBy, amount1);
            stats.incrIAIStats(STATS_TYPE_INVITE_1ST_TODAY_REWARD + block.timestamp.div(86400), _1stInvitedBy, amount1);
            stats.incrIIStats(STATS_TYPE_INVITE_1ST_TOTAL_REWARD, amount1);
        }

        _2ndInvitedBy = stats.getIAAStats(STATS_TYPE_INVITE_RELATION, _1stInvitedBy);
        if(_2ndInvitedBy == address(0x0)){
            return (amount1,amount2,amount3);
        }
        amount2 = amount.div(100);
        if(amount2 > 0){
            frog.safeTransfer(_2ndInvitedBy, amount2);
            stats.incrIAIStats(STATS_TYPE_INVITE_2ND_REWARD_AMOUNT, _2ndInvitedBy, amount2);
            stats.incrIAIStats(STATS_TYPE_INVITE_2ND_TODAY_REWARD + block.timestamp.div(86400), _2ndInvitedBy, amount2);
            stats.incrIIStats(STATS_TYPE_INVITE_2ND_TOTAL_REWARD, amount2);
        }
        return (amount1,amount2,amount3);
    }

    function configRewardByPIDEdit(uint256 _pid, uint256 _startTime, uint256 _duration, uint256 reward)
        external
        onlyFactoryOrOwner
        checkOpen
        updateRewardByPID(_pid, address(0)) 
    {
        poolInfo[_pid].startTime = _startTime;
        poolInfo[_pid].DURATION = _duration;
        poolInfo[_pid].rewardRate = reward.div(_duration);
        poolInfo[_pid].periodFinish = _startTime.add(_duration);
        poolInfo[_pid].lastUpdateTime = _startTime;
        poolInfo[_pid].claimedReward = 0;
        poolInfo[_pid].maxReward = reward;

        emit RewardAdded(reward);

        // avoid overflow to lock assets
        _checkRewardRateByPID(_pid);
    }

    function _checkRewardRateByPID(uint256 _pid) internal view returns (uint256) {
        return poolInfo[_pid].DURATION.mul(poolInfo[_pid].rewardRate).mul(_gunit);
    }

    function setOpen(bool _open) external onlyOwner {
        open = _open;
        emit SetOpen(_open);
    }

    function setEmergency(bool _emergency) external onlyOwner {
        emergency = _emergency;
        emit SetEmergency(_emergency);
    }

    function getPeriodFinishByPID(uint256 _pid) external view returns (uint256) {
        return poolInfo[_pid].periodFinish;
    }

    function getUserPunishedFeesByPID(uint256 _pid, address user) external view returns (uint256){
        return poolInfo[_pid].punishedFees[user];
    }

    function isOpen() external view returns (bool) {
        return open;
    }

    modifier checkStartByPID(uint256 _pid){
        require(block.timestamp > poolInfo[_pid].startTime,"FROG-POOL: Not start");
        _;
    }

    modifier checkEndByPID(uint256 _pid){
        require(block.timestamp >= poolInfo[_pid].periodFinish,"FROG-POOL: Not end");
        _;
    }

    modifier checkNotEndByPID(uint256 _pid){
        require(block.timestamp < poolInfo[_pid].periodFinish,"FROG-POOL: ended");
        _;
    }

    modifier checkOpen() {
        require(open, "FROG: Pool is closed");
        _;
    }

    modifier checkTheEmergency() {
        require(emergency, "FROG: Emergency is closed");
        _;
    }

    modifier checkStakeToken() {
        require(stakeToken != IERC20(0x0), "FROG: Pool is closed");
        _;
    }

    modifier updateRewardByPID(uint256 _pid, address account) {
        poolInfo[_pid].rewardPerTokenStored = rewardPerTokenByPID(_pid);
        poolInfo[_pid].lastUpdateTime = lastTimeRewardApplicableByPID(_pid);
        if (account != address(0)) {
            poolInfo[_pid].rewards[account] = earnedByPID(_pid, account);
            poolInfo[_pid].userRewardPerTokenPaid[account] = poolInfo[_pid].rewardPerTokenStored;
        }
        _;
    }

    function stake(uint256 amount) public {
        require(amount > 0, "FROG-POOL: Cannot stake 0");
    }

    function withdraw(uint256 amount, bool transfer) public {
        require(amount > 0, "FROG-POOL: Cannot withdraw 0");
        require(transfer, "FROG-POOL: Cannot withdraw 0");
    }

    function notifyRewardAmount(address _stakeToken, uint256 _startTime, uint256 _duration, uint256 reward)
        external
        onlyOwner
        checkOpen
    {
        require(_stakeToken != address(0x0), "");
        require(_startTime > 0, "");
        require(_duration > 0, "");
        require(reward > 0, "");
    }

    function setStats(IStats _stats) external onlyFactoryOrOwner{
        stats = _stats;
    }
    function setEnableInvite(bool _enable) external onlyFactoryOrOwner {
        enableInvite = _enable;
    }

    function emergencyTransfer(uint256 amount) public checkOpen checkStakeToken checkTheEmergency onlyOwner{
        require(amount > 0, "FROG-POOL: Cannot emergency transfer 0");
        stakeToken.safeTransfer(msg.sender, amount);
    }
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }
}