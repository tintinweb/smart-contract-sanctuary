/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function sub0(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
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
}


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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

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
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}


contract Governable is Initializable {
    // bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function __Governable_init_unchained(address governor_) virtual public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }
    
    modifier governance() {
        require(msg.sender == governor || msg.sender == _admin());
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }
}


contract Configurable is Governable {

    mapping (bytes32 => uint) internal config;
    
    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfigI(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfigA(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
    
    function setConfig(bytes32 key, uint value) external governance {
        _setConfig(key, value);
    }
    function setConfigI(bytes32 key, uint index, uint value) external governance {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfigA(bytes32 key, address addr, uint value) public governance {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}


contract RewardsDistributor is Configurable {
    using SafeERC20 for IERC20;

    address public rewardsToken;
	
    function __RewardsDistributor_init(address governor, address _rewardsToken) public initializer {
        __Governable_init_unchained(governor);
        __RewardsDistributor_init_unchained(_rewardsToken);
    }
    
    function __RewardsDistributor_init_unchained(address _rewardsToken) public governance {
        rewardsToken = _rewardsToken;
    }
    
    function approvePool(address pool, uint amount) public governance {
        //IERC20(rewardsToken).safeApprove(pool, amount);
        IERC20(rewardsToken).approve(pool, amount);             // GT do not support safeApprove
    }
}


// Inheritancea
interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewards(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}


abstract contract DodoPool {

    function rewardTokenInfos(uint256 i) public view virtual returns(address rewardToken,
        uint256 startBlock,
        uint256 endBlock,
        address rewardVault,
        uint256 rewardPerBlock,
        uint256 accRewardPerShare,
        uint256 lastRewardBlock);
        /*mapping(address => uint256) memory userRewardPerSharePaid,
        mapping(address => uint256) memory userRewards);*/

    function getPendingReward(address user, uint256 i) external view virtual returns (uint256); 

    function getPendingRewardByToken(address user, address rewardToken) external view virtual returns (uint256);

    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address user) public view virtual returns (uint256);

    function getRewardTokenById(uint256 i) external view virtual returns (address);
    function getIdByRewardToken(address rewardToken) external view virtual returns(uint256);
    function getRewardNum() external view virtual returns(uint256);
    
    // ============ Claim ============
    function deposit(uint256 amount) external virtual;
    function withdraw(uint256 amount) external virtual;

    function claimReward(uint256 i) external virtual;
    function claimAllRewards() external virtual;


	

}

abstract contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) virtual external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
}

contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuardUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;                  // obsoleted
    uint256 public rewardsDuration = 60 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) override public rewards;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    /* ========== CONSTRUCTOR ========== */

    //constructor(
    function __StakingRewards_init(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public initializer {
        __ReentrancyGuard_init_unchained();
        __StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
    }

    function __StakingRewards_init_unchained(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public initializer {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() override public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() virtual override public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) virtual override public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() virtual override external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // permit
        IPermit(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stake(uint256 amount) virtual override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) virtual override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() virtual override public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() virtual override public {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) override external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) virtual {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

interface IPermit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract StakingPool is Configurable, StakingRewards {
    using Address for address payable;
    
    bytes32 internal constant _ecoAddr_         = 'ecoAddr';
    bytes32 internal constant _ecoRatio_        = 'ecoRatio';
	bytes32 internal constant _allowContract_   = 'allowContract';
	bytes32 internal constant _allowlist_       = 'allowlist';
	bytes32 internal constant _blocklist_       = 'blocklist';


	uint public lep;            // 1: linear, 2: exponential, 3: power
	uint public period;
	uint public begin;

    function __StakingPool_init(address _governor, 
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        address _ecoAddr
    ) public initializer {
	    __Governable_init_unchained(_governor);
        __ReentrancyGuard_init_unchained();
        __StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_ecoAddr);
    }

    function __StakingPool_init_unchained(address _ecoAddr) public governance {
        config[_ecoAddr_] = uint(_ecoAddr);
        config[_ecoRatio_] = 0.181818181818181818 ether;
    }

    function notifyRewardBegin(uint _lep, uint _period, uint _span, uint _begin) virtual public governance updateReward(address(0)) {
        lep             = _lep;         // 1: linear, 2: exponential, 3: power
        period          = _period;
        rewardsDuration = _span;
        begin           = _begin;
        periodFinish    = _begin.add(_span);
    }

    function rewardDelta() public view returns (uint amt) {
        if(begin == 0 || begin >= now || lastUpdateTime >= now)
            return 0;
            
        amt = Math.min(rewardsToken.allowance(rewardsDistribution, address(this)), rewardsToken.balanceOf(rewardsDistribution)).sub0(rewards[address(0)]);
        
        // calc rewardDelta in period
        if(lep == 3) {                                                              // power
            uint y = period.mul(1 ether).div(lastUpdateTime.add(rewardsDuration).sub(begin));
            uint amt1 = amt.mul(1 ether).div(y);
            uint amt2 = amt1.mul(period).div(now.add(rewardsDuration).sub(begin));
            amt = amt.sub(amt2);
        } else if(lep == 2) {                                                       // exponential
            if(now.sub(lastUpdateTime) < rewardsDuration)
                amt = amt.mul(now.sub(lastUpdateTime)).div(rewardsDuration);
        }else if(now < periodFinish)                                                // linear
            amt = amt.mul(now.sub(lastUpdateTime)).div(periodFinish.sub(lastUpdateTime));
        else if(lastUpdateTime >= periodFinish)
            amt = 0;
            
        if(config[_ecoAddr_] != 0)
            amt = amt.mul(uint(1e18).sub(config[_ecoRatio_])).div(1 ether);
    }
    
    function rewardPerToken() override public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                rewardDelta().mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) virtual override public view returns (uint256) {
        return Math.min(Math.min(super.earned(account), rewardsToken.allowance(rewardsDistribution, address(this))), rewardsToken.balanceOf(rewardsDistribution));
    }

    modifier updateReward(address account) override {
        rewardPerTokenStored = rewardPerToken();
        uint delta = rewardDelta();
        {
            address addr = address(config[_ecoAddr_]);
            uint ratio = config[_ecoRatio_];
            if(addr != address(0) && ratio != 0) {
                uint d = delta.mul(ratio).div(uint(1e18).sub(ratio));
                rewards[addr] = rewards[addr].add(d);
                delta = delta.add(d);
            }
        }
        rewards[address(0)] = rewards[address(0)].add(delta);
        lastUpdateTime = now;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function getReward() override public nonReentrant updateReward(msg.sender) {
        require(getConfigA(_blocklist_, msg.sender) == 0, 'In blocklist');
        bool isContract = msg.sender.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfigA(_allowlist_, msg.sender) != 0, 'No allowContract');

        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewards[address(0)] = rewards[address(0)].sub0(reward);
            rewardsToken.safeTransferFrom(rewardsDistribution, msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    function stakeAndCompound(uint amount) virtual public {
        stake(amount);
        compound();
    }
    
    function compound() virtual public nonReentrant updateReward(msg.sender) {      // only for pool3
        require(getConfigA(_blocklist_, msg.sender) == 0, 'In blocklist');
        bool isContract = msg.sender.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfigA(_allowlist_, msg.sender) != 0, 'No allowContract');
        require(stakingToken == rewardsToken, 'not pool3');

        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewards[address(0)] = rewards[address(0)].sub0(reward);
            rewardsToken.safeTransferFrom(rewardsDistribution, address(this), reward);
            emit RewardPaid(msg.sender, reward);
            
            _totalSupply = _totalSupply.add(reward);
            _balances[msg.sender] = _balances[msg.sender].add(reward);
            emit Staked(msg.sender, reward);
        }
    }

    function getRewardForDuration() override external view returns (uint256) {
        return rewardsToken.allowance(rewardsDistribution, address(this)).sub0(rewards[address(0)]);
    }
    
}


contract StakingLimitPool is StakingPool{
    uint public stakingMin;
    uint public stakingMax;

    function __StakingLimitPool_init(address _governor, 
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken, 
        address _ecoAddr,
        uint _stakingMin,
        uint _stakingMax
    ) public initializer {
	    __Governable_init_unchained(_governor);
        __ReentrancyGuard_init_unchained();
        __StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_ecoAddr);
        __StakingLimitPool_init_unchained(_stakingMin,_stakingMax);
    }

    function __StakingLimitPool_init_unchained(uint _stakingMin,uint _stakingMax) public governance {
        stakingMin = _stakingMin;
        stakingMax = _stakingMax;
    }

    function stake(uint amount) virtual override public {
        uint lastAmount = _balances[msg.sender].add(amount);
        require(lastAmount>=stakingMin,'amount must >= stakingMin');
        if (stakingMax>0)
            require(lastAmount<=stakingMax,'amount must <= stakingMax');
        super.stake(amount);
    }

}



contract DoublePool is StakingPool {
    IStakingRewards public stakingPool2;
    IERC20 public rewardsToken2;
    mapping(address => uint256) public userRewardPerTokenPaid2;
    mapping(address => uint256) public rewards2;

    function __DoublePool_init(address _governor, address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr, address _stakingPool2, address _rewardsToken2) public initializer {
	    __Governable_init_unchained(_governor);
        __ReentrancyGuard_init_unchained();
        __StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_ecoAddr);
	    __DoublePool_init_unchained(_stakingPool2, _rewardsToken2);
	}
    
    function __DoublePool_init_unchained(address _stakingPool2, address _rewardsToken2) public governance {
	    stakingPool2 = IStakingRewards(_stakingPool2);
	    rewardsToken2 = IERC20(_rewardsToken2);
	}
    
    function notifyRewardBegin(uint _lep, uint _period, uint _span, uint _begin) virtual override public governance updateReward2(address(0)) {
        super.notifyRewardBegin(_lep, _period, _span, _begin);
    }
    
    function stake(uint amount) virtual override public updateReward2(msg.sender) {
        super.stake(amount);
        stakingToken.safeApprove(address(stakingPool2), amount);
        stakingPool2.stake(amount);
    }

    function withdraw(uint amount) virtual override public updateReward2(msg.sender) {
        stakingPool2.withdraw(amount);
        super.withdraw(amount);
    }
    
    function getReward2() virtual public nonReentrant updateReward2(msg.sender) {
        uint256 reward2 = rewards2[msg.sender];
        if (reward2 > 0) {
            rewards2[msg.sender] = 0;
            stakingPool2.getReward();
            rewardsToken2.safeTransfer(msg.sender, reward2);
            emit RewardPaid2(msg.sender, reward2);
        }
    }
    event RewardPaid2(address indexed user, uint256 reward2);

    function getDoubleReward() virtual public {
        getReward();
        getReward2();
    }
    
    function exit() override public {
        super.exit();
        getReward2();
    }
    
    function rewardPerToken2() virtual public view returns (uint256) {
        return stakingPool2.rewardPerToken();
    }

    function earned2(address account) virtual public view returns (uint256) {
        return _balances[account].mul(rewardPerToken2().sub(userRewardPerTokenPaid2[account])).div(1e18).add(rewards2[account]);
    }

    modifier updateReward2(address account) virtual {
        if (account != address(0)) {
            rewards2[account] = earned2(account);
            userRewardPerTokenPaid2[account] = rewardPerToken2();
        }
        _;
    }

}


contract DoublePoolDodo is StakingPool {

    using SafeMath for uint256;
    
    struct RewardTokenInfo {
        address rewardToken;
        uint256 startBlock;
        uint256 endBlock;
        address rewardVault;
        uint256 rewardPerBlock;
        uint256 accRewardPerShare;
        uint256 lastRewardBlock;
        mapping(address => uint256) userRewardPerSharePaid;
        mapping(address => uint256) userRewards;
    }

    DodoPool public dodoPool2;
    IERC20 public rewardsToken2;
    mapping(address => uint256) public userRewardPerTokenPaid2;
    mapping(address => uint256) public rewards2;

    function __DoublePool_init(address _governor, address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr, address _dodoPool2, address _rewardsToken2) public initializer {
	    __Governable_init_unchained(_governor);
        __ReentrancyGuard_init_unchained();
        __StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_ecoAddr);
	    __DoublePool_init_unchained(_dodoPool2, _rewardsToken2);
	}
    
    function __DoublePool_init_unchained(address _dodoPool2, address _rewardsToken2) public governance {
	    dodoPool2 = DodoPool(_dodoPool2);
	    rewardsToken2 = IERC20(_rewardsToken2);
	}
    
    function notifyRewardBegin(uint _lep, uint _period, uint _span, uint _begin) virtual override public governance updateReward2(address(0)){
        super.notifyRewardBegin(_lep, _period, _span, _begin);
    }
    
    function stake(uint amount) virtual override public updateReward2(msg.sender) {
        super.stake(amount);
        stakingToken.safeApprove(address(dodoPool2), amount);
        dodoPool2.deposit(amount);
    }

    function withdraw(uint amount) virtual override public updateReward2(msg.sender) {
        dodoPool2.withdraw(amount);
        super.withdraw(amount);
    }
    
    function getReward2() virtual public nonReentrant updateReward2(msg.sender) {
        uint256 reward2 = rewards2[msg.sender];
		if(reward2>0){
            rewards2[msg.sender] = 0;
		    dodoPool2.claimReward(0);
			rewardsToken2.safeTransfer(msg.sender, reward2);
            emit RewardPaid2(msg.sender, reward2);
		}
    }
    event RewardPaid2(address indexed user, uint256 reward2);

    function getDoubleReward() virtual public {
        getReward();
        getReward2();
    }
    
    function exit() override public {
        super.exit();
        getReward2();
    }
    

    function rewardPerToken2() virtual public view returns (uint256) {
        return getAccRewardPerShare(0);
    }

    function earned2(address account) virtual public view returns (uint256) {
        //return dodoPool2.getPendingReward(account,0);
        return _balances[account].mul(rewardPerToken2().sub(userRewardPerTokenPaid2[account])).div(1e18).add(rewards2[account]);
    }

    modifier updateReward2(address account) virtual {
        if (account != address(0)) {
            rewards2[account] = earned2(account);
            userRewardPerTokenPaid2[account] = rewardPerToken2();
        }
        _;
    }


    function _getUnrewardBlockNum(uint256 i) internal view returns (uint256) {
        RewardTokenInfo memory rt;
        (rt.rewardToken,rt.startBlock,rt.endBlock,rt.rewardVault,rt.rewardPerBlock,rt.accRewardPerShare,rt.lastRewardBlock) = dodoPool2.rewardTokenInfos(i);
        if (block.number < rt.startBlock || rt.lastRewardBlock > rt.endBlock) {
            return 0;
        }
        uint256 start = rt.lastRewardBlock < rt.startBlock ? rt.startBlock : rt.lastRewardBlock;
        uint256 end = rt.endBlock < block.number ? rt.endBlock : block.number;
        return end.sub(start);
    }

    function getAccRewardPerShare(uint256 i) public view returns (uint256) {
        RewardTokenInfo memory rt;
        (rt.rewardToken,rt.startBlock,rt.endBlock,rt.rewardVault,rt.rewardPerBlock,rt.accRewardPerShare,rt.lastRewardBlock) = dodoPool2.rewardTokenInfos(i);

       if (dodoPool2.totalSupply() == 0) {
            return rt.accRewardPerShare;
        }
        return rt.accRewardPerShare.add(divFloor(_getUnrewardBlockNum(i).mul(rt.rewardPerBlock), dodoPool2.totalSupply()));
    }
    
    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    
}


interface IMasterChef {
    function poolInfo(uint pid) external view returns (address lpToken, uint allocPoint, uint lastRewardBlock, uint accCakePerShare);
    function userInfo(uint pid, address user) external view returns (uint amount, uint rewardDebt);
    function pending(uint pid, address user) external view returns (uint);
    function pendingCake(uint pid, address user) external view returns (uint);
    function deposit(uint pid, uint amount) external;
    function withdraw(uint pid, uint amount) external;
}

contract NestMasterChef is StakingPool {
    IERC20 internal constant Cake = IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
    
    IMasterChef public stakingPool2;
    IERC20 public rewardsToken2;
    mapping(address => uint256) public userRewardPerTokenPaid2;
    mapping(address => uint256) public rewards2;
    uint public pid2;
    uint internal _rewardPerToken2;

    function __NestMasterChef_init(address _governor, address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr, address _stakingPool2, address _rewardsToken2, uint _pid2) public initializer {
	    __Governable_init_unchained(_governor);
        __ReentrancyGuard_init_unchained();
        __StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_ecoAddr);
        __NestMasterChef_init_unchained(_stakingPool2, _rewardsToken2, _pid2);
	}

    function __NestMasterChef_init_unchained(address _stakingPool2, address _rewardsToken2, uint _pid2) public governance {
	    stakingPool2 = IMasterChef(_stakingPool2);
	    rewardsToken2 = IERC20(_rewardsToken2);
	    pid2 = _pid2;
    }
    
    function notifyRewardBegin(uint _lep, uint _period, uint _span, uint _begin) virtual override public governance updateReward2(address(0)) {
        super.notifyRewardBegin(_lep, _period, _span, _begin);
    }
    
    function migrate() virtual public governance updateReward2(address(0)) {
        uint total = stakingToken.balanceOf(address(this));
        stakingToken.approve(address(stakingPool2), total);
        stakingPool2.deposit(pid2, total);
    }        
    
    function stake(uint amount) virtual override public updateReward2(msg.sender) {
        super.stake(amount);
        stakingToken.approve(address(stakingPool2), amount);
        stakingPool2.deposit(pid2, amount);
    }

    function withdraw(uint amount) virtual override public updateReward2(msg.sender) {
        stakingPool2.withdraw(pid2, amount);
        super.withdraw(amount);
    }
    
    function getReward2() virtual public nonReentrant updateReward2(msg.sender) {
        uint256 reward2 = rewards2[msg.sender];
        if (reward2 > 0) {
            rewards2[msg.sender] = 0;
            rewardsToken2.safeTransfer(msg.sender, reward2);
            emit RewardPaid2(msg.sender, reward2);
        }
    }
    event RewardPaid2(address indexed user, uint256 reward2);

    function getDoubleReward() virtual public {
        getReward();
        getReward2();
    }
    
    function exit() virtual override public {
        super.exit();
        getReward2();
    }
    
    function rewardPerToken2() virtual public view returns (uint256) {
        if(_totalSupply == 0)
            return _rewardPerToken2;
        else if(rewardsToken2 == Cake)
            return stakingPool2.pendingCake(pid2, address(this)).mul(1e18).div(_totalSupply).add(_rewardPerToken2);
        else
            return stakingPool2.pending(pid2, address(this)).mul(1e18).div(_totalSupply).add(_rewardPerToken2);
    }

    function earned2(address account) virtual public view returns (uint256) {
        return _balances[account].mul(rewardPerToken2().sub(userRewardPerTokenPaid2[account])).div(1e18).add(rewards2[account]);
    }

    modifier updateReward2(address account) virtual {
        if(_totalSupply > 0) {
            uint delta = rewardsToken2.balanceOf(address(this));
            stakingPool2.deposit(pid2, 0);
            delta = rewardsToken2.balanceOf(address(this)).sub(delta);
            _rewardPerToken2 = delta.mul(1e18).div(_totalSupply).add(_rewardPerToken2);
        }
        
        if (account != address(0)) {
            rewards2[account] = earned2(account);
            userRewardPerTokenPaid2[account] = _rewardPerToken2;
        }
        _;
    }

    uint256[50] private __gap;
}

interface IAcryptoFarm {
    function harvest(address _lpToken) external;
    function pendingSushi(address _lpToken, address _user) external view returns (uint256);
    function deposit(address _lpToken, uint256 _amount) external;
    function withdraw(address _lpToken, uint256 _amount) external;
}

contract NestAcryptoFarm is StakingPool {
    IAcryptoFarm public stakingPool2;
    IERC20 public rewardsToken2;
    mapping(address => uint256) public userRewardPerTokenPaid2;
    mapping(address => uint256) public rewards2;
	address public lpToken2;
    uint internal _rewardPerToken2;

    function __NestAcryptoFarm_init(address _governor, address _rewardsDistribution, address _rewardsToken, address _stakingToken, address _ecoAddr, address _stakingPool2, address _rewardsToken2, address _lpToken2) public initializer {
	    __Governable_init_unchained(_governor);
        __ReentrancyGuard_init_unchained();
        __StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, _stakingToken);
        __StakingPool_init_unchained(_ecoAddr);
        __NestAcryptoFarm_init_unchained(_stakingPool2, _rewardsToken2, _lpToken2);
	}

    function __NestAcryptoFarm_init_unchained(address _stakingPool2, address _rewardsToken2, address _lpToken2) public governance {
	    stakingPool2 = IAcryptoFarm(_stakingPool2);
	    rewardsToken2 = IERC20(_rewardsToken2);
	    lpToken2 = _lpToken2;
    }
    
    function notifyRewardBegin(uint _lep, uint _period, uint _span, uint _begin) virtual override public governance updateReward2(address(0)) {
        super.notifyRewardBegin(_lep, _period, _span, _begin);
    }
    
    function migrate() virtual public governance updateReward2(address(0)) {
        uint total = stakingToken.balanceOf(address(this));
        stakingToken.approve(address(stakingPool2), total);
        stakingPool2.deposit(lpToken2, total);
    }        
    
    function stake(uint amount) virtual override public updateReward2(msg.sender) {
        super.stake(amount);
        stakingToken.approve(address(stakingPool2), amount);
        stakingPool2.deposit(lpToken2, amount);
    }

    function withdraw(uint amount) virtual override public updateReward2(msg.sender) {
        stakingPool2.withdraw(lpToken2, amount);
        super.withdraw(amount);
    }
    
    function getReward2() virtual public nonReentrant updateReward2(msg.sender) {
        uint256 reward2 = rewards2[msg.sender];
        if (reward2 > 0) {
            rewards2[msg.sender] = 0;
            rewardsToken2.safeTransfer(msg.sender, reward2);
            emit RewardPaid2(msg.sender, reward2);
        }
    }
    event RewardPaid2(address indexed user, uint256 reward2);

    function getDoubleReward() virtual public {
        getReward();
        getReward2();
    }
    
    function exit() virtual override public {
        super.exit();
        getReward2();
    }
    
    function rewardPerToken2() virtual public view returns (uint256) {
        if(_totalSupply == 0)
            return _rewardPerToken2;
		else
		    return stakingPool2.pendingSushi(lpToken2, address(this)).mul(1e18).div(_totalSupply).add(_rewardPerToken2);
    }

    function earned2(address account) virtual public view returns (uint256) {
        return _balances[account].mul(rewardPerToken2().sub(userRewardPerTokenPaid2[account])).div(1e18).add(rewards2[account]);
    }

    modifier updateReward2(address account) virtual {
        if(_totalSupply > 0) {
            uint delta = rewardsToken2.balanceOf(address(this));
            //stakingPool2.deposit(lpToken2, 0);
            stakingPool2.harvest(lpToken2);
            delta = rewardsToken2.balanceOf(address(this)).sub(delta);
            _rewardPerToken2 = delta.mul(1e18).div(_totalSupply).add(_rewardPerToken2);
        }
        
        if (account != address(0)) {
            rewards2[account] = earned2(account);
            userRewardPerTokenPaid2[account] = _rewardPerToken2;
        }
        _;
    }

    uint256[50] private __gap;
}



contract IioPool is StakingPool {
    address internal constant HelmetAddress = 0x948d2a81086A075b3130BAc19e4c6DEe1D2E3fE8;
    address internal constant BurnAddress   = 0x000000000000000000000000000000000000dEaD;

    uint public lastUpdateTime3;
    IERC20 public rewardsToken3;
    mapping(IERC20 => uint) public totalSupply3;                                    // rewardsToken3 => totalSupply3
    mapping(IERC20 => uint) internal _rewardPerToken3;                              // rewardsToken3 => _rewardPerToken3
    mapping(IERC20 => uint) public begin3;                                          // rewardsToken3 => begin3
    mapping(IERC20 => uint) public end3;                                            // rewardsToken3 => end3
    mapping(IERC20 => uint) public claimTime3;                                      // rewardsToken3 => claimTime3
    mapping(IERC20 => uint) public ticketVol3;                                      // rewardsToken3 => ticketVol3
    mapping(IERC20 => IERC20)  public ticketToken3;                                 // rewardsToken3 => ticketToken3
    mapping(IERC20 => address) public ticketRecipient3;                             // rewardsToken3 => ticketRecipient3

    mapping(IERC20 => mapping(address => bool)) public applied3;                    // rewardsToken3 => acct => applied3
    mapping(IERC20 => mapping(address => uint)) public userRewardPerTokenPaid3;     // rewardsToken3 => acct => paid3
    mapping(IERC20 => mapping(address => uint)) public rewards3;                    // rewardsToken3 => acct => rewards3
    
    function setReward3BurnHelmet(IERC20 rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_) virtual external {
        setReward3(rewardsToken3_, begin3_, end3_, claimTime3_, ticketVol3_, IERC20(HelmetAddress), BurnAddress);
    }
    function setReward3(IERC20 rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_, IERC20 ticketToken3_, address ticketRecipient3_) virtual public governance {
        lastUpdateTime3     = begin3_;
        rewardsToken3       = rewardsToken3_;
        begin3              [rewardsToken3_] = begin3_;
        end3                [rewardsToken3_] = end3_;
        claimTime3          [rewardsToken3_] = claimTime3_;
        ticketVol3          [rewardsToken3_] = ticketVol3_;
        ticketToken3        [rewardsToken3_] = ticketToken3_;
        ticketRecipient3    [rewardsToken3_] = ticketRecipient3_;
        emit SetReward3(rewardsToken3_, begin3_, end3_, claimTime3_, ticketVol3_, ticketToken3_, ticketRecipient3_);
    }
    event SetReward3(IERC20 indexed rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_, IERC20 indexed ticketToken3_, address indexed ticketRecipient3_);
    
    function applyReward3() virtual public updateReward3(msg.sender) {
        IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        require(!applied3[rewardsToken3_][msg.sender], 'applied already');
        require(now < end3[rewardsToken3_], 'expired');
        
        IERC20 ticketToken3_ = ticketToken3[rewardsToken3_];                            // save gas
        if(address(ticketToken3_) != address(0))
            ticketToken3_.safeTransferFrom(msg.sender, ticketRecipient3[rewardsToken3_], ticketVol3[rewardsToken3_]);
        applied3[rewardsToken3_][msg.sender] = true;
        userRewardPerTokenPaid3[rewardsToken3_][msg.sender] = _rewardPerToken3[rewardsToken3_];
        totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].add(_balances[msg.sender]);
        emit ApplyReward3(msg.sender, rewardsToken3_);
    }
    event ApplyReward3(address indexed acct, IERC20 indexed rewardsToken3);
    
    function rewardDelta3() virtual public view returns (uint amt) {
        IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        uint lastUpdateTime3_ = lastUpdateTime3;                                        // save gas
        if(begin3[rewardsToken3_] == 0 || begin3[rewardsToken3_] >= now || lastUpdateTime3_ >= now)
            return 0;
            
        amt = Math.min(rewardsToken3_.allowance(rewardsDistribution, address(this)), rewardsToken3_.balanceOf(rewardsDistribution)).sub0(rewards3[rewardsToken3_][address(0)]);
        
        uint end3_ = end3[rewardsToken3_];                                              // save gas
        if(now < end3_)
            amt = amt.mul(now.sub(lastUpdateTime3_)).div(end3_.sub(lastUpdateTime3_));
        else if(lastUpdateTime3_ >= end3_)
            amt = 0;
    }
    
    function rewardPerToken3() virtual public view returns (uint) {
        if (totalSupply3[rewardsToken3] == 0) {
            return _rewardPerToken3[rewardsToken3];
        }
        return
            _rewardPerToken3[rewardsToken3].add(
                rewardDelta3().mul(1e18).div(totalSupply3[rewardsToken3])
            );
    }

    function earned3(address account) virtual public view returns (uint) {
        if(!applied3[rewardsToken3][account])
            return 0;
        return Math.min(rewardsToken3.balanceOf(rewardsDistribution), _balances[account].mul(rewardPerToken3().sub(userRewardPerTokenPaid3[rewardsToken3][account])).div(1e18).add(rewards3[rewardsToken3][account]));
    }

    modifier updateReward3(address account) virtual {
        IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        bool applied3_ = applied3[rewardsToken3_][account];                             // save gas
        if(account == address(0) || applied3_) {
            _rewardPerToken3[rewardsToken3_] = rewardPerToken3();
            rewards3[rewardsToken3_][address(0)] = rewards3[rewardsToken3_][address(0)].add(rewardDelta3());
            lastUpdateTime3 = Math.max(begin3[rewardsToken3_], Math.min(now, end3[rewardsToken3_]));
        }
        if (account != address(0) && applied3_) {
            uint amt = rewards3[rewardsToken3_][account];
            rewards3[rewardsToken3_][account] = earned3(account);
            userRewardPerTokenPaid3[rewardsToken3_][account] = _rewardPerToken3[rewardsToken3_];

            amt = rewards3[rewardsToken3_][account].sub0(amt);
            address addr = address(config[_ecoAddr_]);
            uint ratio = config[_ecoRatio_];
            if(addr != address(0) && addr != account && ratio != 0) {
                uint a = amt.mul(ratio).div(1 ether);
                rewards3[rewardsToken3_][addr] = rewards3[rewardsToken3_][addr].add(a);
                rewards3[rewardsToken3_][address(0)] = rewards3[rewardsToken3_][address(0)].add(a);
            }
        }
        _;
    }

    function stake(uint amount) virtual override public updateReward3(msg.sender) {
        super.stake(amount);
        IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        if(applied3[rewardsToken3_][msg.sender])
            totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].add(amount);
    }

    function withdraw(uint amount) virtual override public updateReward3(msg.sender) {
        IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        if(applied3[rewardsToken3_][msg.sender])
            totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].sub(amount);
        super.withdraw(amount);
    }
    
    function getReward3() virtual public nonReentrant updateReward3(msg.sender) {
        require(getConfigA(_blocklist_, msg.sender) == 0, 'In blocklist');
        bool isContract = msg.sender.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfigA(_allowlist_, msg.sender) != 0, 'No allowContract');

        IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        require(now >= claimTime3[rewardsToken3_], "it's not time yet");
        uint256 reward3 = rewards3[rewardsToken3_][msg.sender];
        if (reward3 > 0) {
            rewards3[rewardsToken3_][msg.sender] = 0;
            rewards3[rewardsToken3_][address(0)] = rewards3[rewardsToken3_][address(0)].sub0(reward3);
            rewardsToken3_.safeTransferFrom(rewardsDistribution, msg.sender, reward3);
            emit RewardPaid3(msg.sender, rewardsToken3_, reward3);
        }
    }
    event RewardPaid3(address indexed user, IERC20 indexed rewardsToken3_, uint256 reward3);
    
    uint[50] private __gap;
}

contract NestMasterChefIio is NestMasterChef, IioPool {
    function notifyRewardBegin(uint _lep, uint _period, uint _span, uint _begin) virtual override(StakingPool, NestMasterChef) public {
        NestMasterChef.notifyRewardBegin(_lep, _period, _span, _begin);
    }
    
    function stake(uint amount) virtual override(NestMasterChef, IioPool) public {
        super.stake(amount);
    }

    function withdraw(uint amount) virtual override(NestMasterChef, IioPool) public {
        super.withdraw(amount);
    }
    
    function exit() virtual override(StakingRewards, NestMasterChef) public {
        NestMasterChef.exit();
    }
    
    
    uint[50] private __gap;
}
    

contract IioPoolV2 is StakingPool {         // support multi IIO at the same time
    address internal constant HelmetAddress = 0x948d2a81086A075b3130BAc19e4c6DEe1D2E3fE8;
    address internal constant BurnAddress   = 0x000000000000000000000000000000000000dEaD;
    bytes32 internal constant _ecoRatio3_   = 'ecoRatio3';

    uint private __lastUpdateTime3;                             // obsolete
    IERC20 private __rewardsToken3;                             // obsolete
    mapping(IERC20 => uint) public totalSupply3;                                    // rewardsToken3 => totalSupply3
    mapping(IERC20 => uint) internal _rewardPerToken3;                              // rewardsToken3 => _rewardPerToken3
    mapping(IERC20 => uint) public begin3;                                          // rewardsToken3 => begin3
    mapping(IERC20 => uint) public end3;                                            // rewardsToken3 => end3
    mapping(IERC20 => uint) public claimTime3;                                      // rewardsToken3 => claimTime3
    mapping(IERC20 => uint) public ticketVol3;                                      // rewardsToken3 => ticketVol3
    mapping(IERC20 => IERC20)  public ticketToken3;                                 // rewardsToken3 => ticketToken3
    mapping(IERC20 => address) public ticketRecipient3;                             // rewardsToken3 => ticketRecipient3

    mapping(IERC20 => mapping(address => bool)) public applied3;                    // rewardsToken3 => acct => applied3
    mapping(IERC20 => mapping(address => uint)) public userRewardPerTokenPaid3;     // rewardsToken3 => acct => paid3
    mapping(IERC20 => mapping(address => uint)) public rewards3;                    // rewardsToken3 => acct => rewards3
    
    mapping(IERC20 => uint) public lastUpdateTime3;                                 // rewardsToken3 => lastUpdateTime3
    IERC20[] public all;                                                            // all rewardsToken3
    IERC20[] public active;                                                         // active rewardsToken3
    
    function setReward3BurnHelmet(IERC20 rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_) virtual external {
        setReward3(rewardsToken3_, begin3_, end3_, claimTime3_, ticketVol3_, IERC20(HelmetAddress), BurnAddress);
    }
    function setReward3(IERC20 rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_, IERC20 ticketToken3_, address ticketRecipient3_) virtual public governance {
        lastUpdateTime3     [rewardsToken3_]= begin3_;
        //rewardsToken3       = rewardsToken3_;
        begin3              [rewardsToken3_] = begin3_;
        end3                [rewardsToken3_] = end3_;
        claimTime3          [rewardsToken3_] = claimTime3_;
        ticketVol3          [rewardsToken3_] = ticketVol3_;
        ticketToken3        [rewardsToken3_] = ticketToken3_;
        ticketRecipient3    [rewardsToken3_] = ticketRecipient3_;
        _setConfig(_ecoRatio3_, address(rewardsToken3_), 0.10 ether);
        
        uint i=0;
        for(; i<all.length; i++)
            if(all[i] == rewardsToken3_)
                break;
        if(i>=all.length)
            all.push(rewardsToken3_);
            
        i=0;
        for(; i<active.length; i++)
            if(active[i] == rewardsToken3_)
                break;
        if(i>=active.length)
            active.push(rewardsToken3_);
            
        emit SetReward3(rewardsToken3_, begin3_, end3_, claimTime3_, ticketVol3_, ticketToken3_, ticketRecipient3_);
    }
    event SetReward3(IERC20 indexed rewardsToken3_, uint begin3_, uint end3_, uint claimTime3_, uint ticketVol3_, IERC20 indexed ticketToken3_, address indexed ticketRecipient3_);
    
    function deactive(IERC20 rewardsToken3_) virtual public governance {
        for(uint i=0; i<active.length; i++)
            if(active[i] == rewardsToken3_) {
                active[i] = active[active.length-1];
                active.pop();
                emit Deactive(rewardsToken3_);
                return;
            }
        revert('not found active rewardsToken3_');
    }
    event Deactive(IERC20 indexed rewardsToken3_);

    function applyReward3(IERC20 rewardsToken3_) virtual public updateReward3(rewardsToken3_, msg.sender) {
        //IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        require(!applied3[rewardsToken3_][msg.sender], 'applied already');
        require(now < end3[rewardsToken3_], 'expired');
        
        IERC20 ticketToken3_ = ticketToken3[rewardsToken3_];                            // save gas
        if(address(ticketToken3_) != address(0))
            ticketToken3_.safeTransferFrom(msg.sender, ticketRecipient3[rewardsToken3_], ticketVol3[rewardsToken3_]);
        applied3[rewardsToken3_][msg.sender] = true;
        userRewardPerTokenPaid3[rewardsToken3_][msg.sender] = _rewardPerToken3[rewardsToken3_];
        totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].add(_balances[msg.sender]);
        emit ApplyReward3(msg.sender, rewardsToken3_);
    }
    event ApplyReward3(address indexed acct, IERC20 indexed rewardsToken3);
    
    function rewardDelta3(IERC20 rewardsToken3_) virtual public view returns (uint amt) {
        //IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        uint lastUpdateTime3_ = lastUpdateTime3[rewardsToken3_];                        // save gas
        if(begin3[rewardsToken3_] == 0 || begin3[rewardsToken3_] >= now || lastUpdateTime3_ >= now)
            return 0;
            
        amt = Math.min(rewardsToken3_.allowance(rewardsDistribution, address(this)), rewardsToken3_.balanceOf(rewardsDistribution)).sub0(rewards3[rewardsToken3_][address(0)]);
        
        uint end3_ = end3[rewardsToken3_];                                              // save gas
        if(now < end3_)
            amt = amt.mul(now.sub(lastUpdateTime3_)).div(end3_.sub(lastUpdateTime3_));
        else if(lastUpdateTime3_ >= end3_)
            amt = 0;
            
        if(config[_ecoAddr_] != 0)
            amt = amt.mul(uint(1e18).sub(getConfigA(_ecoRatio3_, address(rewardsToken3_)))).div(1 ether);
    }
    
    function rewardPerToken3(IERC20 rewardsToken3_) virtual public view returns (uint) {
        if (totalSupply3[rewardsToken3_] == 0) {
            return _rewardPerToken3[rewardsToken3_];
        }
        return
            _rewardPerToken3[rewardsToken3_].add(
                rewardDelta3(rewardsToken3_).mul(1e18).div(totalSupply3[rewardsToken3_])
            );
    }

    function earned3(IERC20 rewardsToken3_, address account) virtual public view returns (uint) {
        if(!applied3[rewardsToken3_][account])
            return 0;
        return Math.min(rewardsToken3_.balanceOf(rewardsDistribution), _balances[account].mul(rewardPerToken3(rewardsToken3_).sub(userRewardPerTokenPaid3[rewardsToken3_][account])).div(1e18).add(rewards3[rewardsToken3_][account]));
    }

    function _updateReward3(IERC20 rewardsToken3_, address account) virtual internal {
        bool applied3_ = applied3[rewardsToken3_][account];                             // save gas
        if(account == address(0) || applied3_) {
            _rewardPerToken3[rewardsToken3_] = rewardPerToken3(rewardsToken3_);
            uint delta = rewardDelta3(rewardsToken3_);
            {
                address addr = address(config[_ecoAddr_]);
                uint ratio = getConfigA(_ecoRatio3_, address(rewardsToken3_));
                if(addr != address(0) && ratio != 0) {
                    uint d = delta.mul(ratio).div(uint(1e18).sub(ratio));
                    rewards3[rewardsToken3_][addr] = rewards3[rewardsToken3_][addr].add(d);
                    delta = delta.add(d);
                }
            }
            rewards3[rewardsToken3_][address(0)] = rewards3[rewardsToken3_][address(0)].add(delta);
            lastUpdateTime3[rewardsToken3_] = Math.max(begin3[rewardsToken3_], Math.min(now, end3[rewardsToken3_]));
        }
        if (account != address(0) && applied3_) {
            rewards3[rewardsToken3_][account] = earned3(rewardsToken3_, account);
            userRewardPerTokenPaid3[rewardsToken3_][account] = _rewardPerToken3[rewardsToken3_];
        }
    }
    
    modifier updateReward3(IERC20 rewardsToken3_, address account) virtual {
        _updateReward3(rewardsToken3_, account);
        _;
        emit TotalSupply3(rewardsToken3_,totalSupply3[rewardsToken3_]);
    }
    event TotalSupply3(IERC20 indexed rewardsToken3_, uint totalSupply3);

    function stake(uint amount) virtual override public {
        super.stake(amount);
        for(uint i=0; i<active.length; i++) {
            IERC20 rewardsToken3_ = active[i];                                          // save gas
            _updateReward3(rewardsToken3_, msg.sender);
            if(applied3[rewardsToken3_][msg.sender])
                totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].add(amount);
        }    
    }

    function withdraw(uint amount) virtual override public {
        for(uint i=0; i<active.length; i++) {
            IERC20 rewardsToken3_ = active[i];                                          // save gas
            _updateReward3(rewardsToken3_, msg.sender);
            if(applied3[rewardsToken3_][msg.sender])
                totalSupply3[rewardsToken3_] = totalSupply3[rewardsToken3_].sub(amount);
        }
        super.withdraw(amount);
    }
    
    function getReward3(IERC20 rewardsToken3_) virtual public nonReentrant updateReward3(rewardsToken3_, msg.sender) {
        require(getConfigA(_blocklist_, msg.sender) == 0, 'In blocklist');
        bool isContract = msg.sender.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfigA(_allowlist_, msg.sender) != 0, 'No allowContract');

        //IERC20 rewardsToken3_ = rewardsToken3;                                          // save gas
        require(now >= claimTime3[rewardsToken3_], "it's not time yet");
        uint256 reward3 = rewards3[rewardsToken3_][msg.sender];
        if (reward3 > 0) {
            rewards3[rewardsToken3_][msg.sender] = 0;
            rewards3[rewardsToken3_][address(0)] = rewards3[rewardsToken3_][address(0)].sub0(reward3);
            rewardsToken3_.safeTransferFrom(rewardsDistribution, msg.sender, reward3);
            emit RewardPaid3(msg.sender, rewardsToken3_, reward3);
        }
    }
    event RewardPaid3(address indexed user, IERC20 indexed rewardsToken3_, uint256 reward3);
    
    uint[47] private __gap;
}

contract NestMasterChefIioV2 is NestMasterChef, IioPoolV2 {
    function notifyRewardBegin(uint _lep, uint _period, uint _span, uint _begin) virtual override(StakingPool, NestMasterChef) public {
        NestMasterChef.notifyRewardBegin(_lep, _period, _span, _begin);
    }
    
    function stake(uint amount) virtual override(NestMasterChef, IioPoolV2) public {
        super.stake(amount);
    }

    function withdraw(uint amount) virtual override(NestMasterChef, IioPoolV2) public {
        super.withdraw(amount);
    }
    
    function exit() virtual override(StakingRewards, NestMasterChef) public {
        NestMasterChef.exit();
    }
    
    
    uint[50] private __gap;
}
    

contract BurningPool is StakingPool {
    address internal constant BurnAddress   = 0x000000000000000000000000000000000000dEaD;
    
    function stake(uint256 amount) virtual override public {
        super.stake(amount);
        stakingToken.safeTransfer(BurnAddress, stakingToken.balanceOf(address(this)));
    }

    function withdraw(uint256) virtual override public {
        revert('Burned already, none to withdraw');
    }

}



contract BurningLimitPool is Configurable,ReentrancyGuardUpgradeSafe {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address internal constant BurnAddress   = 0x000000000000000000000000000000000000dEaD;
    IERC20 public burnToken;
    mapping(address => uint256) public totalBurns;
    uint public burnMin;
    uint public burnMax;
    uint public totalBurnMax;
    uint public totalBurn;
    uint public begin;
    uint public span;

   function __BurningLimitPool_init(address _governor, address _burnToken,uint _burnMin,uint  _burnMax,uint  _totalBurnMax,uint _begin,uint _span) public initializer {
	    __Governable_init_unchained(_governor);
        __ReentrancyGuard_init_unchained();
        __BurningLimitPool_init_unchained(_burnToken, _burnMin, _burnMax, _totalBurnMax,_begin,_span);
    }

    function __BurningLimitPool_init_unchained(address _burnToken,uint _burnMin,uint  _burnMax,uint  _totalBurnMax,uint _begin,uint _span) public governance {
		burnToken = IERC20(_burnToken);
		burnMin = _burnMin;
		burnMax = _burnMax;
		totalBurnMax =_totalBurnMax;
		begin = _begin;
		span =_span;
    }


    function burn(uint256 amount)  public {
        require(now>=begin,"No start");
        require(now<=(begin.add(span)),"pool closed");
        
        require(amount>=burnMin,'amount must >= stakingMin');
        
        if (burnMax>0){
            //require(amount<=burnMax,'amount must <= burnMax');
            require(totalBurns[msg.sender]<burnMax,'burn overflow');
        }
        
        uint256 amountReal = Math.min(amount,totalBurnMax.sub(totalBurn));
        totalBurn = totalBurn.add(amountReal);
        burnToken.safeTransferFrom(msg.sender,BurnAddress,amountReal);
		emit Burn(msg.sender, amountReal,now);
		totalBurns[msg.sender] =totalBurns[msg.sender].add(amountReal);
    }
    event Burn(address indexed user, uint256 amount,uint256 time);
    
}


contract AirPool is StakingPool {
    function __AirPool_init(address _governor, 
        address _rewardsDistribution,
        address _rewardsToken
    ) public initializer {
	    __Governable_init_unchained(_governor);
        __ReentrancyGuard_init_unchained();
        __StakingRewards_init_unchained(_rewardsDistribution, _rewardsToken, address(0));
        __StakingPool_init_unchained(address(0));
        __AirPool_init_unchained();
    }

    function __AirPool_init_unchained() public governance {
    }

    function stake(uint256) virtual override public {
        revert('Air Claim, none to stake');
    }

    function withdraw(uint256) virtual override public {
        revert('Air Claim, none to withdraw');
    }
    
    function setQuota(address acct, uint amt) virtual external updateReward(address(0)) governance {
        _totalSupply = _totalSupply.add(amt).sub(_balances[acct]);
        _balances[acct] = amt;
        emit SetQuota(acct, amt);
    }
    event SetQuota(address acct, uint amt);

    function setQuotaN(address[] calldata accts, uint amt) virtual external updateReward(address(0)) governance {
        uint total = _totalSupply;
        for(uint i=0; i<accts.length; i++) {
            total = total.add(amt).sub(_balances[accts[i]]);
            _balances[accts[i]] = amt;
        }
        _totalSupply = total;
    }
    
    
    function setQuotaNN(address[] calldata accts, uint[] calldata amts) virtual external updateReward(address(0)) governance {
        require(accts.length == amts.length, 'accts.length != amts.length');
        uint total = _totalSupply;
        for(uint i=0; i<accts.length; i++) {
            total = total.add(amts[i]).sub(_balances[accts[i]]);
            _balances[accts[i]] = amts[i];
        }
        _totalSupply = total;
    }
    
}


contract Mine is Governable {
    using SafeERC20 for IERC20;

    address public reward;

    function __Mine_init(address governor, address reward_) public initializer {
        __Governable_init_unchained(governor);
        __Mine_init_unchained(reward_);
    }
    
    function __Mine_init_unchained(address reward_) public governance {
        reward = reward_;
    }
    
    function approvePool(address pool, uint amount) public governance {
        IERC20(reward).approve(pool, amount);
    }
    
    function approveToken(address token, address pool, uint amount) public governance {
        IERC20(token).approve(pool, amount);
    }
    
}