/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// Dependency file: @openzeppelin/contracts/math/Math.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


// pragma solidity >=0.6.0 <0.8.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity >=0.6.2 <0.8.0;

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
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


// Dependency file: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


// pragma solidity >=0.6.0 <0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Dependency file: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Context.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity >=0.6.0 <0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
}


// Dependency file: contracts/utils/SafeDecimalMath.sol

// pragma solidity >=0.6.10 <0.8.0;

// import "@openzeppelin/contracts/math/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint256 private constant decimals = 18;
    uint256 private constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 private constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 private constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(UNIT);
    }

    function multiplyDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(PRECISE_UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    function divideDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(PRECISE_UNIT).div(y);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i.mul(10).div(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen = quotientTimesTen.add(10);
        }

        return quotientTimesTen.div(10);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, and the max value of
     * uint256 on overflow.
     */
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        return c / a != b ? type(uint256).max : c;
    }

    function saturatingMultiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return saturatingMul(x, y).div(UNIT);
    }
}


// Dependency file: contracts/interfaces/IPrimaryMarket.sol

// pragma solidity >=0.6.10 <0.8.0;

interface IPrimaryMarket {
    function claim(address payable account)
        external
        returns (uint256 createdShares, uint256 redeemedUnderlying);

    function transferToFund(uint256 amount) external;

    function settle(
        uint256 day,
        uint256 fundTotalShares,
        uint256 fundUnderlying,
        uint256 underlyingPrice,
        uint256 previousNav
    )
        external
        returns (
            uint256 sharesToMint,
            uint256 sharesToBurn,
            uint256 creationUnderlying,
            uint256 redemptionUnderlying,
            uint256 fee
        );
}


// Dependency file: contracts/interfaces/ILatestPriceOracle.sol

// pragma solidity >=0.6.10 <0.8.0;

interface ILatestPriceOracle {
    function getLatestPrice() external view returns (uint256);
}


// Dependency file: contracts/interfaces/IFund.sol

// pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

// import "contracts/interfaces/ILatestPriceOracle.sol";

interface IFund {
    /// @notice A linear transformation matrix that represents a rebalance.
    ///
    ///         ```
    ///             [ ratioM          0        0 ]
    ///         R = [ ratioA2M  ratioAB        0 ]
    ///             [ ratioB2M        0  ratioAB ]
    ///         ```
    ///
    ///         Amounts of the three tranches `m`, `a` and `b` can be rebalanced by multiplying the matrix:
    ///
    ///         ```
    ///         [ m', a', b' ] = [ m, a, b ] * R
    ///         ```
    struct Rebalance {
        uint256 ratioM;
        uint256 ratioA2M;
        uint256 ratioB2M;
        uint256 ratioAB;
        uint256 timestamp;
    }

    function trancheWeights() external pure returns (uint256 weightA, uint256 weightB);

    function tokenUnderlying() external view returns (address);

    function tokenM() external view returns (address);

    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function underlyingDecimalMultiplier() external view returns (uint256);

    // function twapOracle() external view returns (ITwapOracle);
    function latestPriceOracle() external view returns (ILatestPriceOracle);

    function feeCollector() external view returns (address);

    function endOfDay(uint256 timestamp) external pure returns (uint256);

    function shareTotalSupply(uint256 tranche) external view returns (uint256);

    function shareBalanceOf(uint256 tranche, address account) external view returns (uint256);

    function allShareBalanceOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function shareBalanceVersion(address account) external view returns (uint256);

    function shareAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view returns (uint256);

    function shareAllowanceVersion(address owner, address spender) external view returns (uint256);

    function getRebalanceSize() external view returns (uint256);

    function getRebalance(uint256 index) external view returns (Rebalance memory);

    function getRebalanceTimestamp(uint256 index) external view returns (uint256);

    function currentDay() external view returns (uint256);

    function fundActivityStartTime() external view returns (uint256);

    function exchangeActivityStartTime() external view returns (uint256);

    function isFundActive(uint256 timestamp) external view returns (bool);

    function isPrimaryMarketActive(address primaryMarket, uint256 timestamp)
        external
        view
        returns (bool);

    function isExchangeActive(uint256 timestamp) external view returns (bool);

    function getTotalShares() external view returns (uint256);

    function extrapolateNav(uint256 timestamp, uint256 price)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function calculateNavB(uint256 navM, uint256 navA) external pure returns (uint256);

    function doRebalance(
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 index
    )
        external
        view
        returns (
            uint256 newAmountM,
            uint256 newAmountA,
            uint256 newAmountB
        );

    function batchRebalance(
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        returns (
            uint256 newAmountM,
            uint256 newAmountA,
            uint256 newAmountB
        );

    function refreshBalance(address account, uint256 targetVersion) external;

    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external;

    function mint(
        uint256 tranche,
        address account,
        uint256 amount
    ) external;

    function burn(
        uint256 tranche,
        address account,
        uint256 amount
    ) external;

    function transfer(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function transferFrom(
        uint256 tranche,
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256 newAllowance);

    function increaseAllowance(
        uint256 tranche,
        address sender,
        address spender,
        uint256 addedValue
    ) external returns (uint256 newAllowance);

    function decreaseAllowance(
        uint256 tranche,
        address sender,
        address spender,
        uint256 subtractedValue
    ) external returns (uint256 newAllowance);

    function approve(
        uint256 tranche,
        address owner,
        address spender,
        uint256 amount
    ) external;

    event RebalanceTriggered(
        uint256 indexed index,
        uint256 indexed day,
        uint256 ratioM,
        uint256 ratioA2M,
        uint256 ratioB2M,
        uint256 ratioAB
    );
    event Settled(uint256 indexed day, uint256 navM, uint256 navA, uint256 navB);
    event InterestRateUpdated(uint256 baseInterestRate, uint256 floatingInterestRate);
    event Transfer(
        uint256 indexed tranche,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event Approval(
        uint256 indexed tranche,
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event BalancesRebalanced(
        address indexed account,
        uint256 version,
        uint256 balanceM,
        uint256 balanceA,
        uint256 balanceB
    );
    event AllowancesRebalanced(
        address indexed owner,
        address indexed spender,
        uint256 version,
        uint256 allowanceM,
        uint256 allowanceA,
        uint256 allowanceB
    );
}


// Dependency file: contracts/interfaces/ITrancheIndex.sol

// pragma solidity >=0.6.10 <0.8.0;

/// @notice Amounts of Token M, A and B are sometimes stored in a `uint256[3]` array. This contract
///         defines index of each tranche in this array.
///
///         Solidity does not allow constants to be defined in interfaces. So this contract follows
///         the naming convention of interfaces but is implemented as an `abstract contract`.
abstract contract ITrancheIndex {
    uint256 internal constant TRANCHE_M = 0;
    uint256 internal constant TRANCHE_A = 1;
    uint256 internal constant TRANCHE_B = 2;

    uint256 internal constant TRANCHE_COUNT = 3;
}


// Dependency file: contracts/interfaces/IAddressWhitelist.sol

// pragma solidity >=0.6.10 <0.8.0;

interface IAddressWhitelist {
    function check(address account, bytes32[] memory proof_) external view returns (bool);
}


// Root file: contracts/fund/PrimaryMarket.sol

pragma solidity >=0.6.10 <0.8.0;
// pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/math/Math.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// import "contracts/utils/SafeDecimalMath.sol";

// import "contracts/interfaces/IPrimaryMarket.sol";
// import "contracts/interfaces/IFund.sol";
// import "contracts/interfaces/ITrancheIndex.sol";
// import "contracts/interfaces/IAddressWhitelist.sol";

contract PrimaryMarket is IPrimaryMarket, ReentrancyGuard, ITrancheIndex, Ownable {
    event Created(address indexed account, uint256 underlying);
    event Redeemed(address indexed account, uint256 shares);
    event Split(address indexed account, uint256 inM, uint256 outA, uint256 outB);
    event Merged(address indexed account, uint256 outM, uint256 inA, uint256 inB);
    event Claimed(address indexed account, uint256 createdShares, uint256 redeemedUnderlying);
    event Settled(
        uint256 indexed day,
        uint256 sharesToMint,
        uint256 sharesToBurn,
        uint256 creationUnderlying,
        uint256 redemptionUnderlying,
        uint256 fee
    );

    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Creation and redemption of a single account.
    /// @param day Day of the last creation or redemption request.
    /// @param creatingUnderlying Underlying that will be used for creation at the end of this day.
    /// @param redeemingShares Shares that will be redeemed at the end of this day.
    /// @param createdShares Shares already created in previous days.
    /// @param redeemedUnderlying Underlying already redeemed in previous days.
    /// @param version Rebalance version before the end of this trading day.
    struct CreationRedemption {
        uint256 day;
        uint256 creatingUnderlying;
        uint256 redeemingShares;
        uint256 createdShares;
        uint256 redeemedUnderlying;
        uint256 version;
    }

    uint256 private constant MAX_REDEMPTION_FEE_RATE = 0.01e18;
    uint256 private constant MAX_SPLIT_FEE_RATE = 0.01e18;
    uint256 private constant MAX_MERGE_FEE_RATE = 0.01e18;

    uint256 public immutable guardedLaunchStart;
    uint256 public guardedLaunchTotalCap;
    uint256 public guardedLaunchIndividualCap;
    mapping(address => uint256) public guardedLaunchCreations;

    IFund public fund;

    uint256 public redemptionFeeRate;
    uint256 public splitFeeRate;
    uint256 public mergeFeeRate;
    uint256 public minCreationUnderlying;

    mapping(address => CreationRedemption) private _creationRedemptions;

    uint256 public currentDay;
    uint256 public currentCreatingUnderlying;
    uint256 public currentRedeemingShares;
    uint256 public currentFeeInShares;

    mapping(uint256 => uint256) private _historicalCreationRate;
    mapping(uint256 => uint256) private _historicalRedemptionRate;

    address public addressWhitelist;
    uint256 public guardedCapTimeLimit = 4 weeks;
    uint256 public guardedSplitTimeLimit = 2 weeks;

    constructor(
        address fund_,
        uint256 guardedLaunchStart_,
        uint256 redemptionFeeRate_,
        uint256 splitFeeRate_,
        uint256 mergeFeeRate_,
        uint256 minCreationUnderlying_
    ) public Ownable() {
        require(redemptionFeeRate_ <= MAX_REDEMPTION_FEE_RATE, "Exceed max redemption fee rate");
        require(splitFeeRate_ <= MAX_SPLIT_FEE_RATE, "Exceed max split fee rate");
        require(mergeFeeRate_ <= MAX_MERGE_FEE_RATE, "Exceed max merge fee rate");
        fund = IFund(fund_);
        guardedLaunchStart = guardedLaunchStart_;
        redemptionFeeRate = redemptionFeeRate_;
        splitFeeRate = splitFeeRate_;
        mergeFeeRate = mergeFeeRate_;
        minCreationUnderlying = minCreationUnderlying_;
        currentDay = fund.currentDay();
    }

    function creationRedemptionOf(address account)
        external
        view
        returns (CreationRedemption memory)
    {
        return _currentCreationRedemption(account);
    }

    function create(uint256 underlying_, bytes32[] memory proof_)
        external
        payable
        nonReentrant
        onlyActive
    {
        IERC20 token = IERC20(fund.tokenUnderlying());

        uint256 underlying = underlying_;

        if (token == IERC20(address(0))) {
            //eth
            require(msg.value >= minCreationUnderlying, "Min amount");
            underlying = msg.value;
        } else {
            require(underlying_ >= minCreationUnderlying, "Min amount");
            token.safeTransferFrom(msg.sender, address(this), underlying);
            underlying = underlying_;
        }

        CreationRedemption memory cr = _currentCreationRedemption(msg.sender);
        cr.creatingUnderlying = cr.creatingUnderlying.add(underlying);
        _updateCreationRedemption(msg.sender, cr);

        currentCreatingUnderlying = currentCreatingUnderlying.add(underlying);

        if (block.timestamp < guardedLaunchStart + guardedCapTimeLimit) {
            guardedLaunchCreations[msg.sender] = guardedLaunchCreations[msg.sender].add(underlying);
            uint256 _balance;
            if (token == IERC20(address(0))) {
                _balance = address(fund).balance;
            } else {
                _balance = IERC20(fund.tokenUnderlying()).balanceOf(address(fund));
            }
            require(
                _balance.add(currentCreatingUnderlying) <= guardedLaunchTotalCap,
                "Guarded launch: exceed total cap"
            );
            require(
                guardedLaunchCreations[msg.sender] <= guardedLaunchIndividualCap,
                "Guarded launch: exceed individual cap"
            );
            if (addressWhitelist != address(0) && Address.isContract(addressWhitelist)) {
                require(
                    IAddressWhitelist(addressWhitelist).check(msg.sender, proof_),
                    "You are not in the whitelist."
                );
            }
        }

        emit Created(msg.sender, underlying);
    }

    function redeem(uint256 shares) external onlyActive {
        require(shares != 0, "Zero shares");
        // Use burn and mint to simulate a transfer, so that we don't need a special transferFrom()
        fund.burn(TRANCHE_M, msg.sender, shares);
        fund.mint(TRANCHE_M, address(this), shares);

        CreationRedemption memory cr = _currentCreationRedemption(msg.sender);
        cr.redeemingShares = cr.redeemingShares.add(shares);
        _updateCreationRedemption(msg.sender, cr);

        currentRedeemingShares = currentRedeemingShares.add(shares);
        emit Redeemed(msg.sender, shares);
    }

    function claim(address payable account)
        external
        override
        nonReentrant
        returns (uint256 createdShares, uint256 redeemedUnderlying)
    {
        CreationRedemption memory cr = _currentCreationRedemption(account);
        createdShares = cr.createdShares;
        redeemedUnderlying = cr.redeemedUnderlying;

        if (createdShares > 0) {
            IERC20(fund.tokenM()).safeTransfer(account, createdShares);
            cr.createdShares = 0;
        }
        if (redeemedUnderlying > 0) {
            IERC20 token = IERC20(fund.tokenUnderlying());
            if (token == IERC20(address(0))) {
                // account.transfer(redeemedUnderlying);
                (bool success, ) = payable(address(account)).call{value: redeemedUnderlying}("");
                require(success, "eth transfer failure");
            } else {
                token.safeTransfer(account, redeemedUnderlying);
            }
            cr.redeemedUnderlying = 0;
        }
        _updateCreationRedemption(account, cr);

        emit Claimed(account, createdShares, redeemedUnderlying);
    }

    function split(uint256 inM) external onlyActive {
        require(
            block.timestamp >= guardedLaunchStart + guardedSplitTimeLimit,
            "Guarded launch: split not ready yet"
        );
        (uint256 weightA, uint256 weightB) = fund.trancheWeights();
        // Charge splitting fee and round it to a multiple of (weightA + weightB)
        uint256 unit = inM.sub(inM.multiplyDecimal(splitFeeRate)) / (weightA + weightB);
        require(unit > 0, "Too little to split");
        uint256 inMAfterFee = unit * (weightA + weightB);
        uint256 outA = unit * weightA;
        uint256 outB = inMAfterFee - outA;
        uint256 feeM = inM - inMAfterFee;

        fund.burn(TRANCHE_M, msg.sender, inM);
        fund.mint(TRANCHE_A, msg.sender, outA);
        fund.mint(TRANCHE_B, msg.sender, outB);
        fund.mint(TRANCHE_M, address(this), feeM);

        currentFeeInShares = currentFeeInShares.add(feeM);
        emit Split(msg.sender, inM, outA, outB);
    }

    function merge(uint256 inA) external onlyActive {
        (uint256 weightA, uint256 weightB) = fund.trancheWeights();
        // Round to tranche weights
        uint256 unit = inA / weightA;
        require(unit > 0, "Too little to merge");
        // Keep unmergable Token A unchanged.
        inA = unit * weightA;
        uint256 inB = unit.mul(weightB);
        uint256 outMBeforeFee = inA.add(inB);
        uint256 feeM = outMBeforeFee.multiplyDecimal(mergeFeeRate);
        uint256 outM = outMBeforeFee.sub(feeM);

        fund.burn(TRANCHE_A, msg.sender, inA);
        fund.burn(TRANCHE_B, msg.sender, inB);
        fund.mint(TRANCHE_M, msg.sender, outM);
        fund.mint(TRANCHE_M, address(this), feeM);

        currentFeeInShares = currentFeeInShares.add(feeM);
        emit Merged(msg.sender, outM, inA, inB);
    }

    function transferToFund(uint256 amount) external override nonReentrant onlyFund {
        IERC20 token = IERC20(fund.tokenUnderlying());
        if (token == IERC20(address(0))) {
            (bool success, ) = payable(address(fund)).call{value: amount}("");
            require(success, "eth transfer failure");
        } else {
            token.safeTransferFrom(address(this), address(fund), amount);
        }
    }

    /// @notice Settle ongoing creations and redemptions and also split and merge fees.
    ///
    ///         Creations and redemptions are settled according to the current shares and
    ///         underlying assets in the fund. Split and merge fee charged as Token M are also
    ///         redeemed at the same rate (without redemption fee).
    ///
    ///         This function does not mint or burn shares, nor transfer underlying assets.
    ///         It returns the following changes that should be done by the fund:
    ///
    ///         1. Mint or burn net shares (creations v.s. redemptions + split/merge fee).
    ///         2. Transfer underlying to or from this contract (creations v.s. redemptions).
    ///         3. Transfer fee in underlying assets to the governance address.
    ///
    ///         This function can only be called from the Fund contract. It should be called
    ///         after protocol fee is collected and before rebalance is triggered for the same
    ///         trading day.
    /// @param day The trading day to settle
    /// @param fundTotalShares Total shares of the fund (as if all Token A and B are merged)
    /// @param fundUnderlying Underlying assets in the fund
    /// @param underlyingPrice Price of the underlying assets at the end of the trading day
    /// @param previousNav NAV of Token M of the previous trading day
    /// @return sharesToMint Amount of Token M to mint for creations
    /// @return sharesToBurn Amount of Token M to burn for redemptions and split/merge fee
    /// @return creationUnderlying Underlying assets received for creations (including creation fee)
    /// @return redemptionUnderlying Underlying assets to be redeemed (excluding redemption fee)
    /// @return fee Total fee in underlying assets for the fund to transfer to the governance address,
    ///         inlucding creation fee, redemption fee and split/merge fee
    function settle(
        uint256 day,
        uint256 fundTotalShares,
        uint256 fundUnderlying,
        uint256 underlyingPrice,
        uint256 previousNav
    )
        external
        override
        nonReentrant
        onlyFund
        returns (
            uint256 sharesToMint,
            uint256 sharesToBurn,
            uint256 creationUnderlying,
            uint256 redemptionUnderlying,
            uint256 fee
        )
    {
        require(day >= currentDay, "Already settled");

        // Creation
        creationUnderlying = currentCreatingUnderlying;
        if (creationUnderlying > 0) {
            if (fundUnderlying > 0) {
                sharesToMint = creationUnderlying.mul(fundTotalShares).div(fundUnderlying);
            } else {
                // NAV is rounded down. Computing creations using NAV results in rounded up shares,
                // which is unfair to existing share holders. We only do that when there are
                // no shares before.
                require(
                    fundTotalShares == 0,
                    "Cannot create shares for fund with shares but no underlying"
                );
                require(previousNav > 0, "Cannot create shares at zero NAV");
                sharesToMint = creationUnderlying
                    .mul(underlyingPrice)
                    .mul(fund.underlyingDecimalMultiplier())
                    .div(previousNav);
            }
            _historicalCreationRate[day] = sharesToMint.divideDecimal(creationUnderlying);
        }

        // Redemption
        sharesToBurn = currentRedeemingShares;
        if (sharesToBurn > 0) {
            uint256 underlying = sharesToBurn.mul(fundUnderlying).div(fundTotalShares);
            uint256 redemptionFee = underlying.multiplyDecimal(redemptionFeeRate);
            redemptionUnderlying = underlying.sub(redemptionFee);
            _historicalRedemptionRate[day] = redemptionUnderlying.divideDecimal(sharesToBurn);
            fee = redemptionFee;
        }

        // Redeem split and merge fee
        uint256 feeInShares = currentFeeInShares;
        if (feeInShares > 0) {
            sharesToBurn = sharesToBurn.add(feeInShares);
            fee = fee.add(feeInShares.mul(fundUnderlying).div(fundTotalShares));
        }

        // Approve the fund to take underlying if creation is more than redemption.
        // Instead of directly transfering underlying to the fund, this implementation
        // makes testing much easier.
        if (creationUnderlying > redemptionUnderlying) {
            IERC20 token = IERC20(fund.tokenUnderlying());
            if (token != IERC20(address(0))) {
                token.safeApprove(address(fund), creationUnderlying - redemptionUnderlying);
            }
        }

        // This loop should never execute, because this function is called by Fund
        // for every day. We fill the gap just in case that something goes wrong in Fund.
        for (uint256 t = currentDay; t < day; t += 10 minutes) {
            _historicalCreationRate[t] = _historicalCreationRate[day];
            _historicalRedemptionRate[t] = _historicalRedemptionRate[day];
        }

        currentDay = day + 10 minutes;
        currentCreatingUnderlying = 0;
        currentRedeemingShares = 0;
        currentFeeInShares = 0;
        emit Settled(
            day,
            sharesToMint,
            sharesToBurn,
            creationUnderlying,
            redemptionUnderlying,
            fee
        );
    }

    function updateGuardedLaunchCap(uint256 newTotalCap, uint256 newIndividualCap)
        external
        onlyOwner
    {
        guardedLaunchTotalCap = newTotalCap;
        guardedLaunchIndividualCap = newIndividualCap;
    }

    function updateRedemptionFeeRate(uint256 newRedemptionFeeRate) external onlyOwner {
        require(newRedemptionFeeRate <= MAX_REDEMPTION_FEE_RATE, "Exceed max redemption fee rate");
        redemptionFeeRate = newRedemptionFeeRate;
    }

    function updateSplitFeeRate(uint256 newSplitFeeRate) external onlyOwner {
        require(newSplitFeeRate <= MAX_SPLIT_FEE_RATE, "Exceed max split fee rate");
        splitFeeRate = newSplitFeeRate;
    }

    function updateMergeFeeRate(uint256 newMergeFeeRate) external onlyOwner {
        require(newMergeFeeRate <= MAX_MERGE_FEE_RATE, "Exceed max merge fee rate");
        mergeFeeRate = newMergeFeeRate;
    }

    function updateMinCreationUnderlying(uint256 newMinCreationUnderlying) external onlyOwner {
        minCreationUnderlying = newMinCreationUnderlying;
    }

    function updateAddressWhitelist(address newWhitelist) external onlyOwner {
        require(
            newWhitelist == address(0) || Address.isContract(newWhitelist),
            "Must be null or a contract"
        );
        addressWhitelist = newWhitelist;
    }

    function updateGuardedCapTimeLimit(uint256 newTimeLimit) external onlyOwner {
        guardedCapTimeLimit = newTimeLimit;
    }

    function updateGuardedSplitTimeLimit(uint256 newTimeLimit) external onlyOwner {
        guardedSplitTimeLimit = newTimeLimit;
    }

    function _currentCreationRedemption(address account)
        private
        view
        returns (CreationRedemption memory cr)
    {
        cr = _creationRedemptions[account];
        uint256 oldDay = cr.day;
        if (oldDay < currentDay) {
            if (cr.creatingUnderlying > 0) {
                cr.createdShares = cr.createdShares.add(
                    cr.creatingUnderlying.multiplyDecimal(_historicalCreationRate[oldDay])
                );
                cr.creatingUnderlying = 0;
            }
            uint256 rebalanceSize = fund.getRebalanceSize();
            if (cr.version < rebalanceSize) {
                if (cr.createdShares > 0) {
                    (cr.createdShares, , ) = fund.batchRebalance(
                        cr.createdShares,
                        0,
                        0,
                        cr.version,
                        rebalanceSize
                    );
                }
                cr.version = rebalanceSize;
            }
            if (cr.redeemingShares > 0) {
                cr.redeemedUnderlying = cr.redeemedUnderlying.add(
                    cr.redeemingShares.multiplyDecimal(_historicalRedemptionRate[oldDay])
                );
                cr.redeemingShares = 0;
            }
            cr.day = currentDay;
        }
    }

    function _updateCreationRedemption(address account, CreationRedemption memory cr) private {
        CreationRedemption storage old = _creationRedemptions[account];
        if (old.day != cr.day) {
            old.day = cr.day;
        }
        if (old.creatingUnderlying != cr.creatingUnderlying) {
            old.creatingUnderlying = cr.creatingUnderlying;
        }
        if (old.redeemingShares != cr.redeemingShares) {
            old.redeemingShares = cr.redeemingShares;
        }
        if (old.createdShares != cr.createdShares) {
            old.createdShares = cr.createdShares;
        }
        if (old.redeemedUnderlying != cr.redeemedUnderlying) {
            old.redeemedUnderlying = cr.redeemedUnderlying;
        }
        if (old.version != cr.version) {
            old.version = cr.version;
        }
    }

    modifier onlyActive() {
        require(fund.isPrimaryMarketActive(address(this), block.timestamp), "Only when active");
        _;
    }

    modifier onlyFund() {
        require(msg.sender == address(fund), "Only fund");
        _;
    }

    receive() external payable {}
}