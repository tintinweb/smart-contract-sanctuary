// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

interface ICDFTable {

    function addRows(int128[] calldata _fKeys, int128[] calldata _fValues) external;

    function getValue(int128 _fKey) external view returns (int128);

}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity 0.7.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient, Ownable {
    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public view virtual returns (address) {
        return _trustedForwarder;
    }

    function setTrustedForwarder(address _forwarder) external onlyOwner {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual override returns (bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function msgSender() internal view virtual override returns (address payable ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = payable(msg.sender);
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function msgData() internal view virtual override returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function versionRecipient() external view virtual override returns (string memory) {
        return "2.2.4";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {
    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public view virtual returns (bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function msgSender() internal view virtual returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function msgData() internal view virtual returns (bytes calldata);

    function versionRecipient() external view virtual returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

interface IShareTokenFactory {
    function createShareToken() external returns (address);
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.7.4;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = - 0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        require(x >= - 0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
        return int128(x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        return int64(x >> 64);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        require(x <= 0x7FFFFFFFFFFFFFFF);
        return int128(int256(x << 64));
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        require(x >= 0);
        return uint64(uint128(x >> 64));
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        int256 result = x >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        return int256(x) << 64;
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) + y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) - y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) * y >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        if (x == MIN_64x64) {
            require(y >= - 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
            y <= 0x1000000000000000000000000000000000000000000000000);
            return - y << 63;
        } else {
            bool negativeResult = false;
            if (x < 0) {
                x = - x;
                negativeResult = true;
            }
            if (y < 0) {
                y = - y;
                // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint256 absoluteResult = mulu(x, uint256(y));
            if (negativeResult) {
                require(absoluteResult <=
                    0x8000000000000000000000000000000000000000000000000000000000000000);
                return - int256(absoluteResult);
                // We rely on overflow behavior here
            } else {
                require(absoluteResult <=
                    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int256(absoluteResult);
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 0;

        require(x >= 0);

        uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = uint256(int256(x)) * (y >> 128);

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        hi <<= 64;

        require(hi <=
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
        return hi + lo;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        require(y != 0);
        int256 result = (int256(x) << 64) / y;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        require(y != 0);

        bool negativeResult = false;
        if (x < 0) {
            x = - x;
            // We rely on overflow behavior here
            negativeResult = true;
        }
        if (y < 0) {
            y = - y;
            // We rely on overflow behavior here
            negativeResult = !negativeResult;
        }
        uint128 absoluteResult = divuu(uint256(x), uint256(y));
        if (negativeResult) {
            require(absoluteResult <= 0x80000000000000000000000000000000);
            return - int128(absoluteResult);
            // We rely on overflow behavior here
        } else {
            require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128(absoluteResult);
            // We rely on overflow behavior here
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        require(y != 0);
        uint128 result = divuu(x, y);
        require(result <= uint128(MAX_64x64));
        return int128(result);
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64);
        return - x;
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64);
        return x < 0 ? - x : x;
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        require(x != 0);
        int256 result = int256(0x100000000000000000000000000000000) / x;
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        return int128((int256(x) + int256(y)) >> 1);
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        int256 m = int256(x) * int256(y);
        require(m >= 0);
        require(m <
            0x4000000000000000000000000000000000000000000000000000000000000000);
        return int128(sqrtu(uint256(m)));
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        bool negative = x < 0 && y & 1 == 1;

        uint256 absX = uint128(x < 0 ? - x : x);
        uint256 absResult;
        absResult = 0x100000000000000000000000000000000;

        if (absX <= 0x10000000000000000) {
            absX <<= 63;
            while (y != 0) {
                if (y & 0x1 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x2 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x4 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x8 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                y >>= 4;
            }

            absResult >>= 64;
        } else {
            uint256 absXShift = 63;
            if (absX < 0x1000000000000000000000000) {absX <<= 32;
                absXShift -= 32;}
            if (absX < 0x10000000000000000000000000000) {absX <<= 16;
                absXShift -= 16;}
            if (absX < 0x1000000000000000000000000000000) {absX <<= 8;
                absXShift -= 8;}
            if (absX < 0x10000000000000000000000000000000) {absX <<= 4;
                absXShift -= 4;}
            if (absX < 0x40000000000000000000000000000000) {absX <<= 2;
                absXShift -= 2;}
            if (absX < 0x80000000000000000000000000000000) {absX <<= 1;
                absXShift -= 1;}

            uint256 resultShift = 0;
            while (y != 0) {
                require(absXShift < 64);

                if (y & 0x1 != 0) {
                    absResult = absResult * absX >> 127;
                    resultShift += absXShift;
                    if (absResult > 0x100000000000000000000000000000000) {
                        absResult >>= 1;
                        resultShift += 1;
                    }
                }
                absX = absX * absX >> 127;
                absXShift <<= 1;
                if (absX >= 0x100000000000000000000000000000000) {
                    absX >>= 1;
                    absXShift += 1;
                }

                y >>= 1;
            }

            require(resultShift < 64);
            absResult >>= 64 - resultShift;
        }
        int256 result = negative ? - int256(absResult) : int256(absResult);
        require(result >= MIN_64x64 && result <= MAX_64x64);
        return int128(result);
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        require(x >= 0);
        return int128(sqrtu(uint256(int256(x)) << 64));
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        require(x > 0);

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {xc >>= 64;
            msb += 64;}
        if (xc >= 0x100000000) {xc >>= 32;
            msb += 32;}
        if (xc >= 0x10000) {xc >>= 16;
            msb += 16;}
        if (xc >= 0x100) {xc >>= 8;
            msb += 8;}
        if (xc >= 0x10) {xc >>= 4;
            msb += 4;}
        if (xc >= 0x4) {xc >>= 2;
            msb += 2;}
        if (xc >= 0x2) msb += 1;
        // No need to shift xc anymore

        int256 result = msb - 64 << 64;
        uint256 ux = uint256(int256(x)) << uint256(127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        require(x > 0);

        return int128(int256(
                uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000);
        // Overflow

        if (x < - 0x400000000000000000) return 0;
        // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0)
            result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (x & 0x4000000000000000 > 0)
            result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (x & 0x2000000000000000 > 0)
            result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (x & 0x1000000000000000 > 0)
            result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (x & 0x800000000000000 > 0)
            result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (x & 0x400000000000000 > 0)
            result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (x & 0x200000000000000 > 0)
            result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (x & 0x100000000000000 > 0)
            result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (x & 0x80000000000000 > 0)
            result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (x & 0x40000000000000 > 0)
            result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (x & 0x20000000000000 > 0)
            result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (x & 0x10000000000000 > 0)
            result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (x & 0x8000000000000 > 0)
            result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (x & 0x4000000000000 > 0)
            result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (x & 0x2000000000000 > 0)
            result = result * 0x1000162E525EE054754457D5995292026 >> 128;
        if (x & 0x1000000000000 > 0)
            result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (x & 0x800000000000 > 0)
            result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (x & 0x400000000000 > 0)
            result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (x & 0x200000000000 > 0)
            result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (x & 0x100000000000 > 0)
            result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (x & 0x80000000000 > 0)
            result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (x & 0x40000000000 > 0)
            result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (x & 0x20000000000 > 0)
            result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (x & 0x10000000000 > 0)
            result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (x & 0x8000000000 > 0)
            result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (x & 0x4000000000 > 0)
            result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (x & 0x2000000000 > 0)
            result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (x & 0x1000000000 > 0)
            result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (x & 0x800000000 > 0)
            result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (x & 0x400000000 > 0)
            result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (x & 0x200000000 > 0)
            result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (x & 0x100000000 > 0)
            result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (x & 0x80000000 > 0)
            result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (x & 0x40000000 > 0)
            result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (x & 0x20000000 > 0)
            result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (x & 0x10000000 > 0)
            result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (x & 0x8000000 > 0)
            result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (x & 0x4000000 > 0)
            result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (x & 0x2000000 > 0)
            result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (x & 0x1000000 > 0)
            result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (x & 0x800000 > 0)
            result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (x & 0x400000 > 0)
            result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (x & 0x200000 > 0)
            result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (x & 0x100000 > 0)
            result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (x & 0x80000 > 0)
            result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (x & 0x40000 > 0)
            result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (x & 0x20000 > 0)
            result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (x & 0x10000 > 0)
            result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (x & 0x8000 > 0)
            result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (x & 0x4000 > 0)
            result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (x & 0x2000 > 0)
            result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (x & 0x1000 > 0)
            result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (x & 0x800 > 0)
            result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (x & 0x400 > 0)
            result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (x & 0x200 > 0)
            result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (x & 0x100 > 0)
            result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (x & 0x80 > 0)
            result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (x & 0x40 > 0)
            result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (x & 0x20 > 0)
            result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (x & 0x10 > 0)
            result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (x & 0x8 > 0)
            result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (x & 0x4 > 0)
            result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (x & 0x2 > 0)
            result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (x & 0x1 > 0)
            result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

        result >>= uint256(int256(63 - (x >> 64)));
        require(result <= uint256(int256(MAX_64x64)));

        return int128(int256(result));
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000);
        // Overflow

        if (x < - 0x400000000000000000) return 0;
        // Underflow

        return exp_2(
            int128(int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        require(y != 0);

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) {xc >>= 32;
                msb += 32;}
            if (xc >= 0x10000) {xc >>= 16;
                msb += 16;}
            if (xc >= 0x100) {xc >>= 8;
                msb += 8;}
            if (xc >= 0x10) {xc >>= 4;
                msb += 4;}
            if (xc >= 0x4) {xc >>= 2;
                msb += 2;}
            if (xc >= 0x2) msb += 1;
            // No need to shift xc anymore

            result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo;
            // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo;
            // We rely on overflow behavior here

            assert(xh == hi >> 128);

            result += xl / y;
        }

        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return uint128(result);
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {xx >>= 128;
                r <<= 64;}
            if (xx >= 0x10000000000000000) {xx >>= 64;
                r <<= 32;}
            if (xx >= 0x100000000) {xx >>= 32;
                r <<= 16;}
            if (xx >= 0x10000) {xx >>= 16;
                r <<= 8;}
            if (xx >= 0x100) {xx >>= 8;
                r <<= 4;}
            if (xx >= 0x10) {xx >>= 4;
                r <<= 2;}
            if (xx >= 0x8) {r <<= 1;}
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
}

pragma solidity 0.7.4;

library ConverterDec18 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    int256 private constant DECIMALS = 10**18;

    int128 private constant ONE_64x64 = 0x010000000000000000;

    function fromDec18(int256 x) internal pure returns (int128) {
        int256 result = (x * ONE_64x64) / DECIMALS;
        require(x >= MIN_64x64 && x <= MAX_64x64, "result is out of range");
        return int128(result);
    }

    function toDec18(int128 x) internal pure returns (int256) {
        return (int256(x) * DECIMALS) / ONE_64x64;
    }

    function toUDec18(int128 x) internal pure returns (uint256) {
        require(x >= 0, "negative value");
        return uint256(toDec18(x));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

//import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../../interface/IShareTokenFactory.sol";
import "../../libraries/ABDKMath64x64.sol";
import "./../functions/AMMPerpLogic.sol";
import "../../utils/EnumerableSetUpgradeable.sol";
import "../../gsn/BaseRelayRecipient.sol";

contract PerpStorage is Ownable, ReentrancyGuard, BaseRelayRecipient {
    using ABDKMath64x64 for int128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    /**
     * @notice  Perpetual state:
     *          - INVALID:      Uninitialized or not non-existent perpetual;
     *          - INITIALIZING: Only when LiquidityPoolStorage.isRunning == false. Traders cannot perform operations;
     *          - NORMAL:       Full functional state. Traders is able to perform all operations;
     *          - EMERGENCY:    Perpetual is unsafe and only clear is available;
     *          - CLEARED:      All margin account is cleared. Trade could withdraw remaining margin balance.
     */
    enum PerpetualState {
        INVALID,
        INITIALIZING,
        NORMAL,
        EMERGENCY,
        CLEARED
    }

    // margin and liquidity pool are held in 'collateral currency' which can be either of
    // quote currency, base currency, or quanto currency

    int128 internal constant ONE_64x64 = 0x10000000000000000; // 2^64
    //int128 internal constant ONE_HUNDRED_64x64 = 0x640000000000000000; // 100 * 2^64
    int128 internal constant FUNDING_INTERVAL_SEC = 0x70800000000000000000; //3600 * 8 * 0x10000000000000000 = 8h in seconds scaled by 2^64 for ABDKMath64x64
    int128 internal constant CEIL_PNL_SHARE = 0xc000000000000000; //=0.75: participants get PnL proportional to min[PFund/(PFund+allAMMFundSizes), 75%]
    int128 internal constant DF_TO_AMM_FUND_WITHDRAWAL_SHARE = 0x28f5c28f5c28f51; //=1% if amm margin<target and default fund
    // at target, 1% of missing amount is transferred
    // at every rebalance

    IShareTokenFactory internal shareTokenFactory;

    uint256 internal iPoolCount;
    //pool id (incremental index, starts from 1) => pool data
    mapping(uint256 => LiquidityPoolData) internal liquidityPools;

    //bytes32 id = keccak256(abi.encodePacked(poolId, perpetualIndex));
    //perpetual id (hash(poolId, perpetualIndex)) => pool id
    mapping(bytes32 => uint256) internal perpetualPoolIds;

    /**
     * @notice  Data structure to store oracle price data.
     */
    struct OraclePriceData {
        int128 fPrice;
        uint256 time;
    }

    /**
     * @notice  Data structure to store user margin information.
     */
    struct MarginAccount {
        int128 fLockedInValueQC; // unrealized value locked-in when trade occurs in
        int128 fCashCC; // cash in collateral currency (base, quote, or quanto)
        int128 fPositionBC; // position in base currency (e.g., 1 BTC for BTCUSD)
        int128 fUnitAccumulatedFundingStart; // accumulated funding rate
    }

    /**
     * @notice  Store information for a given perpetual market.
     */
    struct PerpetualData {
        //keccak256(abi.encodePacked(poolId, perpetualIndex)), perpetualIndex starts from 1
        bytes32 id;
        uint256 poolId;
        address oracleS2Addr; //parameter: base-quote pair
        address oracleS3Addr; //parameter: quanto index
        // current prices
        OraclePriceData indexS2PriceData; //base-quote pair
        OraclePriceData indexS3PriceData; //quanto index must be quoted as quanto-quote, 0 if eCollateralCurrency!=QUANTO
        OraclePriceData currentPremium; //signed diff to index price
        OraclePriceData currentPremiumEMA; //diff to index price EMA, used for markprice
        OraclePriceData settlementPremiumEMA; //diff to index price EMA, used for markprice
        OraclePriceData settlementS2PriceData; //base-quote pair
        OraclePriceData settlementS3PriceData; //quanto index
        // funding state
        int128 fCurrentFundingRate;
        int128 fUnitAccumulatedFunding; //accumulated funding in collateral currency
        // Perpetual AMM state
        PerpetualState state;
        int128 fOpenInterest; //open interest is the amount of long positions in base currency or, equiv., the amount of short positions.
        int128 fAMMFundCashCC; // fund-cash in this perpetual - not margin
        int128 fkStar; // signed trade size that minimizes the AMM risk
        int128 fkStarSide; // corresponds to sign(-k*)
        // base parameters
        int128 fInitialMarginRateAlpha; //parameter: initial margin
        int128 fMarginRateBeta; //parameter: initial margin increase factor m=alpha+beta*pos
        int128 fInitialMarginRateCap; //parameter: initial margin stops growing at cap
        int128 fMaintenanceMarginRateAlpha; //parameter: required maintenance margin
        int128 fTreasuryFeeRate; //parameter: fee that the treasury earns
        int128 fPnLPartRate; //parameter: fee that the PnL participants earn
        int128 fReferralRebateRate; //parameter: 0 for now
        int128 fLiquidationPenaltyRate; //parameter: penalty if AMM closes the position and not the trader
        int128 fMinimalSpread; //parameter: minimal spread between long and short perpetual price
        int128 fIncentiveSpread; //parameter: 'incentive' spread to drive AMM to equilibrium
        int128 fLotSizeBC; //parameter: minimal trade unit (in base currency) to avoid dust positions
        // risk parameters for underlying instruments
        int128 fFundingRateClamp; // parameter: funding rate clamp between which we charge 1bps
        int128 fMarkPriceEMALambda; // parameter: Lambda parameter for EMA used in mark-price for funding rates
        int128 fSigma2; // parameter: volatility of base-quote pair
        int128 fSigma3; // parameter: volatility of quanto-quote pair
        int128 fRho23; // parameter: correlation of quanto/base returns
        AMMPerpLogic.CollateralCurrency eCollateralCurrency; //parameter: in what currency is the collateral held?
        // risk parameters for default fund / AMM fund
        int128[2] fStressReturnS2; // parameter: negative and positive stress returns for base-quote asset
        int128[2] fStressReturnS3; // parameter: negative and positive stress returns for quanto-quote asset
        int128 fDFCoverN; // parameter: cover-n rule for default fund. E.g., n=2
        int128[2] fDFLambda; // parameter: EMA lambda for AMM and trader exposure K,k: EMA*lambda + (1-lambda)*K. 0 regular lambda, 1 if current value exceeds past
        int128 fAMMTargetDD; // parameter: target distance to default (=inverse of default probability)
        int128 fAMMMinSizeCC; // parameter: minimal size of AMM pool, regardless of current exposure
        int128 fMinimalTraderExposureEMA; // parameter: minimal value for fCurrentTraderExposureEMA that we don't want to undershoot
        int128 fMinimalAMMExposureEMA; // parameter: minimal value for fCurrentTraderExposureEMA that we don't want to undershoot
        int128 fMaximalTradeSizeBumpUp; // parameter: >1, users can create a maximal position of size fMaximalTradeSizeBumpUp*fCurrentAMMExposureEMA
        //  this is to avoid overly large trades that would put the AMM at risk

        // state: default fund sizing
        int128 fTargetAMMFundSize; //target AMM fund size
        int128 fTargetDFSize; // target default fund size
        int128[2] fCurrentAMMExposureEMA; // 0: negative aggregated exposure (storing negative value), 1: positive
        int128 fCurrentTraderExposureEMA; // trade amounts (storing absolute value)
        // users
        int128 fTotalMarginBalance; //calculated for settlement, in collateral currency
    }

    // users
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) internal activeAccounts; //perpetualId => traderAddressSet
    // accounts
    mapping(bytes32 => mapping(address => MarginAccount)) internal marginAccounts;

    struct Checkpoint {
        uint128 timestamp;
        int128 amount; //amount of tokens returned
    }

    struct LiquidityPoolData {
        //index, starts from 1
        uint256 id;
        bool isRunning;
        //parameters
        address treasuryAddress; // parameter: address for the protocol treasury
        address marginTokenAddress; //parameter: address of the margin token
        address shareTokenAddress; //
        uint256 iTargetPoolSizeUpdateTime; //parameter: timestamp in seconds. How often would we want to update the target size of the pool?
        // liquidity state (held in collateral currency)
        int128 fPnLparticipantsCashCC; //addLiquidity/removeLiquidity + profit/loss - rebalance
        int128 fAMMFundCashCC; //profit/loss - rebalance (sum of cash in individual perpetuals)
        int128 fDefaultFundCashCC; //profit/loss
        uint256 iPriceUpdateTimeSec; // timestamp from block.timestamp
        int128 fTargetAMMFundSize; //target AMM pool size for all perpetuals in pool (sum)
        int128 fTargetDFSize; //target default fund size for all perpetuals in pool
        uint256 iLastTargetPoolSizeTime; //timestamp (seconds) since last update of fTargetDFSize and fTargetAMMFundSize
        uint256 iLastFundingTime; //timestamp since last funding rate payment
        // Liquidity provider restrictions
        //the withdrawal limitation period
        uint256 iPnLparticipantWithdrawalPeriod;
        //percentage of total fPnLparticipantsCashCC (e.g. 10%)
        int128 fPnLparticipantWithdrawalPercentageLimit;
        //minimum amount of tokens to be restricted for the withdrawal (e.g. 1000)
        int128 fPnLparticipantWithdrawalMinAmountLimit;
        int128 fRedemptionRate; // used for settlement in case of AMM default
        uint256 iPerpetualCount;
    }

    //pool id => perpetual id list
    mapping(uint256 => bytes32[]) internal perpetualIds;

    //pool id => perpetual id => data
    mapping(uint256 => mapping(bytes32 => PerpetualData)) internal perpetuals;

    //pool id => user => array of checkpoint data
    mapping(uint256 => mapping(address => Checkpoint[])) internal checkpoints;

    address internal ammPerpLogic;

    /// @dev user => flag whether user has admin role.
    /// @dev recommended that multisig be an admin
    //mapping(address => bool) internal ammGovernanceAddresses;
    EnumerableSetUpgradeable.AddressSet internal ammGovernanceAddresses;

    /// @dev flag whether MarginTradeOrder was already executed
    mapping(bytes32 => bool) executedOrders;

    mapping(address => OraclePriceData) oraclePriceDataUpdate;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2; // to pass structs in public function

import "../../libraries/ABDKMath64x64.sol";
import "../../perpetual/interfaces/IAMMPerpLogic.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../cdf/ICDFTable.sol";

contract AMMPerpLogic is Ownable, IAMMPerpLogic {
    using ABDKMath64x64 for int128;

    int128 public constant ONE_64x64 = 0x10000000000000000; // 2^64
    int128 public constant TWO_64x64 = 0x20000000000000000; // 2*2^64
    int128 public constant FOUR_64x64 = 0x40000000000000000; //4*2^64
    int128 public constant HALF_64x64 = 0x8000000000000000; //0.5*2^64
    int128 public constant TWENTY_64x64 = 0x140000000000000000; //20*2^64

    enum CollateralCurrency {
        QUOTE,
        BASE,
        QUANTO
    }

    struct AMMVariables {
        // all variables are
        // signed 64.64-bit fixed point number
        int128 fLockedValue1; // L1 in quote currency
        int128 fPoolM1; // M1 in quote currency
        int128 fPoolM2; // M2 in base currency
        int128 fPoolM3; // M3 in quanto currency
        int128 fAMM_K2; // AMM exposure (positive if trader long)
    }

    struct MarketVariables {
        int128 fIndexPriceS2; // base index
        int128 fIndexPriceS3; // quanto index
        int128 fSigma2; // standard dev of base currency
        int128 fSigma3; // standard dev of quanto currency
        int128 fRho23; // correlation base/quanto currency
    }

    ICDFTable public CDFTable;

    function setCDFTable(address _CDFTable) external onlyOwner {
        require(_CDFTable != address(0), "invalid address");
        CDFTable = ICDFTable(_CDFTable);
    }

    /**
     * Calculate Exponentially Weighted Moving Average.
     * Returns updated EMA based on
     * _fEMA = _fLambda * _fEMA + (1-_fLambda)* _fCurrentObs
     * @param _fEMA signed 64.64-bit fixed point number
     * @param _fCurrentObs signed 64.64-bit fixed point number
     * @param _fLambda signed 64.64-bit fixed point number
     * @return updated EMA, signed 64.64-bit fixed point number
     */
    function ema(
        int128 _fEMA,
        int128 _fCurrentObs,
        int128 _fLambda
    ) public pure virtual override returns (int128) {
        require(_fLambda > 0, "EMA Lambda must be greater than 0");
        require(_fLambda < ONE_64x64, "EMA Lambda must be smaller than 1");
        // result must be between the two values _fCurrentObs and _fEMA, so no overflow
        int128 fEWMANew = ABDKMath64x64.add(_fEMA.mul(_fLambda), ABDKMath64x64.mul(ONE_64x64.sub(_fLambda), _fCurrentObs));
        return fEWMANew;
    }

    /**
     *  Calculate the normal CDF value of _fX, i.e.,
     *  k=P(X<=_fX), for X~normal(0,1)
     *  @dev replace with proper CDF table
     *  @param _fX signed 64.64-bit fixed point number
     *  @return response approximated normal-cdf evaluated at X
     */
    function _normalCDF(int128 _fX) internal view returns (int128 response) {
        bool isPositive = false;
        if (_fX > 0) {
            _fX = _fX.neg();
            isPositive = true;
        }
        response = CDFTable.getValue(_fX);
        if (isPositive) {
            response = ONE_64x64.sub(response);
        }
        return response;
    }

    /**
     *  Calculate the target size for the default fund
     *
     *  @param _fK2AMM       signed 64.64-bit fixed point number, Conservative negative[0]/positive[1] AMM exposure
     *  @param _fk2Trader    signed 64.64-bit fixed point number, Conservative (absolute) trader exposure
     *  @param _fCoverN      signed 64.64-bit fixed point number, cover-n rule for default fund parameter
     *  @param fStressRet2   signed 64.64-bit fixed point number, negative[0]/positive[1] stress returns for base/quote pair
     *  @param fStressRet3   signed 64.64-bit fixed point number, negative[0]/positive[1] stress returns for quanto/quote currency
     *  @param fIndexPrices  signed 64.64-bit fixed point number, spot price for base/quote[0] and quanto/quote[1] pairs
     *  @param _eCCY         enum that specifies in which currency the collateral is held: QUOTE, BASE, QUANTO
     *  @return approximated normal-cdf evaluated at X
     */
    function calculateDefaultFundSize(
        int128[2] memory _fK2AMM,
        int128 _fk2Trader,
        int128 _fCoverN,
        int128[2] memory fStressRet2,
        int128[2] memory fStressRet3,
        int128[2] memory fIndexPrices,
        AMMPerpLogic.CollateralCurrency _eCCY
    ) public pure override returns (int128) {
        require(_fK2AMM[0] < 0, "First element of _fK2AMM required to be negative");
        require(_fK2AMM[1] > 0, "Second element of _fK2AMM required to be positive");
        require(_fk2Trader > 0, "_fk2Trader required to be positive");

        int128[2] memory fEll;
        _fK2AMM[0] = _fK2AMM[0].abs();
        _fK2AMM[1] = _fK2AMM[1].abs();
        // downward stress scenario
        fEll[0] = (_fK2AMM[0].add(_fk2Trader.mul(_fCoverN))).mul(ONE_64x64.sub(fStressRet2[0].exp()));
        // upward stress scenario
        fEll[1] = (_fK2AMM[1].add(_fk2Trader.mul(_fCoverN))).mul(fStressRet2[1].exp().sub(ONE_64x64));
        int128 fIstar;
        if (_eCCY == AMMPerpLogic.CollateralCurrency.BASE) {
            fIstar = fEll[0].div(fStressRet2[0].exp());
            int128 fI2 = fEll[1].div(fStressRet2[1].exp());
            if (fI2 > fIstar) {
                fIstar = fI2;
            }
        } else if (_eCCY == AMMPerpLogic.CollateralCurrency.QUANTO) {
            fIstar = fEll[0].div(fStressRet3[0].exp());
            int128 fI2 = fEll[1].div(fStressRet3[1].exp());
            if (fI2 > fIstar) {
                fIstar = fI2;
            }
            fIstar = fIstar.mul(fIndexPrices[0].div(fIndexPrices[1]));
        } else {
            assert(_eCCY == AMMPerpLogic.CollateralCurrency.QUOTE);
            if (fEll[0] > fEll[1]) {
                fIstar = fEll[0].mul(fIndexPrices[0]);
            } else {
                fIstar = fEll[1].mul(fIndexPrices[0]);
            }
        }
        return fIstar;
    }

    /**
     *  Calculate the risk neutral Distance to Default (Phi(DD)=default probability) when
     *  there is no quanto currency collateral.
     *  We assume r=0 everywhere.
     *  The underlying distribution is log-normal, hence the log below.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars current AMM variables
     *  @param _mktVars current Market variables (price&params)
     *  @param _fSign signed 64.64-bit fixed point number, sign of denominator of distance to default
     *  @return _fThresh signed 64.64-bit fixed point number, number for which the log is the unnormalized distance to default
     */
    function _calculateRiskNeutralDDNoQuanto(
        AMMVariables memory _ammVars,
        MarketVariables memory _mktVars,
        int128 _fSign,
        int128 _fThresh
    ) internal pure returns (int128) {
        require(_fThresh > 0, "argument to log must be >0");
        require(_mktVars.fSigma2 > 0, "volatility Sigma2 must be positive");
        int128 _fLogTresh = _fThresh.ln();
        int128 fSigma2_2 = _mktVars.fSigma2.mul(_mktVars.fSigma2);
        int128 fMean = fSigma2_2.div(TWO_64x64).neg();
        int128 fDistanceToDefault = ABDKMath64x64.sub(_fLogTresh, fMean).div(_mktVars.fSigma2);
        // because 1-Phi(x) = Phi(-x) we change the sign if _fSign<0
        // now we would like to get the normal cdf of that beast
        if (_fSign < 0) {
            fDistanceToDefault = fDistanceToDefault.neg();
        }
        return fDistanceToDefault;
    }

    /**
     *  Calculate the standard deviation for the random variable
     *  evolving when quanto currencies are involved.
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars current AMM/Market variables
     *  @param _mktVars current Market variables (price&params)
     *  @param _fC3 signed 64.64-bit fixed point number current AMM/Market variables
     *  @param _fC3_2 signed 64.64-bit fixed point number, squared fC3
     *  @return standard deviation, 64.64-bit fixed point number
     */
    function _calculateStandardDeviationQuanto(
        AMMVariables memory _ammVars,
        MarketVariables memory _mktVars,
        int128 _fC3,
        int128 _fC3_2
    ) internal pure returns (int128) {
        int128 fSigmaZ;
        int128 fSigma2_2 = _mktVars.fSigma2.mul(_mktVars.fSigma2);
        int128 fSigma3_2 = _mktVars.fSigma3.mul(_mktVars.fSigma3);
        int128 fVarA = ABDKMath64x64.sub(fSigma3_2.exp(), ONE_64x64);
        // fVarB1 = exp(sigma2*sigma3*rho)
        int128 fVarB1 = (_mktVars.fSigma2.mul(_mktVars.fSigma3).mul(_mktVars.fRho23)).exp();
        // fVarB = 2*(exp(sigma2*sigma3*rho) - 1)
        int128 fVarB = ABDKMath64x64.sub(fVarB1, ONE_64x64).mul(TWO_64x64);
        int128 fVarC = ABDKMath64x64.sub(fSigma2_2.exp(), ONE_64x64);
        // sigmaZ = fVarA*C^2 + fVarB*C + fVarC
        int128 fSigmaZ_2 = ABDKMath64x64.add(fVarA.mul(_fC3_2), fVarB.mul(_fC3)).add(fVarC);
        fSigmaZ = fSigmaZ_2.sqrt();
        return fSigmaZ;
    }

    /**
     *  Calculate the risk neutral Distance to Default (Phi(DD)=default probability) when
     *  presence of quanto currency collateral.
     *
     *  We approximate the distribution with a normal distribution
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number
     *  @param _ammVars current AMM/Market variables
     *  @param _mktVars current Market variables (price&params)
     *  @param _fSign 64.64-bit fixed point number, current AMM/Market variables
     *  @return _fLambdasigned 64.64-bit fixed point number
     */
    function _calculateRiskNeutralDDWithQuanto(
        AMMVariables memory _ammVars,
        MarketVariables memory _mktVars,
        int128 _fSign,
        int128 _fThresh
    ) internal pure returns (int128) {
        if (_fThresh < 0 && _ammVars.fLockedValue1.neg().sub(_ammVars.fPoolM1) <= 0 ) {
            // zero default probability
            return TWENTY_64x64.neg();
        }
        // 1) Calculate C3
        // s2*(M2-K2)
        int128 fDenom = _mktVars.fIndexPriceS2.mul(_ammVars.fPoolM2.sub(_ammVars.fAMM_K2));
        // M3*s3/denom
        int128 fC3 = _ammVars.fPoolM3.mul(_mktVars.fIndexPriceS3).div(fDenom);
        int128 fC3_2 = fC3.mul(fC3);

        // 2) Calculate Variance
        int128 fSigmaZ = _calculateStandardDeviationQuanto(_ammVars, _mktVars, fC3, fC3_2);

        // 3) Calculate mean
        int128 fMean = ABDKMath64x64.add(fC3, ONE_64x64);
        // 4) Distance to default
        int128 fDistanceToDefault = ABDKMath64x64.sub(_fThresh, fMean).div(fSigmaZ);
        // because 1-Phi(x) = Phi(-x) we change the sign if _fSign<0
        // now we would like to get the normal cdf of that beast
        if (_fSign < 0) {
            fDistanceToDefault = fDistanceToDefault.neg();
        }
        return fDistanceToDefault;
    }

    /**
     *  Calculate the risk neutral default probability (>=0).
     *  Function decides whether pricing with or without quanto CCY is chosen.
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars         current AMM variables.
     *  @param _mktVars         current Market variables (price&params)
     *  @param _fTradeAmount    Trade amount (can be 0), hence amounts k2 are not already factored in
     *                          that is, function will set K2:=K2+k2, L1:=L1+k2*s2 (k2=_fTradeAmount)
     *  @param _withCDF         bool. If false, the normal-cdf is not evaluated (in case the caller is only
     *                          interested in the distance-to-default, this saves calculations)
     *  @return (default probabilit, distance to default) ; 64.64-bit fixed point numbers
     */
    function calculateRiskNeutralPD(AMMVariables memory _ammVars, 
        MarketVariables memory _mktVars, int128 _fTradeAmount, bool _withCDF) 
        public view virtual override returns (int128, int128) 
    {
        int128 dL = _fTradeAmount.mul(_mktVars.fIndexPriceS2);
        int128 dK = _fTradeAmount;
        _ammVars.fLockedValue1 = _ammVars.fLockedValue1.add(dL);
        _ammVars.fAMM_K2 = _ammVars.fAMM_K2.add(dK);
        // -L1 - k*s2 - M1
        int128 fNominator = (_ammVars.fLockedValue1.neg()).sub(_ammVars.fPoolM1);
        // s2*(M2-k2-K2)
        int128 fDenominator = (_ammVars.fPoolM2.sub(_ammVars.fAMM_K2)).mul(_mktVars.fIndexPriceS2);
        
        // handle cases when denominator close to zero
        // or when we have opposite signs (to avoid ln(-|value|))
        if (fDenominator.mul(fNominator) <= 0) {
            if (fNominator <= 0) {
                // undo changing the struct
                _ammVars.fLockedValue1 = _ammVars.fLockedValue1.sub(dL);
                _ammVars.fAMM_K2 = _ammVars.fAMM_K2.sub(dK);
                return (int128(0), TWENTY_64x64.neg());
            } else if (_ammVars.fPoolM3 == 0) {
                // undo changing the struct
                _ammVars.fLockedValue1 = _ammVars.fLockedValue1.sub(dL);
                _ammVars.fAMM_K2 = _ammVars.fAMM_K2.sub(dK);
                return (int128(ONE_64x64), TWENTY_64x64);
            }   
        }
        // sign tells us whether we consider norm.cdf(f(threshold)) or 1-norm.cdf(f(threshold))
        int128 fSign = fDenominator < 0 ? ONE_64x64.neg() : ONE_64x64;
        int128 fThresh = fNominator.div(fDenominator);
        int128 dd = _ammVars.fPoolM3 == 0
            ? _calculateRiskNeutralDDNoQuanto(_ammVars, _mktVars, fSign, fThresh)
            : _calculateRiskNeutralDDWithQuanto(_ammVars, _mktVars, fSign, fThresh);
        
        int128 q;
        if (_withCDF) {
            q = _normalCDF(dd);
        }
        // undo changing the struct
        _ammVars.fLockedValue1 = _ammVars.fLockedValue1.sub(dL);
        _ammVars.fAMM_K2 = _ammVars.fAMM_K2.sub(dK);
        return (q, dd);
    }

    /**
     *  Calculate AMM price.
     *
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars current AMM variables.
     *  @param _mktVars current Market variables (price&params)
     *                 Trader amounts k2 must already be factored in
     *                 that is, K2:=K2+k2, L1:=L1+k2*s2
     *  @param _fTradeAmount 64.64-bit fixed point number, signed size of trade
     *  @param _fSpreads [minimal spread, incentive spread] 64.64-bit fixed point number
     *  @return 64.64-bit fixed point number, AMM price
     */
    function calculatePerpetualPrice(
        AMMVariables memory _ammVars,
        MarketVariables memory _mktVars,
        int128 _fTradeAmount,
        int128[2] memory _fSpreads
    ) public view virtual override returns (int128) {
        // get risk-neutral default probability (always >0)
        int128 fQ;
        int128 dd;
        int128 fIncentiveSpread;
        bool isPositive;

        (fQ, dd) = calculateRiskNeutralPD(_ammVars, _mktVars, _fTradeAmount, true);
        if (_ammVars.fPoolM3 == 0) {
            // calculate K*
            int128 fkStar;
            {
                /*
                    u = -L1/s2 - M1/s2
                    v = K2 - M2
                    kStar = (u-v)/2
                */
                int128 u = _ammVars.fLockedValue1.neg().sub(_ammVars.fPoolM1).div(_mktVars.fIndexPriceS2);
                int128 v = _ammVars.fAMM_K2.sub(_ammVars.fPoolM2);
                fkStar = (u.sub(v)).div(TWO_64x64);
            }
            fIncentiveSpread = _fTradeAmount.sub(fkStar).mul(_fSpreads[1]);
            isPositive = _fTradeAmount >= fkStar;
        } else {
            // numerical determination of sign
            if (dd==TWENTY_64x64) {
                // already in default state and DD1 is equal to DD0. We determine the side
                // of k-star by K 
                isPositive = _ammVars.fAMM_K2 > 0 ? true : false;
            } else if (dd==TWENTY_64x64.neg()) {
                // we are in an area where the default probability is 0, the sign is set positive
                isPositive = true;
            } else {
                // numerical, bump by 0.00001
                int128 fddPlus;
                int128 fDelta = 0xa7c5ac471b47; //0.00001
                (, fddPlus) = calculateRiskNeutralPD(_ammVars, _mktVars, _fTradeAmount.add(fDelta), false);
                isPositive = fddPlus >= dd;
            }
        }
        // add minimal spread in quote currency
        int128 _fMinimalSpread = _fTradeAmount>0 ? _fSpreads[0] : _fSpreads[0].neg();
        if (_fTradeAmount == 0) {
            _fMinimalSpread = 0;
        }
        // decide on sign of premium
        if (!isPositive) {
            fQ = fQ.neg();
        }
        // s2*(1 + sign(qp-q)*q + sign(k)*minSpread + incentive)
        return _mktVars.fIndexPriceS2.mul( ONE_64x64.add(fQ).add(_fMinimalSpread).add(fIncentiveSpread) );
    }

    /**
     *  Calculate target collateral M1 (Quote Currency), when no M2, M3 is present
     *  The targeted default probability is expressed using the inverse
     *  _fTargetDD = Phi^(-1)(targetPD)
     *  _fK2 in absolute terms must be 'reasonably large'
     *  sigma3, rho23, IndexpriceS3 not relevant.
     *  @param _fK2 signed 64.64-bit fixed point number, !=0, EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number, >0, EWMA of actual L.
     *  @param  _mktVars contains 64.64 values for fIndexPriceS2*, fIndexPriceS3, fSigma2*, fSigma3, fRho23
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M1Star signed 64.64-bit fixed point number, >0
     */
    function getTargetCollateralM1(
        int128 _fK2,
        int128 _fL1,
        MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) public pure virtual override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 == 0);
        assert(_mktVars.fIndexPriceS3 == 0);
        assert(_mktVars.fRho23 == 0);
        int128 fMu2 = HALF_64x64.neg().mul(_mktVars.fSigma2).mul(_mktVars.fSigma2);
        int128 ddScaled = _fK2 < 0 ? _mktVars.fSigma2.mul(_fTargetDD) : _mktVars.fSigma2.mul(_fTargetDD).neg();
        int128 A1 = ABDKMath64x64.exp(fMu2.add(ddScaled));
        return _fK2.mul(_mktVars.fIndexPriceS2).mul(A1).sub(_fL1);
    }

    /**
     *  Calculate target collateral *M2* (Base Currency), when no M1, M3 is present
     *  The targeted default probability is expressed using the inverse
     *  _fTargetDD = Phi^(-1)(targetPD)
     *  _fK2 in absolute terms must be 'reasonably large'
     *  sigma3, rho23, IndexpriceS3 not relevant.
     *  @param _fK2 signed 64.64-bit fixed point number, EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number, EWMA of actual L.
     *  @param _mktVars contains 64.64 values for fIndexPriceS2, fIndexPriceS3, fSigma2, fSigma3, fRho23
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M2Star signed 64.64-bit fixed point number
     */
    function getTargetCollateralM2(
        int128 _fK2,
        int128 _fL1,
        MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) public pure virtual override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 == 0);
        assert(_mktVars.fIndexPriceS3 == 0);
        assert(_mktVars.fRho23 == 0);
        int128 fMu2 = HALF_64x64.mul(_mktVars.fSigma2).mul(_mktVars.fSigma2).neg();
        int128 ddScaled = _fL1 < 0 ? _mktVars.fSigma2.mul(_fTargetDD) : _mktVars.fSigma2.mul(_fTargetDD).neg();
        int128 A1 = ABDKMath64x64.exp(fMu2.add(ddScaled)).mul(_mktVars.fIndexPriceS2);
        return _fK2.sub(_fL1.div(A1));
    }

    /**
     *  Calculate target collateral M3 (Quanto Currency), when no M1, M2 not present
     *
     *  @param _fK2 signed 64.64-bit fixed point number. EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number.  EWMA of actual L.
     *  @param  _mktVars contains 64.64 values for
     *           fIndexPriceS2, fIndexPriceS3, fSigma2, fSigma3, fRho23 - all required
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M2Star signed 64.64-bit fixed point number
     */
    function getTargetCollateralM3(
        int128 _fK2,
        int128 _fL1,
        MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) public pure override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 != 0);
        assert(_mktVars.fIndexPriceS3 != 0);
        assert(_mktVars.fRho23 != 0);
        int128 fDDSquared = _fTargetDD.mul(_fTargetDD);
        // quadratic equation A x^2 + Bx + C = 0

        int128 fTwoA;
        {
            int128 fV = _mktVars.fIndexPriceS3.div(_mktVars.fIndexPriceS2).div(_fK2).neg();
            // A = ((exp(sig3^2)-1) * DD^2 - 1)*fV
            fTwoA = _mktVars.fSigma3.mul(_mktVars.fSigma3).exp().sub(ONE_64x64);
            fTwoA = fTwoA.mul(fDDSquared).sub(ONE_64x64);
            fTwoA = fTwoA.mul(fV).mul(fV).mul(TWO_64x64);
        }

        int128 fB;
        {
            // b = 2( exp(sig2*sig3*rho) -1 )
            int128 fb = ABDKMath64x64.sub(_mktVars.fSigma2.mul(_mktVars.fSigma3).mul(_mktVars.fRho23).exp(), ONE_64x64).mul(TWO_64x64);
            // B = (b*DD^2- 2 + 2  Kappa ) * v
            int128 fKappa = _fL1.div(_mktVars.fIndexPriceS2).div(_fK2);
            fB = ABDKMath64x64.add(fb.mul(fDDSquared).sub(TWO_64x64), fKappa.mul(TWO_64x64));
            int128 fV = _mktVars.fIndexPriceS3.div(_mktVars.fIndexPriceS2).div(_fK2).neg();
            fB = fB.mul(fV);
        }

        int128 fC;
        {
            // c = exp(sig2^2)-1
            int128 fc = _mktVars.fSigma2.mul(_mktVars.fSigma2).exp().sub(ONE_64x64);
            // C = c*DD^2 - kappa^2 + 2 kappa - 1
            int128 fKappa = _fL1.div(_mktVars.fIndexPriceS2).div(_fK2);
            fC = ABDKMath64x64.add(fc.mul(fDDSquared).sub(fKappa.mul(fKappa)), fKappa.mul(TWO_64x64)).sub(ONE_64x64);
        }

        // two solutions
        int128 delta = ABDKMath64x64.sqrt(fB.mul(fB).sub(TWO_64x64.mul(fTwoA).mul(fC)));
        int128 fMStar = ABDKMath64x64.add(fB.neg(), delta).div(fTwoA);
        {
            int128 fM2 = ABDKMath64x64.sub(fB.neg(), delta).div(fTwoA);
            if (fM2 > fMStar) {
                fMStar = fM2;
            }
        }
        return fMStar;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../core/PerpStorage.sol";
import "../interfaces/ISOVLibraryEvents.sol";
import "../../libraries/ConverterDec18.sol";

contract PerpetualBaseFunctions is PerpStorage, ISOVLibraryEvents {
    using ABDKMath64x64 for int128;
    using ConverterDec18 for int128;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * Calculate initial margin rate (alpha_initial + beta * pos)
     * @param _fPositionSizeBC  The position size
     * @param _perpetual        The perpetual object
     * @return initial margin rate (=1/leverage)
     */
    function _getInitialMarginRate(int128 _fPositionSizeBC, PerpetualData memory _perpetual) internal pure returns (int128) {
        int128 m = _perpetual.fInitialMarginRateAlpha.add(_perpetual.fMarginRateBeta.mul(_fPositionSizeBC.abs()));
        if (m > _perpetual.fInitialMarginRateCap) {
            m = _perpetual.fInitialMarginRateCap;
        }
        return m;
    }

    /**
     * Calculate maintenance margin rate (alpha_mntnc + beta * pos)
     * @param _fPositionSizeBC  The position size
     * @param _perpetual        The perpetual object
     * @return maintenance margin rate (=1/leverage)
     */
    function _getMaintenanceMarginRate(int128 _fPositionSizeBC, PerpetualData memory _perpetual) internal pure returns (int128) {
        int128 m = _getInitialMarginRate(_fPositionSizeBC, _perpetual);
        m = m.sub(_perpetual.fInitialMarginRateAlpha.sub(_perpetual.fMaintenanceMarginRateAlpha));
        return m;
    }

    function _getLiquidityPoolFromPerpetual(bytes32 _Id) internal view returns (LiquidityPoolData storage) {
        uint256 poolId = perpetualPoolIds[_Id];
        return liquidityPools[poolId];
    }

    function _getPoolIdFromPerpetual(bytes32 _Id) internal view returns (uint256) {
        return perpetualPoolIds[_Id];
    }

    /**
     * Get perpetual reference from its 'globally' unique id
     *
     * @param   _iPerpetualId Unique id (across liq pools) in the form of a hash
     *
     */
    function _getPerpetual(bytes32 _iPerpetualId) internal view returns (PerpetualData storage) {
        uint256 poolId = perpetualPoolIds[_iPerpetualId];
        require(poolId > 0, "perpetual not found");

        return perpetuals[poolId][_iPerpetualId];
    }

    /**
     * @dev Check if the account of the trader is empty in the perpetual, which means fCashCC = 0 and fPositionBC = 0
     * @param _perpetual The perpetual object
     * @param _traderAddr The address of the trader
     * @return True if the account of the trader is empty in the perpetual
     */
    function _isEmptyAccount(PerpetualData memory _perpetual, address _traderAddr) internal view returns (bool) {
        MarginAccount storage account = marginAccounts[_perpetual.id][_traderAddr];
        return account.fCashCC == 0 && account.fPositionBC == 0;
    }

    /**
     * Get the trader (or AMM) position (in base currency) in the perpetual
     * @param _perpetual The perpetual object
     * @param _traderAddr The address of the trader
     * @return The trader position of in the perpetual
     */
    function _getTraderPosition(PerpetualData memory _perpetual, address _traderAddr) internal view returns (int128) {
        return marginAccounts[_perpetual.id][_traderAddr].fPositionBC;
    }

    /**
     * Update the trader's cash in the margin account (trader can also be the AMM)
     * The 'cash' is denominated in collateral currency.
     * @param _perpetual   The perpetual struct
     * @param _traderAddr The address of the trader
     * @param _fDeltaCash signed 64.64-bit fixed point number.
     *                    Change of trader margin in collateral currency.
     */
    function _updateTraderMargin(
        PerpetualData storage _perpetual,
        address _traderAddr,
        int128 _fDeltaCash
    ) internal {
        if (_fDeltaCash == 0) {
            return;
        }
        MarginAccount storage account = marginAccounts[_perpetual.id][_traderAddr];
        account.fCashCC = account.fCashCC.add(_fDeltaCash);
    }

    /**
     * Transfer from the user to the vault account.
     * @param   _marginTknAddr Margin token address
     * @param   _userAddr    The address of the account
     * @param   _fAmount     The amount of erc20 token to transfer in ABDK64x64 format.
     */
    function _transferFromUserToVault(
        address _marginTknAddr,
        address _userAddr,
        int128 _fAmount
    ) internal {
        if (_fAmount <= 0) {
            return;
        }
        uint256 ufAmountD18 = _fAmount.toUDec18();
        address vault = address(this);
        IERC20Upgradeable marginToken = IERC20Upgradeable(_marginTknAddr);
        uint256 previousBalance = marginToken.balanceOf(vault);

        marginToken.safeTransferFrom(_userAddr, vault, ufAmountD18);
        uint256 postBalance = marginToken.balanceOf(vault);
        require(postBalance > previousBalance, "inwards transferred amount incorrect");
    }

    /**
     * Transfer from the vault to the user account.
     * @param   _marginTknAddr Margin token address
     * @param   _traderAddr    The address of the account
     * @param   _fAmount       The amount of erc20 token to transfer.
     */
    function _transferFromVaultToUser(
        address _marginTknAddr,
        address _traderAddr,
        int128 _fAmount
    ) internal {
        if (_fAmount == 0) {
            return;
        }
        uint256 ufAmountD18 = _fAmount.toUDec18();
        address vault = address(this);
        IERC20Upgradeable marginToken = IERC20Upgradeable(_marginTknAddr);
        uint256 previousBalance = marginToken.balanceOf(vault);

        marginToken.safeTransfer(_traderAddr, ufAmountD18);
        uint256 postBalance = marginToken.balanceOf(vault);
        require(previousBalance > postBalance, "outwards transferred amount incorrect");
    }

    /**
     * @dev     Check if the trader is initial margin safe in the perpetual, which means available margin >= 0
     * @param   _perpetual   The perpetual object
     * @param   _traderAddr      The address of the trader
     * @return  boolean, true if the trader is initial margin safe in the perpetual
     */
    function _isInitialMarginSafe(PerpetualData memory _perpetual, address _traderAddr) internal view returns (bool) {
        return (_getAvailableMargin(_perpetual, _traderAddr, true) >= 0);
    }

    /**
     * Available margin: (margin collateral + PnL) - initial margin
     * Hence we reserve the initial margin at the current price.
     * @param   _perpetual          The perpetual object
     * @param   _traderAddr         The address of the trader
     * @param   _isInitialMargin    True will calculate difference to initial margin, fals to maintenance margin
     * @return  The available margin of the trader in the perpetual
     */
    function _getAvailableMargin(
        PerpetualData memory _perpetual,
        address _traderAddr,
        bool _isInitialMargin
    ) internal view returns (int128) {
        int128 fInitialMarginCC;
        if (marginAccounts[_perpetual.id][_traderAddr].fPositionBC != 0) {
            // if the position remains open, we reserve the initial/maintenance margin at the current price
            if (_isInitialMargin) {
                fInitialMarginCC = _getInitialMargin(_perpetual, _traderAddr);
            } else {
                fInitialMarginCC = _getMaintenanceMargin(_perpetual, _traderAddr);
            }
        }
        int128 fAvailableMargin = _getMarginBalance(_perpetual, _traderAddr).sub(fInitialMarginCC);
        return fAvailableMargin;
    }

    /**
     * @dev Get the initial margin of the trader in the perpetual in collateral currency.
     *      Initial margin = price * abs(position) * initial margin rate
     * @param _perpetual        The perpetual object
     * @param _traderAddr       The address of the trader
     * @return The initial margin of the trader in the perpetual
     */
    function _getInitialMargin(PerpetualData memory _perpetual, address _traderAddr) internal view returns (int128) {
        // base to collateral currency conversion
        int128 fConversionB2C = _getBaseToCollateralConversionMultiplier(_perpetual, true);
        int128 pos = marginAccounts[_perpetual.id][_traderAddr].fPositionBC;
        int128 m = _getInitialMarginRate(pos, _perpetual);
        return pos.mul(fConversionB2C).mul(m).abs();
    }

    /**
     * @dev Get the maintenance margin of the trader in the perpetual in collateral currency.
     *      Maintenance margin = price * abs(position) * maintenance margin rate
     * @param _perpetual        The perpetual object
     * @param _traderAddr       The address of the trader
     * @return The maintenance margin of the trader in the perpetual
     */
    function _getMaintenanceMargin(PerpetualData memory _perpetual, address _traderAddr) internal view returns (int128) {
        // base to collateral currency conversion
        int128 fConversionB2C = _getBaseToCollateralConversionMultiplier(_perpetual, true);
        int128 pos = marginAccounts[_perpetual.id][_traderAddr].fPositionBC;
        int128 m = _getMaintenanceMarginRate(pos, _perpetual);
        return pos.mul(fConversionB2C).mul(m).abs();
    }

    /**
     * @dev Get the margin of the trader in the perpetual at markprice (collateral currency).
     *      Settlement price is used if perpetual state not normal.
     *      Margin_cc = unrealized P&L + cash - funding
     *             = locked-in value * fx_q2c + position * fx_b2c(at mark price) + cash
     * @param _perpetual The perpetual object
     * @param _traderAddr The address of the trader
     * @return The margin of the trader for the given the perpetual
     */
    function _getMarginBalance(PerpetualData memory _perpetual, address _traderAddr) internal view returns (int128) {
        // base to collateral currency conversion
        int128 fConversionB2C = _getBaseToCollateralConversionMultiplier(_perpetual, true);
        // quote to collateral currency conversion

        int128 fConversionQ2C = ONE_64x64.div(_getCollateralToQuoteConversionMultiplier(_perpetual));
        int128 fLockedInValueCC = marginAccounts[_perpetual.id][_traderAddr].fLockedInValueQC.mul(fConversionQ2C);
        int128 fCashCC = _getAvailableCash(_perpetual, _traderAddr);
        int128 fMargin = marginAccounts[_perpetual.id][_traderAddr].fPositionBC.mul(fConversionB2C).add(fCashCC);
        fMargin = fMargin.sub(fLockedInValueCC);
        return fMargin;
    }

    /**
     * Get the available cash of the trader in the perpetual in *collateral* currency
     * This is pure margin-cash net of funding, locked-in value not considered.
     * Available cash = cash - position * unit accumulative funding
     * @param _perpetual The perpetual object
     * @param traderAddr The address of the trader
     * @return availableCash The available cash of the trader in the perpetual
     */
    function _getAvailableCash(PerpetualData memory _perpetual, address traderAddr) internal view returns (int128) {
        MarginAccount storage account = marginAccounts[_perpetual.id][traderAddr];
        int128 fCashCC = account.fCashCC;
        int128 fConversionB2C = _getBaseToCollateralConversionMultiplier(_perpetual, false);
        // unit-funding is in collateral currency
        int128 fFundingUnitPayment = _perpetual.fUnitAccumulatedFunding.sub(account.fUnitAccumulatedFundingStart);
        return fCashCC.sub(account.fPositionBC.mul(fFundingUnitPayment));
    }

    /**
     * Get the multiplier that converts <base> into
     * the value of <collateralcurrency>
     * Hence 1 if collateral currency = base currency
     * If the state of the perpetual is not "NORMAL",
     * use the settlement price
     * @param   _perpetual           The reference of perpetual storage.
     * @param   _isMarkPriceRequest  If true, get the conversion for the mark-price. If false for spot.
     * @return  The index price of the collateral for the given perpetual.
     */
    function _getBaseToCollateralConversionMultiplier(PerpetualData memory _perpetual, bool _isMarkPriceRequest) internal pure returns (int128) {
        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        /*
        Quote: Pos * markprice --> quote currency
        Base: Pos * markprice / indexprice; E.g., 0.1 BTC * 36500 / 36000
        Quanto: Pos * markprice / index3price. E.g., 0.1 BTC * 36500 / 2000 = 1.83 ETH
        where markprice is replaced by indexprice if _isMarkPriceRequest=FALSE
        */
        int128 fPx2;
        int128 fPxIndex2;
        if (_perpetual.state != PerpetualState.NORMAL) {
            fPxIndex2 = _perpetual.settlementS2PriceData.fPrice;
            require(fPxIndex2 > 0, "settlement price S2 not set");
        } else {
            fPxIndex2 = _perpetual.indexS2PriceData.fPrice;
        }

        if (_isMarkPriceRequest) {
            fPx2 = _getPerpetualMarkPrice(_perpetual);
        } else {
            fPx2 = fPxIndex2;
        }

        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            // equals ONE if _isMarkPriceRequest=FALSE
            return fPx2.div(fPxIndex2);
        }
        if (ccy == AMMPerpLogic.CollateralCurrency.QUANTO) {
            // Example: 0.5 contracts of ETHUSD paid in BTC
            //  the rate is ETHUSD * 1/BTCUSD
            //  BTCUSD = 31000 => 0.5/31000 = 0.00003225806452 BTC
            return _perpetual.state == PerpetualState.NORMAL ? fPx2.div(_perpetual.indexS3PriceData.fPrice) : fPx2.div(_perpetual.settlementS3PriceData.fPrice);
        } else {
            // Example: 0.5 contracts of ETHUSD paid in USD
            //  the rate is ETHUSD
            //  ETHUSD = 2000 => 0.5 * 2000 = 1000
            require(ccy == AMMPerpLogic.CollateralCurrency.QUOTE, "unknown state");
            return fPx2;
        }
    }

    /**
     * Get the mark price of the perpetual. If the state of the perpetual is not "NORMAL",
     * return the settlement price
     * @param   _perpetual The perpetual in the liquidity pool
     * @return  markPrice  The mark price of current perpetual.
     */
    function _getPerpetualMarkPrice(PerpetualData memory _perpetual) internal pure returns (int128) {
        int128 markPrice = _perpetual.state == PerpetualState.NORMAL
            ? (_perpetual.indexS2PriceData.fPrice).add(_perpetual.currentPremiumEMA.fPrice)
            : (_perpetual.settlementS2PriceData.fPrice).add(_perpetual.settlementPremiumEMA.fPrice);
        return markPrice;
    }

    /**
     * Get the multiplier that converts <collateralcurrency> into
     * the value of <quotecurrency>
     * Hence 1 if collateral currency = quote currency
     * If the state of the perpetual is not "NORMAL",
     * use the settlement price
     * @param   _perpetual           The reference of perpetual storage.
     * @return  The index price of the collateral for the given perpetual.
     */
    function _getCollateralToQuoteConversionMultiplier(PerpetualData memory _perpetual) internal pure returns (int128) {
        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        /*
            Quote: 1
            Base: S2, e.g. we hold 1 BTC -> 36000 USD
            Quanto: S3, e.g., we hold 1 ETH -> 2000 USD
        */
        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            return _perpetual.state == PerpetualState.NORMAL ? _perpetual.indexS2PriceData.fPrice : _perpetual.settlementS2PriceData.fPrice;
        }
        if (ccy == AMMPerpLogic.CollateralCurrency.QUANTO) {
            return _perpetual.state == PerpetualState.NORMAL ? _perpetual.indexS3PriceData.fPrice : _perpetual.settlementS3PriceData.fPrice;
        } else {
            return ONE_64x64;
        }
    }

    function _updateMarkPrice(PerpetualData storage _perpetual, uint256 _iCurrentTimeSec) internal {
        _updateInsurancePremium(_perpetual, _iCurrentTimeSec);
        _updatePremiumMarkPrice(_perpetual, _iCurrentTimeSec);
        emit UpdateMarkPrice(_perpetual.id, _perpetual.currentPremiumEMA.fPrice, _perpetual.indexS2PriceData.fPrice, _perpetual.currentPremiumEMA.time);
    }

    /**
     * Update the EMA of insurance premium used for the mark price
     * @param   _perpetual   The reference of perpetual storage.
     * @param   _iCurrentTimeSec   The current timestamp (block.timestamp)
     */
    function _updatePremiumMarkPrice(PerpetualData storage _perpetual, uint256 _iCurrentTimeSec) internal {
        _perpetual.currentPremiumEMA.fPrice = _getAMMPerpLogic().ema(
            _perpetual.currentPremiumEMA.fPrice,
            _perpetual.currentPremium.fPrice,
            _perpetual.fMarkPriceEMALambda
        );
        _perpetual.currentPremiumEMA.time = _iCurrentTimeSec;
    }

    /**
     * Update the mid-price for the insurance premium. This is used for EMA of perpetual prices
     * (mark-price used in funding payments and rebalance)
     * @param   _perpetual   The reference of perpetual storage.
     * @param   _iCurrentTimeSec   The current timestamp (block.timestamp)
     */
    function _updateInsurancePremium(PerpetualData storage _perpetual, uint256 _iCurrentTimeSec) internal {
        // prepare data
        AMMPerpLogic.AMMVariables memory ammState;
        AMMPerpLogic.MarketVariables memory marketState;

        (ammState, marketState) = _prepareAMMAndMarketData(_perpetual);
        // get mid-price premium
        int128[2] memory spreads;
        // mid price has no minimal spread, spread[0] = 0
        spreads[1] = _perpetual.fIncentiveSpread;
        // mid-price parameter obtained using amount k=0
        int128 px_premium = _getAMMPerpLogic().calculatePerpetualPrice(ammState, marketState, 0, spreads);
        px_premium = px_premium.sub(marketState.fIndexPriceS2);
        _perpetual.currentPremium.fPrice = px_premium;
        _perpetual.currentPremium.time = _iCurrentTimeSec;
    }

    /**
     * Prepare data for pricing functions (AMMPerpModule)
     * @param   _perpetual    The reference of perpetual storage.
     */
    function _prepareAMMAndMarketData(PerpetualData memory _perpetual)
        internal
        view
        returns (AMMPerpLogic.AMMVariables memory, AMMPerpLogic.MarketVariables memory)
    {
        // prepare data
        AMMPerpLogic.AMMVariables memory ammState;
        AMMPerpLogic.MarketVariables memory marketState;

        marketState.fIndexPriceS2 = _perpetual.indexS2PriceData.fPrice;
        marketState.fSigma2 = _perpetual.fSigma2;

        require(marketState.fIndexPriceS2 > 0, "Index price S2 must be positive");

        MarginAccount memory AMMMarginAcc = marginAccounts[_perpetual.id][address(this)];
        // get current locked-in value
        ammState.fLockedValue1 = AMMMarginAcc.fLockedInValueQC.neg();

        // get current position of all traders (= - AMM position)
        ammState.fAMM_K2 = AMMMarginAcc.fPositionBC.neg();

        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            ammState.fPoolM2 = _perpetual.fAMMFundCashCC;
        } else if (ccy == AMMPerpLogic.CollateralCurrency.QUANTO) {
            ammState.fPoolM3 = _perpetual.fAMMFundCashCC;
            // additional parameters for quanto case
            marketState.fIndexPriceS3 = _perpetual.indexS3PriceData.fPrice;
            marketState.fSigma3 = _perpetual.fSigma3;
            marketState.fRho23 = _perpetual.fRho23;
            require(marketState.fIndexPriceS3 > 0, "Index price S3 must be positive");
        } else {
            assert(ccy == AMMPerpLogic.CollateralCurrency.QUOTE);
            ammState.fPoolM1 = _perpetual.fAMMFundCashCC;
        }
        return (ammState, marketState);
    }

    function _getAMMPerpLogic() internal view returns (IAMMPerpLogic) {
        return IAMMPerpLogic(address(ammPerpLogic));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./PerpetualBaseFunctions.sol";
import "../interfaces/IPerpetualTradeLogic.sol";
import "../interfaces/IPerpetualUpdateLogic.sol";

contract PerpetualRebalanceFunctions is PerpetualBaseFunctions {
    using ABDKMath64x64 for int128;
    int128 private constant TWO_64x64 = 0x020000000000000000;//2
    
    modifier updateFundingAndPrices(uint256 _iPoolIdx) {
        _getUpdateLogic().updateFundingAndPricesBefore(_iPoolIdx);
        _;
        _getUpdateLogic().updateFundingAndPricesAfter(_iPoolIdx);
    }

    /**
     * @dev     To re-balance the AMM margin to the initial margin.
     *          Transfer margin between the perpetual and the various cash pools, then
     *          update the AMM's cash in perpetual margin account.
     *
     * @param   _perpetual The perpetual in the liquidity pool
     */
    function _rebalance(PerpetualData storage _perpetual) internal {
        if (_perpetual.state != PerpetualState.NORMAL) {
            return;
        }
        _equalizeAMMMargin(_perpetual);
        // updating the mark price changes the markprice that is
        // used for margin calculation and hence the AMM initial 
        // margin will not be exactly at initial margin rate
        _updateMarkPrice(_perpetual, block.timestamp);

        // update trade size that minimizes AMM risk
        _updateKStar(_perpetual);
    }

    function _equalizeAMMMargin(PerpetualData storage _perpetual) internal {
        int128 rebalanceMargin = _getRebalanceMargin(_perpetual);
        if (rebalanceMargin == 0) {
            // nothing to rebalance
            return;
        } else if (rebalanceMargin > 0) {
            // from margin to pool
            _transferFromAMMMarginToPool(_perpetual, rebalanceMargin);
        } else {
            // from pool to margin
            // It's possible that there are not enough funds to draw from
            // in this case not the full margin will be replenished 
            // (and emergency state is raised)
            
            int128 init = _getInitialMargin(_perpetual, address(this));
            int128 bal  = _getMarginBalance(_perpetual, address(this));
            rebalanceMargin = _getRebalanceMargin(_perpetual);  
            
            _transferFromPoolToAMMMargin(_perpetual, rebalanceMargin.neg());
        }
    }

     /**
     * Calculate fkStarSide = sign(-k*), which indicates whether traders should trade short
     * (fkStarSide>0) to decrease the AMM risk or long.
     * The function numerically determines sign(-kStar)
     * @param _perpetual  The reference of perpetual storage.
     * @return sign(-kStar)
     */
    function _calcKStarSide(PerpetualData memory _perpetual) internal view returns (int128) {
        int128 TWENTY_64x64 = 0x140000000000000000; //20*2^64
        AMMPerpLogic.AMMVariables memory ammState;
        AMMPerpLogic.MarketVariables memory marketState;
        (ammState, marketState) = _prepareAMMAndMarketData(_perpetual);
        int128 fDD0;
        int128 fDD1;
        int128 fDelta = 0xa7c5ac471b47; //0.00001
        (,fDD0) = _getAMMPerpLogic().calculateRiskNeutralPD(ammState, marketState, 0, false);
                 
        if (fDD0==TWENTY_64x64) {
            // already in default state and DD1 is equal to DD0. We determine the side
            // of k-star by K 
            return ammState.fAMM_K2 > 0 ? ONE_64x64 : ONE_64x64.neg();
        } else if (fDD0==TWENTY_64x64.neg()) {
            // we are in an area where the default probability is 0, the sign is set positive
            return ONE_64x64;
        } else {
            (,fDD1) = _getAMMPerpLogic().calculateRiskNeutralPD(ammState, marketState, fDelta, false);
            return (fDD1 >= fDD0) ? ONE_64x64 : ONE_64x64.neg();
        }
    }

    /**
     * Update k*, the trade that would minimize the AMM risk.
     * Also updates fkStarSide = sign(-k*)
     * Set 0 in quanto case.
     * @param _perpetual  The reference of perpetual storage.
     */
    function _updateKStar(PerpetualData storage _perpetual) internal {
        
        int128 m2;
        int128 m1;
        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            m2 = _perpetual.fAMMFundCashCC;
            m1 = 0;
        } else if (ccy == AMMPerpLogic.CollateralCurrency.QUOTE) {
            m1 = _perpetual.fAMMFundCashCC;
            m2 = 0;
        } else {
            // quanto
            _perpetual.fkStarSide = _calcKStarSide(_perpetual);
            _perpetual.fkStar = 0;
            return;
        }

        MarginAccount memory AMMMarginAcc = marginAccounts[_perpetual.id][address(this)];
        int128 L1 = AMMMarginAcc.fLockedInValueQC.neg();
        int128 K2 = AMMMarginAcc.fPositionBC.neg();
        int128 s2 = _perpetual.indexS2PriceData.fPrice;
        int128 u = L1.neg().sub(m1).div(s2);
        int128 v = K2.sub(m2);
        _perpetual.fkStar = (u.sub(v)).div(TWO_64x64);
        _perpetual.fkStarSide = ONE_64x64;
        if (_perpetual.fkStar > 0) {
            _perpetual.fkStarSide = ONE_64x64.neg();
        }
    }

    /**
     * Get the margin to rebalance the AMM in the perpetual.
     * Margin to rebalance = margin - initial margin
     * @param   _perpetual The perpetual in the liquidity pool
     * @return  The margin to rebalance in the perpetual
     */
    function _getRebalanceMargin(PerpetualData memory _perpetual) internal view returns (int128) {
        int128 fInitialMargin = _getInitialMargin(_perpetual, address(this));
        return _getMarginBalance(_perpetual, address(this)).sub(fInitialMargin);
    }

    /**
     * Transfer a given amount from the AMM margin account to the
     * liq pools (AMM pool, participation fund).
     * @param   _perpetual   The reference of perpetual storage.
     * @param   _fAmount            signed 64.64-bit fixed point number.
     */
    function _transferFromAMMMarginToPool(PerpetualData storage _perpetual, int128 _fAmount) internal {
        if (_fAmount == 0) {
            return;
        }
        require(_fAmount > 0, "transferFromAMMMarginToPool expects positive amount");
        LiquidityPoolData storage pool = liquidityPools[_perpetual.poolId];
        // update margin of AMM
        _updateTraderMargin(_perpetual, address(this), _fAmount.neg());

        int128 fPnLparticipantAmount;
        int128 fAmmAmount;
        (fPnLparticipantAmount, fAmmAmount) = _splitAmount(pool, _fAmount, false);
        _increasePoolCash(pool, fPnLparticipantAmount);
        _increaseAMMFundCashForPerpetual(_perpetual, fAmmAmount);
    }

    /**
     * Transfer a given amount from the liquidity pools (AMM+PnLparticipant) into the AMM margin account.
     * Margin to rebalance = margin - initial margin
     * @param   _perpetual   The reference of perpetual storage.
     * @param   _fAmount     Amount to transfer. Signed 64.64-bit fixed point number.
     * @return  The amount that could be drawn from the pools.
     */
    function _transferFromPoolToAMMMargin(PerpetualData storage _perpetual, int128 _fAmount) internal returns (int128) {
        if (_fAmount == 0) {
            return 0;
        }
        require(_perpetual.fAMMFundCashCC >0 || _perpetual.state!=PerpetualState.NORMAL,
            "perpetual state cannot be normal with 0 AMM Pool Cash");
        require(_fAmount > 0, "transferFromPoolToAMM expects positive amount");
        LiquidityPoolData storage pool = liquidityPools[_perpetual.poolId];
        int128 fMaxAmount = pool.fPnLparticipantsCashCC.add(pool.fAMMFundCashCC);
        int128 fAmountFromDefFund;
        if (_fAmount > fMaxAmount) {
            // not enough cash in the liquidity pools
            // draw from default fund
            fAmountFromDefFund = _fAmount.sub(fMaxAmount);
            _fAmount = fMaxAmount;
            if (fAmountFromDefFund > pool.fDefaultFundCashCC) {
                // not enough cash in default fund
                // margin cannot be replenished fully
                fAmountFromDefFund = pool.fDefaultFundCashCC;
                // emergency state for the whole liquidity pool
                _setLiqPoolEmergencyState(pool);
            }
            _decreaseDefaultFundCash(pool, fAmountFromDefFund);
        }

        int128 fPnLparticipantAmount;
        int128 fAmmAmount;
        // split amount (takes care if not enough funds in one of the pots, total must be<=sum of funds)
        (fPnLparticipantAmount, fAmmAmount) = _splitAmount(pool, _fAmount, true);
        
        if (fAmmAmount == pool.fAMMFundCashCC) {
            // AMM is empty now, trigger emergency state for this perpetual
            _setEmergencyState(_perpetual);
        }
        _decreaseAMMFundCashForPerpetual(_perpetual, fAmmAmount);
        
        _decreasePoolCash(pool, fPnLparticipantAmount);

        // update margin
        int128 fFeasibleMargin = _fAmount.add(fAmountFromDefFund);
        _updateTraderMargin(_perpetual, address(this), fFeasibleMargin);
        return fFeasibleMargin;
    }

    /**
     * Split amount in relation to pool sizes.
     * If withdrawing and ratio cannot be met, funds are withdrawn from the other pool.
     * Precondition: (_fAmount<PnLparticipantCash+ammcash)|| !_isWithdrawn
     * @param   _liquidityPool    reference to liquidity pool
     * @param   _fAmount          Signed 64.64-bit fixed point number. The amount to be split
     * @param   _isWithdrawn      If true, the function re-distributes the amounts so that the pool
     *                            funds remain non-negative.
     * @return  Signed 64.64-bit fixed point number x 2. Amounts for PnL participants and AMM
     */
    function _splitAmount(
        LiquidityPoolData storage _liquidityPool,
        int128 _fAmount,
        bool _isWithdrawn
    ) internal view returns (int128, int128) {
        int128 fAvailCash = _liquidityPool.fPnLparticipantsCashCC.add(_liquidityPool.fAMMFundCashCC);
        require(_fAmount > 0, "positive amount expected");
        require(!_isWithdrawn || fAvailCash >= _fAmount, "pre-condition not met");
        int128 fWeightPnLparticipants = _liquidityPool.fPnLparticipantsCashCC.div(fAvailCash);
        // ceiling for PnL participant share of PnL
        if (fWeightPnLparticipants > CEIL_PNL_SHARE) {
            fWeightPnLparticipants = CEIL_PNL_SHARE;
        }
        int128 fAmountPnLparticipants = fWeightPnLparticipants.mul(_fAmount);
        int128 fAmountAMM = _fAmount.sub(fAmountPnLparticipants);

        // ensure we have have non-negative funds when withdrawing
        // re-distribute otherwise
        if (_isWithdrawn) {
            int128 fSpillover = _liquidityPool.fPnLparticipantsCashCC.sub(fAmountPnLparticipants);
            if (fSpillover < 0) {
                fSpillover = fSpillover.neg();
                fAmountPnLparticipants = fAmountPnLparticipants.sub(fSpillover);
                fAmountAMM = fAmountAMM.add(fSpillover);
            }
            fSpillover = _liquidityPool.fAMMFundCashCC.sub(fAmountAMM);
            if (fSpillover < 0) {
                fSpillover = fSpillover.neg();
                fAmountAMM = fAmountAMM.sub(fSpillover);
                fAmountPnLparticipants = fAmountPnLparticipants.add(fSpillover);
            }
        }

        return (fAmountPnLparticipants, fAmountAMM);
    }

    /**
     * Increase the participation fund's cash(collateral).
     * @param   _liquidityPool reference to liquidity pool data
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to increase.
     */
    function _increasePoolCash(LiquidityPoolData storage _liquidityPool, int128 _fAmount) internal {
        require(_fAmount >= 0, "increase negative pool cash");
        _liquidityPool.fPnLparticipantsCashCC = _liquidityPool.fPnLparticipantsCashCC.add(_fAmount);

        emit UpdateParticipationFundCash(_liquidityPool.id, 
            _fAmount,
            _liquidityPool.fPnLparticipantsCashCC,
            block.timestamp);
    }

    /**
     * Decrease the participation fund pool's cash(collateral).
     * @param   _liquidityPool reference to liquidity pool data
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to decrease.
     *                       Will not decrease to negative
     */
    function _decreasePoolCash(LiquidityPoolData storage _liquidityPool, int128 _fAmount) internal {
        require(_fAmount >= 0, "decrease negative pool cash");
        _liquidityPool.fPnLparticipantsCashCC = _liquidityPool.fPnLparticipantsCashCC.sub(_fAmount);
        require(_liquidityPool.fPnLparticipantsCashCC >= 0, "participation fund cash should not be negative");

        emit UpdateParticipationFundCash(_liquidityPool.id, 
            _fAmount.neg(), 
            _liquidityPool.fPnLparticipantsCashCC,
            block.timestamp);
    }

    /**
     * Increase the AMM's cash(collateral).
     * The perpetuals cash and the total liquidity pool AMM cash needs to be updated
     * @param   _perpetual  PerpetualData struct
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to decrease.
     *                       Will not decrease total AMM liq pool to negative
     */
    function _increaseAMMFundCashForPerpetual(PerpetualData storage _perpetual, int128 _fAmount) internal {
        require(_fAmount >= 0, "increase negative pool cash");
        LiquidityPoolData storage liqPool = liquidityPools[_perpetual.poolId];
        require(liqPool.fTargetAMMFundSize > 0, "AMM target size must be larger than zero");
        require(liqPool.fTargetDFSize > 0, "Default fund target size must be larger than zero");
        
        int128 fDefaultFundContribution = liqPool.fAMMFundCashCC.add(_fAmount).sub(liqPool.fTargetAMMFundSize);
        if ( (fDefaultFundContribution > 0) ||
             (fDefaultFundContribution < 0 && liqPool.fDefaultFundCashCC > liqPool.fTargetDFSize) )
        {
            // case 1: AMM reached target size (fDefaultFundContribution>0), send 
            //         excess AMM amount (=fDefaultFundContribution) to default fund (regardless of 
            //         whether the default fund already reached target size or not)
            // case 2: AMM below target size (fDefaultFundContribution<0) and default fund is overfunded
            //         Withdraw (scaled) missing amount (=|fDefaultFundContribution|) from default fund
            //         
            if (fDefaultFundContribution < 0) {
                // do not withdraw all the missing amount from the default fund, just a portion
                // so AMM fund slowly moves towards target size
                fDefaultFundContribution = fDefaultFundContribution.mul(DF_TO_AMM_FUND_WITHDRAWAL_SHARE);
            }
            liqPool.fDefaultFundCashCC = liqPool.fDefaultFundCashCC.add(fDefaultFundContribution);
            emit UpdateDefaultFundCash(liqPool.id, 
                fDefaultFundContribution, 
                liqPool.fDefaultFundCashCC, 
                block.timestamp);
            // we decrease the amount by that is sent to the default fund/or if fDefaultFundContribution<0
            // we add this amount from default fund
            _fAmount = _fAmount.sub(fDefaultFundContribution);
        }
        // adjust perpetual's individual pool cash
        _perpetual.fAMMFundCashCC = _perpetual.fAMMFundCashCC.add(_fAmount);
        // adjust total pool amount
        liqPool.fAMMFundCashCC = liqPool.fAMMFundCashCC.add(_fAmount);
        require(liqPool.fAMMFundCashCC > 0, "AMM Cash negative, error in calculation");

        emit UpdateAMMFundCash(_perpetual.id, 
            _perpetual.fAMMFundCashCC, 
            liqPool.fAMMFundCashCC, 
            block.timestamp);
    }

    /**
     * Decrease the AMM's fund cash (not the margin).
     * The perpetuals cash and the total liquidity pool cash needs to be updated
     * @param   _perpetual  PerpetualData struct
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to increase.
     */
    function _decreaseAMMFundCashForPerpetual(PerpetualData storage _perpetual, int128 _fAmount) internal {
        require(_fAmount >= 0, "decrease negative pool cash");

        // adjust total pool amount
        liquidityPools[_perpetual.poolId].fAMMFundCashCC = (liquidityPools[_perpetual.poolId].fAMMFundCashCC).sub(_fAmount);
        // adjust perpetual's individual pool
        _perpetual.fAMMFundCashCC = _perpetual.fAMMFundCashCC.sub(_fAmount);
        emit UpdateAMMFundCash(_perpetual.id, 
            _perpetual.fAMMFundCashCC.neg(), 
            liquidityPools[_perpetual.poolId].fAMMFundCashCC, 
            block.timestamp);
    }

    /**
     * @dev     Decrease default fund cash
     * @param   _liquidityPool reference to liquidity pool data
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to decrease.
     */
    function _decreaseDefaultFundCash(LiquidityPoolData storage _liquidityPool, int128 _fAmount) internal {
        require(_fAmount >= 0, "decrease negative pool cash");
        _liquidityPool.fDefaultFundCashCC = _liquidityPool.fDefaultFundCashCC.sub(_fAmount);
        require(_liquidityPool.fDefaultFundCashCC>=0, "default fund cash cannot be negative");
        emit UpdateDefaultFundCash(_liquidityPool.id, 
            _fAmount.neg(), 
            _liquidityPool.fDefaultFundCashCC, 
            block.timestamp);
    }

    /**
     * Loop through perpetuals of the liquidity pool and set
     * to emergency state
     * @param _liqPool reference to liquidity pool
     */
    function _setLiqPoolEmergencyState(LiquidityPoolData storage _liqPool) internal {
        uint256 length = _liqPool.iPerpetualCount;
        for (uint256 i = 0; i < length; i++) {
            bytes32 idx = perpetualIds[_liqPool.id][i];
            PerpetualData storage perpetual = perpetuals[_liqPool.id][idx];
            if (perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            _setEmergencyState(perpetual);
        }
    }

    /**
     * Set the state of the perpetual to "EMERGENCY". Must rebalance first.
     * After that the perpetual is not allowed to trade, deposit and withdraw.
     * The price of the perpetual is freezed to the settlement price
     * @param   _perpetual  reference to perpetual
     */
    function _setEmergencyState(PerpetualData storage _perpetual) internal {
        if (_perpetual.state == PerpetualState.EMERGENCY) {
            // done
            return;
        }

        require(_perpetual.state == PerpetualState.NORMAL, "perpetual should be in NORMAL state");
        // use mark price as final price when emergency
        _perpetual.settlementPremiumEMA = _perpetual.currentPremiumEMA;
        _perpetual.settlementS2PriceData = _perpetual.indexS2PriceData;
        _perpetual.settlementS3PriceData = _perpetual.indexS3PriceData;
        _perpetual.state = PerpetualState.EMERGENCY;
        emit SetEmergencyState(
            _perpetual.id,
            _perpetual.settlementPremiumEMA.fPrice,
            _perpetual.settlementS2PriceData.fPrice,
            _perpetual.settlementS3PriceData.fPrice,
            _perpetual.settlementPremiumEMA.time
        );
    }

    /**
     * @dev     Check if the trader has opened position in the trade.
     *          Example: 2, 1 => true; 2, -1 => false; -2, -3 => true
     * @param   _fNewPos    The position of the trader after the trade
     * @param   fDeltaPos   The size of the trade
     * @return  True if the trader has opened position in the trade
     */
    function _hasOpenedPosition(int128 _fNewPos, int128 fDeltaPos) internal pure returns (bool) {
        if (_fNewPos == 0) {
            return false;
        }
        return _hasTheSameSign(_fNewPos, fDeltaPos);
    }

    /*
     * Check if two numbers have the same sign. Zero has the same sign with any number
     * @param   _fX 64.64 fixed point number
     * @param   _fY 64.64 fixed point number
     * @return  True if the numbers have the same sign or one of them is zero.
     */
    function _hasTheSameSign(int128 _fX, int128 _fY) internal pure returns (bool) {
        if (_fX == 0 || _fY == 0) {
            return true;
        }
        return (_fX ^ _fY) >> 127 == 0;
    }

    /**
     * Check if Trader is maintenance margin safe in the perpetual,
     * need to rebalance before checking.
     * @param   _perpetual   Reference to the perpetual
     * @param   _traderAddr  The address of the trader
     * @param   _hasOpened   True if the trader opens, false if they close
     * @return  True if Trader is maintenance margin safe in the perpetual.
     */
    function _isTraderMarginSafe(
        PerpetualData storage _perpetual,
        address _traderAddr,
        bool _hasOpened
    ) internal view returns (bool) {
        return _hasOpened ? _isInitialMarginSafe(_perpetual, _traderAddr) : _isMarginSafe(_perpetual, _traderAddr);
    }

    /**
     * Check if the trader's margin safe in the perpetual, which means margin >= 0 or position=0
     * @param   _perpetual The perpetual object
     * @param   _traderAddr The address of the trader
     * @return  True if the trader is initial margin safe in the perpetual
     */
    function _isMarginSafe(PerpetualData storage _perpetual, address _traderAddr) internal view returns (bool) {
        if (_getTraderPosition(_perpetual, _traderAddr) == 0) {
            return true;
        }
        return _getMarginBalance(_perpetual, _traderAddr) >= 0;
    }

    function _getTradeLogic() internal view returns (IPerpetualTradeLogic) {
        return IPerpetualTradeLogic(address(this));
    }

    function _getUpdateLogic() internal view returns (IPerpetualUpdateLogic) {
        return IPerpetualUpdateLogic(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "../functions/AMMPerpLogic.sol";
pragma experimental ABIEncoderV2;

interface IAMMPerpLogic {
    function ema(
        int128 _fEMA,
        int128 _fCurrentObs,
        int128 _fLambda
    ) external pure returns (int128);

    function calculateDefaultFundSize(
        int128[2] memory _fK2AMM,
        int128 _fk2Trader,
        int128 _fCoverN,
        int128[2] memory fStressRet2,
        int128[2] memory fStressRet3,
        int128[2] memory fIndexPrices,
        AMMPerpLogic.CollateralCurrency _eCCY
    ) external pure returns (int128);

    function calculateRiskNeutralPD(AMMPerpLogic.AMMVariables memory _ammVars, 
        AMMPerpLogic.MarketVariables memory _mktVars, int128 _fTradeAmount, bool _withCDF)
        external
        view
        virtual
        returns (int128, int128);

    function calculatePerpetualPrice(
        AMMPerpLogic.AMMVariables memory _ammVars,
        AMMPerpLogic.MarketVariables memory _mktVars,
        int128 _fTradeAmount,
        int128[2] memory _fSpreads
    ) external view returns (int128);

    function getTargetCollateralM1(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);

    function getTargetCollateralM2(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);

    function getTargetCollateralM3(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables memory _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IFunctionList {
    function getFunctionList() external view returns (bytes4[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IPerpetualSettlement {
    function settleNextTraderInPool(uint256 _id) external returns (bool);

    function settle(bytes32 _perpetualID, address _traderAddr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IPerpetualTradeLogic {
    function executeTrade(
        bytes32 _iPerpetualId,
        address _traderAddr,
        int128 _fTraderPos,
        int128 _fTradeAmount,
        int128 _fDeltaLockedValue,
        bool _isClose
    ) external returns (int128);

    function preTrade(
        bytes32 _iPerpetualId,
        address _traderAddr,
        int128 _fAmount,
        int128 _fLimitPrice,
        uint32 _flags
    ) external returns (int128, int128);

    function distributeFees(
        bytes32 _iPerpetualId,
        address _traderAddr,
        address _referrerAddr,
        int128 _fDeltaPositionCC,
        bool _hasOpened
    ) external returns (int256 lpFee, int256 totalFee);

    function getMaxTradeSizesForPos(int128 _fCurrentTraderPos, int128 _fkStar, int128 _fTraderExposureEMA, int128 _fBumpUp)
        external view returns (int128, int128);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IPerpetualUpdateLogic {
    function updateAMMTargetPoolSize(bytes32 _iPerpetualId) external;

    function updateFundingAndPricesBefore(uint256 _iPoolIdx) external;

    function updateFundingAndPricesAfter(uint256 _iPoolIdx) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

/**
 * @notice  The libraryEvents defines events that will be raised from modules (contract/modules).
 * @dev     DO REMEMBER to add new events in modules here.
 */
interface ISOVLibraryEvents {
    // PerpetualModule
    event Clear(bytes32 perpetualIndex, address indexed trader);
    event Settle(bytes32 perpetualIndex, address indexed trader, int256 amount);
    event SetNormalState(bytes32 perpetualIndex);
    event SetEmergencyState(bytes32 perpetualIndex, int128 fSettlementPremiumEMA, int128 fSettlementS2Price, int128 fSettlementS3Price, uint256 iTimestamp);
    event SetClearedState(bytes32 perpetualIndex);
    event UpdateUnitAccumulatedFunding(bytes32 perpetualId, int128 unitAccumulativeFunding);

    // Participation pool
    event LiquidityAdded(uint256 indexed poolId, address indexed user, uint256 tokenAmount, uint256 shareAmount);
    event LiquidityRemoved(uint256 indexed poolId, address indexed user, uint256 tokenAmount, uint256 shareAmount);

    // events with no home
    event TransferTreasuryTo(address indexed newTreasury);
    event SetPerpetualBaseParameter(uint256 perpetualIndex, int256[9] baseParams);
    event SetPerpetualRiskParameter(uint256 perpetualIndex, int256[8] riskParams, int256[8] minRiskParamValues, int256[8] maxRiskParamValues);
    event UpdatePerpetualRiskParameter(uint256 perpetualIndex, int256[8] riskParams);
    event SetOracle(address indexed oldOralce, address indexed newOracle);

    // funds
    event UpdateAMMFundCash(bytes32 indexed perpetualIndex, int128 fNewAMMFundCash, int128 fNewLiqPoolTotalAMMFundsCash, uint256 blockTimestamp);
    event UpdateParticipationFundCash(uint256 indexed poolId, int128 fDeltaAmountCC, int128 fNewFundCash, uint256 blockTimestamp);
    event UpdateDefaultFundCash(uint256 indexed poolId, int128 fDeltaAmountCC, int128 fNewFundCash, uint256 blockTimestamp);

    // TradeModule
    event Trade(bytes32 perpetualId, 
        address indexed trader,
        uint32 orderFlags,
        int128 tradeAmount, 
        int128 price, 
        uint256 blockTimestamp);

    event UpdateMarginAccount(
            bytes32 indexed perpetualId,
            address indexed trader,
            int128 fPositionBC,
            int128 fCashCC,
            int128 fLockedInValueQC,
            int128 fFundingPaymentCC,
            int128 fOpenInterestBC,
            uint256 blockTimestamp);

    event Liquidate(
        bytes32 perpetualId,
        address indexed liquidator,
        address indexed trader,
        int128 amount,
        uint256 blockTimestamp
    );
    event TransferFeeToTreasury(address indexed treasuryAddress, int256 treasuryFee);
    event TransferFeeToReferrer(bytes32 indexed perpetualIndex, address indexed trader, address indexed referrer, int256 referralRebate);

    // PerpetualManager/factory
    event RunLiquidityPool(uint256 _liqPoolID);
    event LiquidityPoolCreated(
        uint256 id,
        address treasuryAddress,
        address marginTokenAddress,
        address shareTokenAddress,
        uint256 iTargetPoolSizeUpdateTime,
        uint256 iPnLparticipantWithdrawalPeriod,
        int128 fPnLparticipantWithdrawalPercentageLimit,
        int128 fPnLparticipantWithdrawalMinAmountLimit
    );
    event PerpetualCreated(
        uint256 poolId,
        bytes32 id,
        address[2] oracles,
        int128[11] baseParams,
        int128[5] underlyingRiskParams,
        int128[12] defaultFundRiskParams,
        uint256 eCollateralCurrency
    );
    
    event TokensDeposited(bytes32 indexed perpetualId, address indexed trader, int128 amount, uint256 blockTimestamp);
    event TokensWithdrawn(bytes32 indexed perpetualId, address indexed trader, int128 amount, uint256 blockTimestamp);

    event UpdatePrice(
        bytes32 indexed perpetualId,
        address indexed oracleS2Addr,
        address indexed oracleS3Addr,
        int128 spotPriceS2,
        uint256 timePriceS2,
        int128 spotPriceS3,
        uint256 timePriceS3
    );

    event UpdateMarkPrice(
        bytes32 indexed perpetualId,
        int128 fMarkPricePremium,
        int128 fSpotIndexPrice,
        uint256 blockTimestamp
    );
    
    event UpdateFundingRate(
        bytes32 indexed perpetualId,
        int128 fFundingRate,
        uint256 blockTimestamp
    );

    event UpdateAMMFundTargetSize(
        bytes32 indexed perpetualId, 
        int128 fTargetAMMFundSize, 
        uint256 blockTimestamp
    );

    event UpdateDefaultFundTargetSize(
        uint256 indexed liquidityPoolId, 
        int128 fTargetDFSize, 
        uint256 blockTimestamp
    );

    event UpdateReprTradeSizes(
         bytes32 indexed perpetualId, 
         int128 fCurrentTraderExposureEMA, 
         int128 fCurrentAMMExposureEMAShort,
         int128 fCurrentAMMExposureEMALong,
         uint256 blockTimestamp);

    event RemoveAmmGovernanceAddress(address indexed gAddress);
    event AddAmmGovernanceAddress(address indexed gAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../functions/PerpetualRebalanceFunctions.sol";
import "../interfaces/IPerpetualSettlement.sol";
import "../interfaces/IFunctionList.sol";

/*
    This contract contains 2 main functions: settleNextTraderInPool and settle:
        If the perpetual pool moves into emergency mode, governance (or anyone)
        calls settleNextTraderInPool until every trader is processed. This will sum up
        the available margin of open positions.
        Once all traders are processed, settleNextTraderInPool calls _setRedemptionRate
        which determines how much from the PnL the trader receives back. Usually all of it,
        but in case there is not enough capital in the pool, the loss is shared.
        setRedemption rate sets the perpetual status to cleared.
    settle:
        Once settleNextTraderInPool is finished (all Emergency-perpetuals in CLEARED state),
        traders or governance can call 'settle' to pay the trader the amount owed.
*/

contract PerpetualSettlement is PerpetualRebalanceFunctions, IFunctionList, IPerpetualSettlement {
    using ABDKMath64x64 for int128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 internal constant PRIVILEGE_WITHDRAW = 0x2;

    /**
     * @notice  Settle next active accounts in the perpetuals that are in emergency state.
     *          If all active accounts are cleared for all emergency perpetuals in the pool,
     *          the clear process is done and the perpetual state
     *          changes to "CLEARED". Active means the trader's account has a position.
     *
     * @param   _id  The index of the liquidity pool.
     */
    function settleNextTraderInPool(uint256 _id) external override nonReentrant returns (bool) {
        LiquidityPoolData storage liquidityPool = liquidityPools[_id];
        uint256 length = liquidityPool.iPerpetualCount;
        int128 fTotalTraderMarginBalance; //sum of trader margin in each perpetual, in collateral currency
        int128 fTotalEmrgAMMMarginBalance; //in collateral currency
        int128 fTotalEmrgAMMFundCashCC; // AMM fund cash of all AMMs that are in emergency mode
        bool isAllCleared = true;
        uint256 iEmergencyCount;
        for (uint256 i = 0; i < length; i++) {
            bytes32 idx = perpetualIds[liquidityPool.id][i];
            PerpetualData storage perpetual = perpetuals[liquidityPool.id][idx];
            if (perpetual.state == PerpetualState.EMERGENCY) {
                isAllCleared = isAllCleared && _clearNextTraderInPerpetual(perpetual);
                fTotalTraderMarginBalance = fTotalTraderMarginBalance.add(perpetual.fTotalMarginBalance);
                fTotalEmrgAMMMarginBalance = fTotalEmrgAMMMarginBalance.add(_getMarginBalance(perpetual, address(this)));
                fTotalEmrgAMMFundCashCC = fTotalEmrgAMMFundCashCC.add(perpetual.fAMMFundCashCC);
                iEmergencyCount = iEmergencyCount + 1;
            }
        }

        // if all trades cleared
        if (isAllCleared) {
            //Total capital of pools to be settled (=AMM margin and AMM pool cash) and the
            // liquidity pool PnL participant cash + default fund cash
            int128 fTotalCapitalCC = liquidityPool.fPnLparticipantsCashCC.add(liquidityPool.fDefaultFundCashCC);
            fTotalCapitalCC = fTotalCapitalCC.add(fTotalEmrgAMMMarginBalance).add(fTotalEmrgAMMFundCashCC);
            // ready to set redemption rate and mark perpetuals as cleared
            // the redemption rate ensures that the trader margin payments does not exceed fTotalCapitalCC
            _setRedemptionRate(liquidityPool, fTotalTraderMarginBalance, fTotalCapitalCC);

            int128 widthdrawFromParticipationFund;
            int128 widthdrawFromDF; // can be negative (adding)
            (widthdrawFromParticipationFund, widthdrawFromDF) = _prepareRedemption(
                liquidityPool,
                fTotalTraderMarginBalance,
                fTotalEmrgAMMMarginBalance,
                fTotalEmrgAMMFundCashCC
            );
            liquidityPool.fDefaultFundCashCC = liquidityPool.fDefaultFundCashCC.sub(widthdrawFromDF);
            liquidityPool.fPnLparticipantsCashCC = liquidityPool.fPnLparticipantsCashCC.sub(widthdrawFromParticipationFund);
        }
        return isAllCleared;
    }

    /**
     * @notice  Calculates the amount of funds left after each trader is settled.
     *          The remaining funds (perpetual AMM margin+AMM fund), if any, are credited to the default fund
     *          (belongs to the liquidity pool).
     *          If no funds left, they are drawn from the participation fund and default fund.
     *
     * @param   _liquidityPool                  Liquidity pool
     * @param   _fTotalTraderMarginBalance      Total trader margin balance in all emergency-state pools
     * @param   _fTotalEmrgAMMMarginBalance     Total AMM margin balance for all emergency-state pools
     * @param   _fTotalEmrgAMMFundCashCC        Total AMM fund cash for all emergency-state perpetuals
     */
    function _prepareRedemption(
        LiquidityPoolData memory _liquidityPool,
        int128 _fTotalTraderMarginBalance,
        int128 _fTotalEmrgAMMMarginBalance,
        int128 _fTotalEmrgAMMFundCashCC
    ) internal pure returns (int128, int128) {
        // correct the amm margin, amm cash, default fund, liquidity provider pool,
        // so that no funds are locked.
        // 1) AMM pool cash is already subtracted in _setRedemptionRate. So we add it back to the default fund
        //    together with the AMM margin, if anything left
        // 2) We correct the LiqPool default fund and participation fund, by subtracting amounts needed
        int128 _fTotalTraderMarginBalanceToPay = _fTotalTraderMarginBalance.mul(_liquidityPool.fRedemptionRate);

        int128 widthdrawFromDF = _fTotalTraderMarginBalanceToPay.sub(_fTotalEmrgAMMMarginBalance).sub(_fTotalEmrgAMMFundCashCC);
        int128 widthdrawFromParticipationFund;
        // if widthdrawFromDF<0, we will credit that to the default fund,
        // otherwise tap default fund/Liquidity Provider Pool to withdraw from
        if (widthdrawFromDF > 0) {
            // AMM margin and AMM pool is not sufficient to cover the trader gains
            // draw liq pool and then default fund
            widthdrawFromParticipationFund = widthdrawFromDF;
            widthdrawFromDF = 0;
            if (widthdrawFromParticipationFund > _liquidityPool.fPnLparticipantsCashCC) {
                widthdrawFromDF = widthdrawFromParticipationFund.sub(_liquidityPool.fPnLparticipantsCashCC);
                widthdrawFromParticipationFund = _liquidityPool.fPnLparticipantsCashCC;
                require(widthdrawFromDF >= 0, "error in redemption rate calculation");
            }
        }
        return (widthdrawFromParticipationFund, widthdrawFromDF);
    }

    /**
     * @notice  Settle next active accounts in a perpetual that is in emergency state.
     *          If all active accounts are cleared, the clear progress is done.
     *          Active means the trader's account is not empty in the perpetual.
     *          Empty means cash and position are zero
     *
     * @param   _perpetual  Reference to perpetual
     * @return  true if last trader was cleared
     */
    function _clearNextTraderInPerpetual(PerpetualData storage _perpetual) internal returns (bool) {
        require(_perpetual.state == PerpetualState.EMERGENCY, "perpetual must be in EMERGENCY state");
        return (activeAccounts[_perpetual.id].length() == 0 || _clearTrader(_perpetual, _getNextActiveAccount(_perpetual)));
    }

    /**
     * @notice  clear the given trader, that is, add their margin
     *          to total margin, remove trader from active accounts
     *
     * @param   _perpetual  Reference to perpetual
     * @return  true if last trader was cleared
     */
    function _clearTrader(PerpetualData storage _perpetual, address _traderAddr) internal returns (bool) {
        require(activeAccounts[_perpetual.id].length() > 0, "no account to clear");
        require(activeAccounts[_perpetual.id].contains(_traderAddr), "account cannot be cleared or already cleared");
        _countMargin(_perpetual, _traderAddr);
        activeAccounts[_perpetual.id].remove(_traderAddr);
        emit Clear(_perpetual.id, _traderAddr);
        return (activeAccounts[_perpetual.id].length() == 0);
    }

    /**
     * @dev     Sum up the total margin of open trades.
     *          -> counted margin = max(0, pure_trader_margin) * (pos!=0)
     *          The total margin is shared if not enough
     *          cash in system (last resort).
     *          Check the margin balance of trader's account, update total margin.
     *          If the margin of the trader's account is not positive, it will be counted as 0.
     *          Position = zero is not counted because the trader who has no position will get
     *          back the full cash.
     *
     * @param   _perpetual   The reference of perpetual storage.
     * @param   _traderAddr  The address of the trader to be counted.
     */
    function _countMargin(PerpetualData storage _perpetual, address _traderAddr) internal {
        int128 margin = _getMarginBalance(_perpetual, _traderAddr);
        if (margin <= 0) {
            return;
        }
        int128 pos = marginAccounts[_perpetual.id][_traderAddr].fPositionBC;
        if (pos != 0) {
            _perpetual.fTotalMarginBalance = _perpetual.fTotalMarginBalance.add(margin);
        }
    }

    /**
     * Get the address of the next active account in the perpetual.
     * AMM is not in active account list
     * @param   _perpetual   The reference of perpetual storage.
     * @return  The address of the next active account.
     */
    function _getNextActiveAccount(PerpetualData storage _perpetual) internal view returns (address) {
        require(activeAccounts[_perpetual.id].length() > 0, "no active account");
        return activeAccounts[_perpetual.id].at(0);
    }

    /**
     * Set redemption rate and mark perpetuals as cleared
     *
     * @param   _liquidityPool       The reference to liquidity pool.
     * @param   _fTotalMarginBalance total margin balance for all perpetuals in the pool that
     *                               need settlement
     * @param   _fTotalCapital       total capital (default fund, amm pools, participation fund, amm margin)
     */
    function _setRedemptionRate(
        LiquidityPoolData storage _liquidityPool,
        int128 _fTotalMarginBalance,
        int128 _fTotalCapital
    ) internal {
        if (_fTotalCapital < _fTotalMarginBalance) {
            // not enough funds, shrink payments proportionally
            // div rounds down
            _liquidityPool.fRedemptionRate = _fTotalCapital.div(_fTotalMarginBalance);
        } else {
            _liquidityPool.fRedemptionRate = ONE_64x64;
        }
        // set cleared state for all perpetuals that need to be settled
        uint256 length = _liquidityPool.iPerpetualCount;
        for (uint256 i = 0; i < length; i++) {
            bytes32 idx = perpetualIds[_liquidityPool.id][i];
            PerpetualData storage perpetual = perpetuals[_liquidityPool.id][idx];
            if (perpetual.state == PerpetualState.EMERGENCY) {
                perpetual.state = PerpetualState.CLEARED;
                // remove liquidity pool cash and target default fund/AMM pool sizes from liquidity pool
                _liquidityPool.fAMMFundCashCC = _liquidityPool.fAMMFundCashCC.sub(perpetual.fAMMFundCashCC);
                _liquidityPool.fTargetAMMFundSize = _liquidityPool.fTargetAMMFundSize.sub(perpetual.fTargetAMMFundSize);
                _liquidityPool.fTargetDFSize = _liquidityPool.fTargetDFSize.sub(perpetual.fTargetDFSize);

                emit SetClearedState(perpetual.id);
            }
        }
    }

    /**
     * @notice  If the state of the perpetual is "CLEARED", governance or the trader themselves can settle
     *          trader's account in the perpetual. Which means to calculate how much the collateral should be returned
     *          to the trader, return it to trader's wallet and clear the trader's cash and position in the perpetual.
     *
     * @param   _perpetualID  The index of the perpetual in the liquidity pool
     * @param   _traderAddr   The address of the trader.
     */
    function settle(bytes32 _perpetualID, address _traderAddr) external override nonReentrant {
        // either governance can return funds to trader or trader himself
        require(msgSender() == _traderAddr || ammGovernanceAddresses.contains(msgSender()));
        require(_traderAddr != address(0), "invalid trader");

        PerpetualData storage perpetual = _getPerpetual(_perpetualID);
        require(perpetual.state == PerpetualState.CLEARED, "perpetual should be in CLEARED state");
        int128 marginToReturn = _getSettleableMargin(perpetual, _traderAddr);
        _resetAccount(perpetual, _traderAddr);
        if (marginToReturn > 0) {
            address marginTokenAddress = _getLiquidityPoolFromPerpetual(perpetual.id).marginTokenAddress;
            _transferFromVaultToUser(marginTokenAddress, _traderAddr, marginToReturn);
        }
        emit Settle(perpetual.id, _traderAddr, marginToReturn);
    }

    /**
     * Reset the trader's account in the perpetual to empty, which means all variables 0
     * @param _perpetual  The perpetual object
     * @param _traderAddr The address of the trader
     */
    function _resetAccount(PerpetualData storage _perpetual, address _traderAddr) internal {
        MarginAccount storage account = marginAccounts[_perpetual.id][_traderAddr];
        account.fCashCC = 0;
        account.fLockedInValueQC = 0;
        account.fPositionBC = 0;
    }

    /**
     * @dev Get the settleable margin of the trader in the perpetual in collateral currency
     *      This is the margin that the trader can withdraw when the state of the perpetual is "CLEARED".
     *      If the state of the perpetual is not "CLEARED", the settleable margin is always zero
     * @param _perpetual  The perpetual object
     * @param _traderAddr The address of the trader
     * @return The settleable margin of the trader in the perpetual
     */
    function _getSettleableMargin(PerpetualData storage _perpetual, address _traderAddr) internal view returns (int128) {
        int128 marginCC = _getMarginBalance(_perpetual, _traderAddr);
        if (marginCC < 0) {
            return 0;
        }
        if (_traderAddr == address(this)) {
            // the AMM itself is already accounted for
            return 0;
        }
        int128 fPos = marginAccounts[_perpetual.id][_traderAddr].fPositionBC;
        int128 fRate = ONE_64x64;
        // if the position is zero, the trader does not participate in loss-sharing
        // i.e., they receive the full margin balance (=cash).
        if (fPos != 0) {
            // rate is 0 if not set yet
            uint256 poolId = perpetualPoolIds[_perpetual.id];
            fRate = liquidityPools[poolId].fRedemptionRate;
        }
        marginCC = marginCC.mul(fRate);
        return marginCC;
    }

    function getFunctionList() external view virtual override returns (bytes4[] memory) {
        bytes4[] memory functionList = new bytes4[](2);
        functionList[0] = this.settleNextTraderInPool.selector;
        functionList[1] = this.settle.selector;
        return functionList;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library EnumerableSetUpgradeable {
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

    function enumerate(
		AddressSet storage set,
		uint256 start,
		uint256 count
	) internal view returns (address[] memory output) {
		uint256 end = start + count;
		require(end >= start, "addition overflow");
        uint256 len = length(set);
		end = len < end ? len : end;
		if (end == 0 || start >= end) {
			return output;
		}

		output = new address[](end - start);
		for (uint256 i; i < end - start; i++) {
			output[i] = at(set, i + start);
		}
		return output;
	}

	function enumerateAll(AddressSet storage set) internal view returns (address[] memory output) {
		return enumerate(set, 0, length(set));
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