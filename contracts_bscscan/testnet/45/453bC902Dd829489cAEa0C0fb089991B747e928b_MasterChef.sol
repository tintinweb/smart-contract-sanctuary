/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

interface TokenAmountLike {
    // get the token0 amount from the token1 amount
    function getTokenAmount(address _token0, address _token1, uint256 _token1Amount) external view returns (uint256);
}

/**
 * @title Helps contracts guard agains rentrancy attacks.
 * @author Remco Bloemen <[email protected]¦Ð.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

    /**
     * @dev We use a single lock for the whole contract.
     */
    bool private rentrancy_lock = false;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * @notice If you mark a function `nonReentrant`, you should also
     * mark it `external`. Calling one nonReentrant function from
     * another is not supported. Instead, you can implement a
     * `private` function doing the actual work, and a `external`
     * wrapper marked as `nonReentrant`.
     */
    modifier nonReentrant() {
        require(!rentrancy_lock);
        rentrancy_lock = true;
        _;
        rentrancy_lock = false;
    }

}

// MasterChef is the master of Maison. He can make Maison and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once MAISON is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.

contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 initialAmount;
        //
        // We do some fancy math here. Basically, any point in time, the amount of Maisons
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMaisonPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accMaisonPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        uint256 oldRewardDebt;
        uint256 unlockTime;
        uint256 withdrawablePerTime;
        uint256 withdrawTX;
        uint256 underclaimed;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract, zero represents HT pool.
        uint256 amount;     // How many LP tokens the pool has.
        uint256 rewardForEachBlock;    //Reward for each block
        uint256 lastRewardBlock;  // Last block number that MSNs distribution occurs.
        uint256 accMaisonPerShare; // Accumulated MSN per share, times 1e12. See below.
        uint256 startBlock; // Reward start block.
        uint256 endBlock;  // Reward end block.
        uint256 rewarded;// the total MSN has beed reward, including the dev and user harvest

        bool lockEnabled; // true if pool has vesting enabled
        uint256 vestingTime; // time of initial vesting
        uint256 unlockPeriod; // time between withdrawals
        uint256 lastDepositBlock;
    }

    uint256 private constant ACC_MAISON_PRECISION = 1e18;

    uint8 public constant ZERO = 0;
    uint16 public constant RATIO_BASE = 1000;

    // bool public emergencyWithdrawal = false;
    // uint256 public emergencyWithdrawalAmount;

    // The MSN TOKEN!
    IERC20 public maison;
    // Dev address.

    TokenAmountLike public tokenAmountContract;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event HarvestAndRestake(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyStop(address indexed user, address to);
    event Add(uint256 rewardForEachBlock, IERC20 lpToken, bool withUpdate,
        uint256 startBlock, uint256 endBlock, bool LockEnabled, bool withMaisonTransfer);
    event SetPoolInfo(uint256 pid, uint256 rewardsOneBlock, bool withUpdate, uint256 startBlock, uint256 endBlock, bool lockEnabled);
    event ClosePool(uint256 pid, address payable to);

    event AddRewardForPool(uint256 pid, uint256 addMaisonPerPool, bool withMaisonTransfer);

    event SetTokenAmountContract(TokenAmountLike tokenAmountContract);

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo .length, "Pool does not exist");
        _;
    }

    constructor(
        IERC20 _maison,
        TokenAmountLike _tokenAmountContract
    ) {
        maison = _maison;
        tokenAmountContract = _tokenAmountContract;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setTokenAmountContract(TokenAmountLike _tokenAmountContract) external onlyOwner {
        require(_tokenAmountContract != TokenAmountLike(address(0)), "tokenAmountContract can not be zero!");
        tokenAmountContract = _tokenAmountContract;
        emit SetTokenAmountContract(_tokenAmountContract);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // Zero lpToken represents HT pool.
    function add(uint256 _totalReward, IERC20 _lpToken, bool _withUpdate,
        uint256 _startBlock, uint256 _endBlock, bool _lockEnabled, uint256 _vestingTime, uint256 _unlockPeriod, bool _withMaisonTransfer) external onlyOwner {
        //require(_lpToken != IERC20(ZERO), "lpToken can not be zero!");
        require(_totalReward > ZERO, "rewardForEachBlock must be greater than zero!");
        require(_startBlock < _endBlock, "start block must less than end block!");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 _rewardForEachBlock = _totalReward.div(_endBlock.sub(_startBlock));
        uint256 _lastDepositBlock;
        if (_lockEnabled) {
            _lastDepositBlock = _endBlock.sub(_vestingTime.div(3).add(_unlockPeriod.mul(50).div(3)));
        }
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            amount : ZERO,
            rewardForEachBlock : _rewardForEachBlock,
            lastRewardBlock : block.number > _startBlock ? block.number : _startBlock,
            accMaisonPerShare : ZERO,
            startBlock : _startBlock,
            endBlock : _endBlock,
            rewarded : ZERO,
            lockEnabled: _lockEnabled,
            vestingTime: _vestingTime,
            unlockPeriod: _unlockPeriod,
            lastDepositBlock: _lastDepositBlock
        }));
        if (_withMaisonTransfer) {
            uint256 amount = (_endBlock - (block.number > _startBlock ? block.number : _startBlock)).mul(_rewardForEachBlock);
            maison.safeTransferFrom(msg.sender, address(this), amount);
        }
        emit Add(_rewardForEachBlock, _lpToken, _withUpdate, _startBlock, _endBlock, _lockEnabled, _withMaisonTransfer);
    }

    // Update the given pool's pool info. Can only be called by the owner. 
    function setPoolInfo(uint256 _pid, uint256 _rewardForEachBlock, bool _withUpdate, uint256 _startBlock, uint256 _endBlock, bool _lockEnabled, uint256 _vestingTime, uint256 _unlockPeriod) external validatePoolByPid(_pid) onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        PoolInfo storage pool = poolInfo[_pid];
        if (_startBlock > ZERO) {
            if (_endBlock > ZERO) {
                require(_startBlock < _endBlock, "start block must less than end block!");
            } else {
                require(_startBlock < pool.endBlock, "start block must less than end block!");
            }
            pool.startBlock = _startBlock;
        }
        if (_endBlock > ZERO) {
            if (_startBlock <= ZERO) {
                require(pool.startBlock < _endBlock, "start block must less than end block!");
            }
            pool.endBlock = _endBlock;
        }
        if (_rewardForEachBlock > ZERO) {
            pool.rewardForEachBlock = _rewardForEachBlock;
        }
        pool.lockEnabled = _lockEnabled;
        if (_lockEnabled) {
            pool.vestingTime = _vestingTime;
            pool.unlockPeriod = _unlockPeriod;
            pool.lastDepositBlock = _endBlock.sub(_vestingTime.div(3).add(_unlockPeriod.mul(50).div(3)));
        }
        emit SetPoolInfo(_pid, _rewardForEachBlock, _withUpdate, _startBlock, _endBlock, _lockEnabled);
    }

    function migrate(uint256 _pid, address[] memory _address, uint256[] memory _amount, uint256[] memory _oldReward, uint256[] memory _unlockTime) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        for (uint256 i=0; i < _address.length; i++) {
            pool.amount = pool.amount.add(_amount[i]);
            UserInfo storage user = userInfo[_pid][_address[i]];
            user.amount = _amount[i];
            user.initialAmount = _amount[i];
            user.oldRewardDebt = _oldReward[i];
            user.unlockTime = _unlockTime[i];
            user.withdrawablePerTime = user.amount.div(50);
            user.withdrawTX = 0;
            user.underclaimed = 0;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        if (_to > _from) {
            return _to.sub(_from);
        }
        return ZERO;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (block.number < pool.startBlock) {
            return;
        }
        if (pool.lastRewardBlock >= pool.endBlock) {
            return;
        }
        if (pool.lastRewardBlock < pool.startBlock) {
            pool.lastRewardBlock = pool.startBlock;
        }
        uint256 multiplier;
        if (block.number > pool.endBlock) {
            multiplier = getMultiplier(pool.lastRewardBlock, pool.endBlock);
            pool.lastRewardBlock = pool.endBlock;
        } else {
            multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            pool.lastRewardBlock = block.number;
        }
        uint256 lpSupply = pool.amount;
        if (lpSupply <= ZERO) {
            return;
        }
        uint256 maisonReward = multiplier.mul(pool.rewardForEachBlock);
        if (maisonReward > ZERO) {
            uint256 poolMaisonReward = maisonReward;
            pool.accMaisonPerShare = pool.accMaisonPerShare.add(poolMaisonReward.mul(ACC_MAISON_PRECISION).div(lpSupply));
        }
    }

    // View function to see pending MSNs on frontend.
    function pendingMaisons(uint256 _pid, address _user) public view validatePoolByPid(_pid) returns (uint256 maisonReward) {
        PoolInfo storage pool = poolInfo[_pid];
        if (_user == address(0)) {
            _user = msg.sender;
        }
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMaisonPerShare = pool.accMaisonPerShare;
        uint256 lpSupply = pool.amount;
        uint256 lastRewardBlock = pool.lastRewardBlock;
        if (lastRewardBlock < pool.startBlock) {
            lastRewardBlock = pool.startBlock;
        }
        if (block.number > lastRewardBlock && block.number >= pool.startBlock && lastRewardBlock < pool.endBlock && lpSupply > ZERO) {
            uint256 multiplier = ZERO;
            if (block.number > pool.endBlock) {
                multiplier = getMultiplier(lastRewardBlock, pool.endBlock);
            } else {
                multiplier = getMultiplier(lastRewardBlock, block.number);
            }
            uint256 poolMaisonReward = multiplier.mul(pool.rewardForEachBlock).div(RATIO_BASE);
            accMaisonPerShare = accMaisonPerShare.add(poolMaisonReward.mul(ACC_MAISON_PRECISION).div(lpSupply));
        }
        if (user.oldRewardDebt != 0) {
            maisonReward = user.amount.mul(accMaisonPerShare).div(ACC_MAISON_PRECISION).sub(user.rewardDebt).add(user.oldRewardDebt);
        } else {
            maisonReward = user.amount.mul(accMaisonPerShare).div(ACC_MAISON_PRECISION).sub(user.rewardDebt);
        }
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = ZERO; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function harvestAndRestake(uint256 _pid) public nonReentrant payable validatePoolByPid(_pid) returns (uint256 restakeAmount, bool success) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 _oldRewardDebt = 0;
        if (user.oldRewardDebt != 0) {
            _oldRewardDebt = user.oldRewardDebt;
        }
        uint256 pending = user.amount.mul(pool.accMaisonPerShare).div(ACC_MAISON_PRECISION).sub(user.rewardDebt);
        uint256 pendingWOld = user.amount.mul(pool.accMaisonPerShare).div(ACC_MAISON_PRECISION).sub(user.rewardDebt).add(_oldRewardDebt);
        if (pendingWOld > ZERO) {
            // success = true;
            // safeTransferTokenFromThis(maison, _to, pending);
            user.oldRewardDebt = 0;
            pool.rewarded = pool.rewarded.add(pending);
            user.rewardDebt = user.amount.mul(pool.accMaisonPerShare).div(ACC_MAISON_PRECISION);
            restakeAmount = pendingWOld;
        } else {
            success = false;
        }
        require(block.number <= pool.endBlock, "this pool has ended!");
        require(block.number >= pool.startBlock, "this pool has not started!");
        if (pool.lockEnabled) {
            require(block.number < pool.lastDepositBlock);
        }
        pool.amount = pool.amount.add(restakeAmount);
        user.amount = user.amount.add(restakeAmount);
        user.initialAmount = user.amount;
        if (pool.lockEnabled) {
            user.unlockTime = block.timestamp + pool.vestingTime;
            user.withdrawTX = 0;
            user.withdrawablePerTime = user.amount.div(50);
            user.underclaimed = 0;
        }
        user.rewardDebt = user.amount.mul(pool.accMaisonPerShare).div(ACC_MAISON_PRECISION);
        success = true;

        emit HarvestAndRestake(msg.sender, _pid, restakeAmount);
    }

    // Deposit LP tokens to MasterChef for MSN allocation.
    function deposit(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) payable {
        PoolInfo storage pool = poolInfo[_pid];
        require(block.number <= pool.endBlock, "this pool has ended!");
        require(block.number >= pool.startBlock, "this pool has not started!");
        if (pool.lpToken == IERC20(address(0))) {//if pool is HT
            require(_amount == msg.value, "msg.value must be equals to amount!");
        }
        if (pool.lockEnabled) {
            require(block.number < pool.lastDepositBlock);
        }
        UserInfo storage user = userInfo[_pid][msg.sender];
        harvest(_pid, msg.sender);
        if (pool.lpToken != IERC20(address(0))) {
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        }
        pool.amount = pool.amount.add(_amount);
        user.amount = user.amount.add(_amount);
        user.initialAmount = user.amount;
        if (pool.lockEnabled) {
            user.unlockTime = block.timestamp + pool.vestingTime;
            user.withdrawTX = 0;
            user.withdrawablePerTime = user.amount.div(50);
            user.underclaimed = 0;
        }
        user.rewardDebt = user.amount.mul(pool.accMaisonPerShare).div(ACC_MAISON_PRECISION);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function isMainnetToken(address _token) private pure returns (bool) {
        return _token == address(0);
    }

    function getClaimCycle(uint256 _pid, address _address) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.lockEnabled, "Vesting is disabled for this pool");
        UserInfo storage user = userInfo[_pid][_address];
        if (user.unlockTime > block.timestamp) {
            return ZERO;
        }
        uint256 _timeShare = 1 + (block.timestamp.sub(user.unlockTime)).div(pool.unlockPeriod);
        if (_timeShare >= 50) {
            _timeShare = 50;
        }
        uint256 userWithdrawTX = user.withdrawTX;
        if (userWithdrawTX > 50) {
            userWithdrawTX = 50;
        }
        uint256 _userCyclesToClaim = _timeShare - userWithdrawTX;
        return _userCyclesToClaim;
    }

    function getUserWithdrawableAmount(uint256 _pid, address _address) public view returns (uint256, uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.lockEnabled, "Vesting is disabled for this pool");
        UserInfo storage user = userInfo[_pid][_address];
        uint256 _userCyclesToClaim = getClaimCycle(_pid, _address);
        uint256 _withdrawableAmount;
        _withdrawableAmount = _userCyclesToClaim.mul(user.withdrawablePerTime).add(user.underclaimed);
        if (_withdrawableAmount > user.amount) {
            _withdrawableAmount = user.amount;
        }
        if (_userCyclesToClaim == ZERO) {
            _withdrawableAmount = user.underclaimed;
        }
        return (_withdrawableAmount, _userCyclesToClaim);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) payable {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.number >= pool.startBlock, "this pool has not started!");
        require(user.amount >= _amount, "withdraw: not good");
        if (pool.lockEnabled) {
            require(user.unlockTime <= block.timestamp);
            (uint256 _maxWithdrawable, uint256 _userCyclesToClaim) = getUserWithdrawableAmount(_pid, msg.sender);
            require(_maxWithdrawable > ZERO);
            require(_amount <= _maxWithdrawable, "Withdraw: Not unlocked yet");
            
            // if (_amount != _maxWithdrawable) {
            //     uint256 _temprealClaimCycle = _realClaimCycle.add(1);
            //     uint256 _diffInAmounts = (_temprealClaimCycle.mul(user.withdrawablePerTime)).sub(_amount);
            //     if (_maxWithdrawable == 0) {
            //         _diffInAmounts = user.underclaimed.sub(_amount);
            //     }
            //     // user.underclaimed = _diffInAmounts;
            // }
            if (_userCyclesToClaim != 0) {
                    user.withdrawTX += _userCyclesToClaim;
            }
        }
        harvest(_pid, msg.sender);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accMaisonPerShare).div(ACC_MAISON_PRECISION);
        pool.amount = pool.amount.sub(_amount);

        user.underclaimed = user.amount.sub(user.initialAmount.sub(user.withdrawablePerTime.mul(user.withdrawTX)));

        if (pool.lpToken != IERC20(address(0))) {
            pool.lpToken.safeTransfer(msg.sender, _amount);
        } else {//if pool is HT
            transferMainnetToken(payable(msg.sender), _amount);
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    //transfer HT
    function transferMainnetToken(address payable _to, uint256 _amount) internal nonReentrant {
        _to.transfer(_amount);
    }

    // function setEmergencyWithdrawal(uint256 _amount, bool _value) public onlyOwner {
    //     emergencyWithdrawal = _value;
    //     emergencyWithdrawalAmount = _amount;
    // }

    // // Withdraw without caring about rewards. EMERGENCY ONLY.
    // function emergencyWithdraw(uint256 _pid) external payable  validatePoolByPid(_pid){
    //     require(emergencyWithdrawal, "Emergency Withdrawal: Function not active");
    //     require(msg.value >= emergencyWithdrawalAmount, "Cheeky");
    //     msg.sender.safeTransfer(payable(_owner), emergencyWithdrawalAmount);
    //     PoolInfo storage pool = poolInfo[_pid];
    //     UserInfo storage user = userInfo[_pid][msg.sender];
    //     pool.amount = pool.amount.sub(user.amount);
    //     uint256 oldAmount = user.amount;
    //     user.amount = ZERO;
    //     user.rewardDebt = ZERO;
    //     if (pool.lpToken != IERC20(address(0))) {
    //         pool.lpToken.safeTransfer(msg.sender, user.amount);
    //     } else {//if pool is HT
    //         transferMainnetToken(payable(msg.sender), user.amount);
    //     }
    //     emit EmergencyWithdraw(msg.sender, _pid, oldAmount);
    // }

    function harvest(uint256 _pid, address _to) public nonReentrant payable validatePoolByPid(_pid) returns (bool success) {
        if (_to == address(0)) {
            _to = msg.sender;
        }
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];
        updatePool(_pid);
        uint256 _oldRewardDebt = 0;
        if (user.oldRewardDebt != 0) {
            _oldRewardDebt = user.oldRewardDebt;
        }
        uint256 pending = user.amount.mul(pool.accMaisonPerShare).div(ACC_MAISON_PRECISION).sub(user.rewardDebt);
        uint256 pendingWOld = user.amount.mul(pool.accMaisonPerShare).div(ACC_MAISON_PRECISION).sub(user.rewardDebt).add(_oldRewardDebt);
        if (pendingWOld > ZERO) {
            success = true;
            user.oldRewardDebt = 0;
            safeTransferTokenFromThis(maison, _to, pendingWOld);
            pool.rewarded = pool.rewarded.add(pending);
            user.rewardDebt = user.amount.mul(pool.accMaisonPerShare).div(ACC_MAISON_PRECISION);
        } else {
            success = false;
        }
        emit Harvest(_to, _pid, pending);
    }

    function emergencyStop(address payable _to) public onlyOwner {
        if (_to == address(0)) {
            _to = payable(msg.sender);
        }
        uint addrBalance = maison.balanceOf(address(this));
        if (addrBalance > ZERO) {
            maison.safeTransfer(_to, addrBalance);
        }
        uint256 length = poolInfo.length;
        for (uint256 pid = ZERO; pid < length; ++pid) {
            closePool(pid, _to);
        }
        emit EmergencyStop(msg.sender, _to);
    }

    function closePool(uint256 _pid, address payable _to) public validatePoolByPid(_pid) onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.endBlock = block.number;
        if (_to == address(0)) {
            _to = payable(msg.sender);
        }
        emit ClosePool(_pid, _to);
    }

    // Safe transfer token function, just in case if rounding error causes pool to not have enough tokens.
    function safeTransferTokenFromThis(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 bal = _token.balanceOf(address(this));
        if (_amount > bal) {
            _token.safeTransfer(_to, bal);
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }

    // Add reward for pool from the current block or start block
    function addRewardForPool(uint256 _pid, uint256 _addMaisonPerPool, bool _withMaisonTransfer) external validatePoolByPid(_pid) onlyOwner {
        require(_addMaisonPerPool > ZERO, "add MSN must be greater than zero!");
        PoolInfo storage pool = poolInfo[_pid];
        require(block.number < pool.endBlock, "this pool has ended!");
        updatePool(_pid);

        uint256 addMaisonPerBlock;
        if (block.number < pool.startBlock) {
            addMaisonPerBlock = _addMaisonPerPool.div(pool.endBlock.sub(pool.startBlock));
        } else {
            addMaisonPerBlock = _addMaisonPerPool.div(pool.endBlock.sub(block.timestamp));
        }

        pool.rewardForEachBlock = pool.rewardForEachBlock.add(addMaisonPerBlock);
        if (_withMaisonTransfer) {
            maison.safeTransferFrom(msg.sender, address(this), _addMaisonPerPool);
        }
        emit AddRewardForPool(_pid, _addMaisonPerPool, _withMaisonTransfer);
    }
}