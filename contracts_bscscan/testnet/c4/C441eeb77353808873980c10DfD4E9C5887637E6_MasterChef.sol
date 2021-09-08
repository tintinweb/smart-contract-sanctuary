/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BaseMath {
    uint constant public DECIMAL_PRECISION = 1e18;
}
/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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

contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        _owner = msg.sender;
       
        emit OwnershipTransferred(address(0), msg.sender);
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
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @title Helps contracts guard agains rentrancy attacks.
 * @author Remco Bloemen
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

interface TokenAmountLike {
    // get the token0 amount from the token1 amount
    function getTokenAmount(address _token0, address _token1, uint256 _token1Amount)  external view returns (uint256);
}

interface LockToken{
    function lock(address _forUser, uint256 _amount, uint256 _lockTokenBlockNumber) external  returns (uint256 _id);
    function minimumLockAmount()external returns (uint256 min);
}

// MasterChef is the master of Sushi. He can make Sushi and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.

contract MasterChef is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract, zero represents mainnet coin pool.
        uint256 amount;     // How many LP tokens the pool has.
        uint256 rewardForEachBlock;    //Reward for each block
        uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
        uint256 startBlock; // Reward start block.
        uint256 endBlock;  // Reward end block.
        uint256 rewarded;// the total sushi has beed reward, including the dev and user harvest
        uint256 operationFee;// Charged when user operate the pool, only deposit.
        //address operationFeeToken;// empty reprsents charged with mainnet token.
        uint16 harvestFeeRatio;// Charged when harvest, div RATIO_BASE for the real ratio, like 100 for 10%
        address harvestFeeToken;// empty reprsents charged with mainnet token.
        bool rewardDev;// if reward dev when reward the farmers.
        bool rewardLocked; //if reward locked token or not, true for LockToken, false for token
    }
    
    uint256 private constant ACC_SUSHI_PRECISION = 1e12;
    uint8 public constant ZERO = 0 ;
    uint16 public constant RATIO_BASE = 1000;
    uint8 public constant DEV1_SUSHI_REWARD_RATIO = 140;// div RATIO_BASE
    uint8 public constant DEV2_SUSHI_REWARD_RATIO = 37;// div RATIO_BASE
    uint8 public constant DEV3_SUSHI_REWARD_RATIO = 23;// div RATIO_BASE
    uint16 public constant MINT_SUSHI_REWARD_RATIO = 800;// div RATIO_BASE
    uint16 public constant DEV1_FEE_RATIO = 500;// div RATIO_BASE
    uint16 public constant DEV2_FEE_RATIO = 250;// div RATIO_BASE
    uint16 public constant DEV3_FEE_RATIO = 250;// div RATIO_BASE
    uint16 public harvestFeeDevRatio = 100;// the dev ratio for harvest, div RATIO_BASE, RATIO_BASE - dev ratio is for buy
    
    // The SUSHI TOKEN!
    IERC20 public sushi;
    // Dev address.
    address payable public dev1Address;
    address payable public dev2Address;
    address payable public dev3Address;
    address payable public buyAddress;// address for the fee to buy HKR
    uint256 public lockBlockNumber = 864000;
    TokenAmountLike public tokenAmountContract;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    LockToken public lockToken;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyStop(address indexed user, address to);
    event Add(uint256 rewardForEachBlock, IERC20 lpToken, bool withUpdate, 
    uint256 startBlock, uint256 endBlock, uint256 operationFee, 
    uint16 harvestFeeRatio, address harvestFeeToken, bool withSushiTransfer, bool rewardDev);
    event SetPoolInfo(uint256 pid, uint256 rewardsOneBlock, bool withUpdate, uint256 startBlock, uint256 endBlock, bool rewardDev, bool rewardLocked);
    event ClosePool(uint256 pid, address payable to);
    event UpdateDev1Address(address payable dev1Address);
    event UpdateDev2Address(address payable dev2Address);
    event UpdateDev3Address(address payable dev3Address);
    event UpdateBuyAddress(address payable buyAddress);
    event AddRewardForPool(uint256 pid, uint256 addSushiPerPool, uint256 addSushiPerBlock, bool withSushiTransfer);
    event SetPoolOperationFee(uint256 pid, uint256 operationFee);
    event SetPoolHarvestFee(uint256 pid, uint16 harvestFeeRatio, address harvestFeeToken, bool feeRatioUpdate, bool feeTokenUpdate);
    event SetTokenAmountContract(TokenAmountLike tokenAmountContract);
    event SetHarvestFeeRatio(uint16 harvestFeeDevRatio);
    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo .length, "Pool does not exist");
        _;
    }

    constructor(
        IERC20 _sushi,
        address payable _dev1Address,
        address payable _dev2Address,
        address payable _dev3Address,
        address payable _buyAddress,
        TokenAmountLike _tokenAmountContract,
        LockToken _lockToken,
        uint256 _lockBlockNumber
    )  {
        sushi = _sushi;
        dev1Address = _dev1Address;
        dev2Address = _dev2Address;
        dev3Address = _dev3Address;
        buyAddress = _buyAddress;
        tokenAmountContract = _tokenAmountContract;
        lockToken = _lockToken;
        lockBlockNumber = _lockBlockNumber;
        }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    function setLockBlockNumber(uint256 _lockBlockNumber)external onlyOwner{
        lockBlockNumber = _lockBlockNumber;
    }
    
    function setTokenAmountContract(TokenAmountLike _tokenAmountContract) external onlyOwner {
        require(_tokenAmountContract != TokenAmountLike(address(0)), "tokenAmountContract can not be zero!");
        tokenAmountContract = _tokenAmountContract;
        emit SetTokenAmountContract(_tokenAmountContract);
    }
    
    // Update the harvest fee ratio
    function setHarvestFeeRatio(uint16 _harvestFeeDevRatio) external onlyOwner {
        require(_harvestFeeDevRatio <= RATIO_BASE, "The _harvestFeeDevRatio must be less than or equals 1000!");
        harvestFeeDevRatio = _harvestFeeDevRatio;
        emit SetHarvestFeeRatio(_harvestFeeDevRatio);
    }
    
    // Add a new lp to the pool. Can only be called by the owner.
    // Zero lpToken represents mainnet coin pool.
    function add(uint256 _rewardForEachBlock, IERC20 _lpToken, bool _withUpdate, 
        uint256 _startBlock, uint256 _endBlock, uint256 _operationFee, 
        uint16 _harvestFeeRatio, address _harvestFeeToken, bool _withSushiTransfer, bool _rewardDev, bool _rewardLocked) external onlyOwner {
        //require(_lpToken != IERC20(ZERO), "lpToken can not be zero!");
        require(_rewardForEachBlock > ZERO, "rewardForEachBlock must be greater than zero!");
        require(_startBlock < _endBlock, "start block must less than end block!");
        if (_withUpdate) {
            massUpdatePools();
        }
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            amount: ZERO,
            rewardForEachBlock: _rewardForEachBlock,
            lastRewardBlock: block.number > _startBlock ? block.number : _startBlock,
            accSushiPerShare: ZERO,
            startBlock: _startBlock,
            endBlock: _endBlock,
            rewarded: ZERO,
            operationFee: _operationFee,
            //operationFeeToken: _operationFeeToken,
            harvestFeeRatio: _harvestFeeRatio,
            harvestFeeToken: _harvestFeeToken,
            rewardDev: _rewardDev,
            rewardLocked: _rewardLocked
        }));
        if(_withSushiTransfer){
            uint256 amount = (_endBlock - (block.number > _startBlock ? block.number : _startBlock)).mul(_rewardForEachBlock);
            sushi.safeTransferFrom(msg.sender, address(this), amount);
        }
        emit Add(_rewardForEachBlock, _lpToken, _withUpdate, _startBlock, _endBlock, _operationFee, _harvestFeeRatio, _harvestFeeToken, _withSushiTransfer, _rewardDev);
    }

    // Update the given pool's pool info. Can only be called by the owner. 
    function setPoolInfo(uint256 _pid, uint256 _rewardForEachBlock, bool _withUpdate, uint256 _startBlock, uint256 _endBlock, bool _rewardDev, bool _rewardLocked) external validatePoolByPid(_pid) onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        PoolInfo storage pool = poolInfo[_pid];
        if(_startBlock > ZERO){
            if(_endBlock > ZERO){
                require(_startBlock < _endBlock, "start block must less than end block!");
            }else{
                require(_startBlock < pool.endBlock, "start block must less than end block!");
            }
            pool.startBlock = _startBlock;
        }
        if(_endBlock > ZERO){
            if(_startBlock <= ZERO){
                require(pool.startBlock < _endBlock, "start block must less than end block!");
            }
            pool.endBlock = _endBlock;
        }
        if(_rewardForEachBlock > ZERO){
            pool.rewardForEachBlock = _rewardForEachBlock;
        }
        pool.rewardDev = _rewardDev;
        pool.rewardLocked = _rewardLocked;
        emit SetPoolInfo(_pid, _rewardForEachBlock, _withUpdate, _startBlock, _endBlock, _rewardDev, _rewardLocked);
    }
    
    function setAllPoolOperationFee(uint256 _operationFee) external onlyOwner {
        uint256 length = poolInfo.length;
        for (uint256 pid = ZERO; pid < length; ++ pid) {
            setPoolOperationFee(pid, _operationFee);
        }
    }
    
    // Update the given pool's operation fee
    function setPoolOperationFee(uint256 _pid, uint256 _operationFee) public validatePoolByPid(_pid) onlyOwner {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        pool.operationFee = _operationFee;
        emit SetPoolOperationFee(_pid, _operationFee);
    }
    
    function setAllPoolHarvestFee(uint16 _harvestFeeRatio, address _harvestFeeToken, bool _feeRatioUpdate, bool _feeTokenUpdate) external onlyOwner {
        uint256 length = poolInfo.length;
        for (uint256 pid = ZERO; pid < length; ++ pid) {
            setPoolHarvestFee(pid, _harvestFeeRatio, _harvestFeeToken, _feeRatioUpdate, _feeTokenUpdate);
        }
    }
    
    // Update the given pool's harvest fee
    function setPoolHarvestFee(uint256 _pid, uint16 _harvestFeeRatio, address _harvestFeeToken, bool _feeRatioUpdate, bool _feeTokenUpdate) public validatePoolByPid(_pid) onlyOwner {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        if(_feeRatioUpdate){
            pool.harvestFeeRatio = _harvestFeeRatio;
        }
        if(_feeTokenUpdate){
            pool.harvestFeeToken = _harvestFeeToken;
        }
        emit SetPoolHarvestFee(_pid, _harvestFeeRatio, _harvestFeeToken, _feeRatioUpdate, _feeTokenUpdate);
    }
    
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        if(_to > _from){
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
        if (block.number < pool.startBlock){
            return;
        }
        if (pool.lastRewardBlock >= pool.endBlock){
             return;
        }
        if (pool.lastRewardBlock < pool.startBlock) {
            pool.lastRewardBlock = pool.startBlock;
        }
        uint256 multiplier;
        if (block.number > pool.endBlock){
            multiplier = getMultiplier(pool.lastRewardBlock, pool.endBlock);
            pool.lastRewardBlock = pool.endBlock;
        }else{
            multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            pool.lastRewardBlock = block.number;
        }
        uint256 lpSupply = pool.amount;
        if (lpSupply <= ZERO) {
            return;
        }
        uint256 sushiReward = multiplier.mul(pool.rewardForEachBlock);
        if(sushiReward > ZERO){
            uint256 poolSushiReward = sushiReward;
            if(pool.rewardDev){
                transferToDev(pool, dev1Address, DEV1_SUSHI_REWARD_RATIO, sushiReward);
                transferToDev(pool, dev2Address, DEV2_SUSHI_REWARD_RATIO, sushiReward);
                transferToDev(pool, dev3Address, DEV3_SUSHI_REWARD_RATIO, sushiReward);
                poolSushiReward = sushiReward.mul(MINT_SUSHI_REWARD_RATIO).div(RATIO_BASE);
            }
            pool.accSushiPerShare = pool.accSushiPerShare.add(poolSushiReward.mul(ACC_SUSHI_PRECISION).div(lpSupply));
        }
    }
    
    function transferToDev(PoolInfo storage _pool, address _devAddress, uint16 _devRatio, uint256 _sushiReward) private returns (uint256 amount){
        if(_devRatio > ZERO){
            amount = _sushiReward.mul(_devRatio).div(RATIO_BASE);
            if (_pool.rewardLocked){
                safeTransferTokenFromThis(sushi, _devAddress, _sushiReward);
            }else{
                safeLockTokenFromThis(sushi, _devAddress, _sushiReward);
            }

            _pool.rewarded = _pool.rewarded.add(amount);
        }
    }

    // View function to see pending SUSHIs on frontend.
    function pendingSushi(uint256 _pid, address _user) public view validatePoolByPid(_pid) returns (uint256 sushiReward, uint256 fee) {
        PoolInfo storage pool =  poolInfo[_pid]; 
        if(_user == address(0)){
            _user = msg.sender;
        }
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSushiPerShare = pool.accSushiPerShare;
        uint256 lpSupply = pool.amount;
        uint256 lastRewardBlock = pool.lastRewardBlock;
        if (lastRewardBlock < pool.startBlock) {
            lastRewardBlock = pool.startBlock;
        }
        if (block.number > lastRewardBlock && block.number >= pool.startBlock && lastRewardBlock < pool.endBlock && lpSupply > ZERO){
            uint256 multiplier = ZERO;
            if (block.number > pool.endBlock){
                multiplier = getMultiplier(lastRewardBlock, pool.endBlock);
            }else{
                multiplier = getMultiplier(lastRewardBlock, block.number);
            }
            uint256 poolSushiReward = multiplier.mul(pool.rewardForEachBlock).mul(MINT_SUSHI_REWARD_RATIO).div(RATIO_BASE);
            accSushiPerShare = accSushiPerShare.add(poolSushiReward.mul(ACC_SUSHI_PRECISION).div(lpSupply));
        }
        sushiReward = user.amount.mul(accSushiPerShare).div(ACC_SUSHI_PRECISION).sub(user.rewardDebt);
        fee = getHarvestFee(pool, sushiReward);
    }
    
    function getHarvestFee(PoolInfo storage _pool, uint256 _sushiAmount) private view returns (uint256){
        uint256 fee = ZERO;
        if(_pool.harvestFeeRatio > ZERO && tokenAmountContract != TokenAmountLike(address(0))){//charge for fee
            fee = tokenAmountContract.getTokenAmount(_pool.harvestFeeToken, address(sushi), _sushiAmount).mul(_pool.harvestFeeRatio).div(RATIO_BASE);
        }
        return fee;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = ZERO; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) payable {
        PoolInfo storage pool = poolInfo[_pid];
        require(block.number <= pool.endBlock, "this pool is end!");
        require(block.number >= pool.startBlock, "this pool is not start!");
        if(pool.lpToken == IERC20(address(0))){//if pool is mainnet coin
            require((_amount + pool.operationFee) == msg.value, "msg.value must be equals to amount + operation fee!");
        }
        checkOperationFee(pool, _amount);
        UserInfo storage user = userInfo[_pid][msg.sender];
        _harvest(_pid, msg.sender, true);
        if(pool.lpToken != IERC20(address(0))){
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        }
        pool.amount = pool.amount.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(ACC_SUSHI_PRECISION);
        emit Deposit(msg.sender, _pid, _amount);
    }
    
    function checkOperationFee(PoolInfo storage _pool, uint256 _amount) private nonReentrant {
        if(_pool.operationFee > ZERO){// charge for fee
            uint256 dev1Amount = _pool.operationFee.mul(DEV1_FEE_RATIO).div(RATIO_BASE);
            uint256 dev2Amount = _pool.operationFee.mul(DEV2_FEE_RATIO).div(RATIO_BASE);
            uint256 dev3Amount = _pool.operationFee.sub(dev1Amount).sub(dev2Amount);
            if(_pool.lpToken != IERC20(address(0))){
                require(msg.value == _pool.operationFee, "Fee is not enough or too much!");
            }else{//if pool is mainnet coin
                require((msg.value.sub(_amount)) == _pool.operationFee, "Fee is not enough or too much!");
            }
            dev1Address.transfer(dev1Amount);
            dev2Address.transfer(dev2Amount);
            dev3Address.transfer(dev3Amount);
        }
    }
    
    function isMainnetToken(address _token) private pure returns (bool) {
        return _token == address(0);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) payable {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.number >= pool.startBlock,"this pool is not start!");
        require(user.amount >= _amount, "withdraw: not good");
        _harvest(_pid, msg.sender, true);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(ACC_SUSHI_PRECISION);
        pool.amount = pool.amount.sub(_amount);
        if (pool.lpToken != IERC20(address(0))) {
            pool.lpToken.safeTransfer(msg.sender, _amount);
        } else {//if pool is mainnet coin
            transferMainnetToken(payable(msg.sender), _amount);
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }
    
    //transfer mainnet coin
    function transferMainnetToken(address payable _to, uint256 _amount) internal nonReentrant {
        _to.transfer(_amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.amount = pool.amount.sub(user.amount);
        uint256 oldAmount = user.amount;
        user.amount = ZERO;
        user.rewardDebt = ZERO;
        if (pool.lpToken != IERC20(address(0))) {
            pool.lpToken.safeTransfer(msg.sender, oldAmount);
        } else {//if pool is mainnet coin
            transferMainnetToken(payable(msg.sender), oldAmount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, oldAmount);
    }
    
    function harvest(uint256 _pid, address _to)external nonReentrant payable validatePoolByPid(_pid) returns (bool success){
       return _harvest(_pid, _to, false);
    }
    

    function _harvest(uint256 _pid, address _to, bool isInternal) internal nonReentrant  validatePoolByPid(_pid) returns (bool success) {
        
        if(_to == address(0)){
            _to = msg.sender;
        }
        PoolInfo storage pool =  poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_to];
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSushiPerShare).div(ACC_SUSHI_PRECISION).sub(user.rewardDebt);
        if (!isInternal){
            require(pending > lockToken.minimumLockAmount(),"reward too low!");
        }
        if (pending > ZERO) {
            success = true;
            checkHarvestFee(pool, pending);
            if (!pool.rewardLocked){
                safeTransferTokenFromThis(sushi, _to, pending);
            }else{
                safeLockTokenFromThis(sushi, _to, pending);
            }
            pool.rewarded = pool.rewarded.add(pending);
            user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(ACC_SUSHI_PRECISION);
        } else{
            success = false; 
        }
        emit Harvest(_to, _pid, pending);
    }
    
    function checkHarvestFee(PoolInfo storage _pool, uint256 _sushiReward) private {
        uint256 fee = getHarvestFee(_pool, _sushiReward);
        if(fee > ZERO){
            uint256 devFee = fee.mul(harvestFeeDevRatio).div(RATIO_BASE);
            uint256 buyFee = fee.sub(devFee);
            uint256 dev1Amount = devFee.mul(DEV1_FEE_RATIO).div(RATIO_BASE);
            uint256 dev2Amount = devFee.mul(DEV2_FEE_RATIO).div(RATIO_BASE);
            uint256 dev3Amount = devFee.sub(dev1Amount).sub(dev2Amount);
            if(isMainnetToken(_pool.harvestFeeToken)){
                require(msg.value == fee, "Fee is not enough or too much!");
                dev1Address.transfer(dev1Amount);
                dev2Address.transfer(dev2Amount);
                dev3Address.transfer(dev3Amount);
                buyAddress.transfer(buyFee);
            }else{
                IERC20 token = IERC20(_pool.harvestFeeToken);
                uint feeBalance = token.balanceOf(msg.sender);
                require(feeBalance >= fee, "Fee is not enough!");
                token.safeTransferFrom(msg.sender, address(this), fee);
                
                token.safeTransfer(dev1Address, dev1Amount);
                token.safeTransfer(dev2Address, dev2Amount);
                token.safeTransfer(dev3Address, dev3Amount);
                token.safeTransfer(buyAddress, buyFee);
            }
        }
    }
    
    function emergencyStop(address payable _to) public onlyOwner {
        if(_to == address(0)){
            _to = payable(msg.sender);
        }
        uint addrBalance = sushi.balanceOf(address(this));
        if(addrBalance > ZERO){
            sushi.safeTransfer(_to, addrBalance);
        }
        uint256 length = poolInfo.length;
        for (uint256 pid = ZERO; pid < length; ++ pid) {
            closePool(pid, _to);
        }
        emit EmergencyStop(msg.sender, _to);
    }
    
    function closePool(uint256 _pid, address payable _to) public validatePoolByPid(_pid) onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.endBlock = block.number;
        if(_to == address(0)){
            _to = payable(msg.sender);
        }
        emit ClosePool(_pid, _to);
    }
    
    // Safe transfer token function, just in case if rounding error causes pool to not have enough tokens.
    function safeLockTokenFromThis(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 bal = _token.balanceOf(address(this));
        if (_amount > bal) {
            // _token.safeTransfer(_to, bal);
            sushi.safeIncreaseAllowance(address(lockToken), bal);
            lockToken.lock(_to, bal, lockBlockNumber);
        } else {
            // _token.safeTransfer(_to, _amount);
            sushi.safeIncreaseAllowance(address(lockToken), bal);
            lockToken.lock(_to, _amount, lockBlockNumber);
        }
    }
    function safeTransferTokenFromThis(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 bal = _token.balanceOf(address(this));
        if (_amount > bal) {
            _token.safeTransfer(_to, bal);
            // lockToken.lock(_to, bal, lockBlockNumber);
        } else {
            _token.safeTransfer(_to, _amount);
            // lockToken.lock(_to, _amount, lockBlockNumber);
        }
    }
     // Update dev1 address by the previous dev.
    function updateDev1Address(address payable _dev1Address) external {
        require(msg.sender == dev1Address, "dev1: wut?");
        require(_dev1Address != address(0), "address can not be zero!");
        dev1Address = _dev1Address;
        emit UpdateDev1Address(_dev1Address);
    }
    
    // Update dev2 address by the previous dev.
    function updateDev2Address(address payable _dev2Address) external {
        require(msg.sender == dev2Address, "dev2: wut?");
        require(_dev2Address != address(0), "address can not be zero!");
        dev2Address = _dev2Address;
        emit UpdateDev2Address(_dev2Address);
    }
    
    // Update dev3 address by the previous dev.
    function updateDev3Address(address payable _dev3Address) external {
        require(msg.sender == dev3Address, "dev3: wut?");
        require(_dev3Address != address(0), "address can not be zero!");
        dev3Address = _dev3Address;
        emit UpdateDev3Address(_dev3Address);
    }
    
    // Update dev3 address by the previous dev.
    function updateBuyAddress(address payable _buyAddress) external {
        require(msg.sender == buyAddress, "buyAddress: wut?");
        require(_buyAddress != address(0), "address can not be zero!");
        buyAddress = _buyAddress;
        emit UpdateBuyAddress(_buyAddress);
    }
    
    // Add reward for pool from the current block or start block
    function addRewardForPool(uint256 _pid, uint256 _addSushiPerPool, uint256 _addSushiPerBlock, bool _withSushiTransfer) external validatePoolByPid(_pid) onlyOwner {
        require(_addSushiPerPool > ZERO || _addSushiPerBlock > ZERO, "add sushi must be greater than zero!");
        PoolInfo storage pool = poolInfo[_pid];
        require(block.number < pool.endBlock, "this pool is going to be end or end!");
        updatePool(_pid);
        uint256 addSushiPerBlock = _addSushiPerBlock;
        uint256 addSushiPerPool = _addSushiPerPool;
        uint256 start = block.number;
        uint256 end = pool.endBlock;
        if(start < pool.startBlock){
            start = pool.startBlock;
        }
        uint256 blockNumber = end.sub(start);
        if(blockNumber <= ZERO){
            blockNumber = 1;
        }
        if(addSushiPerBlock <= ZERO){
            addSushiPerBlock = _addSushiPerPool.div(blockNumber);
        }
        addSushiPerPool = addSushiPerBlock.mul(blockNumber);
        pool.rewardForEachBlock = pool.rewardForEachBlock.add(addSushiPerBlock);
        if(_withSushiTransfer){
            sushi.safeTransferFrom(msg.sender, address(this), addSushiPerPool);
        }
        emit AddRewardForPool(_pid, addSushiPerPool, addSushiPerBlock, _withSushiTransfer);
    }
}