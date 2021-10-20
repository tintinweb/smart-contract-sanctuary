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

interface IAaveV2StrategyStorage {
    function stakedToken() external view returns (address);

    function lendingPool() external view returns (address);

    function incentivesController() external view returns (address);
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
import {ILendingPoolV2} from "./interfaces/ILendingPoolV2.sol";
import {ILendingPoolAddressesProviderV2} from "./interfaces/ILendingPoolAddressesProviderV2.sol";
import {IAaveIncentivesController} from "./interfaces/IAaveIncentivesController.sol";
import {IAaveProtocolDataProviderV2} from "./interfaces/IAaveProtocolDataProviderV2.sol";
import {IStakedToken} from "./interfaces/IStakedToken.sol";

/// @title Oh! Finance AaveV2 Helper
/// @notice Helper functions to interact with the AaveV2
/// @dev https://docs.aave.com/portal/
abstract contract OhAaveV2Helper {
    using SafeERC20 for IERC20;

    /// @notice Get the AaveV2 aToken for a given underlying
    /// @param dataProvider The AaveV2 Data Provider
    /// @param underlying The underlying token to check
    /// @return The address of the associated aToken
    function aToken(address dataProvider, address underlying) internal view returns (address) {
        (address aTokenAddress, , ) = IAaveProtocolDataProviderV2(dataProvider).getReserveTokensAddresses(underlying);
        return aTokenAddress;
    }

    /// @notice Get the AaveV2 Lending Pool
    /// @param addressProvider The AaveV2 Address Provider
    /// @return The address of the AaveV2 Lending Pool
    function lendingPool(address addressProvider) internal view returns (address) {
        return ILendingPoolAddressesProviderV2(addressProvider).getLendingPool();
    }

    /// @notice Get the cooldown timestamp start for this contract
    /// @param stakedToken The address of stkAAVE
    /// @return The timestamp the cooldown started on
    function stakersCooldown(address stakedToken) internal view returns (uint256) {
        uint256 stakerCooldown = IStakedToken(stakedToken).stakersCooldowns(address(this));
        return stakerCooldown;
    }

    /// @notice Get the cooldown window in seconds for unstaking stkAAVE to AAVE before cooldown expires
    /// @dev 864000 - 10 days
    /// @param stakedToken The address of stkAAVE
    /// @return The cooldown seconds to wait before unstaking
    function cooldownWindow(address stakedToken) internal view returns (uint256) {
        uint256 window = IStakedToken(stakedToken).COOLDOWN_SECONDS();
        return window;
    }

    /// @notice Get the unstake window in seconds for unstaking stkAAVE to AAVE after cooldown passes
    /// @dev 172800 - 2 days
    /// @param stakedToken The address of stkAAVE
    /// @return The unstake window seconds we have to unwrap stkAAVE to AAVE
    function unstakingWindow(address stakedToken) internal view returns (uint256) {
        uint256 window = IStakedToken(stakedToken).UNSTAKE_WINDOW();
        return window;
    }

    /// @notice Initiate a claim cooldown to swap stkAAVE to AAVE
    /// @param stakedToken The address of stkAAVE
    function cooldown(address stakedToken) internal {
        IStakedToken(stakedToken).cooldown();
    }

    /// @notice Redeem an amount of stkAAVE for AAVE
    /// @param stakedToken The address of stkAAVE
    /// @param amount The amount of stkAAVE to redeem
    function redeem(address stakedToken, uint256 amount) internal {
        IStakedToken(stakedToken).redeem(address(this), amount);
    }

    /// @notice Claim stkAAVE from the AaveV2 Incentive Controller
    /// @dev Claim all available rewards, return if none available
    /// @param incentivesController The AaveV2 Incentive Controller
    /// @param token The aToken to claim rewards for
    function claimRewards(address incentivesController, address token) internal {
        address[] memory tokens = new address[](1);
        tokens[0] = token;

        uint256 rewards = IAaveIncentivesController(incentivesController).getRewardsBalance(tokens, address(this));

        if (rewards > 0) {
            IAaveIncentivesController(incentivesController).claimRewards(tokens, rewards, address(this));
        }
    }

    /// @notice Lend underlying to Aave V2 Lending Pool, receive aTokens
    /// @param pool The AaveV2 Lending Pool
    /// @param underlying The underlying ERC20 to lend
    /// @param amount The amount of underlying to lend
    function lend(
        address pool,
        address underlying,
        uint256 amount
    ) internal {
        IERC20(underlying).safeIncreaseAllowance(pool, amount);
        ILendingPoolV2(pool).deposit(
            underlying,
            amount,
            address(this),
            0 // referral code
        );
    }

    /// @notice Reclaim underlying by sending aTokens to Aave V2 Lending Pool
    /// @param pool The AaveV2 Lending Pool
    /// @param token The aToken to redeem for underlying
    /// @param amount The amount of aTokens to send
    function reclaim(
        address pool,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeIncreaseAllowance(pool, amount);
        uint256 withdrawn = ILendingPoolV2(pool).withdraw(token, amount, address(this));
        require(withdrawn == amount || withdrawn == balance, "AaveV2: Withdraw failed");
        return withdrawn;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IStrategy} from "../../interfaces/strategies/IStrategy.sol";
import {TransferHelper} from "../../libraries/TransferHelper.sol";
import {OhStrategy} from "../OhStrategy.sol";
import {OhAaveV2Helper} from "./OhAaveV2Helper.sol";
import {OhAaveV2StrategyStorage} from "./OhAaveV2StrategyStorage.sol";

/// @title Oh! Finance Aave V2 Strategy
/// @notice Standard strategy using Aave V2 Protocol
/// @dev Underlying: USDC, USDT, etc.
/// @dev Derivative: aToken, 1:1 ratio with underlying
/// @dev https://docs.aave.com/developers/the-core-protocol/atokens
contract OhAaveV2Strategy is IStrategy, OhAaveV2Helper, OhStrategy, OhAaveV2StrategyStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice Initialize the AaveV2 Strategy Logic
    constructor() initializer {
        assert(registry() == address(0));
        assert(bank() == address(0));
        assert(underlying() == address(0));
        assert(reward() == address(0));
    }

    /// @notice Initialize the AaveV2 Strategy Proxy
    /// @param registry_ the registry contract
    /// @param bank_ the bank associated with the strategy
    /// @param underlying_ the underlying token that is deposited
    /// @param derivative_ the aToken address received from Aave
    /// @param reward_ the address of the reward token stkAAVE
    /// @param lendingPool_ the AaveV2 lending pool that we lend to
    /// @param incentivesController_ the AaveV2 rewards contract
    /// @dev The function should be called at time of deployment
    function initializeAaveV2Strategy(
        address registry_,
        address bank_,
        address underlying_,
        address derivative_,
        address reward_,
        address stakedToken_,
        address lendingPool_,
        address incentivesController_
    ) public initializer {
        initializeStrategy(registry_, bank_, underlying_, derivative_, reward_);
        initializeAaveV2Storage(stakedToken_, lendingPool_, incentivesController_);
    }

    /// @notice Balance of underlying invested in AaveV2
    /// @dev aTokens are 1:1 with underlying, they are continuously distributed to users
    function investedBalance() public view override returns (uint256) {
        return derivativeBalance();
    }

    /// @notice Balance of stkAAVE await liquidation
    /// @dev Rewards are first received in stkAAVe, then must undergo 10 day cooldown
    /// @dev Before batch claiming.
    function stakedBalance() public view returns (uint256) {
        return IERC20(stakedToken()).balanceOf(address(this));
    }

    /// @notice Invest in the AaveV2 Strategy
    /// @dev Compound by claiming stkAAVE, then unwrapping + liquidating if cooldown permits
    /// @dev Deposit all underlying to receive aTokens
    function invest() external override onlyBank {
        _compound();
        _deposit();
    }

    /// @notice
    function withdraw(uint256 amount) external override onlyBank returns (uint256) {
        uint256 withdrawn = _withdraw(msg.sender, amount);
        return withdrawn;
    }

    /// @notice
    function withdrawAll() external override onlyBank {
        uint256 amount = derivativeBalance();
        _withdraw(msg.sender, amount);
    }

    /// @dev Compound stkAAVE rewards on a alternating cooldown schedule
    function _compound() internal {
        uint256 currentCooldown = rewardCooldown();

        // if the current cooldown has passed
        if (block.timestamp > currentCooldown) {
            // save state variables
            uint256 balance = stakedBalance();
            address staked = stakedToken();
            uint256 expiration = currentCooldown.add(unstakingWindow(staked));

            // if we have stkAAVE and the unstaking window hasn't passed
            if (balance > 0 && block.timestamp < expiration) {
                // redeem all available AAVE
                redeem(staked, balance);

                // validate we received AAVE
                uint256 amount = rewardBalance();
                if (amount > 0) {
                    // liquidate for underlying
                    liquidate(reward(), underlying(), amount);
                }
            }

            // claim new batch of available stkAAVE rewards
            claimRewards(incentivesController(), derivative());

            balance = stakedBalance();
            if (balance > 0) {
                // initiate a new cooldown
                cooldown(staked);

                // validate the cooldown was set
                uint256 newCooldown = stakersCooldown(staked);
                require(newCooldown == block.timestamp, "AaveV2: Cooldown failed");

                // find reward cooldown, new timestamp when rewards are claimable
                uint256 newRewardCooldown = newCooldown.add(cooldownWindow(staked));
                _setRewardCooldown(newRewardCooldown);
            }
        }
    }

    function _deposit() internal {
        uint256 amount = underlyingBalance();
        if (amount > 0) {
            lend(lendingPool(), underlying(), amount);
        }
    }

    // withdraw tokens from protocol after converting aTokens to underlying
    function _withdraw(address recipient, uint256 amount) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        uint256 reclaimed = reclaim(lendingPool(), underlying(), amount);
        uint256 withdrawn = TransferHelper.safeTokenTransfer(recipient, underlying(), reclaimed);
        return withdrawn;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {IAaveV2StrategyStorage} from "../../interfaces/strategies/aave/IAaveV2StrategyStorage.sol";
import {OhUpgradeable} from "../../proxy/OhUpgradeable.sol";

contract OhAaveV2StrategyStorage is Initializable, OhUpgradeable, IAaveV2StrategyStorage {
    bytes32 internal constant _STAKED_TOKEN_SLOT = 0x6ffcc641b9dd32ae63496168decfef38477654371686576c048aacac7664aa89;
    bytes32 internal constant _LENDING_POOL_SLOT = 0x32da969ce0980814ec712773a44ab0fbc7a926f6c25ab5c3ab143cbaf257713b;
    bytes32 internal constant _INCENTIVES_CONTROLLER_SLOT = 0x8354a0ba382ef5f265c75cfb638fc27db941b9db0fd5dc17719a651d5d4cda15;
    bytes32 internal constant _REWARD_COOLDOWN_SLOT = 0x29ba1167c1adca0c8d6bf06d5964666a1db7a70ebfda62e977c0e3331d7b3923;

    constructor() {
        assert(_STAKED_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.aaveV2Strategy.stakedToken")) - 1));
        assert(_LENDING_POOL_SLOT == bytes32(uint256(keccak256("eip1967.aaveV2Strategy.lendingPool")) - 1));
        assert(_INCENTIVES_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.aaveV2Strategy.incentivesController")) - 1));
        assert(_REWARD_COOLDOWN_SLOT == bytes32(uint256(keccak256("eip1967.aaveV2Strategy.rewardCooldown")) - 1));
    }

    function initializeAaveV2Storage(
        address stakedToken_,
        address lendingPool_,
        address incentiveController_
    ) internal initializer {
        _setStakedToken(stakedToken_);
        _setLendingPool(lendingPool_);
        _setIncentiveController(incentiveController_);
        _setRewardCooldown(block.timestamp + 864000); // initialize with 10 day reward lag
    }

    function stakedToken() public view override returns (address) {
        return getAddress(_STAKED_TOKEN_SLOT);
    }

    function lendingPool() public view override returns (address) {
        return getAddress(_LENDING_POOL_SLOT);
    }

    function incentivesController() public view override returns (address) {
        return getAddress(_INCENTIVES_CONTROLLER_SLOT);
    }

    function rewardCooldown() public view returns (uint256) {
        return getUInt256(_REWARD_COOLDOWN_SLOT);
    }

    function _setStakedToken(address stakedToken_) internal {
        setAddress(_STAKED_TOKEN_SLOT, stakedToken_);
    }

    function _setLendingPool(address lendingPool_) internal {
        setAddress(_LENDING_POOL_SLOT, lendingPool_);
    }

    function _setIncentiveController(address incentiveController_) internal {
        setAddress(_INCENTIVES_CONTROLLER_SLOT, incentiveController_);
    }

    function _setRewardCooldown(uint256 rewardCooldown_) internal {
        setUInt256(_REWARD_COOLDOWN_SLOT, rewardCooldown_);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {DistributionTypes} from "../libraries/DistributionTypes.sol";

interface IAaveDistributionManager {
    event AssetConfigUpdated(address indexed asset, uint256 emission);
    event AssetIndexUpdated(address indexed asset, uint256 index);
    event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);
    event DistributionEndUpdated(uint256 newDistributionEnd);

    /**
     * @dev Sets the end date for the distribution
     * @param distributionEnd The end date timestamp
     **/
    function setDistributionEnd(uint256 distributionEnd) external;

    /**
     * @dev Gets the end date for the distribution
     * @return The end of the distribution
     **/
    function getDistributionEnd() external view returns (uint256);

    /**
     * @dev for backwards compatibility with the previous DistributionManager used
     * @return The end of the distribution
     **/
    function DISTRIBUTION_END() external view returns (uint256);

    /**
     * @dev Returns the data of an user on a distribution
     * @param user Address of the user
     * @param asset The address of the reference asset of the distribution
     * @return The new index
     **/
    function getUserAssetData(address user, address asset) external view returns (uint256);

    /**
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {IAaveDistributionManager} from "./IAaveDistributionManager.sol";

interface IAaveIncentivesController {
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(address indexed user, address indexed to, address indexed claimer, uint256 amount);

    event ClaimerSet(address indexed user, address indexed claimer);

    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @dev Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleAction(
        address asset,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    /**
     * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user) external view returns (uint256);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function REWARD_TOKEN() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IAaveProtocolDataProviderV2 {
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ILendingPoolAddressesProviderV2 {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProviderV2} from "./ILendingPoolAddressesProviderV2.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface ILendingPoolV2 {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referral);

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider() external view returns (ILendingPoolAddressesProviderV2);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IStakedToken {
    function stake(address to, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;

    function stakersCooldowns(address staker) external view returns (uint256);

    function COOLDOWN_SECONDS() external view returns (uint256);

    function UNSTAKE_WINDOW() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

library DistributionTypes {
    struct AssetConfigInput {
        uint104 emissionPerSecond;
        uint256 totalStaked;
        address underlyingAsset;
    }

    struct UserStakeInput {
        address underlyingAsset;
        uint256 stakedByUser;
        uint256 totalStaked;
    }
}