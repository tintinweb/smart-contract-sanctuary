/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


// 
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)
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

// 
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)
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

// 
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)
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

// 
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)
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
     * by making the `nonReentrant` function external, and making it call a
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

// 
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)
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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// 
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)
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

// 
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// 
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// 
/**
 * @title FlexibleTimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame that can be adjusted by the owner.
 */
contract FlexibleTimedCrowdsale {
    using SafeMath for uint256;

    uint256 public openingTime;
    uint256 public closingTime;

    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen() virtual {
        // solium-disable-next-line security/no-block-members
        require(
            block.timestamp >= openingTime && block.timestamp <= closingTime,
            "Crowdsale is not opening"
        );
        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     */
    constructor(uint256 _openingTime, uint256 _closingTime) {
        // solium-disable-next-line security/no-block-members
        require(_openingTime > 0, "Opening time must be valid");
        require(_closingTime >= block.timestamp, "Closing time must be valid");

        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view virtual returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > closingTime;
    }

    /**
     * @dev Re-adjust the sale time based
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time
     */
    function adjustSaleTime(uint256 _openingTime, uint256 _closingTime)
        external
    {
        require(_closingTime >= block.timestamp);

        if (_openingTime > 0) {
            openingTime = _openingTime;
        }
        closingTime = _closingTime;
    }
}

// 
/**
 * @title PrivateSaleContract
 */
contract PrivateSaleContract is
    Ownable,
    ReentrancyGuard,
    FlexibleTimedCrowdsale
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    struct VestingSchedule {
        bool initialized;
        // beneficiary of tokens after they are released
        address beneficiary;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256 released;        
    }    

    uint256 public constant DECIMALS = 10**18; // MEI Token has the same decimals as Ether (18)
    uint256 public constant VESTING_CLIFF = 335 days; // Cliff for 1 year
    uint256 public constant VESTING_TOTAL_DURATION = 695 days; // Total vesting for 2 years
    uint256 public constant VESTING_DURATION =
        VESTING_TOTAL_DURATION - VESTING_CLIFF; // Vesting duration after cliff (1 year)
    uint256 public constant VESTING_SLICE_PERIOD = 30 days;
    uint256 public constant VESTING_SLICES_TOTAL = VESTING_DURATION / VESTING_SLICE_PERIOD;

    // aggregation data
    uint256 public totalTokenPurchased;
    uint256 public totalTokenReleased;

    // exchange rate of 1 MEI to USDT
    uint256 public tokenUsdRate;

    // Purchasable packages
    uint256[] private PURCHASE_PACKAGES_USD = [5000 ether, 10000 ether, 20000 ether, 30000 ether];    

    // address of the MEI token
    IERC20 private immutable _token;

    // address of the stable token
    mapping(string => IERC20) private _stableToken;
    
    // vest timing
    uint256 private immutable _startVestingTime;
    uint256 private immutable _endVestingTime;

    // white-list mapping
    mapping (address => bool) private whitelisteds;

    mapping(address => VestingSchedule) private vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;    

    event PurchasedWithCoin(uint256 amount, uint256 purchasedAmount);
    event PurchasedWithStable(uint256 amount, uint256 purchasedAmount);
    event Released(uint256 amount);

    /**
     * @dev Reverts if no vesting schedule matches the passed identifier.
     */
    modifier onlyIfVestingScheduleExists(address beneficiary) {
        require(vestingSchedules[beneficiary].initialized == true, "PrivateSaleContract: Vesting schedule must exist");
        _;
    }

    /**
     * @dev Reverts if not whitelisted
     */
    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "PrivateSaleContract: Only whitelisted wallets");
        _;
    }

    /**
     * @dev Creates a vesting contract.
     * @param token_ address of the ERC20 token contract
     * @param _openingTime Crowdsale opening time
     * @param _closingTime Crowdsale closing time     
     */
    constructor(
        address token_,
        uint256 _openingTime,
        uint256 _closingTime        
    ) FlexibleTimedCrowdsale(_openingTime, _closingTime) {
        require(token_ != address(0x0));

        tokenUsdRate = (5 * DECIMALS) / 100;
        
        _token = IERC20(token_);

        _startVestingTime = _closingTime.add(VESTING_CLIFF);
        _endVestingTime = _closingTime.add(VESTING_CLIFF).add(VESTING_DURATION);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice Returns the total amount of vesting schedules.
     * @return the total amount of vesting schedules
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    /**
     * @dev Returns the address of the ERC20 token managed by the vesting contract.
     */
    function getToken() external view returns (address) {
        return address(_token);
    }

    /**
     * @dev add a new stable coin contract address
     * @param name Name of token
     * @param token Token contract adddress
     */
    function allowStableCoin(string calldata name, address token) public onlyOwner {
        _stableToken[name] = IERC20(token);
    }

    /**
     * @dev set TOKEN to USD exchange rate (number of USDs for 1 TOKEN)
     *
     * Requirements:
     * - Only the owner can set
     *
     * @param rate_ exchange rate in fixed point decimals
     */
    function setTokenUsdRate(uint256 rate_) public onlyOwner {
        tokenUsdRate = rate_;
    }

    /**
     * @dev Withdraw total ether to owner's wallet
     *
     * Requirements:
     * - Only the owner can withdraw
     * - The contract must have ether left.
     */
    function withdrawSaleFunds() external onlyOwner {
        require(
            address(this).balance > 0,
            "PrivateSaleContract: Contract's balance is empty"
        );

        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Withdraw total stable coins to owner's wallet
     *
     * Requirements:
     * - Only the owner can withdraw
     */
    function withdrawStableToken(string calldata name) external onlyOwner {
        IERC20 token = _stableToken[name];
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(owner(), balance);
    }

    /**
     * @dev Withdraw the remaining tokens to owner's wallet
     *
     * Requirements:
     * - Only the owner can withdraw.
     */
    function withdrawRemainedToken() external onlyOwner {
        _token.safeTransfer(owner(), this.getWithdrawableAmount());
    }

    /**
     * @dev give many accounts access to whitelisted
     * @param accounts Accounts to grant access
     */
    function addToWhitelisted(address[] calldata accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            whitelisteds[accounts[i]] = true;
        }
    }

    /**
     * @dev remove an account's access to whitelisted
     * @param accounts Accounts to remove access
     */
    function removeWhitelisted(address[] calldata accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            whitelisteds[accounts[i]] = false;
        }
    }

    /**
     * @dev check if an account is whitelisted
     * @return bool
     */
    function isWhitelisted(address account) public view returns (bool) {
        require(account != address(0));
        return whitelisteds[account];
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _amount
    ) public onlyOwner {
        require(
            this.getWithdrawableAmount() >= _amount,
            "PrivateSaleContract: cannot create vesting schedule because not sufficient tokens"
        );
        require(_amount > 0, "PrivateSaleContract: amount must be > 0");

        if (vestingSchedules[_beneficiary].initialized == true) {
            vestingSchedules[_beneficiary].amountTotal = vestingSchedules[_beneficiary].amountTotal.add(_amount);
        } else {
            vestingSchedules[_beneficiary] = VestingSchedule(
                true,
                _beneficiary,
                _amount,
                0
            );
        }
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(_amount);
        totalTokenPurchased = totalTokenPurchased.add(_amount);
    }

    /**
     * @notice Withdraw the specified amount of tokens to owner wallet
     * @param amount the amount to withdraw
     */
    function withdraw(uint256 amount) public nonReentrant onlyOwner {        
        _token.safeTransfer(owner(), amount);
    }

    /**
     * @notice Buy Token with stable coin under vesting conditions.
     * @param name Name of token to use
     * @param package Amount of stable token to use (to be multiplied by step)
     */
    function buyPackageWithStable(string calldata name, uint256 package) external {        
        // require(vestingSchedules[msg.sender].initialized != true, "PrivateSaleContract: multiple purchases not allowed");

        uint256 amount = PURCHASE_PACKAGES_USD[package];
        require(amount > 0, "PrivateSaleContract: invalid package id");

        IERC20 token = _stableToken[name];

        uint256 purchasableAmount = amount.mul(DECIMALS).div(tokenUsdRate);
        require(
            this.getWithdrawableAmount() >= purchasableAmount,
            "PrivateSaleContract: not enough funds to buy"
        );

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Could not transfer USD"
        );

        if (vestingSchedules[msg.sender].initialized == true) {
            vestingSchedules[msg.sender].amountTotal = vestingSchedules[msg.sender].amountTotal.add(purchasableAmount);
        } else {
            // vesting starts now
            vestingSchedules[msg.sender] = VestingSchedule(
                true,
                msg.sender,
                purchasableAmount,
                0
            );
        }

        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(purchasableAmount);        
        totalTokenPurchased = totalTokenPurchased.add(purchasableAmount);
        emit PurchasedWithStable(amount, purchasableAmount);
    }

    /**
     * @notice Release all vested tokens.
     * @param beneficiary the beneficiary of the vesting
     */
    function release(address beneficiary)
        public
        nonReentrant
        onlyIfVestingScheduleExists(beneficiary)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[beneficiary];
        bool isBeneficiary = msg.sender == beneficiary;
        bool isOwner = msg.sender == owner();
        require(
            isBeneficiary || isOwner,
            "PrivateSaleContract: only beneficiary and owner can release vested tokens"
        );
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(
            vestedAmount > 0,
            "PrivateSaleContract: no tokens vested yet"
        );
        
        vestingSchedule.released = vestingSchedule.released.add(vestedAmount);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(vestedAmount);

        address payable payableBeneficiary = payable(beneficiary);
        _token.safeTransfer(payableBeneficiary, vestedAmount);

        totalTokenReleased = totalTokenReleased.add(vestedAmount);
        emit Released(vestedAmount);
    }

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @return the vested amount
     */
    function computeReleasableAmount()
        public
        view
        onlyIfVestingScheduleExists(msg.sender)
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @notice Returns the vesting schedule information for a given identifier.
     * @return the vesting schedule structure information
     */
    function getVestingSchedule()
        public
        view
        returns (VestingSchedule memory)
    {
        return vestingSchedules[msg.sender];
    }

    /**
     * @dev Returns the amount of tokens that can be withdrawn by the owner.
     * @return the amount of tokens
     */
    function getWithdrawableAmount() public view returns (uint256) {
        return _token.balanceOf(address(this)).sub(vestingSchedulesTotalAmount);
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = getCurrentTime();
        if (
            currentTime < _startVestingTime
        ) {
            return 0;
        } else if (
            currentTime >= _endVestingTime
        ) {
            return vestingSchedule.amountTotal.sub(vestingSchedule.released);
        } else {
            uint256 vestedSlicesCount = currentTime.sub(_startVestingTime).div(VESTING_SLICE_PERIOD);
            uint256 vestedAmount = vestingSchedule
                .amountTotal
                .mul(vestedSlicesCount)
                .div(VESTING_SLICES_TOTAL);
            return vestedAmount.sub(vestingSchedule.released);
        }
    }

    /**
     * @dev overridable timestamp getter
     */
    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// 
contract MockPrivateSaleContract is PrivateSaleContract {
    uint256 public mockTime = 0;

    constructor(
        address token_,
        uint256 _openingTime,
        uint256 _closingTime        
    ) PrivateSaleContract(token_, _openingTime, _closingTime) {}

    function setForwardTime(uint256 _time) external {
        mockTime = _time;
    }

///// Truong ADD
    function addForwardTime(uint256 _time) external {
        mockTime = mockTime + _time;
    }

    function getCurrentTimePublic() external view returns (uint256) {
        uint256 currentTime =  getCurrentTime();
        return currentTime;
    }

    modifier onlyWhileOpen() override {
        // solium-disable-next-line security/no-block-members
        uint256 currentTime = getCurrentTime();
        require(
            currentTime >= openingTime && currentTime <= closingTime,
            "Crowdsale is not opening"
        );
        _;
    }

    function hasClosed() public view override returns (bool) {
        // solium-disable-next-line security/no-block-members
        return getCurrentTime() > closingTime;
    }

    function getCurrentTime() internal view virtual override returns (uint256) {
        return block.timestamp + mockTime;
    }
}