/**
 *Submitted for verification at arbiscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    
    function decimals() external view returns (uint8);

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

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.2;

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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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
contract Ownable is Context {
    address private _owner;

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit GovernanceTransferred(address(0), msgSender);
    }

    /**
     * Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _owner;
    }

    /**
     * Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function _transferGovernance(address newOwner) internal virtual onlyGovernance {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit GovernanceTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Stabilize Token Interface
interface StabilizeToken is IERC20 {

    /// Operator is the only contract that can mint
    function mint(address _to, uint256 _amount) external returns (bool);
    
    // Get the minter address
    function minterAddress() external view returns (address);
}

interface StabilizeBank {
    function totalWeeklyRevenue() external view returns(uint256);
    function strategyWeeklyRevenue(address) external view returns(uint256);
    function getSTBZBalance() external view returns (uint256);
    function depositSTBZ(address _credit, uint256 amount) external;
    function withdrawSTBZ(uint256 amount) external;
    function resetStrategyRevenue(address _credit) external;
    function resetTotalRevenue() external;
}

// File: contracts/EmissionsOperator.sol

pragma solidity =0.6.6;

// EmissionsOperator is the minter of Stablize Arbitrum. 
// After the initial burst phase, emission will continue for perpetuity at an inflation rate that is offset by profit generated

contract EmissionsOperator is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for StabilizeToken;
    using Address for address;
    
    // variables
    uint256 constant WEEKLY_DURATION = 7 days; // Each reward period lasts for one week
    uint256 constant DIVISION_FACTOR = 100000;
    uint256 constant DEV_PERCENT = 10000; // For each week's minting, dev team gets 10%
    
    uint256 private _periodFinished; // The UTC time that the current reward period ends
    uint256 public protocolStartTime; // UTC time that the protocol begins to reward tokens
    uint256 public weeklyReward; // The reward for the current week, this determines the reward rate
    uint256 public boostPercent = 5000; // This is reduced weekly then switched to weekly inflation
    uint256 public weeklyInflation = 19; // The inflation rate is about 1% per year, 0.019% per week
    uint256 public vestTime = 90 days; // Time it takes to reach 0% penalty
    address public stbzBankAddress;
    address public developerTreasuryAddress;
    
    StabilizeToken private STBZ; // A reference to the StabilizeToken
    uint256 private _currentWeek = 0;
    bool private protocolStarted = false; // This will become true when protocol is started
  
    // Reward variables
    uint256 public rewardPercentLP = 65000; // This is the percent of rewards reserved for LP pools. Represents 65% of all Stabilize Token rewards 
    
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many zsTokens/Lp tokens tokens the user has provided.
        uint256 rewardDebt; // Reward debt. The amount of rewards already given to depositer
        uint256 unclaimedReward; // Total reward potential
        uint256 depositAverageTime; // The average deposit time
    }

    // Info of each pool.
    struct PoolInfo {
        address tokenAddress; // Address of LP/strat token contract.
        uint256 rewardRate; // The rate at which Stabilize Token is earned per second
        uint256 rewardPerTokenStored; // Reward per token stored which should gradually increase with time
        uint256 lastUpdateTime; // Time the pool was last updated
        uint256 totalSupply; // The total amount of LP/Strat tokens in the pool
        uint256 poolWeight;
        bool deactivated; // If deactivated, user cannot deposit into pool anymore
        bool excludedFromWeight; // If true, pool weight matches highest earning pool
        uint256 poolID; // ID for the pool
        bool isLpPool; // LP pools are calculated separate from other pools
    }

    // Info of each pool.
    PoolInfo[] private totalPools;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) private userInfo;
    // List of the active pools IDs
    uint256[] private activePools;
    mapping(address => bool) public blockedContracts; // Governance can block contracts (only) from withdrawing rewards at anytime

    // Events
    event Deposited(uint256 pid, address indexed user, uint256 amount);
    event Withdrawn(uint256 pid, address indexed user, uint256 amount);
    event RewardPaid(uint256 pid, address indexed user, uint256 reward, uint256 rewardFee);
    event RewardDenied(uint256 pid, address indexed user, uint256 reward);
    event NewWeek(uint256 weekNum, uint256 rewardAmount);
    event GovernorChanged(address oldGov, address newGov);

    constructor(
        address _treasury,
        address _stbzbank,
        StabilizeToken _stabilize,
        uint256 startTime
    ) public {
        developerTreasuryAddress = _treasury;
        stbzBankAddress = _stbzbank;
        STBZ = _stabilize;
        protocolStartTime = startTime;
    }
    
    // Modifiers
    
    modifier updateRewardEarned(uint256 _pid, address account) {
        totalPools[_pid].rewardPerTokenStored = rewardPerToken(_pid);
        totalPools[_pid].lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            userInfo[_pid][account].unclaimedReward = rewardEarned(_pid,account);
            userInfo[_pid][account].rewardDebt = totalPools[_pid].rewardPerTokenStored;
        }
        _;
    }
    
    // Getters
    function currentWeek() external view returns (uint256){
        return _currentWeek;
    }
    
    function periodFinished() external view returns (uint256){
        return _periodFinished;
    }

    function poolLength() public view returns (uint256) {
        return totalPools.length;
    }
    
    function activePoolLength() public view returns (uint256) {
        return activePools.length;
    }
    
    function getActivePoolPID(uint256 _pos) public view returns (uint256) {
        return activePools[_pos];
    }
    
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < _periodFinished ? block.timestamp : _periodFinished;
    }
    
    function rewardRate(uint256 _pid) external view returns (uint256) {
        return totalPools[_pid].rewardRate;
    }
    
    function poolSize(uint256 _pid) external view returns (uint256) {
        return totalPools[_pid].totalSupply;
    }
    
    function poolBalance(uint256 _pid, address _address) external view returns (uint256) {
        return userInfo[_pid][_address].amount;
    }
    
    function poolDepositTime(uint256 _pid, address _address) external view returns (uint256) {
        return userInfo[_pid][_address].depositAverageTime;
    }
    
    // Returns the amount of vesting remaining
    function poolVestedPercent(uint256 _pid, address _address) public view returns (uint256) {
        uint256 depositTime = userInfo[_pid][_address].depositAverageTime;
        if(depositTime == 0){ return DIVISION_FACTOR; }
        if(vestTime == 0){ return 0; }
        if(now > depositTime.add(vestTime)){ return 0; } // Met maximum vest time
        uint256 timeDiff = now.sub(depositTime);
        uint256 percent = DIVISION_FACTOR.sub(timeDiff.mul(DIVISION_FACTOR).div(vestTime));
        return percent;
    }
    
    function poolTokenAddress(uint256 _pid) external view returns (address) {
        return totalPools[_pid].tokenAddress;
    }
    
    function isPoolWeightExcluded(uint256 _pid) external view returns (bool) {
        return totalPools[_pid].excludedFromWeight;
    }
    
    function rewardPerToken(uint256 _pid) public view returns (uint256) {
        if (totalPools[_pid].totalSupply == 0) {
            return totalPools[_pid].rewardPerTokenStored;
        }
        return
            totalPools[_pid].rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(totalPools[_pid].lastUpdateTime)
                    .mul(totalPools[_pid].rewardRate)
                    .mul(1e18)
                    .div(totalPools[_pid].totalSupply)
            );
    }

    function rewardEarned(uint256 _pid, address account) public view returns (uint256) {
        return
            userInfo[_pid][account].amount
                .mul(rewardPerToken(_pid).sub(userInfo[_pid][account].rewardDebt))
                .div(1e18)
                .add(userInfo[_pid][account].unclaimedReward);
    }
    
    // Setters
    // 
    function mintNewWeek() public nonReentrant {
        require(now >= protocolStartTime,"Too soon to start this protocol");
        if(protocolStarted == true){
            // We cannot mint a new week until the current week is over
            require(now >= _periodFinished,"Too early to start next week");
        }
        require(STBZ.minterAddress() == address(this),"The Operator does not have permission to mint tokens");
        
        if(protocolStarted == false){
            // Determine the base reward rate
            protocolStarted = true;

            // Activate all the pools
            uint256 length = totalPools.length;
            for(uint256 i = 0; i < length; i++){
                activePools.push(totalPools[i].poolID);
            }
        }
        _currentWeek = _currentWeek.add(1);
        
        uint256 tokensNeeded;
        {
            // Determine the amount of tokens to mint this week
            if(boostPercent > 0){
                tokensNeeded = STBZ.totalSupply().mul(boostPercent).div(DIVISION_FACTOR);
                boostPercent = boostPercent.sub(1000); // Decrease it by 1%
            }else{
                // We are at weekly inflation now
                tokensNeeded = STBZ.totalSupply().mul(weeklyInflation).div(DIVISION_FACTOR);
            }
            // Pull from the bank the STBZ tokens
            if(tokensNeeded > 0){
                StabilizeBank bank = StabilizeBank(stbzBankAddress);
                if(bank.getSTBZBalance() >= tokensNeeded){
                    // No need to mint, pull entire stbz from bank
                    bank.withdrawSTBZ(tokensNeeded);
                }else{
                    uint256 mintAmount = tokensNeeded.sub(bank.getSTBZBalance()); // Mint what we don't have in the bank
                    STBZ.mint(address(this), mintAmount);
                    if(bank.getSTBZBalance() > 0){
                        bank.withdrawSTBZ(bank.getSTBZBalance());
                    }
                }
                // Send some of the new STBZ to the dev account
                uint256 devShare = tokensNeeded.mul(DEV_PERCENT).div(DIVISION_FACTOR);
                STBZ.safeTransfer(developerTreasuryAddress, devShare);
                tokensNeeded = tokensNeeded.sub(devShare);
            }
        }

        // Now adjust the contract values
        // Force update all the active pools before we extend the period
        for(uint256 i = 0; i < activePools.length; i++){
            forceUpdateRewardEarned(activePools[i],address(0));
            totalPools[activePools[i]].rewardRate = 0; // Set the reward rate to 0 until pools rebalanced
        }
        _periodFinished = now + WEEKLY_DURATION;
        weeklyReward = tokensNeeded; // This is this week's distribution
        rebalancePoolRewards(true); // The pools will determine their reward rates based on profit
        
        {
            // Reset the profits for the pools
            StabilizeBank bank = StabilizeBank(stbzBankAddress);
            for(uint256 i = 0; i < activePools.length; i++){
                if(totalPools[activePools[i]].isLpPool == false){
                    bank.resetStrategyRevenue(totalPools[activePools[i]].tokenAddress);
                }
            }
            bank.resetTotalRevenue();
        }
        
        emit NewWeek(_currentWeek,weeklyReward);
    }
    
    function rebalancePoolRewards(bool recalculateFromProfit) internal {
        // This function rebalances the pool rewards based on the weight of the profit in the pools
        uint256 rewardPerSecond = weeklyReward.div(WEEKLY_DURATION);
        if(weeklyReward == 0){ return; } // Can't rebalance if there are no rewards
        uint256 rewardLeft = 0;
        uint256 timeLeft = 0;
        if(now < _periodFinished){
            timeLeft = _periodFinished.sub(now);
            rewardLeft = timeLeft.mul(rewardPerSecond); // The amount of rewards left in this week
        }
        uint256 lpRewardLeft = rewardLeft.mul(rewardPercentLP).div(DIVISION_FACTOR);
        uint256 sbRewardLeft = rewardLeft.sub(lpRewardLeft);
        
        // First figure out the pool splits for the lp tokens
        // LP pools are split evenly
        uint256 length = activePools.length;
        require(length > 0,"No active pools exist on the protocol");
        uint256 totalWeight = 0;
        uint256 mostProfit = 0;
        StabilizeBank bank = StabilizeBank(stbzBankAddress);
        uint256 totalEarned = bank.totalWeeklyRevenue();
        
        uint256 i = 0;
        for(i = 0; i < length; i++){
            if(totalPools[activePools[i]].isLpPool == true){
                totalPools[activePools[i]].poolWeight = 1;
                totalWeight++;
            }else{
                if(recalculateFromProfit == true){
                    totalPools[activePools[i]].poolWeight = 0;
                    // We will recalculate the pool weights from last week profit
                    if(totalEarned == 0){
                        // No earnings, give all pools equal weight
                        totalPools[activePools[i]].poolWeight = 1;
                    }else if(totalPools[activePools[i]].excludedFromWeight == false){
                        // Determine the weights based on the strategy profit to total profit
                        uint256 weight = bank.strategyWeeklyRevenue(totalPools[activePools[i]].tokenAddress);
                        weight = weight.mul(DIVISION_FACTOR).div(totalEarned);
                        if(weight == 0){weight = 1;} // Give this low earning pool a small weight
                        totalPools[activePools[i]].poolWeight = weight;
                    }
                }
                if(totalPools[activePools[i]].poolWeight > mostProfit){
                    // Get the highest weight each time this function is called
                    mostProfit = totalPools[activePools[i]].poolWeight;
                }
            }
        }
        // Now split the lpReward between the pools
        for(i = 0; i < length; i++){
            if(totalPools[activePools[i]].isLpPool == true){
                uint256 rewardPercent = totalPools[activePools[i]].poolWeight.mul(DIVISION_FACTOR).div(totalWeight);
                uint256 poolReward = lpRewardLeft.mul(rewardPercent).div(DIVISION_FACTOR);
                forceUpdateRewardEarned(activePools[i],address(0)); // Update the stored rewards for this pool before changing the rates
                if(timeLeft > 0){
                    totalPools[activePools[i]].rewardRate = poolReward.div(timeLeft); // The rate of return per second for this pool
                }else{
                    totalPools[activePools[i]].rewardRate = 0;
                }
            }
        }
        
        // Now we do the same for the non LP pools
        // Get the total weights first
        totalWeight = 0;
        for(i = 0; i < length; i++){
            if(totalPools[activePools[i]].isLpPool == false){
                if(totalPools[activePools[i]].poolWeight == 0){
                    // For new pools, they get the same weight as the highest earning pool
                    if(mostProfit > 0){
                        totalPools[activePools[i]].poolWeight = mostProfit;
                    }else{
                        totalPools[activePools[i]].poolWeight = 1;
                    }
                }
                totalWeight += totalPools[activePools[i]].poolWeight;
            }
        }

        // Now split the sbReward among the strat pools
        for(i = 0; i < length; i++){
            if(totalPools[activePools[i]].isLpPool == false){
                uint256 rewardPercent = totalPools[activePools[i]].poolWeight.mul(DIVISION_FACTOR).div(totalWeight);
                uint256 poolReward = sbRewardLeft.mul(rewardPercent).div(DIVISION_FACTOR);
                forceUpdateRewardEarned(activePools[i],address(0)); // Update the stored rewards for this pool before changing the rates
                if(timeLeft > 0){
                    totalPools[activePools[i]].rewardRate = poolReward.div(timeLeft); // The rate of return per second for this pool
                }else{
                    totalPools[activePools[i]].rewardRate = 0;
                }               
            }
        }
    }
    
    function forceUpdateRewardEarned(uint256 _pid, address _address) internal updateRewardEarned(_pid, _address) {
        
    }

    function deposit(uint256 _pid, uint256 amount) public updateRewardEarned(_pid, _msgSender()) {
        require(amount > 0, "Cannot deposit 0");
        require(totalPools[_pid].deactivated == false, "This pool is no longer active");
        if(protocolStarted == true && now > _periodFinished){
            // Auto mint new week on first deposit after previous period has ended
            mintNewWeek();
        }
        
        // Calculate the deposit time first based on the amount of tokens deposited
        if(userInfo[_pid][_msgSender()].amount == 0){
            userInfo[_pid][_msgSender()].depositAverageTime = now;
        }else{
            // Take the weighted average
            uint256 timeDiff = now.sub(userInfo[_pid][_msgSender()].depositAverageTime);
            uint256 weight = amount.mul(DIVISION_FACTOR).div(amount.add(userInfo[_pid][_msgSender()].amount));
            timeDiff = timeDiff.mul(weight).div(DIVISION_FACTOR);
            userInfo[_pid][_msgSender()].depositAverageTime = userInfo[_pid][_msgSender()].depositAverageTime.add(timeDiff);
        }
        
        totalPools[_pid].totalSupply = totalPools[_pid].totalSupply.add(amount);
        userInfo[_pid][_msgSender()].amount = userInfo[_pid][_msgSender()].amount.add(amount);
        IERC20 token = IERC20(totalPools[_pid].tokenAddress);
        token.safeTransferFrom(_msgSender(), address(this), amount);
        emit Deposited(_pid, _msgSender(), amount);
    }

    // User can withdraw without claiming reward tokens
    function withdraw(uint256 _pid, uint256 amount) public nonReentrant updateRewardEarned(_pid, _msgSender()) {
        require(amount > 0, "Cannot withdraw 0");
        totalPools[_pid].totalSupply = totalPools[_pid].totalSupply.sub(amount);
        userInfo[_pid][_msgSender()].amount = userInfo[_pid][_msgSender()].amount.sub(amount);
        IERC20 token = IERC20(totalPools[_pid].tokenAddress);
        token.safeTransfer(_msgSender(), amount);
        emit Withdrawn(_pid, _msgSender(), amount);
    }

    // Normally used to exit the contract and claim reward tokens at same time
    function exit(uint256 _pid, uint256 _amount) external {
        withdraw(_pid, _amount);
        getReward(_pid);
    }

    function getReward(uint256 _pid) public updateRewardEarned(_pid, _msgSender()) {
        if(protocolStarted == true && now > _periodFinished){
            // Auto mint new week on first reward claiming after previous period has ended
            mintNewWeek();
        }

        uint256 reward = rewardEarned(_pid,_msgSender());
        if (reward > 0) {
            userInfo[_pid][_msgSender()].unclaimedReward = 0;
            // If it is a normal user and not a blocked smart contract,
            // then the requirement will pass
            if (tx.origin == _msgSender() || blockedContracts[_msgSender()] == false) {
                // Check the contract to make sure the reward exists
                uint256 contractBalance = STBZ.balanceOf(address(this));
                if(contractBalance < reward){ // This prevents a contract with zero balance from locking up
                    reward = contractBalance;
                }
                
                // Subtract the vesting fee and send to bank
                uint256 vestPercent = poolVestedPercent(_pid, _msgSender());
                uint256 vest = 0;
                if(vestPercent > 0){
                    vest = reward.mul(vestPercent).div(DIVISION_FACTOR);
                    // Send this to the buyback bank
                    STBZ.safeApprove(stbzBankAddress, 0);
                    STBZ.safeApprove(stbzBankAddress, vest);
                    StabilizeBank(stbzBankAddress).depositSTBZ(address(0), vest);
                    reward = reward.sub(vest);
                }
                
                STBZ.safeTransfer(_msgSender(), reward);
                emit RewardPaid(_pid, _msgSender(), reward, vest);
            } else {
                emit RewardDenied(_pid, _msgSender(), reward);
            }
        }
    }
    
    // Governance only functions
    function governanceSetBlockedContracts(address _add, bool _blocked) external onlyGovernance {
        // Governance can block contracts from pulling rewards at anytime
        blockedContracts[_add] = _blocked;
    }
    
    function governanceSetWeightOnPool(uint256 _pid, bool _excluded) external onlyGovernance {
        require(_pid < totalPools.length, "ID is too high");
        totalPools[_pid].excludedFromWeight = _excluded;
    }
    
    /// A push mechanism for accounts that have not claimed their rewards for a long time.
    function pushReward(uint256 _pid, address recipient) external updateRewardEarned(_pid, recipient) onlyGovernance {
        uint256 reward = rewardEarned(_pid,recipient);
        if (reward > 0) {
            userInfo[_pid][recipient].unclaimedReward = 0;
            // If it is a normal user and not a blocked smart contract,
            // then the requirement will pass
            if (!recipient.isContract() || blockedContracts[recipient] == false) {
                uint256 contractBalance = STBZ.balanceOf(address(this));
                if(contractBalance < reward){ // This prevents a contract with zero balance locking up
                    reward = contractBalance;
                }
                STBZ.safeTransfer(recipient, reward);
                emit RewardPaid(_pid, recipient, reward, 0);
            } else {
                emit RewardDenied(_pid, recipient, reward);
            }
        }
    }
    
    // Timelock variables
    // Timelock doesn't activate until protocol has started to distribute rewards
    
    uint256 private _timelockStart; // The start of the timelock to change governance variables
    uint256 private _timelockType; // The function that needs to be changed
    uint256 constant TIMELOCK_DURATION = 86400; // Timelock is 24 hours
    
    // Reusable timelock variables
    uint256 private _timelock_data;
    address private _timelock_address;
    bool private _timelock_bool;
    
    modifier timelockConditionsMet(uint256 _type) {
        require(_timelockType == _type, "Timelock not acquired for this function");
        _timelockType = 0; // Reset the type once the timelock is used
        if(protocolStarted == true){
            // Timelock is only required after the protocol starts
            require(now >= _timelockStart + TIMELOCK_DURATION, "Timelock time not met");
        }
        _;
    }
    
    // Change the owner of the Operator contract
    // --------------------
    function startGovernanceChange(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 1;
        _timelock_address = _address;       
    }
    
    function finishGovernanceChange() external onlyGovernance timelockConditionsMet(1) {
        emit GovernorChanged(governance(), _timelock_address);
        _transferGovernance(_timelock_address);
    }
    // --------------------
    
    // Change the amount of time required to vest
    // --------------------
    function startChangeVestTime(uint256 _time) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 2;
        _timelock_data = _time;
    }
    
    function finishChangeVestTime() external onlyGovernance timelockConditionsMet(2) {
        vestTime = _timelock_data;
    }
    // --------------------
    
    // Change the weekly inflation
    // --------------------
    function startChangeWeeklyInflation(uint256 _amount) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 3;
        _timelock_data = _amount;
    }
    
    function finishChangeWeeklyInflation() external onlyGovernance timelockConditionsMet(3) {
        weeklyInflation = _timelock_data;
    }
    // --------------------

    // Change the percent of rewards that is dedicated to LP providers
    // --------------------
    function startChangeRewardPercentLP(uint256 _percent) external onlyGovernance {
        require(_percent <= 100000, "Percent is too high");
        _timelockStart = now;
        _timelockType = 4;
        _timelock_data = _percent;
    }
    
    function finishChangeRewardPercentLP() external onlyGovernance timelockConditionsMet(4) {
        rewardPercentLP = _timelock_data;
    }
    // --------------------
   
    // Add a new token to the pool
    // --------------------
    function startAddNewPool(address _address, bool _lpPool) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 5;
        _timelock_address = _address;
        _timelock_bool = _lpPool;
        if(protocolStarted == false){
            finishAddNewPool(); // Automatically add the pool if protocol hasn't started yet
        }
    }
    
    function finishAddNewPool() public onlyGovernance timelockConditionsMet(5) {
        // This adds a new pool to the pool lists
        totalPools.push(
            PoolInfo({
                tokenAddress: _timelock_address,
                poolID: poolLength(),
                isLpPool: _timelock_bool,
                rewardRate: 0,
                rewardPerTokenStored: 0,
                lastUpdateTime: 0,
                totalSupply: 0,
                poolWeight: 0,
                deactivated: false,
                excludedFromWeight: true
            })
        );
    }
    // --------------------
    
    // Select a pool to activate in rewards distribution
    // --------------------
    function startAddActivePool(uint256 _pid) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 6;
        _timelock_data = _pid;
    }
    
    function finishAddActivePool() external onlyGovernance timelockConditionsMet(6) {
        require(totalPools[_timelock_data].rewardRate == 0, "This pool is already earning rewards");
        activePools.push(_timelock_data);
        totalPools[_timelock_data].deactivated = false;
        // Rebalance the pools now that there is a new pool
        if(protocolStarted == true){
            rebalancePoolRewards(false);
        }
    }
    // --------------------
    
    // Select a pool to deactivate from rewards distribution
    // --------------------
    function startRemoveActivePool(uint256 _pid) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 7;
        _timelock_data = _pid;
    }
    
    function finishRemoveActivePool() external onlyGovernance timelockConditionsMet(7) updateRewardEarned(_timelock_data, address(0)) {
        uint256 length = activePools.length;
        for(uint256 i = 0; i < length; i++){
            if(totalPools[activePools[i]].poolID == _timelock_data){
                // Move all the remaining elements down one
                // Remove any earned revenue from the calculations
                StabilizeBank(stbzBankAddress).resetStrategyRevenue(totalPools[activePools[i]].tokenAddress);
                totalPools[activePools[i]].deactivated = true;
                totalPools[activePools[i]].rewardRate = 0; // Deactivate rewards but first make sure to store current rewards
                for(uint256 i2 = i; i2 < length-1; i2++){
                    activePools[i2] = activePools[i2 + 1]; // Shift the data down one
                }
                activePools.pop(); //Remove last element
                break;
            }
        }
        // Rebalance the remaining pools 
        if(protocolStarted == true){
            rebalancePoolRewards(false);
        }
    }
    // --------------------
    
    // Change the treasury
    // --------------------
    function startChangeDeveloperTreasury(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 8;
        _timelock_address = _address;       
    }
    
    function finishChangeDeveloperTreasury() external onlyGovernance timelockConditionsMet(8) {
        developerTreasuryAddress = _timelock_address;
    }
    // --------------------
    
    // Change the bank
    // --------------------
    function startChangeSTBZBank(address _address) external onlyGovernance {
        _timelockStart = now;
        _timelockType = 9;
        _timelock_address = _address;       
    }
    
    function finishChangeSTBZBank() external onlyGovernance timelockConditionsMet(9) {
        stbzBankAddress = _timelock_address;
    }
    // --------------------
}