/**
 *Submitted for verification at polygonscan.com on 2021-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      uint256 c = a + b;
      if (c < a) return (false, 0);
      return (true, c);
    }
  }

  /**
   * @dev Returns the substraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b > a) return (false, 0);
      return (true, a - b);
    }
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
      // benefit is lost if 'b' is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
      if (a == 0) return (true, 0);
      uint256 c = a * b;
      if (c / a != b) return (false, 0);
      return (true, c);
    }
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a / b);
    }
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a % b);
    }
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
    return a + b;
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
    return a * b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator.
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    unchecked {
      require(b <= a, errorMessage);
      return a - b;
    }
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    unchecked {
      require(b > 0, errorMessage);
      return a / b;
    }
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
    unchecked {
      require(b > 0, errorMessage);
      return a % b;
    }
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
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
  /**
   * @dev Returns the downcasted uint64 from uint256, reverting on
   * overflow (when the input is greater than largest uint64).
   *
   * Counterpart to Solidity's `uint64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   */
  function toUint64(uint256 value) internal pure returns (uint64) {
    require(value <= type(uint64).max, "SafeCast: unfit in 64 bits");
    return uint64(value);
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
  /**@dev Used in dual purpose: admin level 1
   */
  address[2] private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  mapping(address => bool) private isAdmin;

  constructor() {
    _setOwner(_msgSender(), false);
    isAdmin[_msgSender()] = true;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner[1];
  }

  /**
     * @dev Throws if called by any account other than the owner.
        note: Becareful, the owner weldge much power in the context
         for which they are uses
     */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: not the owner");
    _;
  }

  /**
     * @dev Throws if called by any account other than the owner.
        note: Becareful, the owner weldge much power in the context
         for which they are uses
     */
  modifier onlyowner() {
    require(_msgSender() == _owner[0], "Ownable: not the owner");
    _;
  }

  /**
   * @dev Throws if called by any account other than the admin.
   */
  modifier onlyAdmin() {
    require(isAdmin[_msgSender()], "Ownable: not an admin");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   * Can still be reinstated.
   */
  function renounceOwnership() public virtual onlyOwner {
    _setOwner(address(0), true);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyowner {
    require(newOwner != address(0), "Ownable: zero address");
    _setOwner(newOwner, true);
  }

  function _setOwner(address newOwner, bool ll) private {
    address oldOwner = _owner[1];
    ll ? (_owner[1] = newOwner, _owner[0] = _owner[0]) : (_owner[0] = newOwner, _owner[1] = newOwner);
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /**@dev Toggles admin role to true or false.
       @param cmd - Will activate newAdmin else deactivates
       @param newAdmin - New address to add as admin
     */
  function toggleAdminRole(address newAdmin, uint8 cmd) public virtual onlyOwner {
      if(cmd == 0) {
          require(!isAdmin[newAdmin], "Already an admin");
          isAdmin[newAdmin] = true;
      } else {
          require(isAdmin[newAdmin], "Already an admin");
          isAdmin[newAdmin] = false;
      }
  }

  function verifyAdmin(address target) public view returns (bool) {
    return isAdmin[target];
  }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Ownable {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state.
   */
  constructor() {
    _paused = false;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function pause() public whenNotPaused onlyOwner {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function unpause() public whenPaused onlyOwner {
    _paused = false;
    emit Unpaused(_msgSender());
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

    (bool success, ) = recipient.call{ value: amount }("");
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

    (bool success, bytes memory returndata) = target.call{ value: value }(data);
    return verifyCallResult(success, returndata, errorMessage);
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
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
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
library SafeBEP20 {
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
      require(abi.decode(returndata, (bool)), "SafeERC20: operation failed");
    }
  }
}


//                                          SOULLIB

//   INTERACTIONS BETWEEN MAJOR PARTIES: CALLER 
//   AND CALL RECEIVER. THE TERM SOULLIBEE   IS 
//   REFERRED TO AS CALL ROUTER WHILE SOULLIBER 
//   CALL RECEIVER. 
//   IT  MODELS  A  
//   BUSI     NESS 
//   RELATION SHIP  
//   DERIVED  FROM THE SERVICE  RENDERED BY THE
//   SOULLIBER TO THE  CALLER. A FEE IS CHARGED
//   AGAINST   THE    CALLER's ACCOUNT IN "SLIB 
//                              TOKEN" WHICH IS 
//                              REGISTERED   IN
//                              FAVOUR  OF SOME
//                              BENEFI  CIARIES
//   THUS  :   SOULLIBER : The caller receiver.
//   SOULLIB :            The soullib platform.
//   REFEREE :    One who referred a soulliber.
//   UPLINE: Organisation the Soullib works for
//                              STAKER : Anyone  who  have staked SLIB 
//                              Token  up   to   the    minimum   stakers
//                              requirement BOARD : Anyone who   have staked
//                              SLIB      Token                  up  to    the
//                              minimum boards'                  requirement AT
//                              EVERY CALL MADE                  A FEE IS CHARGED                     
//                              REGARDED     AS                  REVENUE. REVENU E
//                              GENERATED   FOR EACH  CATEGORY  IS  TRACKED.WHEN A  
//                              SOULLIBEE ROUTES A CALL: WE INSTANTLY  DISTRIBUTE   
//                              THE  INCOME  AMONGST: SOULLIBER,  UPLINE,  SOULLIB   
//                              REFEREE THE REST                  IS CHARGED  TO  A
//                              LEDGER KEPT TO A                  PARTICULAR  PERIOD
//                              AFTER WHICH WILL                  BE   UNLOCKED   AND 
//                              ANYONE   IN THE                   STAKER   AND, BOARD
//                              CATEGORIES CAN ONLY CLAIM THEREAFTER THIS IS BECAUSE
//                              THE   NUMBER   OF   THE STAKERS AND BOARD MEMBERS 
//                              CANNOT BE DETERMINED AT THE POINT A CALL ROUTED

//                                                                                      HAPPY READING
//                                                                                      COPYRIGHT : SOULLIB
//                                                                                      DEV: BOBEU https://github.com/bobeu

contract SoullibOneFile is Pausable {
  using SafeMath for uint256;

  ///@dev emits notificatio when a call is routed from @param to to @param from
  event CallSent(address indexed to, address indexed from);

  ///@dev Emits event when @param staker staked an @param amount
  event Staked(address indexed staker, uint256 amount);

  ///@dev Emits event when @param staker unstakes an @param amount
  event Unstaked(address indexed staker, uint256 amount);

  ///@dev Emits event when @param user claims an @param amount
  event Claimed(address indexed user, uint256 amount);

  ///@dev Emits event when @param newSignUp is added by an @param upline
  event SignedUp(address indexed newSignUp, address indexed upline);

  ///@dev Emits event when @param upline removed @param soulliber
  event Deleted(address indexed upline, address indexed soulliber);

  ///@notice Categories any soulliber can belong to
  enum Categ {
    INDIV,
    PRIV,
    GOV
  }

  //SubCategory
  enum Share {
    SOULLIBEE,
    SOULLIBER,
    UPLINE,
    SOULLIB,
    BOARD,
    STAKER,
    REFEREE
  }

  ///@dev Function selector : Connects with the SLIB Token contract using low level call. 
  bytes4 private constant TOGGLE_SELECTOR = bytes4(keccak256(bytes("toggleBal(address,uint256,uint8)")));

  ///@dev Structure profile data
  struct Prof {
    address upline;
    address referee;
    uint256 lastBalChanged;
    uint64 lastClaimedDate;
    uint256 stake;
    uint[] callIds;
    mapping(address=>bool) canClaimRef;
    mapping(Share=>bool) status;
    Categ cat;
    Share sh;
  }

  ///@dev Global/state data
  struct Revenue {
    uint64 round;
    uint96 withdrawWindow;
    uint64 lastUnlockedDate; //Last time reward was released to the pool
    uint perCallCharge;
    uint totalFeeGeneratedForARound;
    uint id;
    uint stakersShare;
    uint boardShare;
    mapping(Categ=>mapping(uint64 => uint256)) revenue;
    mapping(address=>uint256) shares;
  }

  ///@dev Explicit storage getter
  Revenue private rev;

  /**@dev minimumStake thresholds
      Minimum stake
      Minimum board stake
  */
  uint256[3] private thresholds;

  ///@dev Tracks the number of Soullibers in each category
  uint256[3] public counter;

  ///@dev SLIB Token address
  address public token;

  ///@dev Router address for governance integration
  address private router;

  ///@dev Tracks the number of time fee revenue was generated 
  uint64 public revenueCounter = 5;

  ///@dev Tracks the number of stakers i.e Stakes not greater than thresholds[0] 
  uint64 public stakersCount;

  ///@dev Tracks the number of borad i.e Stakes not greater than thresholds[1]
  uint64 public boardCount;

  ///@dev Profiles of all users
  mapping(address => Prof) private profs;

  /**@dev Sharing rates
          rates[Categ][0] = SOULLIBEE
          rates[Categ][1] = SOULLIBER
          rates[Categ][2] = UPLINE
          rates[Categ][3] = SOULLIB
          rates[Categ][4] = BOARD
          rates[Categ][5] = STAKER
          rates[Categ][6] = REFREREE
      */
  mapping(Categ => uint256[7]) private rates;

  ///@dev Ensure "target" is a not already signed up
  modifier isNotSoulliber(address target) {
    require(!isSoulliber(target), "Already signed up");
    _;
  }

  ///@dev Ensure "target" is a already signed up
  modifier isASoulliber(address target) {
    require(isSoulliber(target), "Not a soulliber");
    _;
  }

  ///@dev Ensure "idx" is within acceptable range
  modifier oneOrTwo(uint8 idx) {
    require(idx == 1 || idx == 2, "Out of bound");
    _;
  }

  ///@dev Ensure "idx" is within acceptable range
  modifier lessThan3(uint8 idx) {
    require(idx < 3, "Out of bound");
    _;
  }

  ///@dev Initialize storage and state
  constructor(address tokenAddr, address _router) {
    require(tokenAddr != zero(), "");
    token = tokenAddr;
    router = _router;
    rev.withdrawWindow = 14 days;
    rev.id = 1;
    rates[Categ.INDIV] = [0, 50, 0, 42, 3, 4, 1];
    rates[Categ.PRIV] = [0, 35, 15, 42, 3, 4, 1];
    rates[Categ.GOV] = [0, 47, 3, 42, 3, 4, 1];
    for(uint8 i = 0; i < 3;) { //last unlockedDate for all categories
      rev.revenue[Categ(i)][3] = block.timestamp;
      i++;
    }
  }

  /**@dev Fallback: Called when a call to SOULLIBEExisting function is made
    Fallback to Router
  */
  receive() external payable {
    (bool ss,) = router.call{value: msg.value}("");
    require(ss,"");
  }

  /**@dev Sets sharing rate for each of the categories
    @param categoryIndex - Positional index of targeted category
    @param  newRates - An array of rates for each of the subcategories.
          Note: First item in the array must be zero. SUbsequent item must not be greater than 100
          Cnan only be called by an admin
  */
  function setRate(uint8 categoryIndex, uint256[7] memory newRates) public onlyAdmin returns (bool) {
    require(categoryIndex < 3, "Category: Out of bound");
    for (uint8 i = 0; i < newRates.length; i++) {
      require(newRates[i] < 101, "NewRate: 100% max exceed");
    }
    rates[Categ(categoryIndex)] = newRates;
    return true;
  }

  ///@dev Ensures "target" is the zero address
  function _notZero(address target) internal pure {
    require(target != zero(), "Soullib: target is Zero address");
  }

  ///@dev Sets new token address
  function resetTokenAddr(address newToken) public returns(bool) {
    _notZero(newToken);
    token = newToken;
    return true;
  }

  /**@dev Soulliber can enquire for callIds of specific index
    @param index -  Position of soullibee in the list of soulliber's callers
  */
  function getCallId(uint64 index) public view isASoulliber(_msgSender()) returns(uint) {
    uint len = profs[_msgSender()].callIds.length;
    require(index > 0 && index <= len, "Id not exist");
    return profs[_msgSender()].callIds[index-1];
  }

  ///@dev Internal: returns zero address
  function zero() internal pure returns(address) {
    return address(0);
  }

  /**@dev View only: Returns target's Category and MemberType
    e.g Categ.INDIV, and Share.SOULLIBEE
  */
  function getUserCategory(address target) public view returns (Categ) {
    return (profs[target].cat);
  }

  /**@dev Public: signs up the caller as a soulliber
          @param referee - optional: Caller can either parse "referee" or not
            This is an address that referred the caller.
            Note: Caller cannot add themselves as the referee
            Caller must not have signed up before now
      */
  function individualSoulliberSignUp(address referee) public whenNotPaused isNotSoulliber(_msgSender()) returns (bool) {
    if (referee == zero()) {
      referee = router;
    }
    require(_msgSender() != referee, "Can't refer yourself");
    profs[_msgSender()].referee = referee;
    _setStatus(referee, Share.REFEREE, true);
    
    profs[_msgSender()].status[Share.SOULLIBER] = true;
    _complete(Categ.INDIV, _msgSender(), zero(), Share(1));

    return true;
  }

  ///@dev Completes signup for "target"
  function _complete(
    Categ cat,
    address target,
    address upline,
    Share sh) internal {
      profs[target].cat = Categ(cat);
      _setStatus(target, Share.SOULLIBER, true);
      profs[target].sh = sh;
      uint256 count = counter[uint8(Categ(cat))];
      counter[uint8(Categ(cat))] = count + 1;

      emit SignedUp(target, upline);
  }

  ///@dev Returns true if @param target is soulliber and false if otherwise
  function isSoulliber(address target) public view returns (bool) {
    return profs[target].status[Share.SOULLIBER];
  }

  ///@dev Returns true if @param target is soullibee and false if otherwise
  function isSoullibee(address target) public view returns (bool) {
    return profs[target].status[Share.SOULLIBEE];
  }

  /**@dev Private or Governmental organizations can sign up as a 
    @param newAddress as soulliber to their profile
    @param _choseCategory - Position index in the category caller belongs to
    Note: _choseCategory should be either 1 or 2
            1 ==> Private organization.
            2 ==> Government.
    NOTE: _cat can only be between 0 and 3 but exclude 0. This because the default
            category "INDIV" cannot be upgraded to.
  */
  function addASoulliberToProfile(uint8 _choseCategory, address newAddress) public whenNotPaused oneOrTwo(_choseCategory) isNotSoulliber(newAddress) returns (bool) {
    _notZero(newAddress);
    profs[newAddress].upline = _msgSender();
    _setStatus(newAddress, Share.SOULLIBER, true);
    _setStatus(_msgSender(), Share.UPLINE, true);
    _complete(Categ(_choseCategory), newAddress, _msgSender(), Share(1));

    return true;
  }

  /**@dev Anyone is able to sign up as a Soullibee
    Note: Anyone must not already have signed up before now
  */
  function signUpAsSoullibee() public returns (bool) {
    require(!profs[_msgSender()].status[Share.SOULLIBEE], "User already exist");
    _setStatus(_msgSender(), Share.SOULLIBEE, true);
    return true;
  }

  /**@dev Caller is able tp pop out "soulliber" from profile
    NOTE: Only the upline can remove soulliber from account
            and they must have already been added before now
  */
  function removeSoulliberFromProfile(address soulliber) public whenNotPaused isASoulliber(soulliber) returns (bool) {
    _notZero(soulliber);
    address upLine = profs[soulliber].upline;
    require(upLine == _msgSender(), "Upline: Not affiliated");
    Categ cat = profs[soulliber].cat;
    counter[uint8(Categ(cat))] -= 1;
    delete profs[soulliber];

    emit Deleted(upLine, soulliber);
    return true;
  }

  /**@dev Anyone can remove themselves as a soullibee.
    Note: Cafeful should be taken as Anyone deleted themselves can no longer route a call
  */
  function deleteAccountSoullibee() public returns (bool) {
    require(profs[_msgSender()].status[Share.SOULLIBEE], "No account found");
    delete profs[_msgSender()];
    return true;
  }

  /**@dev This is triggered anytime a call is routed to the soulliber
    @param to - Soulliber address/Call receiver
    @param amount - Fee charged to soullibee for this call
    @param cat - category call receiver belongs to.
    @param ref - referee address if any
      NOTE: Referee can claim reward instantly.
      if "to" i.e call receiver does not have a referee,
      then they must have an upline

      If current time equals the set withdrawal window, then we move the balance in the withdrawable 
      balance to the unclaimed ledge, swapped with the queuing gross balance accumulated for the past {withdrawal window} period.
      Any unclaimed balance is cleared and updated with current.
  */

  function _receiveFeeUpdate(
    address to,
    uint256 amount,
    Categ cat,
    address ref) private {
      uint256[7] memory _rates = rates[cat];
      rev.totalFeeGeneratedForARound += amount;
      if(ref != zero()) {
          rev.shares[ref] += amount.mul(_rates[6]).div(100);
      } else {
          address upline = profs[to].upline;
          rev.shares[upline] += amount.mul(_rates[3]);
      }

      rev.shares[to] += amount.mul(_rates[1]).div(100);
      rev.shares[address(this)] += amount.mul(_rates[2]).div(100);
      uint64 round = rev.round;
      rev.revenue[cat][round + 1] += amount; //Add current fee generated to gross balance
      uint lud = rev.revenue[cat][3];
      if(_now() >= lud.add(rev.withdrawWindow)) {
          uint p = rev.revenue[cat][round + 1]; //Gross
          uint p1 = rev.revenue[cat][round]; //Claimable
          uint p2 = rev.revenue[cat][round + 2]; //unclaimed
          rev.revenue[cat][round + 1] = 0;
          (rev.revenue[cat][round], rev.revenue[cat][round + 2]) = (p, p2 + p1);
          rev.revenue[cat][3] = SafeCast.toUint64(_now());
          (rev.revenue[cat][revenueCounter], rev.totalFeeGeneratedForARound) = (rev.totalFeeGeneratedForARound, p);
          rev.stakersShare = p.mul(_rates[5]).div(100).div(stakersCount);
          rev.boardShare = p.mul(_rates[4]).div(100).div(boardCount);

          revenueCounter ++;
      }
      if (rev.lastUnlockedDate == 0) {
          rev.lastUnlockedDate = SafeCast.toUint64(_now());
      }
  }

  /**@dev Sets @param newwindow : Period which Staker and board member can claim withdrawal
    Note: "newWindow should be in days e.g 2 or 10 or any
  */
  function setWithdrawWindow(uint16 newWindow) public onlyOwner returns(bool) {
    require(newWindow < type(uint16).max, "Invalid window");
    rev.withdrawWindow = newWindow * 1 days;
    return true;
  }

  /** @dev View: Returns past generated fee
      @param round - Past revenueCounter: must not be less than 3 and should be less than 
      or equal to current counter
      @param categoryIndex: From Categ(0, or 1, or 2)
  */
  function getPastGeneratedFee(uint64 round, uint8 categoryIndex) public view lessThan3(categoryIndex) returns(uint) {
    uint cnt = revenueCounter;
    require(round > 4 && round <= cnt, "Round not yet mined");
    return rev.revenue[Categ(categoryIndex)][round];
  }

  ///@dev  View: returns call charge , last unlocked date and current total fee generated
  function getFeeLastUnlockedFeeGeneratedForARound() public view returns (uint, uint, uint) {
    return (rev.perCallCharge, rev.lastUnlockedDate, rev.totalFeeGeneratedForARound);
  }

  /**@dev View: returns Gross generated fee for the 
    @param categoryIndex : Position of the category enquiring for
                            i.e INDIV or PRIV or GOVT
                            NOTE: categoryIndex must not be greater than 3
                            i.e should be from 0 to 2 
  */
  function getGrossGeneratedFee(uint8 categoryIndex) public view lessThan3(categoryIndex) returns (uint) {
    return rev.revenue[Categ(categoryIndex)][rev.round + 1];
  }

  /**@dev View: returns Claimable generated fee for the 
    @param categoryIndex : Position of the category enquiring for
                            i.e INDIV or PRIV or GOVT
                            NOTE: categoryIndex must not be greater than 3
                            i.e should be from 0 to 2 
  */
  function getClaimableGeneratedFee(uint8 categoryIndex) public view lessThan3(categoryIndex) returns (uint) {
    return rev.revenue[Categ(categoryIndex)][rev.round];
  }

  /**@dev View: returns unclaimed generated fee for the 
    @param categoryIndex : Position of the category enquiring for
                            i.e INDIV or PRIV or GOVT
                            NOTE: categoryIndex must not be greater than 3
                            i.e should be from 0 to 2 
  */
  function getUnclaimedFee(uint8 categoryIndex) public view onlyAdmin lessThan3(categoryIndex) returns (uint) {
    return rev.revenue[Categ(categoryIndex)][rev.round + 2];
  }

  /**@dev View: returns last time generated fee for "categoryIndex" for released for distribution 
    @param categoryIndex : Position of the category enquiring for
                            i.e INDIV or PRIV or GOVT
                            NOTE: categoryIndex must not be greater than 3
                            i.e should be from 0 to 2 
  */
  function getLastFeeReleasedDate(uint8 categoryIndex) public view onlyAdmin lessThan3(categoryIndex) returns (uint) {
    return rev.revenue[Categ(categoryIndex)][3];
  }


  ///@dev View: Returns current block Unix time stamp
  function _now() internal view returns (uint256) {
    return block.timestamp;
  } 

  function _getStatus(address target) internal view returns(bool, bool, bool, bool, bool, bool) {
    return (
      profs[target].status[Share(0)],
      profs[target].status[Share(1)],
      profs[target].status[Share(2)],
      profs[target].status[Share(6)],
      profs[target].status[Share(5)],
      profs[target].status[Share(4)]
    );
  }

  /**@notice Users in the Categ can claim fee reward if they're eligible
    Note: Referees are extempted
  */

  function claimRewardExemptReferee() public whenNotPaused returns (bool) {
    (, bool isSouliber, bool isUplin,, bool isStaker, bool isBoard) = _getStatus(_msgSender());
    // require(!isSolibee && !isRef, "Ref: Use designated method");
    uint256 shr;
    if (isSouliber || isUplin) {
      shr = rev.shares[_msgSender()];
      rev.shares[_msgSender()] = 0;
    } else {
      require(isStaker || isBoard, "Not eligible");
      require(rev.lastUnlockedDate > profs[_msgSender()].lastClaimedDate, "Already claimed");
      profs[_msgSender()].lastClaimedDate = SafeCast.toUint64(rev.lastUnlockedDate);
      uint256 lastBalChanged = profs[_msgSender()].lastBalChanged;
      (uint stak, uint bor) = _getThresholds();
      require(
        profs[_msgSender()].stake >= stak || 
        profs[_msgSender()].stake >= bor && 
        _now() - lastBalChanged >= 30 days,
        "Not eligible"
      );
      Categ cat = profs[_msgSender()].cat;
      shr = isStaker ? rev.stakersShare : rev.boardShare;
      rev.revenue[cat][rev.round + 2] -= shr;

    }
    require(shr > 0, "No generated fee ATM");
    SafeBEP20.safeTransfer(IERC20(token), _msgSender(), shr);

    emit Claimed(_msgSender(), shr);
    return true;
  }

  ///@dev Only referee can claim using this method
  function claimReferralReward() public returns (bool) {
    (,,, bool isRef,,) = _getStatus(_msgSender());
    require(isRef, "No referred");
    uint256 claim = rev.shares[_msgSender()];
    require(claim > 0, "Nothing to Calim ATM");
    rev.shares[_msgSender()] = 0;
    _setStatus(_msgSender(), Share.REFEREE,  false);
    SafeBEP20.safeTransfer(IERC20(token), _msgSender(), claim);

    emit Claimed(_msgSender(), claim);
    return true;
  }

  /**@dev Move unclaimed reward to "to"
      @param to - address to receive balance
      @param index - Which of the unclaimed pool balance from the Category do you want to move?
      Note: Callable only by the owner
  */
  function moveUnclaimedReward(address to, uint8 index) public onlyowner lessThan3(index) returns (bool) {
    uint256 unclaimed = rev.revenue[Categ(index)][rev.round + 2];
    require(unclaimed > 0, "No unclained revenue");
    rev.revenue[Categ(index)][rev.round + 2] = 0;
    address[2] memory _to = [to, router];
    uint sP;
    for(uint8 i = 0; i < _to.length; i++) {
        sP = unclaimed.mul(30).div(100);
        address to_ = _to[i];
        if(to_ == to) {
            sP = unclaimed.mul(70).div(100);
        }
        SafeBEP20.safeTransfer(IERC20(token), to_, sP);
    }

    return true;
  }

  ///@dev View: Returbs the minimum stake for both staker and board members
  function _getThresholds() internal view returns (uint256, uint256) {
    return (thresholds[1], thresholds[2]);
  }

  ///@dev Internal: updates target's PROFILE status
  function _updateState(
    address target,
    uint8 cmd) internal returns (bool) {
      (uint256 staker, uint256 board) = _getThresholds();
      uint256 lastBalChanged = profs[target].lastBalChanged;
      uint curStake = _stakes(target);
      if(cmd == 0) {
        if(curStake >= board) {
          _setStatus(target, Share.BOARD, true);
        } else if(curStake < board && curStake >= staker) {
          _setStatus(target, Share.STAKER, true);
        } else { 
          _setStatus(target, Share.BOARD, false);
          _setStatus(target, Share.STAKER, false);
        }

        if(lastBalChanged == 0) {
          profs[target].lastBalChanged = _now();
        }
      } else {
        profs[target].lastBalChanged = _now();
        _setStatus(target, Share.STAKER,  false);
        _setStatus(target, Share.BOARD,  false);
      } 
      return true;
  }

  /**@notice Utility to stake SLIB Token
    Note: Must not be disabled
    Staker's stake balance are tracked hence if an user unstake before the unlocked date, they 
    will lose the reward. They must keep the stake up to a minimum of 30 days
  */
  function stakeSlib(uint256 amount) public whenNotPaused returns (bool) {
    (uint stak, uint bor) = _getThresholds();
    if(!hasStake(_msgSender())) {
      if(amount >= bor) {
        boardCount ++;
      }
      if(amount >= stak && amount < bor){
        stakersCount ++;
      }
    }
    (bool thisSuccess, ) = token.call(abi.encodeWithSelector(TOGGLE_SELECTOR, _msgSender(), amount, 0));
    require(thisSuccess, "Stake: operation failed");
    profs[_msgSender()].stake = _stakes(_msgSender()).add(amount);
    _updateState(_msgSender(), 0);

    emit Staked(_msgSender(), amount);
    return true;
  }

  /**@notice Utility for to unstake SLIB Token
    Note: Must not be disabled
    Staker's stake balance are tracked hence if an user unstake before the unlocked date, they 
    will lose the reward. They must keep the stake up to a minimum of 30 days
  */
  function unstakeSlib() public whenNotPaused returns (bool) {
      uint256 curStake = _stakes(_msgSender());
      require(curStake > 0, "No stake");
      profs[_msgSender()].stake = 0;
      (bool thisSuccess, ) = token.call(abi.encodeWithSelector(TOGGLE_SELECTOR, _msgSender(), curStake, 1));
      require(thisSuccess, "Unstake: operation failed");
      _updateState(_msgSender(), 1);

      emit Unstaked(_msgSender(), curStake);
      return true;
  }

  //@dev shows if target has stake running or not
  function hasStake(address target) public view returns (bool) {
    return _stakes(target) > 0;
  }

  ///@dev Internal: Returns stake position of @param target
  function _stakes(address target) internal view returns (uint256) {
    return profs[target].stake;
  }

  ///@dev Public: Returns stake position of @param target
  function stakes(address target) public view returns (uint256) {
    return _stakes(target);
  }

  /**@param to - Soullibee routes a call to a specific Soulliber @param "to"
      Performs a safe external low level calls to feeDistributor address
  */
  function routACall(address to) public whenNotPaused isASoulliber(to) returns (bool) {
    require(profs[_msgSender()].status[Share.SOULLIBEE], "Not registered");
    uint256 _fee = rev.perCallCharge;
    address ref = profs[to].referee;
    uint curId = rev.id;
    rev.id = curId + 1;
    profs[to].callIds.push(curId);
    (bool thisSuccess, ) = token.call(abi.encodeWithSelector(TOGGLE_SELECTOR, _msgSender(), _fee, 2));
    require(thisSuccess, "Call: operation failed");
    Categ ofClient = profs[to].cat;
    _setStatus(to, Share.REFEREE, true);
    _receiveFeeUpdate(to, _fee, ofClient, ref);
    emit CallSent(to, _msgSender());

    return true;
  }

  ///@dev Internal : Sets @param target 's status to true
  function _setStatus(address target, Share sh, bool stat) internal {
    profs[target].status[sh] = stat;
  }

  ///@dev sets new fee on calls.
  function updateCallCharge(uint256 newPerCallCharge) public onlyAdmin {
    rev.perCallCharge = newPerCallCharge;
  }

  /**@dev sets minimum hold in SLIB for eitherstakers
  */
  function setMinimumHoldForStaker(uint256 amount) public onlyAdmin {
    thresholds[1] = amount;
  }

  /**@dev sets minimum hold in SLIB for either board
  */
  function setMinimumHoldForBoard(uint256 amount) public onlyAdmin {
    thresholds[2] = amount;
  }

  /**@dev sets minimum hold in SLIB for either board or stakers
  */
  function getMinimumHolds() public view returns (uint256, uint256) {
    return (thresholds[1], thresholds[2]);
  }

  ///@notice Returns the total number of members in each "catIndex"
  function getCounterOfEachCategory(uint8 categoryIndex) public view onlyAdmin lessThan3(categoryIndex) returns (uint256) {
    return counter[categoryIndex];
  }

  ///@notice Read only: returns rate for each subcategory in each category
  function getRate(uint8 categoryIndex) public view lessThan3(categoryIndex) returns (uint256[7] memory) {
    return rates[Categ(categoryIndex)];
  }

  ///@dev Emergency withdraw function: Only owner is permitted
  function emergencyWithdraw(address to, uint256 amount) public onlyOwner returns (bool) {
    _notZero(to);
    require(address(this).balance >= amount, "Insufficeint balance");
    (bool success, ) = to.call{ value: amount }("");
    require(success, "Transfer errored");
    return true;
  }

  ///@dev Returns current withdrawal window
  function getWIthdrawalWindow() public view returns(uint96) {
    return rev.withdrawWindow;    
  }

}