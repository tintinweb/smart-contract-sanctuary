/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

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


// Dependency file: @openzeppelin/contracts/math/Math.sol


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


// Dependency file: contracts/utils/CoreUtility.sol

// pragma solidity >=0.6.10 <0.8.0;

// import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract CoreUtility {
    using SafeMath for uint256;

    /// @dev UTC time of a day when the fund settles.
    uint256 internal constant SETTLEMENT_TIME = 14 hours;

    /// @dev Return end timestamp of the trading week containing a given timestamp.
    ///
    ///      A trading week starts at UTC time `SETTLEMENT_TIME` on a Thursday (inclusive)
    ///      and ends at the same time of the next Thursday (exclusive).
    /// @param timestamp The given timestamp
    /// @return End timestamp of the trading week.
    function _endOfWeek(uint256 timestamp) internal pure returns (uint256) {
        return ((timestamp.add(1 weeks) - SETTLEMENT_TIME) / 1 weeks) * 1 weeks + SETTLEMENT_TIME;
    }
}


// Dependency file: contracts/interfaces/IPrimaryMarket.sol

// pragma solidity >=0.6.10 <0.8.0;

interface IPrimaryMarket {
    function claim(address payable account) external returns (uint256 createdShares, uint256 redeemedUnderlying);

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

// import 'contracts/interfaces/ILatestPriceOracle.sol';

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

    function isPrimaryMarketActive(address primaryMarket, uint256 timestamp) external view returns (bool);

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
    event Transfer(uint256 indexed tranche, address indexed from, address indexed to, uint256 amount);
    event Approval(uint256 indexed tranche, address indexed owner, address indexed spender, uint256 amount);
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


// Dependency file: contracts/interfaces/ITwapOracle.sol

// pragma solidity >=0.6.10 <0.8.0;

interface ITwapOracle {
    function getTwap(uint256 timestamp) external view returns (uint256);
}


// Dependency file: contracts/interfaces/IAprOracle.sol

// pragma solidity >=0.6.10 <0.8.0;

interface IAprOracle {
    function capture() external returns (uint256 dailyRate);
}


// Dependency file: contracts/interfaces/IBallot.sol

// pragma solidity >=0.6.10 <0.8.0;

interface IBallot {
    struct Voter {
        uint256 amount;
        uint256 unlockTime;
        uint256 weight;
    }

    function count(uint256 timestamp) external view returns (uint256);

    function syncWithVotingEscrow(address account) external;
}


// Dependency file: contracts/interfaces/IVotingEscrow.sol

// pragma solidity >=0.6.10 <0.8.0;
// pragma experimental ABIEncoderV2;

interface IVotingEscrow {
    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    function token() external view returns (address);

    function maxTime() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        returns (uint256);

    function getTimestampDropBelow(address account, uint256 threshold)
        external
        view
        returns (uint256);

    function getLockedBalance(address account) external view returns (LockedBalance memory);
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


// Dependency file: @openzeppelin/contracts/utils/EnumerableSet.sol


// pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


// Dependency file: contracts/fund/FundRoles.sol

// pragma solidity >=0.6.10 <0.8.0;

// import "@openzeppelin/contracts/utils/EnumerableSet.sol";

abstract contract FundRoles {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _primaryMarketMembers;
    mapping(address => bool) private _shareMembers;

    event PrimaryMarketAdded(address indexed primaryMarket);
    event PrimaryMarketRemoved(address indexed primaryMarket);

    function _initializeRoles(
        address tokenM_,
        address tokenA_,
        address tokenB_,
        address primaryMarket_
    ) internal {
        _shareMembers[tokenM_] = true;
        _shareMembers[tokenA_] = true;
        _shareMembers[tokenB_] = true;

        _addPrimaryMarket(primaryMarket_);
    }

    modifier onlyPrimaryMarket() {
        require(isPrimaryMarket(msg.sender), "FundRoles: only primary market");
        _;
    }

    function isPrimaryMarket(address account) public view returns (bool) {
        return _primaryMarketMembers.contains(account);
    }

    function getPrimaryMarketMember(uint256 index) public view returns (address) {
        return _primaryMarketMembers.at(index);
    }

    function getPrimaryMarketCount() public view returns (uint256) {
        return _primaryMarketMembers.length();
    }

    function _addPrimaryMarket(address primaryMarket) internal {
        if (_primaryMarketMembers.add(primaryMarket)) {
            emit PrimaryMarketAdded(primaryMarket);
        }
    }

    function _removePrimaryMarket(address primaryMarket) internal {
        if (_primaryMarketMembers.remove(primaryMarket)) {
            emit PrimaryMarketRemoved(primaryMarket);
        }
    }

    modifier onlyShare() {
        require(isShare(msg.sender), "FundRoles: only share");
        _;
    }

    function isShare(address account) public view returns (bool) {
        return _shareMembers[account];
    }
}


// Root file: contracts/fund/Fund.sol

pragma solidity >=0.6.10 <0.8.0;
// pragma experimental ABIEncoderV2;

// import '/Users/alone/ethereum/ArbiChess/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import '/Users/alone/ethereum/ArbiChess/node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
// import '/Users/alone/ethereum/ArbiChess/node_modules/@openzeppelin/contracts/math/Math.sol';
// import '/Users/alone/ethereum/ArbiChess/node_modules/@openzeppelin/contracts/access/Ownable.sol';
// import '/Users/alone/ethereum/ArbiChess/node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol';

// import 'contracts/utils/SafeDecimalMath.sol';
// import 'contracts/utils/CoreUtility.sol';

// import 'contracts/interfaces/IPrimaryMarket.sol';
// import 'contracts/interfaces/IFund.sol';
// import "contracts/interfaces/ITwapOracle.sol";
// import 'contracts/interfaces/ILatestPriceOracle.sol';
// import 'contracts/interfaces/IAprOracle.sol';
// import 'contracts/interfaces/IBallot.sol';
// import 'contracts/interfaces/IVotingEscrow.sol';
// import 'contracts/interfaces/ITrancheIndex.sol';

// import 'contracts/fund/FundRoles.sol';

contract Fund is IFund, Ownable, ReentrancyGuard, FundRoles, CoreUtility, ITrancheIndex {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant UNIT = 1e18;
    uint256 private constant MAX_INTEREST_RATE = 0.2e18; // 20% daily
    uint256 private constant MAX_DAILY_PROTOCOL_FEE_RATE = 0.05e18; // 5% daily rate

    uint256 private constant WEIGHT_A = 1;
    uint256 private constant WEIGHT_B = 1;
    uint256 private constant WEIGHT_M = WEIGHT_A + WEIGHT_B;

    /// @notice Upper bound of `NAV_B / NAV_A` to trigger a rebalance.
    uint256 public immutable upperRebalanceThreshold;

    /// @notice Lower bound of `NAV_B / NAV_A` to trigger a rebalance.
    uint256 public immutable lowerRebalanceThreshold;

    /// @notice Address of the underlying token.
    address public immutable override tokenUnderlying;

    /// @notice A multipler that normalizes an underlying balance to 18 decimal places.
    uint256 public immutable override underlyingDecimalMultiplier;

    /// @notice Daily protocol fee rate.
    uint256 public dailyProtocolFeeRate;

    /// @notice TwapOracle address for the underlying asset.
    // ITwapOracle public override twapOracle;

    ILatestPriceOracle public override latestPriceOracle;

    /// @notice AprOracle address.
    IAprOracle public aprOracle;

    /// @notice Address of the interest rate ballot.
    address public ballot;

    /// @notice Fee Collector address.
    address public override feeCollector;

    /// @notice Address of Token M.
    address public override tokenM;

    /// @notice Address of Token A.
    address public override tokenA;

    /// @notice Address of Token B.
    address public override tokenB;

    /// @notice End timestamp of the current trading day.
    ///         A trading day starts at UTC time `SETTLEMENT_TIME` of a day (inclusive)
    ///         and ends at the same time of the next day (exclusive).
    uint256 public override currentDay;

    /// @notice Start timestamp of the current primary market activity window.
    uint256 public override fundActivityStartTime;

    /// @notice Start timestamp of the current exchange activity window.
    uint256 public override exchangeActivityStartTime;

    /// @dev Historical rebalances. Rebalances are often accessed in loops with bounds checking.
    ///      So we store them in a fixed-length array, in order to make compiler-generated
    ///      bounds checking on every access cheaper. The actual length of this array is stored in
    ///      `_rebalanceSize` and should be explicitly checked when necessary.
    Rebalance[65535] private _rebalances;

    /// @dev Historical rebalance count.
    uint256 private _rebalanceSize;

    /// @dev Total share supply of the three tranches. They are always rebalanced to the latest
    ///      version.
    uint256[TRANCHE_COUNT] private _totalSupplies;

    /// @dev Mapping of account => share balance of the three tranches.
    ///      Rebalance versions are stored in a separate mapping `_balanceVersions`.
    mapping(address => uint256[TRANCHE_COUNT]) private _balances;

    /// @dev Rebalance version mapping for `_balances`.
    mapping(address => uint256) private _balanceVersions;

    /// @dev Mapping of owner => spender => share allowance of the three tranches.
    ///      Rebalance versions are stored in a separate mapping `_allowanceVersions`.
    mapping(address => mapping(address => uint256[TRANCHE_COUNT])) private _allowances;

    /// @dev Rebalance version mapping for `_allowances`.
    mapping(address => mapping(address => uint256)) private _allowanceVersions;

    /// @dev Mapping of trading day => NAV tuple.
    mapping(uint256 => uint256[TRANCHE_COUNT]) private _historicalNavs;

    /// @notice Mapping of trading day => total fund shares.
    ///
    ///         Key is the end timestamp of a trading day. Value is the total fund shares after
    ///         settlement of that trading day, as if all Token A and B are merged.
    mapping(uint256 => uint256) public historicalTotalShares;

    /// @notice Mapping of trading day => underlying assets in the fund.
    ///
    ///         Key is the end timestamp of a trading day. Value is the underlying assets in
    ///         the fund after settlement of that trading day.
    mapping(uint256 => uint256) public historicalUnderlying;

    /// @notice Mapping of trading week => interest rate of Token A.
    ///
    ///         Key is the end timestamp of a trading week. Value is the interest rate captured
    ///         after settlement of the last day of the previous trading week.
    mapping(uint256 => uint256) public historicalInterestRate;

    address[] private obsoletePrimaryMarkets;
    address[] private newPrimaryMarkets;

    constructor(
        address tokenUnderlying_,
        uint256 underlyingDecimals_,
        uint256 dailyProtocolFeeRate_,
        uint256 upperRebalanceThreshold_,
        uint256 lowerRebalanceThreshold_,
        address latestPriceOracle_,
        address aprOracle_,
        address ballot_,
        address feeCollector_
    ) public Ownable() FundRoles() {
        tokenUnderlying = tokenUnderlying_;
        require(underlyingDecimals_ <= 18, 'Underlying decimals larger than 18');
        underlyingDecimalMultiplier = 10**(18 - underlyingDecimals_);
        require(dailyProtocolFeeRate_ <= MAX_DAILY_PROTOCOL_FEE_RATE, 'Exceed max protocol fee rate');
        dailyProtocolFeeRate = dailyProtocolFeeRate_;
        upperRebalanceThreshold = upperRebalanceThreshold_;
        lowerRebalanceThreshold = lowerRebalanceThreshold_;
        latestPriceOracle = ILatestPriceOracle(latestPriceOracle_);
        aprOracle = IAprOracle(aprOracle_);
        ballot = ballot_;
        feeCollector = feeCollector_;

        currentDay = endOfDay(block.timestamp);
        uint256 lastDay = currentDay - 1 days;
        // uint256 currentPrice = latestPriceOracle.getLatestPrice();
        // require(currentPrice != 0, 'Price not available');
        _historicalNavs[lastDay][TRANCHE_M] = UNIT;
        _historicalNavs[lastDay][TRANCHE_A] = UNIT;
        _historicalNavs[lastDay][TRANCHE_B] = UNIT;
        historicalInterestRate[_endOfWeek(lastDay)] = MAX_INTEREST_RATE.min(aprOracle.capture());
        fundActivityStartTime = lastDay;
        exchangeActivityStartTime = lastDay + 30 minutes;
    }

    function initialize(
        address tokenM_,
        address tokenA_,
        address tokenB_,
        address primaryMarket_
    ) external onlyOwner {
        require(tokenM == address(0) && tokenM_ != address(0), 'Already initialized');
        tokenM = tokenM_;
        tokenA = tokenA_;
        tokenB = tokenB_;
        _initializeRoles(tokenM_, tokenA_, tokenB_, primaryMarket_);
    }

    /// @notice Return weights of Token A and B when splitting Token M.
    /// @return weightA Weight of Token A
    /// @return weightB Weight of Token B
    function trancheWeights() external pure override returns (uint256 weightA, uint256 weightB) {
        return (WEIGHT_A, WEIGHT_B);
    }

    /// @notice UTC time of a day when the fund settles.
    function settlementTime() external pure returns (uint256) {
        return SETTLEMENT_TIME;
    }

    /// @notice Return end timestamp of the trading day containing a given timestamp.
    ///
    ///         A trading day starts at UTC time `SETTLEMENT_TIME` of a day (inclusive)
    ///         and ends at the same time of the next day (exclusive).
    /// @param timestamp The given timestamp
    /// @return End timestamp of the trading day.
    function endOfDay(uint256 timestamp) public pure override returns (uint256) {
        return ((timestamp.add(1 days) - SETTLEMENT_TIME) / 1 days) * 1 days + SETTLEMENT_TIME;
    }

    /// @notice Return end timestamp of the trading week containing a given timestamp.
    ///
    ///         A trading week starts at UTC time `SETTLEMENT_TIME` on a Thursday (inclusive)
    ///         and ends at the same time of the next Thursday (exclusive).
    /// @param timestamp The given timestamp
    /// @return End timestamp of the trading week.
    function endOfWeek(uint256 timestamp) external pure returns (uint256) {
        return _endOfWeek(timestamp);
    }

    /// @notice Return the status of the fund contract.
    /// @param timestamp Timestamp to assess
    /// @return True if the fund contract is active
    function isFundActive(uint256 timestamp) public view override returns (bool) {
        return timestamp >= fundActivityStartTime;
    }

    /// @notice Return the status of a given primary market contract.
    /// @param primaryMarket The primary market contract address
    /// @param timestamp Timestamp to assess
    /// @return True if the primary market contract is active
    function isPrimaryMarketActive(address primaryMarket, uint256 timestamp) public view override returns (bool) {
        return isPrimaryMarket(primaryMarket) && timestamp >= fundActivityStartTime && timestamp < currentDay;
    }

    /// @notice Return the status of the exchange. Unlike the primary market, exchange is
    ///         anonymous to fund
    /// @param timestamp Timestamp to assess
    /// @return True if the exchange contract is active
    function isExchangeActive(uint256 timestamp) public view override returns (bool) {
        return (timestamp >= exchangeActivityStartTime && timestamp < (currentDay - 60 minutes));
    }

    /// @notice Total shares of the fund, as if all Token A and B are merged.
    function getTotalShares() public view override returns (uint256) {
        return _totalSupplies[TRANCHE_M].add(_totalSupplies[TRANCHE_A]).add(_totalSupplies[TRANCHE_B]);
    }

    /// @notice Return the rebalance matrix at a given index. A zero struct is returned
    ///         if `index` is out of bound.
    /// @param index Rebalance index
    /// @return A rebalance matrix
    function getRebalance(uint256 index) external view override returns (Rebalance memory) {
        return _rebalances[index];
    }

    /// @notice Return timestamp of the transaction triggering the rebalance at a given index.
    ///         Zero is returned if `index` is out of bound.
    /// @param index Rebalance index
    /// @return Timestamp of the rebalance
    function getRebalanceTimestamp(uint256 index) external view override returns (uint256) {
        return _rebalances[index].timestamp;
    }

    /// @notice Return the number of historical rebalances.
    function getRebalanceSize() external view override returns (uint256) {
        return _rebalanceSize;
    }

    /// @notice Return NAV of Token M, A and B of the given trading day.
    /// @param day End timestamp of a trading day
    /// @return NAV of Token M, A and B
    function historicalNavs(uint256 day)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (_historicalNavs[day][TRANCHE_M], _historicalNavs[day][TRANCHE_A], _historicalNavs[day][TRANCHE_B]);
    }

    /// @notice Estimate NAV of all tranches at a given timestamp, considering underlying price
    ///         change, accrued protocol fee and accrued interest since the previous settlement.
    ///
    ///         The extrapolation uses simple interest instead of daily compound interest in
    ///         calculating protocol fee and Token A's interest. There may be significant error
    ///         in the returned values when `timestamp` is far beyond the last settlement.
    /// @param timestamp Timestamp to estimate
    /// @param price Price of the underlying asset (18 decimal places)
    /// @return Estimated NAV of all tranches
    function extrapolateNav(uint256 timestamp, uint256 price)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Find the last settled trading day before the given timestamp.
        uint256 previousDay = currentDay - 1 days;
        if (previousDay > timestamp) {
            previousDay = endOfDay(timestamp) - 1 days;
        }
        uint256 previousShares = historicalTotalShares[previousDay];
        uint256 navM = _extrapolateNavM(previousDay, previousShares, timestamp, price);
        uint256 navA = _extrapolateNavA(previousDay, previousShares, timestamp);
        uint256 navB = calculateNavB(navM, navA);
        return (navM, navA, navB);
    }

    function _extrapolateNavM(
        uint256 previousDay,
        uint256 previousShares,
        uint256 timestamp,
        uint256 price
    ) private view returns (uint256) {
        uint256 navM;
        if (previousShares == 0) {
            // The fund is empty. Just return the previous recorded NAV.
            navM = _historicalNavs[previousDay][TRANCHE_M];
            if (navM == 0) {
                // No NAV is recorded because the given timestamp is before the fund launches.
                return UNIT;
            } else {
                return navM;
            }
        }
        uint256 totalValue = price.mul(historicalUnderlying[previousDay].mul(underlyingDecimalMultiplier));
        uint256 accruedFee = totalValue.multiplyDecimal(dailyProtocolFeeRate).mul(timestamp - previousDay).div(1 days);
        navM = (totalValue - accruedFee).div(previousShares);
        return navM;
    }

    function _extrapolateNavA(
        uint256 previousDay,
        uint256 previousShares,
        uint256 timestamp
    ) private view returns (uint256) {
        uint256 navA = _historicalNavs[previousDay][TRANCHE_A];
        if (previousShares == 0) {
            // The fund is empty. Just return the previous recorded NAV.
            if (navA == 0) {
                // No NAV is recorded because the given timestamp is before the fund launches.
                return UNIT;
            } else {
                return navA;
            }
        }

        uint256 week = _endOfWeek(previousDay);
        uint256 newNavA = navA
            .multiplyDecimal(UNIT.sub(dailyProtocolFeeRate.mul(timestamp - previousDay).div(1 days)))
            .multiplyDecimal(UNIT.add(historicalInterestRate[week].mul(timestamp - previousDay).div(1 days)));
        return newNavA > navA ? newNavA : navA;
    }

    function calculateNavB(uint256 navM, uint256 navA) public pure override returns (uint256) {
        // Using unchecked multiplications because they are unlikely to overflow
        if (navM * WEIGHT_M >= navA * WEIGHT_A) {
            return (navM * WEIGHT_M - navA * WEIGHT_A) / WEIGHT_B;
        } else {
            return 0;
        }
    }

    /// @notice Transform share amounts according to the rebalance at a given index.
    ///         This function performs no bounds checking on the given index. A non-existent
    ///         rebalance transforms anything to a zero vector.
    /// @param amountM Amount of Token M before the rebalance
    /// @param amountA Amount of Token A before the rebalance
    /// @param amountB Amount of Token B before the rebalance
    /// @param index Rebalance index
    /// @return newAmountM Amount of Token M after the rebalance
    /// @return newAmountA Amount of Token A after the rebalance
    /// @return newAmountB Amount of Token B after the rebalance
    function doRebalance(
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 index
    )
        public
        view
        override
        returns (
            uint256 newAmountM,
            uint256 newAmountA,
            uint256 newAmountB
        )
    {
        Rebalance storage rebalance = _rebalances[index];
        newAmountM = amountM.multiplyDecimal(rebalance.ratioM).add(amountA.multiplyDecimal(rebalance.ratioA2M)).add(
            amountB.multiplyDecimal(rebalance.ratioB2M)
        );
        uint256 ratioAB = rebalance.ratioAB; // Gas saver
        newAmountA = amountA.multiplyDecimal(ratioAB);
        newAmountB = amountB.multiplyDecimal(ratioAB);
    }

    /// @notice Transform share amounts according to rebalances in a given index range,
    ///         This function performs no bounds checking on the given indices. The original amounts
    ///         are returned if `fromIndex` is no less than `toIndex`. A zero vector is returned
    ///         if `toIndex` is greater than the number of existing rebalances.
    /// @param amountM Amount of Token M before the rebalance
    /// @param amountA Amount of Token A before the rebalance
    /// @param amountB Amount of Token B before the rebalance
    /// @param fromIndex Starting of the rebalance index range, inclusive
    /// @param toIndex End of the rebalance index range, exclusive
    /// @return newAmountM Amount of Token M after the rebalance
    /// @return newAmountA Amount of Token A after the rebalance
    /// @return newAmountB Amount of Token B after the rebalance
    function batchRebalance(
        uint256 amountM,
        uint256 amountA,
        uint256 amountB,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        override
        returns (
            uint256 newAmountM,
            uint256 newAmountA,
            uint256 newAmountB
        )
    {
        for (uint256 i = fromIndex; i < toIndex; i++) {
            (amountM, amountA, amountB) = doRebalance(amountM, amountA, amountB, i);
        }
        newAmountM = amountM;
        newAmountA = amountA;
        newAmountB = amountB;
    }

    /// @notice Transform share balance to a given rebalance version, or to the latest version
    ///         if `targetVersion` is zero.
    /// @param account Account of the balance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function refreshBalance(address account, uint256 targetVersion) external override {
        if (targetVersion > 0) {
            require(targetVersion <= _rebalanceSize, 'Target version out of bound');
        }
        _refreshBalance(account, targetVersion);
    }

    /// @notice Transform allowance to a given rebalance version, or to the latest version
    ///         if `targetVersion` is zero.
    /// @param owner Owner of the allowance to rebalance
    /// @param spender Spender of the allowance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external override {
        if (targetVersion > 0) {
            require(targetVersion <= _rebalanceSize, 'Target version out of bound');
        }
        _refreshAllowance(owner, spender, targetVersion);
    }

    function shareBalanceOf(uint256 tranche, address account) external view override returns (uint256) {
        uint256 amountM = _balances[account][TRANCHE_M];
        uint256 amountA = _balances[account][TRANCHE_A];
        uint256 amountB = _balances[account][TRANCHE_B];

        if (tranche == TRANCHE_M) {
            if (amountM == 0 && amountA == 0 && amountB == 0) return 0;
        } else if (tranche == TRANCHE_A) {
            if (amountA == 0) return 0;
        } else {
            if (amountB == 0) return 0;
        }

        uint256 size = _rebalanceSize; // Gas saver
        for (uint256 i = _balanceVersions[account]; i < size; i++) {
            (amountM, amountA, amountB) = doRebalance(amountM, amountA, amountB, i);
        }

        if (tranche == TRANCHE_M) {
            return amountM;
        } else if (tranche == TRANCHE_A) {
            return amountA;
        } else {
            return amountB;
        }
    }

    /// @notice Return all three share balances transformed to the latest rebalance version.
    /// @param account Owner of the shares
    function allShareBalanceOf(address account)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amountM = _balances[account][TRANCHE_M];
        uint256 amountA = _balances[account][TRANCHE_A];
        uint256 amountB = _balances[account][TRANCHE_B];

        uint256 size = _rebalanceSize; // Gas saver
        for (uint256 i = _balanceVersions[account]; i < size; i++) {
            (amountM, amountA, amountB) = doRebalance(amountM, amountA, amountB, i);
        }

        return (amountM, amountA, amountB);
    }

    function shareBalanceVersion(address account) external view override returns (uint256) {
        return _balanceVersions[account];
    }

    function shareAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view override returns (uint256) {
        uint256 allowanceM = _allowances[owner][spender][TRANCHE_M];
        uint256 allowanceA = _allowances[owner][spender][TRANCHE_A];
        uint256 allowanceB = _allowances[owner][spender][TRANCHE_B];

        if (tranche == TRANCHE_M) {
            if (allowanceM == 0) return 0;
        } else if (tranche == TRANCHE_A) {
            if (allowanceA == 0) return 0;
        } else {
            if (allowanceB == 0) return 0;
        }

        uint256 size = _rebalanceSize; // Gas saver
        for (uint256 i = _allowanceVersions[owner][spender]; i < size; i++) {
            (allowanceM, allowanceA, allowanceB) = _rebalanceAllowance(allowanceM, allowanceA, allowanceB, i);
        }

        if (tranche == TRANCHE_M) {
            return allowanceM;
        } else if (tranche == TRANCHE_A) {
            return allowanceA;
        } else {
            return allowanceB;
        }
    }

    function shareAllowanceVersion(address owner, address spender) external view override returns (uint256) {
        return _allowanceVersions[owner][spender];
    }

    function shareTotalSupply(uint256 tranche) external view override returns (uint256) {
        return _totalSupplies[tranche];
    }

    function mint(
        uint256 tranche,
        address account,
        uint256 amount
    ) external override onlyPrimaryMarket {
        _refreshBalance(account, _rebalanceSize);
        _mint(tranche, account, amount);
    }

    function burn(
        uint256 tranche,
        address account,
        uint256 amount
    ) external override onlyPrimaryMarket {
        _refreshBalance(account, _rebalanceSize);
        _burn(tranche, account, amount);
    }

    function transfer(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount
    ) public override onlyShare {
        require(isFundActive(block.timestamp), 'Transfer is inactive');
        _refreshBalance(sender, _rebalanceSize);
        _refreshBalance(recipient, _rebalanceSize);
        _transfer(tranche, sender, recipient, amount);
    }

    function transferFrom(
        uint256 tranche,
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external override onlyShare returns (uint256 newAllowance) {
        transfer(tranche, sender, recipient, amount);

        _refreshAllowance(sender, spender, _rebalanceSize);
        newAllowance = _allowances[sender][spender][tranche].sub(amount, 'ERC20: transfer amount exceeds allowance');
        _approve(tranche, sender, spender, newAllowance);
    }

    function approve(
        uint256 tranche,
        address owner,
        address spender,
        uint256 amount
    ) external override onlyShare {
        _refreshAllowance(owner, spender, _rebalanceSize);
        _approve(tranche, owner, spender, amount);
    }

    function increaseAllowance(
        uint256 tranche,
        address sender,
        address spender,
        uint256 addedValue
    ) external override onlyShare returns (uint256 newAllowance) {
        _refreshAllowance(sender, spender, _rebalanceSize);
        newAllowance = _allowances[sender][spender][tranche].add(addedValue);
        _approve(tranche, sender, spender, newAllowance);
    }

    function decreaseAllowance(
        uint256 tranche,
        address sender,
        address spender,
        uint256 subtractedValue
    ) external override onlyShare returns (uint256 newAllowance) {
        _refreshAllowance(sender, spender, _rebalanceSize);
        newAllowance = _allowances[sender][spender][tranche].sub(subtractedValue);
        _approve(tranche, sender, spender, newAllowance);
    }

    function _transfer(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        _balances[sender][tranche] = _balances[sender][tranche].sub(amount, 'ERC20: transfer amount exceeds balance');
        _balances[recipient][tranche] = _balances[recipient][tranche].add(amount);

        emit Transfer(tranche, sender, recipient, amount);
    }

    function _mint(
        uint256 tranche,
        address account,
        uint256 amount
    ) private {
        require(account != address(0), 'ERC20: mint to the zero address');

        _totalSupplies[tranche] = _totalSupplies[tranche].add(amount);
        _balances[account][tranche] = _balances[account][tranche].add(amount);

        emit Transfer(tranche, address(0), account, amount);
    }

    function _burn(
        uint256 tranche,
        address account,
        uint256 amount
    ) private {
        require(account != address(0), 'ERC20: burn from the zero address');

        _balances[account][tranche] = _balances[account][tranche].sub(amount, 'ERC20: burn amount exceeds balance');
        _totalSupplies[tranche] = _totalSupplies[tranche].sub(amount);

        emit Transfer(tranche, account, address(0), amount);
    }

    function _approve(
        uint256 tranche,
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender][tranche] = amount;

        emit Approval(tranche, owner, spender, amount);
    }

    /// @notice Settle the current trading day. Settlement includes the following changes
    ///         to the fund.
    ///
    ///         1. Transfer protocol fee of the day to the fee collector.
    ///         2. Settle all pending creations and redemptions from all primary markets.
    ///         3. Calculate NAV of the day and trigger rebalance if necessary.
    ///         4. Capture new interest rate for Token A.
    function settle() external nonReentrant {
        uint256 day = currentDay;
        uint256 currentWeek = _endOfWeek(day - 1 days);
        require(block.timestamp >= day, 'The current trading day does not end yet');
        uint256 price = latestPriceOracle.getLatestPrice();
        require(price != 0, 'Underlying price for settlement is not ready yet');

        _collectFee();

        _settlePrimaryMarkets(day, price);

        // Calculate NAV
        uint256 totalShares = getTotalShares();
        uint256 underlying = IERC20(tokenUnderlying).balanceOf(address(this));
        uint256 navA = _historicalNavs[day - 1 days][TRANCHE_A];
        uint256 navM;
        if (totalShares > 0) {
            navM = price.mul(underlying.mul(underlyingDecimalMultiplier)).div(totalShares);
            if (historicalTotalShares[day - 1 days] > 0) {
                // Update NAV of Token A only when the fund is non-empty both before and after
                // this settlement
                uint256 newNavA = navA.multiplyDecimal(UNIT.sub(dailyProtocolFeeRate)).multiplyDecimal(
                    historicalInterestRate[currentWeek].add(UNIT)
                );
                if (navA < newNavA) {
                    navA = newNavA;
                }
            }
        } else {
            // If the fund is empty, use NAV of Token M in the last day
            navM = _historicalNavs[day - 1 days][TRANCHE_M];
        }
        uint256 navB = calculateNavB(navM, navA);

        if (_shouldTriggerRebalance(navA, navB)) {
            _triggerRebalance(day, navM, navA, navB);
            navM = UNIT;
            navA = UNIT;
            navB = UNIT;
            totalShares = getTotalShares();
            fundActivityStartTime = day + 12 hours;
            exchangeActivityStartTime = day + 12 hours;
        } else {
            fundActivityStartTime = day;
            exchangeActivityStartTime = day + 30 minutes;
        }

        if (currentDay == currentWeek) {
            historicalInterestRate[currentWeek + 1 weeks] = _updateInterestRate(currentWeek);
        }

        historicalTotalShares[day] = totalShares;
        historicalUnderlying[day] = underlying;
        _historicalNavs[day][TRANCHE_M] = navM;
        _historicalNavs[day][TRANCHE_A] = navA;
        _historicalNavs[day][TRANCHE_B] = navB;
        currentDay = day + 1 days;

        if (obsoletePrimaryMarkets.length > 0) {
            for (uint256 i = 0; i < obsoletePrimaryMarkets.length; i++) {
                _removePrimaryMarket(obsoletePrimaryMarkets[i]);
            }
            delete obsoletePrimaryMarkets;
        }

        if (newPrimaryMarkets.length > 0) {
            for (uint256 i = 0; i < newPrimaryMarkets.length; i++) {
                _addPrimaryMarket(newPrimaryMarkets[i]);
            }
            delete newPrimaryMarkets;
        }

        emit Settled(day, navM, navA, navB);
    }

    function addObsoletePrimaryMarket(address obsoletePrimaryMarket) external onlyOwner {
        require(isPrimaryMarket(obsoletePrimaryMarket), 'The address is not a primary market');
        obsoletePrimaryMarkets.push(obsoletePrimaryMarket);
    }

    function addNewPrimaryMarket(address newPrimaryMarket) external onlyOwner {
        require(!isPrimaryMarket(newPrimaryMarket), 'The address is already a primary market');
        newPrimaryMarkets.push(newPrimaryMarket);
    }

    function updateDailyProtocolFeeRate(uint256 newDailyProtocolFeeRate) external onlyOwner {
        require(newDailyProtocolFeeRate <= MAX_DAILY_PROTOCOL_FEE_RATE, 'Exceed max protocol fee rate');
        dailyProtocolFeeRate = newDailyProtocolFeeRate;
    }

    function updateLatestPriceOracle(address newLatestPriceOracle) external onlyOwner {
        latestPriceOracle = ILatestPriceOracle(newLatestPriceOracle);
    }

    function updateAprOracle(address newAprOracle) external onlyOwner {
        aprOracle = IAprOracle(newAprOracle);
    }

    function updateBallot(address newBallot) external onlyOwner {
        require(newBallot == address(0) || Address.isContract(newBallot), 'Must be null or a contract');
        ballot = newBallot;
    }

    function updateFeeCollector(address newFeeCollector) external onlyOwner {
        feeCollector = newFeeCollector;
    }

    /// @dev Transfer protocol fee of the current trading day to the fee collector.
    ///      This function should be called before creation and redemption on the same day
    ///      are settled.
    function _collectFee() private {
        uint256 currentUnderlying = IERC20(tokenUnderlying).balanceOf(address(this));
        uint256 fee = currentUnderlying.multiplyDecimal(dailyProtocolFeeRate);
        if (fee > 0) {
            IERC20(tokenUnderlying).safeTransfer(address(feeCollector), fee);
        }
    }

    /// @dev Settle primary market operations in every PrimaryMarket contract.
    function _settlePrimaryMarkets(uint256 day, uint256 price) private {
        uint256 totalShares = getTotalShares();
        uint256 underlying = IERC20(tokenUnderlying).balanceOf(address(this));
        uint256 prevNavM = _historicalNavs[day - 1 days][TRANCHE_M];
        uint256 primaryMarketCount = getPrimaryMarketCount();
        for (uint256 i = 0; i < primaryMarketCount; i++) {
            uint256 price_ = price; // Fix the "stack too deep" error
            IPrimaryMarket pm = IPrimaryMarket(getPrimaryMarketMember(i));
            (
                uint256 sharesToMint,
                uint256 sharesToBurn,
                uint256 creationUnderlying,
                uint256 redemptionUnderlying,
                uint256 fee
            ) = pm.settle(day, totalShares, underlying, price_, prevNavM);
            if (sharesToMint > sharesToBurn) {
                _mint(TRANCHE_M, address(pm), sharesToMint - sharesToBurn);
            } else if (sharesToBurn > sharesToMint) {
                _burn(TRANCHE_M, address(pm), sharesToBurn - sharesToMint);
            }
            if (creationUnderlying > redemptionUnderlying) {
                IERC20(tokenUnderlying).safeTransferFrom(
                    address(pm),
                    address(this),
                    creationUnderlying - redemptionUnderlying
                );
            } else if (redemptionUnderlying > creationUnderlying) {
                IERC20(tokenUnderlying).safeTransfer(address(pm), redemptionUnderlying - creationUnderlying);
            }
            if (fee > 0) {
                IERC20(tokenUnderlying).safeTransfer(address(feeCollector), fee);
            }
        }
    }

    /// @dev Check whether a new rebalance should be triggered. Rebalance is triggered if
    ///      NAV of Token B over NAV of Token A is greater than the upper threshold or
    ///      less than the lower threshold.
    /// @param navA NAV of Token A before the rebalance
    /// @param navBOrZero NAV of Token B before the rebalance or zero if the NAV is negative
    /// @return Whether a new rebalance should be triggered
    function _shouldTriggerRebalance(uint256 navA, uint256 navBOrZero) private view returns (bool) {
        uint256 bOverA = navBOrZero.divideDecimal(navA);
        return bOverA < lowerRebalanceThreshold || bOverA > upperRebalanceThreshold;
    }

    /// @dev Create a new rebalance that resets NAV of all tranches to 1. Total supplies are
    ///      rebalanced immediately.
    /// @param day Trading day that triggers this rebalance
    /// @param navM NAV of Token M before this rebalance
    /// @param navA NAV of Token A before this rebalance
    /// @param navBOrZero NAV of Token B before this rebalance or zero if the NAV is negative
    function _triggerRebalance(
        uint256 day,
        uint256 navM,
        uint256 navA,
        uint256 navBOrZero
    ) private {
        Rebalance memory rebalance = _calculateRebalance(navM, navA, navBOrZero);
        uint256 oldSize = _rebalanceSize;
        _rebalances[oldSize] = rebalance;
        _rebalanceSize = oldSize + 1;
        emit RebalanceTriggered(
            oldSize,
            day,
            rebalance.ratioM,
            rebalance.ratioA2M,
            rebalance.ratioB2M,
            rebalance.ratioAB
        );

        (_totalSupplies[TRANCHE_M], _totalSupplies[TRANCHE_A], _totalSupplies[TRANCHE_B]) = doRebalance(
            _totalSupplies[TRANCHE_M],
            _totalSupplies[TRANCHE_A],
            _totalSupplies[TRANCHE_B],
            oldSize
        );
        _refreshBalance(address(this), oldSize + 1);
    }

    /// @dev Create a new rebalance matrix that resets given NAVs to (1, 1, 1).
    ///
    ///      Note that NAV of Token B can be negative before the rebalance when the underlying price
    ///      drops dramatically in a single trading day, in which case zero should be passed to
    ///      this function instead of the negative NAV.
    /// @param navM NAV of Token M before the rebalance
    /// @param navA NAV of Token A before the rebalance
    /// @param navBOrZero NAV of Token B before the rebalance or zero if the NAV is negative
    /// @return The rebalance matrix
    function _calculateRebalance(
        uint256 navM,
        uint256 navA,
        uint256 navBOrZero
    ) private view returns (Rebalance memory) {
        uint256 ratioAB;
        uint256 ratioA2M;
        uint256 ratioB2M;
        if (navBOrZero <= navA) {
            // Lower rebalance
            ratioAB = navBOrZero;
            ratioA2M = ((navM - navBOrZero) * WEIGHT_M) / WEIGHT_A;
            ratioB2M = 0;
        } else {
            // Upper rebalance
            ratioAB = UNIT;
            ratioA2M = navA - UNIT;
            ratioB2M = navBOrZero - UNIT;
        }
        return
            Rebalance({
                ratioM: navM,
                ratioA2M: ratioA2M,
                ratioB2M: ratioB2M,
                ratioAB: ratioAB,
                timestamp: block.timestamp
            });
    }

    function _updateInterestRate(uint256 week) private returns (uint256) {
        uint256 baseInterestRate = MAX_INTEREST_RATE.min(aprOracle.capture());
        uint256 floatingInterestRate;
        if (ballot != address(0) && Address.isContract(ballot)) {
            floatingInterestRate = IBallot(ballot).count(week).div(365);
        }
        uint256 rate = baseInterestRate.add(floatingInterestRate);

        emit InterestRateUpdated(baseInterestRate, floatingInterestRate);

        return rate;
    }

    /// @dev Transform share balance to a given rebalance version, or to the latest version
    ///      if `targetVersion` is zero. This function does no bound check on `targetVersion`.
    /// @param account Account of the balance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function _refreshBalance(address account, uint256 targetVersion) private {
        if (targetVersion == 0) {
            targetVersion = _rebalanceSize;
        }
        uint256 oldVersion = _balanceVersions[account];
        if (oldVersion >= targetVersion) {
            return;
        }

        uint256[TRANCHE_COUNT] storage balanceTuple = _balances[account];
        uint256 balanceM = balanceTuple[TRANCHE_M];
        uint256 balanceA = balanceTuple[TRANCHE_A];
        uint256 balanceB = balanceTuple[TRANCHE_B];
        _balanceVersions[account] = targetVersion;

        if (balanceM == 0 && balanceA == 0 && balanceB == 0) {
            // Fast path for an empty account
            return;
        }

        for (uint256 i = oldVersion; i < targetVersion; i++) {
            (balanceM, balanceA, balanceB) = doRebalance(balanceM, balanceA, balanceB, i);
        }
        balanceTuple[TRANCHE_M] = balanceM;
        balanceTuple[TRANCHE_A] = balanceA;
        balanceTuple[TRANCHE_B] = balanceB;

        emit BalancesRebalanced(account, targetVersion, balanceM, balanceA, balanceB);
    }

    /// @dev Transform allowance to a given rebalance version, or to the latest version
    ///      if `targetVersion` is zero. This function does no bound check on `targetVersion`.
    /// @param owner Owner of the allowance to rebalance
    /// @param spender Spender of the allowance to rebalance
    /// @param targetVersion The target rebalance version, or zero for the latest version
    function _refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) private {
        if (targetVersion == 0) {
            targetVersion = _rebalanceSize;
        }
        uint256 oldVersion = _allowanceVersions[owner][spender];
        if (oldVersion >= targetVersion) {
            return;
        }

        uint256[TRANCHE_COUNT] storage allowanceTuple = _allowances[owner][spender];
        uint256 allowanceM = allowanceTuple[TRANCHE_M];
        uint256 allowanceA = allowanceTuple[TRANCHE_A];
        uint256 allowanceB = allowanceTuple[TRANCHE_B];
        _allowanceVersions[owner][spender] = targetVersion;

        if (allowanceM == 0 && allowanceA == 0 && allowanceB == 0) {
            // Fast path for an empty allowance
            return;
        }

        for (uint256 i = oldVersion; i < targetVersion; i++) {
            (allowanceM, allowanceA, allowanceB) = _rebalanceAllowance(allowanceM, allowanceA, allowanceB, i);
        }
        allowanceTuple[TRANCHE_M] = allowanceM;
        allowanceTuple[TRANCHE_A] = allowanceA;
        allowanceTuple[TRANCHE_B] = allowanceB;

        emit AllowancesRebalanced(owner, spender, targetVersion, allowanceM, allowanceA, allowanceB);
    }

    function _rebalanceAllowance(
        uint256 allowanceM,
        uint256 allowanceA,
        uint256 allowanceB,
        uint256 index
    )
        private
        view
        returns (
            uint256 newAllowanceM,
            uint256 newAllowanceA,
            uint256 newAllowanceB
        )
    {
        Rebalance storage rebalance = _rebalances[index];

        /// @dev using saturating arithmetic to avoid unconscious overflow revert
        newAllowanceM = allowanceM.saturatingMultiplyDecimal(rebalance.ratioM);
        newAllowanceA = allowanceA.saturatingMultiplyDecimal(rebalance.ratioAB);
        newAllowanceB = allowanceB.saturatingMultiplyDecimal(rebalance.ratioAB);
    }
}