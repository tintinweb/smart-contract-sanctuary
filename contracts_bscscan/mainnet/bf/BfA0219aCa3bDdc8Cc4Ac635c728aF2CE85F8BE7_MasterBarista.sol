/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

// SPDX-License-Identifier: GPL-3.0

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
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
    uint256[49] private __gap;
}

library LinkList {
  address public constant start = address(1);
  address public constant end = address(1);
  address public constant empty = address(0);

  struct List {
    uint256 llSize;
    mapping(address => address) next;
  }

  function init(List storage list) internal returns (List memory) {
    list.next[start] = end;

    return list;
  }

  function has(List storage list, address addr) internal view returns (bool) {
    return list.next[addr] != empty;
  }

  function add(List storage list, address addr) internal returns (List memory) {
    require(!has(list, addr), "LinkList::add:: addr is already in the list");
    list.next[addr] = list.next[start];
    list.next[start] = addr;
    list.llSize++;

    return list;
  }

  function remove(
    List storage list,
    address addr,
    address prevAddr
  ) internal returns (List memory) {
    require(has(list, addr), "LinkList::remove:: addr not whitelisted yet");
    require(list.next[prevAddr] == addr, "LinkList::remove:: wrong prevConsumer");
    list.next[prevAddr] = list.next[addr];
    list.next[addr] = empty;
    list.llSize--;

    return list;
  }

  function getAll(List storage list) internal view returns (address[] memory) {
    address[] memory addrs = new address[](list.llSize);
    address curr = list.next[start];
    for (uint256 i = 0; curr != end; i++) {
      addrs[i] = curr;
      curr = list.next[curr];
    }
    return addrs;
  }

  function getPreviousOf(List storage list, address addr) internal view returns (address) {
    address curr = list.next[start];
    require(curr != empty, "LinkList::getPreviousOf:: please init the linkedlist first");
    for (uint256 i = 0; curr != end; i++) {
      if (list.next[curr] == addr) return curr;
      curr = list.next[curr];
    }
    return end;
  }

  function getNextOf(List storage list, address curr) internal view returns (address) {
    return list.next[curr];
  }

  function length(List storage list) internal view returns (uint256) {
    return list.llSize;
  }
}


interface ILATTE {
  // LATTE specific functions
  function lock(address _account, uint256 _amount) external;
  function lockOf(address _account) external view returns (uint256); 
  function unlock() external;
  function mint(address _to, uint256 _amount) external;

  // Generic BEP20 functions
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBeanBag {
  // BEAN specific functions
  function safeLatteTransfer(address _account, uint256 _amount) external;
  function mint(address _to, uint256 _amount) external;
  function burn(address _from, uint256 _amount) external;
}

interface IMasterBarista {
  /// @dev functions return information. no states changed.
  function poolLength() external view returns (uint256);

  function pendingLatte(address _stakeToken, address _user) external view returns (uint256);

  function userInfo(address _stakeToken, address _user)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      address
    );

  function devAddr() external view returns (address);

  function devFeeBps() external view returns (uint256);

  /// @dev configuration functions
  function addPool(address _stakeToken, uint256 _allocPoint) external;

  function setPool(address _stakeToken, uint256 _allocPoint) external;

  function updatePool(address _stakeToken) external;

  function removePool(address _stakeToken) external;

  /// @dev user interaction functions
  function deposit(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function withdraw(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external;

  function depositLatte(address _for, uint256 _amount) external;

  function withdrawLatte(address _for, uint256 _amount) external;

  function harvest(address _for, address _stakeToken) external;

  function harvest(address _for, address[] calldata _stakeToken) external;

  function emergencyWithdraw(address _for, address _stakeToken) external;

  function mintExtraReward(
    address _stakeToken,
    address _to,
    uint256 _amount
  ) external;
}


interface IMasterBaristaCallback {
  function masterBaristaCall(
    address stakeToken,
    address userAddr,
    uint256 unboostedReward
  ) external;
}


/// @notice MasterBarista is a smart contract for distributing LATTE by asking user to stake the BEP20-based token.
contract MasterBarista is IMasterBarista, OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using LinkList for LinkList.List;
  using AddressUpgradeable for address;

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many Staking tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    uint256 bonusDebt; // Last block that user exec something to the pool.
    address fundedBy;
  }

  // Info of each pool.
  struct PoolInfo {
    uint256 allocPoint; // How many allocation points assigned to this pool.
    uint256 lastRewardBlock; // Last block number that LATTE distribution occurs.
    uint256 accLattePerShare; // Accumulated LATTE per share, times 1e12. See below.
    uint256 accLattePerShareTilBonusEnd; // Accumated LATTE per share until Bonus End.
    uint256 allocBps; // Pool allocation in BPS, if it's not a fixed bps pool, leave it 0
  }

  // LATTE token.
  ILATTE public latte;
  // BEAN token.
  IBeanBag public bean;
  // Dev address.
  address public override devAddr;
  uint256 public override devFeeBps;
  // LATTE per block.
  uint256 public lattePerBlock;
  // Bonus muliplier for early users.
  uint256 public bonusMultiplier;
  // Block number when bonus LATTE period ends.
  uint256 public bonusEndBlock;
  // Bonus lock-up in BPS
  uint256 public bonusLockUpBps;

  // Info of each pool.
  // PoolInfo[] public poolInfo;
  // Pool link list
  LinkList.List public pools;
  // Pool Info
  mapping(address => PoolInfo) public poolInfo;
  // Info of each user that stakes Staking tokens.
  mapping(address => mapping(address => UserInfo)) public override userInfo;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;
  // The block number when LATTE mining starts.
  uint256 public startBlock;

  // Does the pool allows some contracts to fund for an account
  mapping(address => bool) public stakeTokenCallerAllowancePool;

  // list of contracts that the pool allows to fund
  mapping(address => LinkList.List) public stakeTokenCallerContracts;

  event AddPool(address stakeToken, uint256 allocPoint, uint256 totalAllocPoint);
  event SetPool(address stakeToken, uint256 allocPoint, uint256 totalAllocPoint);
  event RemovePool(address stakeToken, uint256 allocPoint, uint256 totalAllocPoint);
  event Deposit(address indexed funder, address indexed fundee, address indexed stakeToken, uint256 amount);
  event Withdraw(address indexed funder, address indexed fundee, address indexed stakeToken, uint256 amount);
  event EmergencyWithdraw(address indexed user, address indexed stakeToken, uint256 amount);
  event BonusChanged(uint256 bonusMultiplier, uint256 bonusEndBlock, uint256 bonusLockUpBps);
  event PoolAllocChanged(address indexed pool, uint256 allocBps, uint256 allocPoint);
  event SetStakeTokenCallerAllowancePool(address indexed stakeToken, bool isAllowed);
  event AddStakeTokenCallerContract(address indexed stakeToken, address indexed caller);
  event RemoveStakeTokenCallerContract(address indexed stakeToken, address indexed caller);
  event MintExtraReward(address indexed sender, address indexed stakeToken, address indexed to, uint256 amount);

  /// @dev Initializer to create LatteMasterBarista instance + add pool(0)
  /// @param _latte The address of LATTE
  /// @param _devAddr The address that will LATTE dev fee
  /// @param _lattePerBlock The initial emission rate
  /// @param _startBlock The block that LATTE will start to release
  function initialize(
    ILATTE _latte,
    IBeanBag _bean,
    address _devAddr,
    uint256 _lattePerBlock,
    uint256 _startBlock
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    bonusMultiplier = 0;
    latte = _latte;
    bean = _bean;
    devAddr = _devAddr;
    devFeeBps = 1500;
    lattePerBlock = _lattePerBlock;
    startBlock = _startBlock;
    pools.init();

    // add LATTE->LATTE pool
    pools.add(address(_latte));
    poolInfo[address(_latte)] = PoolInfo({
      allocPoint: 1000,
      lastRewardBlock: startBlock,
      accLattePerShare: 0,
      accLattePerShareTilBonusEnd: 0,
      allocBps: 4000
    });
    totalAllocPoint = 1000;
  }

  /// @dev only permitted funder can continue the execution
  /// @dev eg. if a pool accepted funders, then msg.sender needs to be those funders, otherwise it will be reverted
  /// @dev --  if a pool doesn't accepted any funders, then msg.sender needs to be the one with beneficiary (eoa account)
  /// @param _beneficiary is an address this funder funding for
  /// @param _stakeToken a stake token
  modifier onlyPermittedTokenFunder(address _beneficiary, address _stakeToken) {
    require(_isFunder(_beneficiary, _stakeToken), "MasterBarista::onlyPermittedTokenFunder: caller is not permitted");
    _;
  }

  /// @notice only permitted funder can continue the execution
  /// @dev eg. if a pool accepted funders (from setStakeTokenCallerAllowancePool), then msg.sender needs to be those funders, otherwise it will be reverted
  /// @dev --  if a pool doesn't accepted any funders, then msg.sender needs to be the one with beneficiary (eoa account)
  /// @param _beneficiary is an address this funder funding for
  /// @param _stakeTokens a set of stake token (when doing batch)
  modifier onlyPermittedTokensFunder(address _beneficiary, address[] calldata _stakeTokens) {
    for (uint256 i = 0; i < _stakeTokens.length; i++) {
      require(
        _isFunder(_beneficiary, _stakeTokens[i]),
        "MasterBarista::onlyPermittedTokensFunder: caller is not permitted"
      );
    }
    _;
  }

  /// @dev only stake token caller contract can continue the execution (stakeTokenCaller must be a funder contract)
  /// @param _stakeToken a stakeToken to be validated
  modifier onlyStakeTokenCallerContract(address _stakeToken) {
    require(
      stakeTokenCallerContracts[_stakeToken].has(_msgSender()),
      "MasterBarista::onlyStakeTokenCallerContract: bad caller"
    );
    _;
  }

  /// @notice set funder allowance for a stake token pool
  /// @param _stakeToken a stake token to allow funder
  /// @param _isAllowed a parameter just like in doxygen (must be followed by parameter name)
  function setStakeTokenCallerAllowancePool(address _stakeToken, bool _isAllowed) external onlyOwner {
    stakeTokenCallerAllowancePool[_stakeToken] = _isAllowed;

    emit SetStakeTokenCallerAllowancePool(_stakeToken, _isAllowed);
  }

  /// @notice Setter function for adding stake token contract caller
  /// @param _stakeToken a pool for adding a corresponding stake token contract caller
  /// @param _caller a stake token contract caller
  function addStakeTokenCallerContract(address _stakeToken, address _caller) external onlyOwner {
    require(
      stakeTokenCallerAllowancePool[_stakeToken],
      "MasterBarista::addStakeTokenCallerContract: the pool doesn't allow a contract caller"
    );
    LinkList.List storage list = stakeTokenCallerContracts[_stakeToken];
    if (list.getNextOf(LinkList.start) == LinkList.empty) {
      list.init();
    }
    list.add(_caller);
    emit AddStakeTokenCallerContract(_stakeToken, _caller);
  }

  /// @notice Setter function for removing stake token contract caller
  /// @param _stakeToken a pool for removing a corresponding stake token contract caller
  /// @param _caller a stake token contract caller
  function removeStakeTokenCallerContract(address _stakeToken, address _caller) external onlyOwner {
    require(
      stakeTokenCallerAllowancePool[_stakeToken],
      "MasterBarista::removeStakeTokenCallerContract: the pool doesn't allow a contract caller"
    );
    LinkList.List storage list = stakeTokenCallerContracts[_stakeToken];
    list.remove(_caller, pools.getPreviousOf(_stakeToken));

    emit RemoveStakeTokenCallerContract(_stakeToken, _caller);
  }

  /// @dev Update dev address by the previous dev.
  /// @param _devAddr The new dev address
  function setDev(address _devAddr) external {
    require(_msgSender() == devAddr, "MasterBarista::setDev::only prev dev can changed dev address");
    devAddr = _devAddr;
  }

  /// @dev Set LATTE per block.
  /// @param _lattePerBlock The new emission rate for LATTE
  function setLattePerBlock(uint256 _lattePerBlock) external onlyOwner {
    massUpdatePools();
    lattePerBlock = _lattePerBlock;
  }

  /// @dev Set a specified pool's alloc BPS
  /// @param _allocBps The new alloc Bps
  /// @param _stakeToken pid
  function setPoolAllocBps(address _stakeToken, uint256 _allocBps) external onlyOwner {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPoolAllocBps::_stakeToken must not be address(0) or address(1)"
    );
    require(pools.has(_stakeToken), "MasterBarista::setPoolAllocBps::pool hasn't been set");
    address curr = pools.next[LinkList.start];
    uint256 accumAllocBps = 0;
    while (curr != LinkList.end) {
      if (poolInfo[curr].allocBps > 0) {
        accumAllocBps = accumAllocBps.add(poolInfo[curr].allocBps);
      }
      curr = pools.getNextOf(curr);
    }
    require(accumAllocBps.add(_allocBps) < 10000, "MasterBarista::setPoolallocBps::accumAllocBps must < 10000");
    massUpdatePools();
    poolInfo[_stakeToken].allocBps = _allocBps;
    updatePoolsAlloc();
  }

  /// @dev Set Bonus params. Bonus will start to accu on the next block that this function executed.
  /// @param _bonusMultiplier The new multiplier for bonus period.
  /// @param _bonusEndBlock The new end block for bonus period
  /// @param _bonusLockUpBps The new lock up in BPS
  function setBonus(
    uint256 _bonusMultiplier,
    uint256 _bonusEndBlock,
    uint256 _bonusLockUpBps
  ) external onlyOwner {
    require(_bonusEndBlock > block.number, "MasterBarista::setBonus::bad bonusEndBlock");
    require(_bonusMultiplier > 1, "MasterBarista::setBonus::bad bonusMultiplier");
    require(_bonusLockUpBps <= 10000, "MasterBarista::setBonus::bad bonusLockUpBps");

    massUpdatePools();

    bonusMultiplier = _bonusMultiplier;
    bonusEndBlock = _bonusEndBlock;
    bonusLockUpBps = _bonusLockUpBps;

    emit BonusChanged(bonusMultiplier, bonusEndBlock, bonusLockUpBps);
  }

  /// @dev Add a pool. Can only be called by the owner.
  /// @param _stakeToken The token that needed to be staked to earn LATTE.
  /// @param _allocPoint The allocation point of a new pool.
  function addPool(address _stakeToken, uint256 _allocPoint) external override onlyOwner {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::addPool::_stakeToken must not be address(0) or address(1)"
    );
    require(!pools.has(_stakeToken), "MasterBarista::addPool::_stakeToken duplicated");

    massUpdatePools();

    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    pools.add(_stakeToken);
    poolInfo[_stakeToken] = PoolInfo({
      allocPoint: _allocPoint,
      lastRewardBlock: lastRewardBlock,
      accLattePerShare: 0,
      accLattePerShareTilBonusEnd: 0,
      allocBps: 0
    });

    updatePoolsAlloc();

    emit AddPool(_stakeToken, _allocPoint, totalAllocPoint);
  }

  /// @dev Update the given pool's LATTE allocation point. Can only be called by the owner.
  /// @param _stakeToken The pool id to be updated
  /// @param _allocPoint The new allocPoint
  function setPool(address _stakeToken, uint256 _allocPoint) external override onlyOwner {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPool::_stakeToken must not be address(0) or address(1)"
    );
    require(pools.has(_stakeToken), "MasterBarista::setPool::_stakeToken not in the list");

    massUpdatePools();

    totalAllocPoint = totalAllocPoint.sub(poolInfo[_stakeToken].allocPoint).add(_allocPoint);
    uint256 prevAllocPoint = poolInfo[_stakeToken].allocPoint;
    poolInfo[_stakeToken].allocPoint = _allocPoint;

    if (prevAllocPoint != _allocPoint) {
      updatePoolsAlloc();
    }

    emit SetPool(_stakeToken, _allocPoint, totalAllocPoint);
  }

  /// @dev Remove pool. Can only be called by the owner.
  /// @param _stakeToken The stake token pool to be removed
  function removePool(address _stakeToken) external override onlyOwner {
    require(_stakeToken != address(latte), "MasterBarista::removePool::can't remove LATTE pool");
    require(pools.has(_stakeToken), "MasterBarista::removePool::pool not add yet");
    require(IERC20(_stakeToken).balanceOf(address(this)) == 0, "MasterBarista::removePool::pool not empty");

    massUpdatePools();

    totalAllocPoint = totalAllocPoint.sub(poolInfo[_stakeToken].allocPoint);

    pools.remove(_stakeToken, pools.getPreviousOf(_stakeToken));
    poolInfo[_stakeToken].allocPoint = 0;
    poolInfo[_stakeToken].lastRewardBlock = 0;
    poolInfo[_stakeToken].accLattePerShare = 0;
    poolInfo[_stakeToken].accLattePerShareTilBonusEnd = 0;
    poolInfo[_stakeToken].allocBps = 0;

    updatePoolsAlloc();

    emit RemovePool(_stakeToken, 0, totalAllocPoint);
  }

  /// @dev Update pools' alloc point
  function updatePoolsAlloc() internal {
    address curr = pools.next[LinkList.start];
    uint256 points = 0;
    uint256 accumAllocBps = 0;
    while (curr != LinkList.end) {
      if (poolInfo[curr].allocBps > 0) {
        accumAllocBps = accumAllocBps.add(poolInfo[curr].allocBps);
        curr = pools.getNextOf(curr);
        continue;
      }

      points = points.add(poolInfo[curr].allocPoint);
      curr = pools.getNextOf(curr);
    }

    // re-adjust an allocpoints for those pool having an allocBps
    if (points != 0) {
      _updatePoolAlloc(accumAllocBps, points);
    }
  }

  // @dev internal function for updating pool based on accumulated bps and points
  function _updatePoolAlloc(uint256 _accumAllocBps, uint256 _accumNonBpsPoolPoints) internal {
    // n = kp/(1-k),
    // where  k is accumAllocBps
    // p is sum of points of other pools
    address curr = pools.next[LinkList.start];
    uint256 num = _accumNonBpsPoolPoints.mul(_accumAllocBps);
    uint256 denom = uint256(10000).sub(_accumAllocBps);
    uint256 adjustedPoints = num.div(denom);
    uint256 poolPoints;
    while (curr != LinkList.end) {
      if (poolInfo[curr].allocBps == 0) {
        curr = pools.getNextOf(curr);
        continue;
      }
      poolPoints = adjustedPoints.mul(poolInfo[curr].allocBps).div(_accumAllocBps);
      totalAllocPoint = totalAllocPoint.sub(poolInfo[curr].allocPoint).add(poolPoints);
      poolInfo[curr].allocPoint = poolPoints;
      emit PoolAllocChanged(curr, poolInfo[curr].allocBps, poolPoints);
      curr = pools.getNextOf(curr);
    }
  }

  /// @dev Return the length of poolInfo
  function poolLength() external view override returns (uint256) {
    return pools.length();
  }

  /// @dev Return reward multiplier over the given _from to _to block.
  /// @param _lastRewardBlock The last block that rewards have been paid
  /// @param _currentBlock The current block
  function getMultiplier(uint256 _lastRewardBlock, uint256 _currentBlock) private view returns (uint256) {
    if (_currentBlock <= bonusEndBlock) {
      return _currentBlock.sub(_lastRewardBlock).mul(bonusMultiplier);
    }
    if (_lastRewardBlock >= bonusEndBlock) {
      return _currentBlock.sub(_lastRewardBlock);
    }
    // This is the case where bonusEndBlock is in the middle of _lastRewardBlock and _currentBlock block.
    return bonusEndBlock.sub(_lastRewardBlock).mul(bonusMultiplier).add(_currentBlock.sub(bonusEndBlock));
  }

  /// @notice validating if a msg sender is a funder
  /// @param _beneficiary if a stake token does't allow stake token contract caller, checking if a msg sender is the same with _beneficiary
  /// @param _stakeToken a stake token for checking a validity
  /// @return boolean result of validating if a msg sender is allowed to be a funder
  function _isFunder(address _beneficiary, address _stakeToken) internal view returns (bool) {
    if (stakeTokenCallerAllowancePool[_stakeToken]) return stakeTokenCallerContracts[_stakeToken].has(_msgSender());
    return _beneficiary == _msgSender();
  }

  /// @dev View function to see pending LATTEs on frontend.
  /// @param _stakeToken The stake token
  /// @param _user The address of a user
  function pendingLatte(address _stakeToken, address _user) external view override returns (uint256) {
    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_user];
    uint256 accLattePerShare = pool.accLattePerShare;
    uint256 totalStakeToken = IERC20(_stakeToken).balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && totalStakeToken != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 latteReward = multiplier.mul(lattePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
      accLattePerShare = accLattePerShare.add(latteReward.mul(1e12).div(totalStakeToken));
    }
    return user.amount.mul(accLattePerShare).div(1e12).sub(user.rewardDebt);
  }

  /// @dev Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    address curr = pools.next[LinkList.start];
    while (curr != LinkList.end) {
      updatePool(curr);
      curr = pools.getNextOf(curr);
    }
  }

  /// @dev Update reward variables of the given pool to be up-to-date.
  /// @param _stakeToken The stake token address of the pool to be updated
  function updatePool(address _stakeToken) public override {
    PoolInfo storage pool = poolInfo[_stakeToken];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 totalStakeToken = IERC20(_stakeToken).balanceOf(address(this));
    if (totalStakeToken == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 latteReward = multiplier.mul(lattePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
    latte.mint(devAddr, latteReward.mul(devFeeBps).div(10000));
    latte.mint(address(bean), latteReward);
    pool.accLattePerShare = pool.accLattePerShare.add(latteReward.mul(1e12).div(totalStakeToken));

    // Clear bonus & update accLattePerShareTilBonusEnd.
    if (block.number <= bonusEndBlock) {
      latte.lock(devAddr, latteReward.mul(bonusLockUpBps).mul(15).div(1000000));
      pool.accLattePerShareTilBonusEnd = pool.accLattePerShare;
    }
    if (block.number > bonusEndBlock && pool.lastRewardBlock < bonusEndBlock) {
      uint256 latteBonusPortion = bonusEndBlock
        .sub(pool.lastRewardBlock)
        .mul(bonusMultiplier)
        .mul(lattePerBlock)
        .mul(pool.allocPoint)
        .div(totalAllocPoint);
      latte.lock(devAddr, latteBonusPortion.mul(bonusLockUpBps).mul(15).div(1000000));
      pool.accLattePerShareTilBonusEnd = pool.accLattePerShareTilBonusEnd.add(
        latteBonusPortion.mul(1e12).div(totalStakeToken)
      );
    }

    pool.lastRewardBlock = block.number;
  }

  /// @dev Deposit token to get LATTE.
  /// @param _stakeToken The stake token to be deposited
  /// @param _amount The amount to be deposited
  function deposit(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external override onlyPermittedTokenFunder(_for, _stakeToken) nonReentrant {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPool::_stakeToken must not be address(0) or address(1)"
    );
    require(_stakeToken != address(latte), "MasterBarista::deposit::use depositLatte instead");
    require(pools.has(_stakeToken), "MasterBarista::deposit::no pool");

    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    if (user.fundedBy != address(0)) require(user.fundedBy == _msgSender(), "MasterBarista::deposit::bad sof");

    updatePool(_stakeToken);

    if (user.amount > 0) _harvest(_for, _stakeToken);
    if (user.fundedBy == address(0)) user.fundedBy = _msgSender();
    if (_amount > 0) {
      IERC20(_stakeToken).safeTransferFrom(address(_msgSender()), address(this), _amount);
      user.amount = user.amount.add(_amount);
    }

    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);

    emit Deposit(_msgSender(), _for, _stakeToken, _amount);
  }

  /// @dev Withdraw token from LatteMasterBarista.
  /// @param _stakeToken The token to be withdrawn
  /// @param _amount The amount to be withdrew
  function withdraw(
    address _for,
    address _stakeToken,
    uint256 _amount
  ) external override nonReentrant {
    require(
      _stakeToken != address(0) && _stakeToken != address(1),
      "MasterBarista::setPool::_stakeToken must not be address(0) or address(1)"
    );
    require(_stakeToken != address(latte), "MasterBarista::withdraw::use withdrawLatte instead");
    require(pools.has(_stakeToken), "MasterBarista::withdraw::no pool");

    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    require(user.fundedBy == _msgSender(), "MasterBarista::withdraw::only funder");
    require(user.amount >= _amount, "MasterBarista::withdraw::not good");

    updatePool(_stakeToken);
    _harvest(_for, _stakeToken);

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
    if (user.amount == 0) user.fundedBy = address(0);
    IERC20(_stakeToken).safeTransfer(_msgSender(), _amount);

    emit Withdraw(_msgSender(), _for, _stakeToken, user.amount);
  }

  /// @dev Deposit LATTE to get even more LATTE.
  /// @param _amount The amount to be deposited
  function depositLatte(address _for, uint256 _amount)
    external
    override
    onlyPermittedTokenFunder(_for, address(latte))
    nonReentrant
  {
    PoolInfo storage pool = poolInfo[address(latte)];
    UserInfo storage user = userInfo[address(latte)][_for];

    if (user.fundedBy != address(0)) require(user.fundedBy == _msgSender(), "MasterBarista::depositLatte::bad sof");

    updatePool(address(latte));

    if (user.amount > 0) _harvest(_for, address(latte));
    if (user.fundedBy == address(0)) user.fundedBy = _msgSender();
    if (_amount > 0) {
      IERC20(address(latte)).safeTransferFrom(address(_msgSender()), address(this), _amount);
      user.amount = user.amount.add(_amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);

    bean.mint(_for, _amount);

    emit Deposit(_msgSender(), _for, address(latte), _amount);
  }

  /// @dev Withdraw LATTE
  /// @param _amount The amount to be withdrawn
  function withdrawLatte(address _for, uint256 _amount) external override nonReentrant {
    PoolInfo storage pool = poolInfo[address(latte)];
    UserInfo storage user = userInfo[address(latte)][_for];

    require(user.fundedBy == _msgSender(), "MasterBarista::withdrawLatte::only funder");
    require(user.amount >= _amount, "MasterBarista::withdrawLatte::not good");

    updatePool(address(latte));
    _harvest(_for, address(latte));

    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      IERC20(address(latte)).safeTransfer(address(_msgSender()), _amount);
    }
    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
    if (user.amount == 0) user.fundedBy = address(0);

    bean.burn(_for, _amount);

    emit Withdraw(_msgSender(), _for, address(latte), user.amount);
  }

  /// @dev Harvest LATTE earned from a specific pool.
  /// @param _stakeToken The pool's stake token
  function harvest(address _for, address _stakeToken) external override nonReentrant {
    PoolInfo storage pool = poolInfo[_stakeToken];
    UserInfo storage user = userInfo[_stakeToken][_for];

    updatePool(_stakeToken);
    _harvest(_for, _stakeToken);

    user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
    user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
  }

  /// @dev Harvest LATTE earned from pools.
  /// @param _stakeTokens The list of pool's stake token to be harvested
  function harvest(address _for, address[] calldata _stakeTokens) external override nonReentrant {
    for (uint256 i = 0; i < _stakeTokens.length; i++) {
      PoolInfo storage pool = poolInfo[_stakeTokens[i]];
      UserInfo storage user = userInfo[_stakeTokens[i]][_for];
      updatePool(_stakeTokens[i]);
      _harvest(_for, _stakeTokens[i]);
      user.rewardDebt = user.amount.mul(pool.accLattePerShare).div(1e12);
      user.bonusDebt = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12);
    }
  }

  /// @dev Internal function to harvest LATTE
  /// @param _for The beneficiary address
  /// @param _stakeToken The pool's stake token
  function _harvest(address _for, address _stakeToken) internal {
    PoolInfo memory pool = poolInfo[_stakeToken];
    UserInfo memory user = userInfo[_stakeToken][_for];
    require(user.fundedBy == _msgSender(), "MasterBarista::_harvest::only funder");
    require(user.amount > 0, "MasterBarista::_harvest::nothing to harvest");
    uint256 pending = user.amount.mul(pool.accLattePerShare).div(1e12).sub(user.rewardDebt);
    require(pending <= latte.balanceOf(address(bean)), "MasterBarista::_harvest::wait what.. not enough LATTE");
    uint256 bonus = user.amount.mul(pool.accLattePerShareTilBonusEnd).div(1e12).sub(user.bonusDebt);

    bean.safeLatteTransfer(_for, pending);
    if (stakeTokenCallerContracts[_stakeToken].has(_msgSender())) {
      _masterBaristaCallee(_msgSender(), _stakeToken, _for, pending);
    }
    latte.lock(_for, bonus.mul(bonusLockUpBps).div(10000));
  }

  /// @dev Observer function for those contract implementing onBeforeLock, execute an onBeforelock statement
  /// @param _caller that perhaps implement an onBeforeLock observing function
  /// @param _stakeToken parameter for sending a staoke token
  /// @param _for the user this callback will be used
  /// @param _pending pending amount
  function _masterBaristaCallee(
    address _caller,
    address _stakeToken,
    address _for,
    uint256 _pending
  ) internal {
    if (!_caller.isContract()) {
      return;
    }
    (bool success, ) = _caller.call(
      abi.encodeWithSelector(IMasterBaristaCallback.masterBaristaCall.selector, _stakeToken, _for, _pending)
    );
    require(success, "MasterBarista::_masterBaristaCallee:: failed to execute masterBaristaCall");
  }

  /// @dev Withdraw without caring about rewards. EMERGENCY ONLY.
  /// @param _for if the msg sender is a funder, can emergency withdraw a fundee
  /// @param _stakeToken The pool's stake token
  function emergencyWithdraw(address _for, address _stakeToken) external override nonReentrant {
    UserInfo storage user = userInfo[_stakeToken][_for];
    require(user.fundedBy == _msgSender(), "MasterBarista::emergencyWithdraw::only funder");
    IERC20(_stakeToken).safeTransfer(address(_for), user.amount);

    emit EmergencyWithdraw(_for, _stakeToken, user.amount);

    // Burn BEAN if user emergencyWithdraw LATTE
    if (_stakeToken == address(latte)) {
      bean.burn(_msgSender(), user.amount);
    }

    // Reset user info
    user.amount = 0;
    user.rewardDebt = 0;
    user.bonusDebt = 0;
    user.fundedBy = address(0);
  }

  /// @dev This is a function for mining an extra amount of latte, should be called only by stake token caller contract (boosting purposed)
  /// @param _stakeToken a stake token address for validating a msg sender
  /// @param _amount amount to be minted
  function mintExtraReward(
    address _stakeToken,
    address _to,
    uint256 _amount
  ) external override onlyStakeTokenCallerContract(_stakeToken) {
    latte.mint(_to, _amount);
    latte.mint(devAddr, _amount.mul(devFeeBps).div(1e4));

    emit MintExtraReward(_msgSender(), _stakeToken, _to, _amount);
  }
}