/**
 *Submitted for verification at cronoscan.com on 2022-05-25
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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

        // solhint-disable-next-line avoid-low-level-calls
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

        // solhint-disable-next-line avoid-low-level-calls
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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
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
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

    uint256[49] private __gap;
}

contract DarkSport is OwnableUpgradeSafe {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    uint256 private _locked = 0;

    address public dark = address(0x83b2AC8642aE46FC2823Bc959fFEB3c1742c48B5);

    struct MatchInfo {
        uint256 index;
        string name;
        uint256 startBettingTime;
        uint256 endBettingTime;
        uint256 numTickets;
        uint8 settledBetTypesCount;
        uint8 status; // 0-NEW 1-FINISH 8-CANCEL/POSTPONE
    }

    struct BetType {
        uint8 index;
        string description;
        uint8 numDoors;
        uint32[] odds;
        uint8[] doorResults; // 0-PENDING 1-WIN 2-LOSE 3-DRAW 4-WIN-HALF 5-LOSE-HALF
        uint256 numTickets;
        uint256 totalBetAmount;
        uint256 totalPayoutAmount;
        uint256[] doorBetAmount;
        uint256 maxBudget;
        uint8 status; // 0-NEW 1-FINISH 8-CANCEL/POSTPONE
    }

    struct Ticket {
        uint256 index;
        address player;
        uint256 matchId;
        uint8 betTypeId;
        uint8 betDoor;
        uint32 betOdd;
        uint256 betAmount;
        uint256 payout;
        uint256 bettingTime;
        uint256 claimedTime;
        uint8 status; // 0-PENDING 1-WIN 2-LOSE 3-DRAW 4-WIN-HALF 5-LOSE-HALF 8-REFUND
    }

    struct PlayerStat {
        uint256 totalBet;
        uint256 totalPayout;
    }

    address public fund;
    uint256 public standardPrice;
    uint256 public losePayoutRate; // payback even you lose
    uint8 public maxNumberOfBetTypes;

    MatchInfo[] public matchInfos; // All matches
    mapping(uint256 => BetType[]) public matchBetTypes; // Store all match bet types: matchId => array of BetType
    Ticket[] public tickets; // All tickets of player
    mapping(address => mapping(uint256 => uint256[])) public matchesOf; // Store all ticket of player/match: player => matchId => ticket_id
    mapping(address => uint256[]) public ticketsOf; // Store all ticket of player: player => ticket_id

    mapping(address => PlayerStat) public playerStats;
    uint256 public totalBetAmount;
    uint256 public totalPayoutAmount;

    mapping(address => bool) public admin;

    mapping(uint256 => mapping(address => bool)) private _btxStatus;

    /* =================== Added variables (need to keep orders for proxy to work) =================== */
    // ...

    /* ========== EVENTS ========== */

    event SetAdminStatus(address account, bool adminStatus);
    event EditFund(address fund);
    event EditStandardPrice(uint256 standardPrice);
    event EditLosePayoutRate(uint256 losePayoutRate);
    event AddMatchInfo(uint256 matchId, string matchName, uint256 startBettingTime, uint256 endBettingTime);
    event EditMatchStartBettingTime(uint256 matchId, uint256 startBettingTime);
    event EditMatchEndBettingTime(uint256 matchId, uint256 endBettingTime);
    event AddBetType(uint256 matchId, uint8 betTypeId, string betDescription, uint8 numDoors, uint32[] odds, uint256 maxBudget);
    event EditBetTypeOdds(uint256 matchId, uint8 betTypeId, uint32[] odds);
    event EditBetTypeBudget(uint256 matchId, uint8 betTypeId, uint256 maxBudget);
    event CancelMatch(uint256 matchId);
    event SettleMatchResult(uint256 matchId, uint8 betTypeId, uint8[] doorResults);
    event NewTicket(address player, uint256 ticketIndex, uint256 matchId, uint8 betTypeId, uint256 betAmount, uint256 bettingTime);
    event DrawTicket(address player, uint256 ticketIndex, uint256 matchId, uint8 betTypeId, uint256 payout, uint256 claimedTime);
    event DrawAllTicket(address player, uint256 matchId, uint256 numPendingTickets, uint256 totalPayout, uint256 claimedTime);

    modifier lock() {
        require(_locked == 0, "LOCKED");
        _locked = 1;
        _;
        _locked = 0;
    }

    modifier notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "contract not allowed");
        require(tx.origin == msg.sender, "contract not allowed");
        _;
    }

    modifier onlyAdmin() {
        require(admin[msg.sender], "!admin");
        _;
    }

    modifier onlyOneBlock() {
        require(!_btxStatus[block.number][tx.origin] && !_btxStatus[block.number][msg.sender], "ContractGuard: one block, one function");

        _btxStatus[block.number][tx.origin] = true;
        _btxStatus[block.number][msg.sender] = true;

        _;
    }

    function initialize(address _dark, address _fund) public initializer {
        require(_fund != address(0), "zero");
        OwnableUpgradeSafe.__Ownable_init();
        dark = _dark;
        fund = _fund;
        standardPrice = 10 ether;
        losePayoutRate = 200; // 2%
        maxNumberOfBetTypes = 200;
        admin[msg.sender] = true;

        emit SetAdminStatus(msg.sender, true);
        emit EditFund(_fund);
        emit EditStandardPrice(standardPrice);
        emit EditLosePayoutRate(losePayoutRate);
    }

    function setAdminStatus(address _account, bool _isAdmin) external onlyOwner {
        admin[_account] = _isAdmin;

        emit SetAdminStatus(_account, _isAdmin);
    }

    function setStandardPrice(uint256 _standardPrice) external onlyOwner {
        require(_standardPrice >= 0.01 ether, "too low");
        standardPrice = _standardPrice;

        emit EditStandardPrice(standardPrice);
    }

    function setLosePayout(uint256 _losePayoutRate) external onlyOwner {
        require(_losePayoutRate <= 1000, "too high"); // <= 10%
        losePayoutRate = _losePayoutRate;

        emit EditLosePayoutRate(losePayoutRate);
    }

    function setMaxNumberOfBetTypes(uint8 _maxNumberOfBetTypes) external onlyOwner {
        require(_maxNumberOfBetTypes <= 255, "too high");
        maxNumberOfBetTypes = _maxNumberOfBetTypes;
    }

    function setStartBettingTime(uint256 _matchId, uint256 _startBettingTime) external onlyOwner {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(matchInfo.status == 0, "match is not new"); // 0-NEW 1-FINISH 2-CANCEL/POSTPONE
        matchInfo.startBettingTime = _startBettingTime;

        emit EditMatchStartBettingTime(_matchId, _startBettingTime);
    }

    function setEndBettingTime(uint256 _matchId, uint256 _endBettingTime) external onlyOwner {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(matchInfo.status == 0, "match is not new"); // 0-NEW 1-FINISH 2-CANCEL/POSTPONE
        matchInfo.endBettingTime = _endBettingTime;

        emit EditMatchEndBettingTime(_matchId, _endBettingTime);
    }

    function setFund(address _fund) external onlyOwner {
        require(_fund != address(0), "zero");
        fund = _fund;

        emit EditFund(_fund);
    }

    function totalNumberOfBets(address _player) public view returns (uint256) {
        return (_player == address(0x0)) ? tickets.length : ticketsOf[_player].length;
    }

    function getMatchNumberOfBetTypes(uint256 _matchId) public view returns (uint256) {
        return matchBetTypes[_matchId].length;
    }

    function getTicketNumberOfMatch(address _player, uint256 _matchId) public view returns (uint256) {
        return matchesOf[_player][_matchId].length;
    }

    function getMatchInfo(uint256 _matchId)
        external
        view
        returns (
            uint256 _index,
            string memory _name,
            uint256 _startBettingTime,
            uint256 _endBettingTime,
            uint8 _numberOfBetTypes,
            uint256 _numTickets,
            uint8 _status
        )
    {
        MatchInfo memory matchInfo = matchInfos[_matchId];
        _index = matchInfo.index;
        _name = matchInfo.name;
        _startBettingTime = matchInfo.startBettingTime;
        _endBettingTime = matchInfo.endBettingTime;
        _numberOfBetTypes = uint8(matchBetTypes[_matchId].length);
        _numTickets = matchInfo.numTickets;
        _status = matchInfo.status;
    }

    function getMatchBetType(uint256 _matchId, uint8 _betTypeId)
        external
        view
        returns (
            uint8 _index,
            string memory _description,
            uint8 _numDoors,
            uint32[] memory _odds,
            uint8[] memory _doorResults,
            uint256 _numTickets,
            uint256 _totalBetAmount,
            uint256 _totalPayoutAmount,
            uint256[] memory _doorBetAmount,
            uint256 _maxBudget
        )
    {
        BetType memory betType = matchBetTypes[_matchId][_betTypeId];
        _index = betType.index;
        _description = betType.description;
        _numDoors = betType.numDoors;
        _odds = betType.odds;
        _doorResults = betType.doorResults;
        _numTickets = betType.numTickets;
        _totalBetAmount = betType.totalBetAmount;
        _totalPayoutAmount = betType.totalPayoutAmount;
        _doorBetAmount = betType.doorBetAmount;
        _maxBudget = betType.maxBudget;
    }

    function getMaxBetAmount(
        uint256 _matchId,
        uint8 _betTypeId,
        uint8 _door
    ) public view returns (uint256 _amount) {
        BetType memory betType = matchBetTypes[_matchId][_betTypeId];
        // (_doorBetAmount[_door] + X) * _odds[_door]/10000 <= (_totalBetAmount + X + _maxBudget) >=
        // (_odds[_door]/10000 - 1) * X <= (_totalBetAmount + _maxBudget - _doorBetAmount[_door] * _odds[_door]/10000)
        // X <= (_totalBetAmount + _maxBudget - _doorBetAmount[_door] * _odds[_door]/10000) / (_odds[_door]/10000 - 1)
        uint256 _odd = betType.odds[_door];
        return betType.totalBetAmount.add(betType.maxBudget).sub(betType.doorBetAmount[_door].mul(_odd).div(10000)).mul(10000).div(_odd.sub(10000));
    }

    function addMatchInfoThreeStandardBetTypes(
        string memory _matchName,
        uint256 _startBettingTime,
        uint256 _endBettingTime,
        string memory _betDescription1x2,
        uint32[] memory _odds1x2,
        string memory _betDescriptionHandicap,
        uint32[] memory _oddsHandicap,
        string memory _betDescriptionOverUnder,
        uint32[] memory _oddsOverUnder,
        uint256[] memory _maxBudgets
    ) external onlyAdmin returns (uint256 _matchId) {
        // 0: 1x2, 1: Handcap, 2: Over/Under
        require(_maxBudgets.length == 3, "Invalid _maxBudgets length");

        _matchId = addMatchInfo(_matchName, _startBettingTime, _endBettingTime, _betDescription1x2, 3, _odds1x2, _maxBudgets[0]);
        addMatchBetType(_matchId, _betDescriptionHandicap, 2, _oddsHandicap, _maxBudgets[1]);
        addMatchBetType(_matchId, _betDescriptionOverUnder, 2, _oddsOverUnder, _maxBudgets[2]);
    }

    function addMatchInfo(
        string memory _matchName,
        uint256 _startBettingTime,
        uint256 _endBettingTime,
        string memory _betDescription,
        uint8 _numDoors,
        uint32[] memory _odds,
        uint256 _maxBudget
    ) public onlyAdmin returns (uint256 _matchId) {
        require(_startBettingTime < _endBettingTime && now < _endBettingTime, "Invalid _endBettingTime");

        _matchId = matchInfos.length;
        matchInfos.push(MatchInfo({index: _matchId, name: _matchName, startBettingTime: _startBettingTime, endBettingTime: _endBettingTime, numTickets: 0, settledBetTypesCount: 0, status: 0}));
        emit AddMatchInfo(_matchId, _matchName, _startBettingTime, _endBettingTime);

        addMatchBetType(_matchId, _betDescription, _numDoors, _odds, _maxBudget);
    }

    function addMatchBetType(
        uint256 _matchId,
        string memory _betDescription,
        uint8 _numDoors,
        uint32[] memory _odds,
        uint256 _maxBudget
    ) public onlyAdmin returns (uint8 _betTypeId) {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(now <= matchInfo.endBettingTime, "late");
        require(_numDoors > 0, "Invalid _numDoors");
        require(_numDoors == _odds.length, "Invalid _odds length");

        _betTypeId = uint8(matchBetTypes[_matchId].length);
        require(_betTypeId < maxNumberOfBetTypes, "Number of ticket types exceeds limit");

        for (uint8 i = 0; i < _numDoors; i++) {
            require(_odds[i] > 10000, "odd must be greater than x1");
        }

        matchBetTypes[_matchId].push(
            BetType({
                index: _betTypeId,
                description: _betDescription,
                numDoors: _numDoors,
                odds: _odds,
                doorResults: new uint8[](_numDoors),
                numTickets: 0,
                totalBetAmount: 0,
                totalPayoutAmount: 0,
                doorBetAmount: new uint256[](_numDoors),
                maxBudget: _maxBudget,
                status: 0
            })
        );

        emit AddBetType(_matchId, _betTypeId, _betDescription, _numDoors, _odds, _maxBudget);
    }

    function editMatchBetTypeOdds(
        uint256 _matchId,
        uint8 _betTypeId,
        uint32[] memory _odds
    ) external onlyAdmin {
        MatchInfo memory matchInfo = matchInfos[_matchId];
        require(now <= matchInfo.endBettingTime, "late");

        BetType storage betType = matchBetTypes[_matchId][_betTypeId];
        require(betType.odds.length == _odds.length, "Invalid _odds");

        uint256 _numDoors = _odds.length;
        for (uint256 i = 0; i < _numDoors; i++) {
            require(_odds[i] > 10000, "odd must be greater than x1");
        }

        betType.odds = _odds;

        emit EditBetTypeOdds(_matchId, _betTypeId, _odds);
    }

    function editMatchBetTypeBudget(
        uint256 _matchId,
        uint8 _betTypeId,
        uint256 _maxBudget
    ) external onlyAdmin {
        MatchInfo memory matchInfo = matchInfos[_matchId];
        require(now <= matchInfo.endBettingTime, "late");

        BetType storage betType = matchBetTypes[_matchId][_betTypeId];
        betType.maxBudget = _maxBudget;

        emit EditBetTypeBudget(_matchId, _betTypeId, _maxBudget);
    }

    function cancelMatch(uint256 _matchId) external onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(matchInfo.status == 0, "match is not new"); // 0-NEW 1-FINISH 2-CANCEL/POSTPONE
        matchInfo.status = 8;

        emit CancelMatch(_matchId);
    }

    function settleMatchResult(
        uint256 _matchId,
        uint8 _betTypeId,
        uint8[] memory _doorResults
    ) public onlyAdmin {
        MatchInfo storage matchInfo = matchInfos[_matchId];
        if (msg.sender != owner() || now > matchInfo.endBettingTime.add(48 hours)) {
            // owner has rights to over-write the match result in 48 hours (in case admin made mistake)
            require(matchInfo.status == 0, "match is not new"); // 0-NEW 1-FINISH 2-CANCEL/POSTPONE
        }

        BetType storage betType = matchBetTypes[_matchId][_betTypeId];
        require(_doorResults.length == betType.numDoors, "Invalid _doorResults length");
        if (betType.status == 0) {
            betType.status = 1;
            matchInfo.settledBetTypesCount++;
            if (matchInfo.settledBetTypesCount == matchBetTypes[_matchId].length) {
                matchInfo.status = 1;
            }
        }
        betType.doorResults = _doorResults;

        emit SettleMatchResult(_matchId, _betTypeId, _doorResults);
    }

    function settleMatchResultThreeStandardBetTypes(
        uint256 _matchId,
        uint8[] memory _doorResults1x2,
        uint8[] memory _doorResultsHandicap,
        uint8[] memory _doorResultsOverUnder
    ) external onlyAdmin {
        require(_doorResults1x2.length == 3, "Invalid _doorResults1x2 length");
        require(_doorResultsHandicap.length == 2, "Invalid _doorResultsHandicap length");
        require(_doorResultsOverUnder.length == 2, "Invalid _doorResultsOverUnder length");

        settleMatchResult(_matchId, 0, _doorResults1x2);
        settleMatchResult(_matchId, 1, _doorResultsHandicap);
        settleMatchResult(_matchId, 2, _doorResultsOverUnder);
    }

    function buyTicket(
        uint256 _matchId,
        uint8 _betTypeId,
        uint8 _betDoor,
        uint32 _betOdd,
        uint256 _betAmount
    ) public lock returns (uint256 _ticketIndex) {
        require(_betAmount >= standardPrice, "_betAmount less than standard price");

        uint256 _maxBetAmount = getMaxBetAmount(_matchId, _betTypeId, _betDoor);
        require(_betAmount <= _maxBetAmount, "_betAmount exceeds _maxBetAmount");

        MatchInfo storage matchInfo = matchInfos[_matchId];
        require(now >= matchInfo.startBettingTime, "early");
        require(now <= matchInfo.endBettingTime, "late");
        require(matchInfo.status == 0, "match not opened for ticket"); // 0-NEW 1-FINISH 2-CANCEL/POSTPONE

        BetType storage betType = matchBetTypes[_matchId][_betTypeId];
        require(_betDoor < betType.numDoors, "Invalid _betDoor");
        require(_betOdd == betType.odds[_betDoor], "Invalid _betOdd");

        address _player = msg.sender;
        IERC20(dark).safeTransferFrom(_player, address(fund), _betAmount);

        _ticketIndex = tickets.length;

        tickets.push(
            Ticket({
                index: _ticketIndex,
                player: _player,
                matchId: _matchId,
                betTypeId: _betTypeId,
                betDoor: _betDoor,
                betOdd: _betOdd,
                betAmount: _betAmount,
                payout: 0,
                bettingTime: now,
                claimedTime: 0,
                status: 0 // 0-PENDING 1-WIN 2-LOSE 3-REFUND
            })
        );

        matchInfo.numTickets = matchInfo.numTickets.add(1);
        betType.numTickets = betType.numTickets.add(1);
        betType.totalBetAmount = betType.totalBetAmount.add(_betAmount);
        betType.doorBetAmount[_betDoor] = betType.doorBetAmount[_betDoor].add(_betAmount);
        totalBetAmount = totalBetAmount.add(_betAmount);
        matchesOf[_player][_matchId].push(_ticketIndex);
        ticketsOf[_player].push(_ticketIndex);
        playerStats[_player].totalBet = playerStats[_player].totalBet.add(_betAmount);

        emit NewTicket(_player, _ticketIndex, _matchId, _betTypeId, _betAmount, now);
    }

    function settleBet(uint256 _ticketIndex) public lock returns (address _player, uint256 _payout) {
        require(_ticketIndex < tickets.length, "_ticketIndex out of range");

        Ticket storage ticket = tickets[_ticketIndex];
        require(ticket.status == 0, "ticket settled");

        uint256 _matchId = ticket.matchId;
        MatchInfo memory matchInfo = matchInfos[_matchId];
        require(now > matchInfo.endBettingTime, "early");

        uint8 _betTypeId = ticket.betTypeId;
        BetType storage betType = matchBetTypes[_matchId][_betTypeId];

        uint256 _betAmount = ticket.betAmount;
        // Ticket status: 0-PENDING 1-WIN 2-LOSE 3-DRAW 4-WIN-HALF 5-LOSE-HALF 8-REFUND
        if (matchInfo.status == 8) {
            // CANCEL/POSTPONE
            _payout = _betAmount;
            ticket.status = 8; // REFUND
        } else if (matchInfo.status == 1) {
            // FINISH
            uint8 _betDoor = ticket.betDoor;
            uint8 _betDoorResult = betType.doorResults[_betDoor];
            if (_betDoorResult == 1) {
                _payout = _betAmount.mul(uint256(ticket.betOdd)).div(10000);
                ticket.status = 1; // WIN
            } else if (_betDoorResult == 2) {
                _payout = _betAmount.mul(losePayoutRate).div(10000);
                ticket.status = 2; // LOSE
            } else if (_betDoorResult == 3) {
                _payout = _betAmount;
                ticket.status = 3; // DRAW
            } else if (_betDoorResult == 4) {
                uint256 _fullAmount = _betAmount.mul(uint256(ticket.betOdd)).div(10000);
                _payout = _betAmount.add(_fullAmount.sub(_betAmount).div(2)); // = BET + (WIN - BET) * 0.5
                ticket.status = 4; // WIN-HALF
            } else if (_betDoorResult == 5) {
                _payout = _betAmount.div(2);
                ticket.status = 5; // LOSE-HALF
            } else {
                revert("no bet door result");
            }
        } else {
            revert("match is not opened for settling");
        }

        _player = ticket.player;
        betType.totalPayoutAmount = betType.totalPayoutAmount.add(_payout);
        totalPayoutAmount = totalPayoutAmount.add(_payout);
        playerStats[_player].totalPayout = playerStats[_player].totalPayout.add(_payout);
        ticket.claimedTime = now;

        if (_payout > 0) {
            IERC20(dark).safeTransferFrom(address(fund), _player, _payout);
        }

        emit DrawTicket(_player, _ticketIndex, _matchId, _betTypeId, _payout, now);
    }

    function settleAll(uint256 _matchId) external onlyOneBlock returns (uint256 _totalPayout) {
        address _player = msg.sender;
        uint256 _length = ticketsOf[_player].length;
        uint256 _numPendingTickets = 0;
        for (uint256 _ticketIndex = 0; _ticketIndex < _length; _ticketIndex++) {
            Ticket storage ticket = tickets[ticketsOf[_player][_ticketIndex]];
            if (ticket.matchId == _matchId && ticket.status == 0) {
                (, uint256 _payout) = settleBet(ticket.index);
                _totalPayout = _totalPayout.add(_payout);
                _numPendingTickets = _numPendingTickets.add(1);
            }
        }
        emit DrawAllTicket(_player, _matchId, _numPendingTickets, _totalPayout, now);
    }

    function getTotalPendingRewardOfMatch(address _player, uint256 _matchId) public view returns (uint256) {
        uint256 _pendingReward = 0;
        uint256 _payout = 0;
        uint256 _length = ticketsOf[_player].length;
        for (uint256 _ticketIndex = 0; _ticketIndex < _length; _ticketIndex++) {
            Ticket storage ticket = tickets[ticketsOf[_player][_ticketIndex]];
            if (ticket.matchId == _matchId && ticket.status == 0) {
                uint256 _betAmount = ticket.betAmount;
                MatchInfo memory matchInfo = matchInfos[_matchId];
                if (now > matchInfo.endBettingTime) {
                    uint8 _betTypeId = ticket.betTypeId;
                    BetType storage betType = matchBetTypes[_matchId][_betTypeId];
                    if (matchInfo.status == 1) {
                        // FINISH
                        uint8 _betDoor = ticket.betDoor;
                        uint8 _betDoorResult = betType.doorResults[_betDoor];
                        if (_betDoorResult == 1) {
                            _payout = _betAmount.mul(uint256(ticket.betOdd)).div(10000);
                            _pendingReward = _pendingReward.add(_payout);
                        } else if (_betDoorResult == 2) {
                            _payout = _betAmount.mul(losePayoutRate).div(10000);
                            _pendingReward = _pendingReward.add(_payout);
                        } else if (_betDoorResult == 3) {
                            _payout = _betAmount;
                            _pendingReward = _pendingReward.add(_payout);
                        } else if (_betDoorResult == 4) {
                            uint256 _fullAmount = _betAmount.mul(uint256(ticket.betOdd)).div(10000);
                            _payout = _betAmount.add(_fullAmount.sub(_betAmount).div(2));
                            // = BET + (WIN - BET) * 0.5
                            _pendingReward = _pendingReward.add(_payout);
                        } else if (_betDoorResult == 5) {
                            _payout = _betAmount.div(2);
                            _pendingReward = _pendingReward.add(_payout);
                        } else {
                            revert("no bet door result");
                        }
                    }
                }
            }
        }
        return _pendingReward;
    }

    // This function allows governance to take unsupported tokens out of the contract. This is in an effort to make someone whole, should they seriously mess up.
    // There is no guarantee governance will vote to return these. It also allows for removal of airdropped tokens.
    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 amount,
        address to
    ) external onlyOwner {
        _token.safeTransfer(to, amount);
    }
}