/**
 *Submitted for verification at polygonscan.com on 2022-01-26
*/

pragma solidity ^0.8.0;

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
//------
// removed: MIT

pragma solidity ^0.8.0;

//removed"../utils/Context.sol";

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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
//------
// removed: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
//------
// removed: MIT

pragma solidity ^0.8.0;

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

        (bool success, ) = recipient.call{value: amount}("");
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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
//------
// removed: MIT

pragma solidity ^0.8.0;

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
//------
// removed: MIT

pragma solidity ^0.8.0;

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
//------
// removed: MIT

pragma solidity ^0.8.0;

//removed"../IERC20.sol";
//removed"../../../utils/Address.sol";

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
//------
// removed: MIT
pragma solidity 0.8.2;

//removed"@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//removed"@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @notice Library for handling safe token transactions including fee per transaction tokens.
 */
abstract contract TokenReceivable is ReentrancyGuard {
  using SafeERC20 for IERC20;
  mapping(address => uint256) public inventory; // Amount of received tokens that are accounted for

  /**
   @notice Sync the inventory of a token based on amount changed
   @param token The token address
   @return amount The changed amount
   */
  function sync(address token) internal returns (uint256 amount) {
    uint256 inv = inventory[token];
    uint256 balance = IERC20(token).balanceOf(address(this));
    amount = balance - inv;
    inventory[token] = balance;
  }

  /**
   @notice Safely sends a token out and updates the inventory
   @param token The token address
   @param payee The payee
   @param amount The amount
   */
  function sendToken(address token, address payee, uint256 amount) internal {
    inventory[token] = inventory[token] - amount;
    IERC20(token).safeTransfer(payee, amount);
  }
}
//------
// removed: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}
//------
// removed: MIT
pragma solidity ^0.8.0;

//removed"@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//removed"@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract ERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal virtual {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}
//------
// removed: MIT
pragma solidity ^0.8.0;

interface IGeneralTaxDistributor {
    function distributeTax(address token) external returns (uint256);
}
//------
// removed: MIT
pragma solidity ^0.8.0;

interface IHasTaxDistributor {
	function taxDistributor() external returns (address);
}
//------
// removed: MIT
pragma solidity 0.8.2;

interface ICrucibleTokenDeployer {
    function parameters()
        external
        returns (
            address,
            address,
            uint64,
            uint64,
            string memory,
            string memory
        );
}
//------
// removed: MIT
pragma solidity 0.8.2;

interface ICrucibleToken {
    enum OverrideState {
        Default,
        OverrideIn,
        OverrideOut,
        OverrideBoth
    }

    function deposit(address to) external returns (uint256);

    function withdraw(address to, uint256 amount)
        external
        returns (uint256, uint256);

    function baseToken() external returns (address);

    function overrideFee(
        address target,
        OverrideState overrideType,
        uint64 newFeeX10000
    ) external;

    function upgradeRouter(address router) external;
}
//------
// removed: MIT
pragma solidity 0.8.2;

//removed"./ICrucibleToken.sol";
//removed"./ICrucibleTokenDeployer.sol";
//removed"./ICrucibleFactory.sol";
//removed"../taxing/IHasTaxDistributor.sol";
//removed"../taxing/IGeneralTaxDistributor.sol";
//removed"../common/ERC20/ERC20.sol";
//removed"../common/math/FullMath.sol";
//removed"../staking/library/TokenReceivable.sol";

contract CrucibleToken is ERC20, TokenReceivable, ICrucibleToken {
    uint256 constant MAX_FEE_X10k = 0.6 * 10000;

    struct FeeOverride {
        OverrideState over;
        uint64 feeX10000;
    }

    address public immutable factory;
    address public router;
    address public override baseToken; // Remocing immutables to allow etherscan verification to work. Hopefully etherscan gives us a solution
    uint64 public feeOnTransferX10000;
    uint64 public feeOnWithdrawX10000;
    mapping(address => FeeOverride) public feeOverrides;

    event Withdrawn(uint256 amount, uint256 fee, address from, address to);
    event Deposited(address token, uint256 amount, address to);
    event FeeSet(address target, OverrideState overrideType, uint64 feeX10k);

    modifier onlyRouter() {
        require(msg.sender == router, "CT: not allowed");
        _;
    }

    constructor() {
        address token;
        address fac;
        (
            fac,
            token,
            feeOnTransferX10000,
            feeOnWithdrawX10000,
            name,
            symbol
        ) = ICrucibleTokenDeployer(msg.sender).parameters();
        decimals = safeDecimals(token);
        baseToken = token;
        router = ICrucibleFactory(fac).router();
        factory = fac;
    }

    /**
     @notice Upgrades a router
     @param _router The new router
     @dev Can only be called by the current router
     */
    function upgradeRouter(address _router
    ) external override onlyRouter {
        require(_router != address(0), "CT: router required");
        router = _router;
    }

    /**
     @notice Overrides fee for a target
     @param target The target to be overriden
     @param overrideType The type of override
     @param newFeeX10000 The new fee
     @dev Can only be called by the router
     */
    function overrideFee(
        address target,
        OverrideState overrideType,
        uint64 newFeeX10000
    ) external override onlyRouter {
        require(newFeeX10000 < MAX_FEE_X10k, "CT: fee too large");
        feeOverrides[target] = FeeOverride({
            over: overrideType,
            feeX10000: newFeeX10000
        });
        emit FeeSet(target, overrideType, newFeeX10000);
    }

    /**
     @notice Deposits into the crucible
        Can only be called by the router
     @param to Receiver of minted tokens
     @return amount The deposited amount
     */
    function deposit(address to
    ) external override onlyRouter returns (uint256 amount) {
        amount = sync(baseToken);
        require(amount != 0, "CT: empty");
        _mint(to, amount);
        emit Deposited(baseToken, amount, to);
    }

    /**
     @notice Withdraws from the crucible
     @param to Receiver of minted tokens
     @param amount The amount to withdraw
     @return fee The fee
     @return withdrawn The withdrawn amounts
     */
    function withdraw(address to, uint256 amount
    ) external override returns (uint256 fee, uint256 withdrawn) {
        (fee, withdrawn) = _withdraw(msg.sender, to, amount);
    }

    /*
     @notice Burn the underlying asset. If not burnable, send to the factory.
     @param amount Amount to burn
     */
    function burn(uint256 amount
    ) external virtual {
        require(amount != 0, "CT: amount required");
        doBurn(msg.sender, amount);
    }

    /*
     @notice Burn the underlying asset. If not burnable, send to the factory.
     @param from The address to burn from
     @param amount Amount to burn
     */
    function burnFrom(address from, uint256 amount
    ) external virtual {
        require(from != address(0), "CT: from required");
        require(amount != 0, "CT: amount required");
        uint256 decreasedAllowance = allowance[from][msg.sender] - amount;

        _approve(from, msg.sender, decreasedAllowance);
        doBurn(from, amount);
    }

    /**
     @notice Withdraws from crucible
     @param from From address
     @param to To address
     @param amount The amount
     @return fee The fee
     @return withdrawn The withdrawn amount
     */
    function _withdraw(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (uint256 fee, uint256 withdrawn) {
        fee = calculateFeeX10000(amount, feeOnWithdrawX10000);
        withdrawn = amount - fee;
        address td = IHasTaxDistributor(router).taxDistributor();
        tax(from, td, fee);
        _burn(from, withdrawn);
        sendToken(baseToken, to, withdrawn);
        emit Withdrawn(amount, fee, from, to);
    }

    /**
     @notice Burns tokens. Send base tokens to factory to be locke or burned later
     @param from The from address
     @param amount The amount
     */
    function doBurn(address from, uint256 amount
    ) internal {
        sendToken(baseToken, factory, amount);
        _burn(from, amount);
    }

    /**
     @notice Overrides the ERC20 transfer method
     @param sender The sender
     @param recipient The recipient
     @param amount The amount
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        FeeOverride memory overFrom = feeOverrides[sender];
        FeeOverride memory overTo = feeOverrides[recipient];
        address td = IHasTaxDistributor(router).taxDistributor();
        if (sender == td || recipient == td) {
            _doTransfer(sender, recipient, amount);
            return;
        }

        uint256 feeRatioX10k = 0;
        bool overriden = false;
        if (
            overFrom.over == OverrideState.OverrideOut ||
            overFrom.over == OverrideState.OverrideBoth
        ) {
            feeRatioX10k = overFrom.feeX10000;
            overriden = true;
        }
        if (
            (overTo.over == OverrideState.OverrideIn ||
                overTo.over == OverrideState.OverrideBoth) &&
            overTo.feeX10000 >= feeRatioX10k
        ) {
            feeRatioX10k = overTo.feeX10000;
            overriden = true;
        }
        if (feeRatioX10k == 0 && !overriden) {
            feeRatioX10k = feeOnTransferX10000;
        }
        uint256 fee = feeRatioX10k == 0 ? 0 : calculateFeeX10000(amount, feeRatioX10k);
        amount = amount - fee;
        if (fee != 0) {
            tax(sender, td, fee);
        }
        _doTransfer(sender, recipient, amount);
    }

    /**
     @notice Just does the transfer
     @param sender The sender
     @param recipient The recipient
     @param amount The amount
     */
    function _doTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        ERC20._transfer(sender, recipient, amount);
    }

    /**
     @notice charges the tax
     @param from From address
     @param taxDist The tax distributor contract
     @param amount The tax amount
     */
    function tax(
        address from,
        address taxDist,
        uint256 amount
    ) internal {
        _doTransfer(from, taxDist, amount);
        IGeneralTaxDistributor(taxDist).distributeTax(address(this));
    }

    /**
     @notice Gets the decimals or default
     @param token The token
     @return The decimals
     */
    function safeDecimals(address token
    ) private view returns (uint8) {
        (bool succ, bytes memory data) = token.staticcall(
            abi.encodeWithSignature(("decimals()"))
        );
        if (succ) {
            return abi.decode(data, (uint8));
        } else {
            return 18;
        }
    }

    /**
     @notice Calculates the fee
     @param amount The amount
     @param feeX10000 The fee rate
     @return The fee amount
     */
    function calculateFeeX10000(uint256 amount, uint256 feeX10000
    ) private pure returns (uint256) {
        return FullMath.mulDiv(amount, feeX10000, 10000);
    }
}
//------
// removed: MIT
pragma solidity 0.8.2;
//removed"@openzeppelin/contracts/access/Ownable.sol";

contract WithAdmin is Ownable {
	address public admin;
	event AdminSet(address admin);

	function setAdmin(address _admin) external onlyOwner {
		admin = _admin;
		emit AdminSet(_admin);
	}

	modifier onlyAdmin() {
		require(msg.sender == admin || msg.sender == owner(), "WA: not admin");
		_;
	}
}
//------
// removed: MIT
pragma solidity ^0.8.0;

library StringLib {
	// Taken from: 
	// https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
	function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

	function strToB32(string memory s) internal pure returns (bytes32 len, bytes32 b1, bytes32 b2) {
		bytes memory t = bytes(s);
		assembly {
			len := mload(s)
			b1 := mload(add(s, 32))
		}
		if (t.length >= 16) {
			assembly {
				b2 := mload(add(s, 64))
			}
		} else {
			b2 = 0;
		}
	}

	function b32ToStr(bytes32 len, bytes32 b1, bytes32 b2, uint256 maxLen) internal pure returns (string memory str) {
		require(maxLen <= 64, "maxLen");
		bytes memory t;
		uint256 l = uint256(len);
		if (l > maxLen) {
			len = bytes32(maxLen);
		}
		assembly {
			mstore(t, len)
			mstore(add(t, 32), b1)
		}
		if (uint256(len) >= 16) {
			assembly {
				mstore(add(t, 64), b2)
			}
		}
		str = string(t);
	}
}
//------
// removed: BUSL-1.1
pragma solidity ^0.8.0;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}
//------
// removed: MIT
pragma solidity 0.8.2;

//removed"./CrucibleToken.sol";

abstract contract CrucibleTokenDeployer is ICrucibleTokenDeployer {
    struct Parameters {
        address factory;
        address baseToken;
        uint64 feeOnTransferX10000;
        uint64 feeOnWithdrawX10000;
        string name;
        string symbol;
    }

    Parameters public override parameters;

    /**
     @notice Deploys a crucible token
     @param factory The factory
     @param baseToken The base token
     @param feeOnTransferX10000 Fee on transfer rate per 10k
     @param feeOnWithdrawX10000 Fee on withdraw rate per 10k
     @param name The name
     @param symbol The symbol
     @return token The deployed token address
     */
    function deploy(
        address factory,
        address baseToken,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000,
        string memory name,
        string memory symbol
    ) internal returns (address token) {
        parameters = Parameters({
            factory: factory,
            baseToken: baseToken,
            feeOnTransferX10000: feeOnTransferX10000,
            feeOnWithdrawX10000: feeOnWithdrawX10000,
            name: name,
            symbol: symbol
        });

        token = address(
            new CrucibleToken{
                salt: keccak256(
                    abi.encode(
                        baseToken,
                        feeOnTransferX10000,
                        feeOnWithdrawX10000
                    )
                )
            }()
        );
        delete parameters;
    }
}
//------
// removed: MIT
pragma solidity 0.8.2;

interface ICrucibleFactory {
    function getCrucible(
        address baseToken,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) external view returns (address);

    function router() external view returns (address);
}
//------
// removed: MIT
pragma solidity ^0.8.0;

interface IFerrumDeployer {
    function initData() external returns (bytes memory);
}
//------
// removed: MIT
pragma solidity ^0.8.0;

interface IBurnable {
    function burn(uint256 amount) external;
}
//------
// removed: MIT
pragma solidity 0.8.2;

//removed"../common/IBurnable.sol";
//removed"../common/IFerrumDeployer.sol";
//removed"./ICrucibleFactory.sol";
//removed"./CrucibleTokenDeployer.sol";
//removed"../staking/factory/NoDelegateCall.sol";
//removed"../common/strings/StringLib.sol";
//removed"../common/WithAdmin.sol";

/// @title Factory for generating crucible tokens
/// @author Ferrum Network
contract CrucibleFactory is
    CrucibleTokenDeployer,
    NoDelegateCall,
    ICrucibleFactory,
    WithAdmin
{
    uint64 constant MAX_FEE = 10000;
    address public immutable override router;
    mapping(bytes32 => address) private crucible;

    event CrucibleCreated(
        address token,
        address baseToken,
        uint256 feeOnTransferX10000,
        uint256 feeOnWithdrawX10000
    );

    constructor() {
        (router) = abi.decode(
            IFerrumDeployer(msg.sender).initData(),
            (address)
        );
    }

    /**
    @notice Returns the crucible address
    @param baseToken The base token address
    @param feeOnTransferX10000 Fee on transfer rate per 10k
    @param feeOnWithdrawX10000 Fee on withdraw rate per 10k
    @return The crucible address if any
     */
    function getCrucible(
        address baseToken,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) external view override returns (address) {
        return
            crucible[
                crucibleKey(baseToken, feeOnTransferX10000, feeOnWithdrawX10000)
            ];
    }

    /**
    @notice Creates a crucible
    @param baseToken The base token address
    @param feeOnTransferX10000 Fee on transfer rate per 10k
    @param feeOnWithdrawX10000 Fee on withdraw rate per 10k
    @return token The created crucible address
     */
    function createCrucible(
        address baseToken,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) external noDelegateCall returns (address token) {
        return
            _createCrucible(
                baseToken,
                safeName(baseToken),
                safeSymbol(baseToken),
                feeOnTransferX10000,
                feeOnWithdrawX10000
            );
    }

    /**
    @notice Creates a crucible directly
    @dev To be used only by contract admin in case normal crucible generation
         cannot succeed.
    @return token The created crucible token address
     */
    function createCrucibleDirect(
        address baseToken,
        string memory name,
        string memory symbol,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) external onlyAdmin returns (address token) {
        bytes32 key = validateCrucible(
            baseToken,
            name,
            symbol,
            feeOnTransferX10000,
            feeOnWithdrawX10000
        );
        return
            _createCrucibleWithName(
                key,
                baseToken,
                name,
                symbol,
                feeOnTransferX10000,
                feeOnWithdrawX10000
            );
    }

    /**
    @notice Tokens accumulated in the factory can be burned by anybody.
    @param token The token address
     */
    function burn(address token
    ) external {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IBurnable(token).burn(amount);
    }

    /**
     @notice Creats a crucible
     @param baseToken The base token
     @param name The name
     @param symbol The symbol
     @param feeOnTransferX10000 Fee on transfer over 10k
     @param feeOnWithdrawX10000 Fee on withdraw over 10k
     @return token The crucible token address
     */
    function _createCrucible(
        address baseToken,
        string memory name,
        string memory symbol,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) internal returns (address token) {
        bytes32 key = validateCrucible(
            baseToken,
            name,
            symbol,
            feeOnTransferX10000,
            feeOnWithdrawX10000
        );
        string memory feeOnT = StringLib.uint2str(feeOnTransferX10000);
        string memory feeOnW = StringLib.uint2str(feeOnWithdrawX10000);
        string memory cName = string(
            abi.encodePacked("Crucible: ", name, " ", feeOnT, "X", feeOnW)
        );
        string memory cSymbol = string(
            abi.encodePacked(symbol, feeOnT, "X", feeOnW)
        );
        token = _createCrucibleWithName(
            key,
            baseToken,
            cName,
            cSymbol,
            feeOnTransferX10000,
            feeOnWithdrawX10000
        );
    }

    /**
     @notice Validates crucible parameters
     @param baseToken The base token
     @param name The name
     @param symbol The symbol
     @param feeOnTransferX10000 Fee on transfer over 10k
     @param feeOnWithdrawX10000 Fee on withdraw over 10k
     */
    function validateCrucible(
        address baseToken,
        string memory name,
        string memory symbol,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) internal view returns (bytes32 key) {
        require(bytes(name).length != 0, "CF: name is required");
        require(bytes(symbol).length != 0, "CF: symbol is required");
        require(
            feeOnTransferX10000 != 0 || feeOnWithdrawX10000 != 0,
            "CF: at least one fee is required"
        );
        require(feeOnTransferX10000 < MAX_FEE, "CF: fee too high");
        require(feeOnWithdrawX10000 < MAX_FEE, "CF: fee too high");
        key = crucibleKey(baseToken, feeOnTransferX10000, feeOnWithdrawX10000);
        require(crucible[key] == address(0), "CF: already exists");
    }

    /**
     @notice Creates a crucible wit the given name
     @param key The crucible key
     @param baseToken The base token
     @param cName The name
     @param cSymbol The symbol
     @param feeOnTransferX10000 Fee on transfer over 10k
     @param feeOnWithdrawX10000 Fee on withdraw over 10k
     */
    function _createCrucibleWithName(
        bytes32 key,
        address baseToken,
        string memory cName,
        string memory cSymbol,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) internal returns (address token) {
        token = deploy(
            address(this),
            baseToken,
            feeOnTransferX10000,
            feeOnWithdrawX10000,
            cName,
            cSymbol
        );
        crucible[key] = token;
        emit CrucibleCreated(
            token,
            baseToken,
            feeOnTransferX10000,
            feeOnWithdrawX10000
        );
    }

    /**
     @notice Returns a name or default
     @param token The token
     @return The name
     */
    function safeName(address token
    ) internal view returns (string memory) {
        (bool succ, bytes memory data) = token.staticcall(
            abi.encodeWithSignature(("name()"))
        );
        if (succ) {
            return abi.decode(data, (string));
        } else {
            return "Crucible";
        }
    }

    /**
     @notice returns the symbol or default
     @param token The token
     @return The symbol
     */
    function safeSymbol(address token
    ) internal view returns (string memory) {
        (bool succ, bytes memory data) = token.staticcall(
            abi.encodeWithSignature(("symbol()"))
        );
        require(succ, "CF: Token has no symbol");
        return abi.decode(data, (string));
    }

    /**
     @notice Creates a key for crucible
     @param baseToken The base token
     @param feeOnTransferX10000 Fee on transfer over 10k
     @param feeOnWithdrawX10000 Fee on withdraw over 10k
     @return The key
     */
    function crucibleKey(
        address baseToken,
        uint64 feeOnTransferX10000,
        uint64 feeOnWithdrawX10000
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    baseToken,
                    feeOnTransferX10000,
                    feeOnWithdrawX10000
                )
            );
    }
}