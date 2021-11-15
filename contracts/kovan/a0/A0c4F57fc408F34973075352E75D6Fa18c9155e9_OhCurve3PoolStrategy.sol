// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ILiquidator {
    function liquidate(
        address recipient,
        address from,
        address to,
        uint256 amount,
        uint256 minOut
    ) external returns (uint256);

    function getSwapInfo(address from, address to) external view returns (address router, address[] memory path);

    function sushiswapRouter() external view returns (address);

    function uniswapRouter() external view returns (address);

    function weth() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IManager {
    function token() external view returns (address);

    function buybackFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    function liquidators(address from, address to) external view returns (address);

    function whitelisted(address _contract) external view returns (bool);

    function banks(uint256 i) external view returns (address);

    function totalBanks() external view returns (uint256);

    function strategies(address bank, uint256 i) external view returns (address);

    function totalStrategies(address bank) external view returns (uint256);

    function withdrawIndex(address bank) external view returns (uint256);

    function setWithdrawIndex(uint256 i) external;

    function rebalance(address bank) external;

    function finance(address bank) external;

    function financeAll(address bank) external;

    function buyback(address from) external;

    function accrueRevenue(
        address bank,
        address underlying,
        uint256 amount
    ) external;

    function exitAll(address bank) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IRegistry {
    function governance() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISubscriber {
    function registry() external view returns (address);

    function governance() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IBankStorage} from "./IBankStorage.sol";

interface IBank is IBankStorage {
    function strategies(uint256 i) external view returns (address);

    function totalStrategies() external view returns (uint256);

    function underlyingBalance() external view returns (uint256);

    function strategyBalance(uint256 i) external view returns (uint256);

    function investedBalance() external view returns (uint256);

    function virtualBalance() external view returns (uint256);

    function virtualPrice() external view returns (uint256);

    function pause() external;

    function unpause() external;

    function invest(address strategy, uint256 amount) external;

    function investAll(address strategy) external;

    function exit(address strategy, uint256 amount) external;

    function exitAll(address strategy) external;

    function deposit(uint256 amount) external;

    function depositFor(uint256 amount, address recipient) external;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IBankStorage {
    function paused() external view returns (bool);

    function underlying() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IStrategyBase} from "./IStrategyBase.sol";

interface IStrategy is IStrategyBase {
    function investedBalance() external view returns (uint256);

    function invest() external;

    function withdraw(uint256 amount) external returns (uint256);

    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IStrategyStorage} from "./IStrategyStorage.sol";

interface IStrategyBase is IStrategyStorage {
    function underlyingBalance() external view returns (uint256);

    function derivativeBalance() external view returns (uint256);

    function rewardBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IStrategyStorage {
    function bank() external view returns (address);

    function underlying() external view returns (address);

    function derivative() external view returns (address);

    function reward() external view returns (address);

    // function investedBalance() external view returns (uint256);

    // function invest() external;

    // function withdraw(uint256 amount) external returns (uint256);

    // function withdrawAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ICurve3PoolStrategyStorage {
    function pool() external view returns (address);

    function gauge() external view returns (address);

    function mintr() external view returns (address);

    function index() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

library TransferHelper {
    using SafeERC20 for IERC20;

    // safely transfer tokens without underflowing
    function safeTokenTransfer(
        address recipient,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) {
            IERC20(token).safeTransfer(recipient, balance);
            return balance;
        } else {
            IERC20(token).safeTransfer(recipient, amount);
            return amount;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/// @title Oh! Finance Base Upgradeable
/// @notice Contains internal functions to get/set primitive data types used by a proxy contract
abstract contract OhUpgradeable {
    function getAddress(bytes32 slot) internal view returns (address _address) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _address := sload(slot)
        }
    }

    function getBoolean(bytes32 slot) internal view returns (bool _bool) {
        uint256 bool_;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            bool_ := sload(slot)
        }
        _bool = bool_ == 1;
    }

    function getBytes32(bytes32 slot) internal view returns (bytes32 _bytes32) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _bytes32 := sload(slot)
        }
    }

    function getUInt256(bytes32 slot) internal view returns (uint256 _uint) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _uint := sload(slot)
        }
    }

    function setAddress(bytes32 slot, address _address) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function setBytes32(bytes32 slot, bytes32 _bytes32) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _bytes32)
        }
    }

    /// @dev Set a boolean storage variable in a given slot
    /// @dev Convert to a uint to take up an entire contract storage slot
    function setBoolean(bytes32 slot, bool _bool) internal {
        uint256 bool_ = _bool ? 1 : 0;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, bool_)
        }
    }

    function setUInt256(bytes32 slot, uint256 _uint) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _uint)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ISubscriber} from "../interfaces/ISubscriber.sol";
import {IRegistry} from "../interfaces/IRegistry.sol";
import {OhUpgradeable} from "../proxy/OhUpgradeable.sol";

/// @title Oh! Finance Subscriber Upgradeable
/// @notice Base Oh! Finance upgradeable contract used to control access throughout the protocol
abstract contract OhSubscriberUpgradeable is Initializable, OhUpgradeable, ISubscriber {
    bytes32 private constant _REGISTRY_SLOT = 0x1b5717851286d5e98a28354be764b8c0a20eb2fbd059120090ee8bcfe1a9bf6c;

    /// @notice Only allow authorized addresses (governance or manager) to execute a function
    modifier onlyAuthorized {
        require(msg.sender == governance() || msg.sender == manager(), "Subscriber: Only Authorized");
        _;
    }

    /// @notice Only allow the governance address to execute a function
    modifier onlyGovernance {
        require(msg.sender == governance(), "Subscriber: Only Governance");
        _;
    }

    /// @notice Verify the registry storage slot is correct
    constructor() {
        assert(_REGISTRY_SLOT == bytes32(uint256(keccak256("eip1967.subscriber.registry")) - 1));
    }

    /// @notice Initialize the Subscriber
    /// @param registry_ The Registry contract address
    /// @dev Always call this method in the initializer function for any derived classes
    function initializeSubscriber(address registry_) internal initializer {
        require(Address.isContract(registry_), "Subscriber: Invalid Registry");
        _setRegistry(registry_);
    }

    /// @notice Set the Registry for the contract. Only callable by Governance.
    /// @param registry_ The new registry
    /// @dev Requires sender to be Governance of the new Registry to avoid bricking.
    /// @dev Ideally should not be used
    function setRegistry(address registry_) external onlyGovernance {
        _setRegistry(registry_);
        require(msg.sender == governance(), "Subscriber: Bad Governance");
    }

    /// @notice Get the Governance address
    /// @return The current Governance address
    function governance() public view override returns (address) {
        return IRegistry(registry()).governance();
    }

    /// @notice Get the Manager address
    /// @return The current Manager address
    function manager() public view override returns (address) {
        return IRegistry(registry()).manager();
    }

    /// @notice Get the Registry address
    /// @return The current Registry address
    function registry() public view override returns (address) {
        return getAddress(_REGISTRY_SLOT);
    }

    function _setRegistry(address registry_) private {
        setAddress(_REGISTRY_SLOT, registry_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IBank} from "../interfaces/bank/IBank.sol";
import {IStrategyBase} from "../interfaces/strategies/IStrategyBase.sol";
import {ILiquidator} from "../interfaces/ILiquidator.sol";
import {IManager} from "../interfaces/IManager.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";
import {OhSubscriberUpgradeable} from "../registry/OhSubscriberUpgradeable.sol";
import {OhStrategyStorage} from "./OhStrategyStorage.sol";

/// @title Oh! Finance Strategy
/// @notice Base Upgradeable Strategy Contract to build strategies on
contract OhStrategy is OhSubscriberUpgradeable, OhStrategyStorage, IStrategyBase {
    using SafeERC20 for IERC20;

    event Liquidate(address indexed router, address indexed token, uint256 amount);
    event Sweep(address indexed token, uint256 amount, address recipient);

    /// @notice Only the Bank can execute these functions
    modifier onlyBank() {
        require(msg.sender == bank(), "Strategy: Only Bank");
        _;
    }

    /// @notice Initialize the base Strategy
    /// @param registry_ Address of the Registry
    /// @param bank_ Address of Bank
    /// @param underlying_ Underying token that is deposited
    /// @param derivative_ Derivative token received from protocol, or address(0)
    /// @param reward_ Reward token received from protocol, or address(0)
    function initializeStrategy(
        address registry_,
        address bank_,
        address underlying_,
        address derivative_,
        address reward_
    ) internal initializer {
        initializeSubscriber(registry_);
        initializeStorage(bank_, underlying_, derivative_, reward_);
    }

    /// @dev Balance of underlying awaiting Strategy investment
    function underlyingBalance() public view override returns (uint256) {
        return IERC20(underlying()).balanceOf(address(this));
    }

    /// @dev Balance of derivative tokens received from Strategy, if applicable
    /// @return The balance of derivative tokens
    function derivativeBalance() public view override returns (uint256) {
        if (derivative() == address(0)) {
            return 0;
        }
        return IERC20(derivative()).balanceOf(address(this));
    }

    /// @dev Balance of reward tokens awaiting liquidation, if applicable
    function rewardBalance() public view override returns (uint256) {
        if (reward() == address(0)) {
            return 0;
        }
        return IERC20(reward()).balanceOf(address(this));
    }

    /// @notice Governance function to sweep any stuck / airdrop tokens to a given recipient
    /// @param token The address of the token to sweep
    /// @param amount The amount of tokens to sweep
    /// @param recipient The address to send the sweeped tokens to
    function sweep(
        address token,
        uint256 amount,
        address recipient
    ) external onlyGovernance {
        // require(!_protected[token], "Strategy: Cannot sweep");
        TransferHelper.safeTokenTransfer(recipient, token, amount);
        emit Sweep(token, amount, recipient);
    }

    /// @dev Liquidation function to swap rewards for underlying
    function liquidate(
        address from,
        address to,
        uint256 amount
    ) internal {
        // if (amount > minimumSell())

        // find the liquidator to use
        address manager = manager();
        address liquidator = IManager(manager).liquidators(from, to);

        // increase allowance and liquidate to the manager
        TransferHelper.safeTokenTransfer(liquidator, from, amount);
        uint256 received = ILiquidator(liquidator).liquidate(manager, from, to, amount, 1);

        // notify revenue and transfer proceeds back to strategy
        IManager(manager).accrueRevenue(bank(), to, received);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {IStrategyStorage} from "../interfaces/strategies/IStrategyStorage.sol";
import {OhUpgradeable} from "../proxy/OhUpgradeable.sol";

contract OhStrategyStorage is Initializable, OhUpgradeable, IStrategyStorage {
    bytes32 internal constant _BANK_SLOT = 0xd2eff96e29993ca5431993c3a205e12e198965c0e1fdd87b4899b57f1e611c74;
    bytes32 internal constant _UNDERLYING_SLOT = 0x0fad97fe3ec7d6c1e9191a09a0c4ccb7a831b6605392e57d2fedb8501a4dc812;
    bytes32 internal constant _DERIVATIVE_SLOT = 0x4ff4c9b81c0bf267e01129f4817e03efc0163ee7133b87bd58118a96bbce43d3;
    bytes32 internal constant _REWARD_SLOT = 0xaeb865605058f37eedb4467ee2609ddec592b0c9a6f7f7cb0db3feabe544c71c;

    constructor() {
        assert(_BANK_SLOT == bytes32(uint256(keccak256("eip1967.strategy.bank")) - 1));
        assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategy.underlying")) - 1));
        assert(_DERIVATIVE_SLOT == bytes32(uint256(keccak256("eip1967.strategy.derivative")) - 1));
        assert(_REWARD_SLOT == bytes32(uint256(keccak256("eip1967.strategy.reward")) - 1));
    }

    function initializeStorage(
        address bank_,
        address underlying_,
        address derivative_,
        address reward_
    ) internal initializer {
        _setBank(bank_);
        _setUnderlying(underlying_);
        _setDerivative(derivative_);
        _setReward(reward_);
    }

    /// @notice The Bank that the Strategy is associated with
    function bank() public view override returns (address) {
        return getAddress(_BANK_SLOT);
    }

    /// @notice The underlying token the Strategy invests in AaveV2
    function underlying() public view override returns (address) {
        return getAddress(_UNDERLYING_SLOT);
    }

    /// @notice The derivative token received from AaveV2 (aToken)
    function derivative() public view override returns (address) {
        return getAddress(_DERIVATIVE_SLOT);
    }

    /// @notice The reward token received from AaveV2 (stkAave)
    function reward() public view override returns (address) {
        return getAddress(_REWARD_SLOT);
    }

    function _setBank(address _address) internal {
        setAddress(_BANK_SLOT, _address);
    }

    function _setUnderlying(address _address) internal {
        setAddress(_UNDERLYING_SLOT, _address);
    }

    function _setDerivative(address _address) internal {
        setAddress(_DERIVATIVE_SLOT, _address);
    }

    function _setReward(address _address) internal {
        setAddress(_REWARD_SLOT, _address);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ICurve3Pool} from "./interfaces/ICurve3Pool.sol";
import {IGauge} from "./interfaces/IGauge.sol";
import {IMintr} from "./interfaces/IMintr.sol";

/// @title Oh! Finance Curve 3Pool Helper
/// @notice Helper functions for Curve 3Pool Strategies
abstract contract OhCurve3PoolHelper {
    using SafeERC20 for IERC20;

    /// @notice Add liquidity to Curve's 3Pool, receiving 3CRV in return
    /// @param pool The address of Curve 3Pool
    /// @param underlying The underlying we want to deposit
    /// @param index The index of the underlying
    /// @param amount The amount of underlying to deposit
    /// @param minMint The min LP tokens to mint before tx reverts (slippage)
    function addLiquidity(
        address pool,
        address underlying,
        uint256 index,
        uint256 amount,
        uint256 minMint
    ) internal {
        uint256[3] memory amounts = [uint256(0), uint256(0), uint256(0)];
        amounts[index] = amount;
        IERC20(underlying).safeIncreaseAllowance(pool, amount);
        ICurve3Pool(pool).add_liquidity(amounts, minMint);
    }

    /// @notice Remove liquidity from Curve 3Pool, receiving a single underlying
    /// @param pool The Curve 3Pool
    /// @param index The index of underlying we want to withdraw
    /// @param amount The amount to withdraw
    /// @param maxBurn The max LP tokens to burn before the tx reverts (slippage)
    function removeLiquidity(
        address pool,
        uint256 index,
        uint256 amount,
        uint256 maxBurn
    ) internal {
        uint256[3] memory amounts = [uint256(0), uint256(0), uint256(0)];
        amounts[index] = amount;
        ICurve3Pool(pool).remove_liquidity_imbalance(amounts, maxBurn);
    }

    /// @notice Claim CRV rewards from the Mintr for a given Gauge
    /// @param mintr The CRV Mintr (Rewards Contract)
    /// @param gauge The Gauge (Staking Contract) to claim from
    function claim(address mintr, address gauge) internal {
        IMintr(mintr).mint(gauge);
    }

    /// @notice Calculate the max withdrawal amount to a single underlying
    /// @param pool The Curve LP Pool
    /// @param amount The amount of underlying to deposit
    /// @param index The index of the underlying in the LP Pool
    function calcWithdraw(
        address pool,
        uint256 amount,
        int128 index
    ) internal view returns (uint256) {
        return ICurve3Pool(pool).calc_withdraw_one_coin(amount, index);
    }

    /// @notice Get the balance of staked tokens in a given Gauge
    /// @param gauge The Curve Gauge to check
    function staked(address gauge) internal view returns (uint256) {
        return IGauge(gauge).balanceOf(address(this));
    }

    /// @notice Stake crvUnderlying into the Gauge to earn CRV
    /// @param gauge The Curve Gauge to stake into
    /// @param crvUnderlying The Curve LP Token to stake
    /// @param amount The amount of LP Tokens to stake
    function stake(
        address gauge,
        address crvUnderlying,
        uint256 amount
    ) internal {
        IERC20(crvUnderlying).safeIncreaseAllowance(gauge, amount);
        IGauge(gauge).deposit(amount);
    }

    /// @notice Unstake crvUnderlying funds from the Curve Gauge
    /// @param gauge The Curve Gauge to unstake from
    /// @param amount The amount of LP Tokens to withdraw
    function unstake(address gauge, uint256 amount) internal {
        IGauge(gauge).withdraw(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {IStrategy} from "../../interfaces/strategies/IStrategy.sol";
import {TransferHelper} from "../../libraries/TransferHelper.sol";
import {OhStrategy} from "../OhStrategy.sol";
import {OhCurve3PoolHelper} from "./OhCurve3PoolHelper.sol";
import {OhCurve3PoolStrategyStorage} from "./OhCurve3PoolStrategyStorage.sol";

/// @title Oh! Finance Curve 3Pool Strategy
/// @notice Standard Curve 3Pool LP + Gauge Single Underlying Strategy
/// @notice 3Pool Underlying, in order: (DAI, USDC, USDT)
contract OhCurve3PoolStrategy is OhStrategy, OhCurve3PoolStrategyStorage, OhCurve3PoolHelper, IStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice Initialize the Curve 3Pool Strategy Logic
    constructor() initializer {
        assert(registry() == address(0));
        assert(bank() == address(0));
        assert(underlying() == address(0));
        assert(reward() == address(0));
    }

    /// @notice Initialize the Curve 3Pool Strategy Proxy
    /// @param registry_ Address of the Registry
    /// @param bank_ Address of the Bank
    /// @param underlying_ Underlying (DAI, USDC, USDT)
    /// @param derivative_ 3CRV LP Token
    /// @param reward_ CRV Gov Token
    /// @param pool_ Address of the Curve 3Pool
    /// @param gauge_ Curve Gauge, Staking Contract
    /// @param mintr_ Curve Mintr, Rewards Contract
    /// @param index_ Underlying 3Pool Index
    function initializeCurve3PoolStrategy(
        address registry_,
        address bank_,
        address underlying_,
        address derivative_,
        address reward_,
        address pool_,
        address gauge_,
        address mintr_,
        uint256 index_
    ) public initializer {
        initializeStrategy(registry_, bank_, underlying_, derivative_, reward_);
        initializeCurve3PoolStorage(pool_, gauge_, mintr_, index_);
    }

    // calculate the total underlying balance
    function investedBalance() public view override returns (uint256) {
        return calcWithdraw(pool(), stakedBalance(), int128(index()));
    }

    // amount of 3CRV staked in the Gauge
    function stakedBalance() public view returns (uint256) {
        return staked(gauge());
    }

    /// @notice Execute the Curve 3Pool Strategy
    /// @dev Compound CRV Yield, Add Liquidity, Stake into Gauge
    function invest() external override onlyBank {
        _compound();
        _deposit();
    }

    /// @notice Withdraw an amount of underlying from Curve 3Pool Strategy
    /// @param amount Amount of Underlying tokens to withdraw
    /// @dev Unstake from Gauge, Remove Liquidity
    function withdraw(uint256 amount) external override onlyBank returns (uint256) {
        uint256 withdrawn = _withdraw(msg.sender, amount);
        return withdrawn;
    }

    /// @notice Withdraw all underlying from Curve 3Pool Strategy
    /// @dev Unstake from Gauge, Remove Liquidity
    function withdrawAll() external override onlyBank {
        uint256 invested = investedBalance();
        _withdraw(msg.sender, invested);
    }

    /// @dev Compound rewards into underlying through liquidation
    /// @dev Claim Rewards from Mintr, sell CRV for USDC
    function _compound() internal {
        // claim available CRV rewards
        claim(mintr(), gauge());
        uint256 rewardAmount = rewardBalance();
        if (rewardAmount > 0) {
            liquidate(reward(), underlying(), rewardAmount);
        }
    }

    // deposit underlying into 3Pool to get 3CRV and stake into Gauge
    function _deposit() internal {
        uint256 amount = underlyingBalance();
        if (amount > 0) {
            // add liquidity to 3Pool to receive 3CRV
            addLiquidity(pool(), underlying(), index(), amount, 1);
            // stake all received in the 3CRV gauge
            stake(gauge(), derivative(), derivativeBalance());
        }
    }

    // withdraw underlying tokens from the protocol
    // TODO: Double check withdrawGauge math, TransferHelper
    function _withdraw(address recipient, uint256 amount) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 invested = investedBalance();
        uint256 staked = stakedBalance();

        // calculate % of supply ownership
        uint256 supplyShare = amount.mul(1e18).div(invested);

        // find amount to unstake in 3CRV
        uint256 unstakeAmount = Math.min(staked, supplyShare.mul(staked).div(1e18));

        // find amount to redeem in underlying
        uint256 redeemAmount = Math.min(invested, supplyShare.mul(invested).div(1e18));

        // unstake from Gauge & remove liquidity from Pool
        unstake(gauge(), unstakeAmount);
        removeLiquidity(pool(), index(), redeemAmount, unstakeAmount);

        // withdraw to bank
        uint256 withdrawn = TransferHelper.safeTokenTransfer(recipient, underlying(), amount);
        return withdrawn;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {ICurve3PoolStrategyStorage} from "../../interfaces/strategies/curve/ICurve3PoolStrategyStorage.sol";
import {OhUpgradeable} from "../../proxy/OhUpgradeable.sol";

contract OhCurve3PoolStrategyStorage is Initializable, OhUpgradeable, ICurve3PoolStrategyStorage {
    bytes32 internal constant _POOL_SLOT = 0x6c9960513c6769ea8f48802ea7b637e9ce937cc3d022135cc43626003296fc46;
    bytes32 internal constant _GAUGE_SLOT = 0x85c79ab2dc779eb860ec993658b7f7a753e59bdfda156c7391620a5f513311e6;
    bytes32 internal constant _MINTR_SLOT = 0x3e7777dca2f9f31e4c2d62ce76af8def0f69b868d665539787b25b39a9f7224f;
    bytes32 internal constant _INDEX_SLOT = 0xd5700a843c20bfe827ca47a7c73f83287e1b32b3cd4ac659d79f800228d617fd;

    constructor() {
        assert(_POOL_SLOT == bytes32(uint256(keccak256("eip1967.curve3PoolStrategy.pool")) - 1));
        assert(_GAUGE_SLOT == bytes32(uint256(keccak256("eip1967.curve3PoolStrategy.gauge")) - 1));
        assert(_MINTR_SLOT == bytes32(uint256(keccak256("eip1967.curve3PoolStrategy.mintr")) - 1));
        assert(_INDEX_SLOT == bytes32(uint256(keccak256("eip1967.curve3PoolStrategy.index")) - 1));
    }

    function initializeCurve3PoolStorage(
        address pool_,
        address gauge_,
        address mintr_,
        uint256 index_
    ) internal initializer {
        _setPool(pool_);
        _setGauge(gauge_);
        _setMintr(mintr_);
        _setIndex(index_);
    }

    function pool() public view override returns (address) {
        return getAddress(_POOL_SLOT);
    }

    function gauge() public view override returns (address) {
        return getAddress(_GAUGE_SLOT);
    }

    function mintr() public view override returns (address) {
        return getAddress(_MINTR_SLOT);
    }

    function index() public view override returns (uint256) {
        return getUInt256(_INDEX_SLOT);
    }

    function _setPool(address pool_) internal {
        setAddress(_POOL_SLOT, pool_);
    }

    function _setGauge(address gauge_) internal {
        setAddress(_GAUGE_SLOT, gauge_);
    }

    function _setMintr(address mintr_) internal {
        setAddress(_MINTR_SLOT, mintr_);
    }

    function _setIndex(uint256 index_) internal {
        setUInt256(_INDEX_SLOT, index_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ICurve3Pool {
    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256, int128) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;

    function user_checkpoint(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IMintr {
    function mint(address) external;
}

