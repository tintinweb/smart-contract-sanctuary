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

pragma solidity ^0.7.0;

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
import "../proxy/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    function _pause() internal virtual whenNotPaused {
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
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

/**
 * Based on https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0-solc-0.7/contracts/access/OwnableUpgradeable.sol
 *
 * Changes:
 * - Added owner argument to initializer
 * - Reformatted styling in line with this repository.
 */

/*
The MIT License (MIT)

Copyright (c) 2016-2020 zOS Global Limited

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/* solhint-disable func-name-mixedcase */

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

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

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	function __Ownable_init(address owner_) internal initializer {
		__Context_init_unchained();
		__Ownable_init_unchained(owner_);
	}

	function __Ownable_init_unchained(address owner_) internal initializer {
		_owner = owner_;
		emit OwnershipTransferred(address(0), owner_);
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

// SPDX-License-Identifier: MIT

/**
 * Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0-solc-0.7/contracts/utils/EnumerableMap.sol
 *
 * Changes:
 * - Replaced UintToAddressMap with AddressToUintMap
 * - Reformatted styling in line with this repository.
 */

/*
The MIT License (MIT)

Copyright (c) 2016-2020 zOS Global Limited

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity 0.7.6;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
	// To implement this library for multiple types with as little code
	// repetition as possible, we write it in terms of a generic Map type with
	// bytes32 keys and values.
	// The Map implementation uses private functions, and user-facing
	// implementations (such as Uint256ToAddressMap) are just wrappers around
	// the underlying Map.
	// This means that we can only create new EnumerableMaps for types that fit
	// in bytes32.

	struct MapEntry {
		bytes32 _key;
		bytes32 _value;
	}

	struct Map {
		// Storage of map keys and values
		MapEntry[] _entries;
		// Position of the entry defined by a key in the `entries` array, plus 1
		// because index 0 means a key is not in the map.
		mapping(bytes32 => uint256) _indexes;
	}

	/**
	 * @dev Adds a key-value pair to a map, or updates the value for an existing
	 * key. O(1).
	 *
	 * Returns true if the key was added to the map, that is if it was not
	 * already present.
	 */
	function _set(
		Map storage map,
		bytes32 key,
		bytes32 value
	) private returns (bool) {
		// We read and store the key's index to prevent multiple reads from the same storage slot
		uint256 keyIndex = map._indexes[key];

		// Equivalent to !contains(map, key)
		if (keyIndex == 0) {
			map._entries.push(MapEntry({ _key: key, _value: value }));
			// The entry is stored at length-1, but we add 1 to all indexes
			// and use 0 as a sentinel value
			map._indexes[key] = map._entries.length;
			return true;
		} else {
			map._entries[keyIndex - 1]._value = value;
			return false;
		}
	}

	/**
	 * @dev Removes a key-value pair from a map. O(1).
	 *
	 * Returns true if the key was removed from the map, that is if it was present.
	 */
	function _remove(Map storage map, bytes32 key) private returns (bool) {
		// We read and store the key's index to prevent multiple reads from the same storage slot
		uint256 keyIndex = map._indexes[key];

		// Equivalent to contains(map, key)
		if (keyIndex != 0) {
			// To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
			// in the array, and then remove the last entry (sometimes called as 'swap and pop').
			// This modifies the order of the array, as noted in {at}.

			uint256 toDeleteIndex = keyIndex - 1;
			uint256 lastIndex = map._entries.length - 1;

			// When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
			// so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

			MapEntry storage lastEntry = map._entries[lastIndex];

			// Move the last entry to the index where the entry to delete is
			map._entries[toDeleteIndex] = lastEntry;
			// Update the index for the moved entry
			map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

			// Delete the slot where the moved entry was stored
			map._entries.pop();

			// Delete the index for the deleted slot
			delete map._indexes[key];

			return true;
		} else {
			return false;
		}
	}

	/**
	 * @dev Returns true if the key is in the map. O(1).
	 */
	function _contains(Map storage map, bytes32 key)
		private
		view
		returns (bool)
	{
		return map._indexes[key] != 0;
	}

	/**
	 * @dev Returns the number of key-value pairs in the map. O(1).
	 */
	function _length(Map storage map) private view returns (uint256) {
		return map._entries.length;
	}

	/**
	 * @dev Returns the key-value pair stored at position `index` in the map. O(1).
	 *
	 * Note that there are no guarantees on the ordering of entries inside the
	 * array, and it may change when more entries are added or removed.
	 *
	 * Requirements:
	 *
	 * - `index` must be strictly less than {length}.
	 */
	function _at(Map storage map, uint256 index)
		private
		view
		returns (bytes32, bytes32)
	{
		require(map._entries.length > index, "EnumerableMap: index out of bounds");

		MapEntry storage entry = map._entries[index];
		return (entry._key, entry._value);
	}

	/**
	 * @dev Returns the value associated with `key`.  O(1).
	 *
	 * Requirements:
	 *
	 * - `key` must be in the map.
	 */
	function _get(Map storage map, bytes32 key) private view returns (bytes32) {
		return _get(map, key, "EnumerableMap: nonexistent key");
	}

	/**
	 * @dev Same as {_get}, with a custom error message when `key` is not in the map.
	 */
	function _get(
		Map storage map,
		bytes32 key,
		string memory errorMessage
	) private view returns (bytes32) {
		uint256 keyIndex = map._indexes[key];
		require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
		return map._entries[keyIndex - 1]._value; // All indexes are 1-based
	}

	// AddressToUintMap

	struct AddressToUintMap {
		Map _inner;
	}

	/**
	 * @dev Adds a key-value pair to a map, or updates the value for an existing
	 * key. O(1).
	 *
	 * Returns true if the key was added to the map, that is if it was not
	 * already present.
	 */
	function set(
		AddressToUintMap storage map,
		address key,
		uint256 value
	) internal returns (bool) {
		return _set(map._inner, bytes32(uint256(key)), bytes32(value));
	}

	/**
	 * @dev Removes a value from a set. O(1).
	 *
	 * Returns true if the key was removed from the map, that is if it was present.
	 */
	function remove(AddressToUintMap storage map, address key)
		internal
		returns (bool)
	{
		return _remove(map._inner, bytes32(uint256(key)));
	}

	/**
	 * @dev Returns true if the key is in the map. O(1).
	 */
	function contains(AddressToUintMap storage map, address key)
		internal
		view
		returns (bool)
	{
		return _contains(map._inner, bytes32(uint256(key)));
	}

	/**
	 * @dev Returns the number of elements in the map. O(1).
	 */
	function length(AddressToUintMap storage map)
		internal
		view
		returns (uint256)
	{
		return _length(map._inner);
	}

	/**
	 * @dev Returns the element stored at position `index` in the set. O(1).
	 * Note that there are no guarantees on the ordering of values inside the
	 * array, and it may change when more values are added or removed.
	 *
	 * Requirements:
	 *
	 * - `index` must be strictly less than {length}.
	 */
	function at(AddressToUintMap storage map, uint256 index)
		internal
		view
		returns (address, uint256)
	{
		(bytes32 key, bytes32 value) = _at(map._inner, index);
		return (address(uint256(key)), uint256(value));
	}

	/**
	 * @dev Returns the value associated with `key`.  O(1).
	 *
	 * Requirements:
	 *
	 * - `key` must be in the map.
	 */
	function get(AddressToUintMap storage map, address key)
		internal
		view
		returns (uint256)
	{
		return uint256(_get(map._inner, bytes32(uint256(key))));
	}

	/**
	 * @dev Same as {get}, with a custom error message when `key` is not in the map.
	 */
	function get(
		AddressToUintMap storage map,
		address key,
		string memory errorMessage
	) internal view returns (uint256) {
		return uint256(_get(map._inner, bytes32(uint256(key)), errorMessage));
	}
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Copyright 2021 weiWard LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./LPRewardsData.sol";
import "../../libraries/EnumerableMap.sol";
import "../interfaces/ILPRewards.sol";
import "../interfaces/IValuePerToken.sol";
import "../../tokens/interfaces/IWETH.sol";
import "../../access/OwnableUpgradeable.sol";

contract LPRewards is
	Initializable,
	ContextUpgradeable,
	OwnableUpgradeable,
	PausableUpgradeable,
	LPRewardsData,
	ILPRewards
{
	using Address for address payable;
	using EnumerableMap for EnumerableMap.AddressToUintMap;
	using EnumerableSet for EnumerableSet.AddressSet;
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	/* Immutable Internal State */

	uint256 internal constant _MULTIPLIER = 1e36;

	/* Constructor */

	constructor(address owner_) {
		init(owner_);
	}

	/* Initializers */

	function init(address owner_) public virtual initializer {
		__Context_init_unchained();
		__Ownable_init_unchained(owner_);
		__Pausable_init_unchained();
	}

	/* Fallbacks */

	receive() external payable {
		// Only accept ETH via fallback from the WETH contract
		require(msg.sender == _rewardsToken);
	}

	/* Modifiers */

	modifier supportsToken(address token) {
		require(supportsStakingToken(token), "LPRewards: unsupported token");
		_;
	}

	/* Public Views */

	function accruedRewardsPerTokenFor(address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _tokenData[token].arpt;
	}

	function accruedRewardsPerTokenLastFor(address account, address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _users[account].rewardsFor[token].arptLast;
	}

	function lastRewardsBalanceOf(address account)
		public
		view
		virtual
		override
		returns (uint256 total)
	{
		UserData storage user = _users[account];
		EnumerableSet.AddressSet storage tokens = user.tokensWithRewards;
		for (uint256 i = 0; i < tokens.length(); i++) {
			total += user.rewardsFor[tokens.at(i)].pending;
		}
	}

	function lastRewardsBalanceOfFor(address account, address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _users[account].rewardsFor[token].pending;
	}

	function lastTotalRewardsAccrued()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _lastTotalRewardsAccrued;
	}

	function lastTotalRewardsAccruedFor(address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _tokenData[token].lastRewardsAccrued;
	}

	function numStakingTokens()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _tokens.length();
	}

	function rewardsBalanceOf(address account)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return lastRewardsBalanceOf(account) + _allPendingRewardsFor(account);
	}

	function rewardsBalanceOfFor(address account, address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		uint256 rewards = lastRewardsBalanceOfFor(account, token);
		uint256 amountStaked = stakedBalanceOf(account, token);
		if (amountStaked != 0) {
			rewards += _pendingRewardsFor(account, token, amountStaked);
		}
		return rewards;
	}

	function rewardsForToken(address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _tokenData[token].rewards;
	}

	function rewardsToken() public view virtual override returns (address) {
		return _rewardsToken;
	}

	function sharesFor(address account, address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _shares(token, stakedBalanceOf(account, token));
	}

	function sharesPerToken(address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _shares(token, 1e18);
	}

	function stakedBalanceOf(address account, address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		EnumerableMap.AddressToUintMap storage staked = _users[account].staked;
		if (staked.contains(token)) {
			return staked.get(token);
		}
		return 0;
	}

	function stakingTokenAt(uint256 index)
		external
		view
		virtual
		override
		returns (address)
	{
		return _tokens.at(index);
	}

	function supportsStakingToken(address token)
		public
		view
		virtual
		override
		returns (bool)
	{
		return _tokens.contains(token);
	}

	function totalRewardsAccrued()
		public
		view
		virtual
		override
		returns (uint256)
	{
		// Overflow is OK
		return _currentRewardsBalance() + _totalRewardsRedeemed;
	}

	function totalRewardsAccruedFor(address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		TokenData storage td = _tokenData[token];
		// Overflow is OK
		return td.rewards + td.rewardsRedeemed;
	}

	function totalRewardsRedeemed()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _totalRewardsRedeemed;
	}

	function totalRewardsRedeemedFor(address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _tokenData[token].rewardsRedeemed;
	}

	function totalShares()
		external
		view
		virtual
		override
		returns (uint256 total)
	{
		for (uint256 i = 0; i < _tokens.length(); i++) {
			total = total.add(_totalSharesForToken(_tokens.at(i)));
		}
	}

	function totalSharesFor(address account)
		external
		view
		virtual
		override
		returns (uint256 total)
	{
		EnumerableMap.AddressToUintMap storage staked = _users[account].staked;
		for (uint256 i = 0; i < staked.length(); i++) {
			(address token, uint256 amount) = staked.at(i);
			total = total.add(_shares(token, amount));
		}
	}

	function totalSharesForToken(address token)
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _totalSharesForToken(token);
	}

	function totalStaked(address token)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _tokenData[token].totalStaked;
	}

	function unredeemableRewards()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _unredeemableRewards;
	}

	function valuePerTokenImpl(address token)
		public
		view
		virtual
		override
		returns (address)
	{
		return _tokenData[token].valueImpl;
	}

	/* Public Mutators */

	function addToken(address token, address tokenValueImpl)
		external
		virtual
		override
		onlyOwner
	{
		require(!supportsStakingToken(token), "LPRewards: token already added");
		require(
			tokenValueImpl != address(0),
			"LPRewards: tokenValueImpl cannot be zero address"
		);
		_tokens.add(token);
		// Only update implementation in case this was previously used and removed
		_tokenData[token].valueImpl = tokenValueImpl;
		emit TokenAdded(_msgSender(), token, tokenValueImpl);
	}

	function changeTokenValueImpl(address token, address tokenValueImpl)
		external
		virtual
		override
		onlyOwner
		supportsToken(token)
	{
		require(
			tokenValueImpl != address(0),
			"LPRewards: tokenValueImpl cannot be zero address"
		);
		_tokenData[token].valueImpl = tokenValueImpl;
		emit TokenValueImplChanged(_msgSender(), token, tokenValueImpl);
	}

	function exit(bool asWETH) external virtual override {
		unstakeAll();
		redeemAllRewards(asWETH);
	}

	function exitFrom(address token, bool asWETH) external virtual override {
		unstakeAllFrom(token);
		redeemAllRewardsFrom(token, asWETH);
	}

	function pause() external virtual override onlyOwner {
		_pause();
	}

	function recoverUnredeemableRewards(address to, uint256 amount)
		external
		virtual
		override
		onlyOwner
	{
		require(
			amount <= _unredeemableRewards,
			"LPRewards: recovery amount > unredeemable"
		);
		_unredeemableRewards -= amount;
		IERC20(_rewardsToken).safeTransfer(to, amount);
		emit RecoveredUnredeemableRewards(_msgSender(), to, amount);
	}

	function recoverUnstaked(
		address token,
		address to,
		uint256 amount
	) external virtual override onlyOwner {
		require(token != _rewardsToken, "LPRewards: cannot recover rewardsToken");

		uint256 unstaked =
			IERC20(token).balanceOf(address(this)).sub(totalStaked(token));

		require(amount <= unstaked, "LPRewards: recovery amount > unstaked");

		IERC20(token).safeTransfer(to, amount);
		emit RecoveredUnstaked(_msgSender(), token, to, amount);
	}

	function redeemAllRewards(bool asWETH) public virtual override {
		address account = _msgSender();
		_updateAllRewardsFor(account);

		UserData storage user = _users[account];
		EnumerableSet.AddressSet storage tokens = user.tokensWithRewards;
		uint256 redemption = 0;

		for (uint256 length = tokens.length(); length > 0; length--) {
			address token = tokens.at(0);
			TokenData storage td = _tokenData[token];
			UserTokenRewards storage rewards = user.rewardsFor[token];
			uint256 pending = rewards.pending; // Save gas

			redemption += pending;

			rewards.pending = 0;

			td.rewards = td.rewards.sub(pending);
			td.rewardsRedeemed += pending;

			emit RewardPaid(account, token, pending);
			tokens.remove(token);
		}

		_totalRewardsRedeemed += redemption;

		_sendRewards(account, redemption, asWETH);
	}

	function redeemAllRewardsFrom(address token, bool asWETH)
		public
		virtual
		override
	{
		address account = _msgSender();
		_updateRewardFor(account, token);
		uint256 pending = _users[account].rewardsFor[token].pending;
		if (pending != 0) {
			_redeemRewardFrom(token, pending, asWETH);
		}
	}

	function redeemReward(uint256 amount, bool asWETH)
		external
		virtual
		override
	{
		require(amount != 0, "LPRewards: cannot redeem zero");
		address account = _msgSender();
		_updateAllRewardsFor(account);
		require(
			amount <= lastRewardsBalanceOf(account),
			"LPRewards: cannot redeem more rewards than earned"
		);

		UserData storage user = _users[account];
		EnumerableSet.AddressSet storage tokens = user.tokensWithRewards;
		uint256 amountLeft = amount;

		for (uint256 length = tokens.length(); length > 0; length--) {
			address token = tokens.at(0);
			TokenData storage td = _tokenData[token];
			UserTokenRewards storage rewards = user.rewardsFor[token];

			uint256 pending = rewards.pending; // Save gas
			uint256 taken = 0;
			if (pending <= amountLeft) {
				taken = pending;
				tokens.remove(token);
			} else {
				taken = amountLeft;
			}

			rewards.pending = pending - taken;

			td.rewards = td.rewards.sub(taken);
			td.rewardsRedeemed += taken;

			amountLeft -= taken;

			emit RewardPaid(account, token, taken);

			if (amountLeft == 0) {
				break;
			}
		}

		_totalRewardsRedeemed += amount;

		_sendRewards(account, amount, asWETH);
	}

	function redeemRewardFrom(
		address token,
		uint256 amount,
		bool asWETH
	) external virtual override {
		require(amount != 0, "LPRewards: cannot redeem zero");
		address account = _msgSender();
		_updateRewardFor(account, token);
		require(
			amount <= _users[account].rewardsFor[token].pending,
			"LPRewards: cannot redeem more rewards than earned"
		);
		_redeemRewardFrom(token, amount, asWETH);
	}

	function removeToken(address token)
		external
		virtual
		override
		onlyOwner
		supportsToken(token)
	{
		_tokens.remove(token);
		// Clean up. Keep totalStaked and rewards since those will be cleaned up by
		// users unstaking and redeeming.
		_tokenData[token].valueImpl = address(0);
		emit TokenRemoved(_msgSender(), token);
	}

	function setRewardsToken(address token) public virtual override onlyOwner {
		_rewardsToken = token;
		emit RewardsTokenSet(_msgSender(), token);
	}

	function stake(address token, uint256 amount)
		external
		virtual
		override
		whenNotPaused
		supportsToken(token)
	{
		require(amount != 0, "LPRewards: cannot stake zero");

		address account = _msgSender();
		_updateRewardFor(account, token);

		UserData storage user = _users[account];
		TokenData storage td = _tokenData[token];
		td.totalStaked += amount;
		user.staked.set(token, amount + stakedBalanceOf(account, token));

		IERC20(token).safeTransferFrom(account, address(this), amount);
		emit Staked(account, token, amount);
	}

	function unpause() external virtual override onlyOwner {
		_unpause();
	}

	function unstake(address token, uint256 amount) external virtual override {
		require(amount != 0, "LPRewards: cannot unstake zero");

		address account = _msgSender();
		// Prevent making calls to any addresses that were never supported.
		uint256 staked = stakedBalanceOf(account, token);
		require(
			amount <= staked,
			"LPRewards: cannot unstake more than staked balance"
		);

		_unstake(token, amount);
	}

	function unstakeAll() public virtual override {
		UserData storage user = _users[_msgSender()];
		for (uint256 length = user.staked.length(); length > 0; length--) {
			(address token, uint256 amount) = user.staked.at(0);
			_unstake(token, amount);
		}
	}

	function unstakeAllFrom(address token) public virtual override {
		_unstake(token, stakedBalanceOf(_msgSender(), token));
	}

	function updateAccrual() external virtual override {
		// Gas savings
		uint256 totalRewardsAccrued_ = totalRewardsAccrued();
		uint256 pending = totalRewardsAccrued_ - _lastTotalRewardsAccrued;
		if (pending == 0) {
			return;
		}

		_lastTotalRewardsAccrued = totalRewardsAccrued_;

		// Iterate once to know totalShares
		uint256 totalShares_ = 0;
		// Store some math for current shares to save on gas and revert ASAP.
		uint256[] memory pendingSharesFor = new uint256[](_tokens.length());
		for (uint256 i = 0; i < _tokens.length(); i++) {
			uint256 share = _totalSharesForToken(_tokens.at(i));
			pendingSharesFor[i] = pending.mul(share);
			totalShares_ = totalShares_.add(share);
		}

		if (totalShares_ == 0) {
			_unredeemableRewards = _unredeemableRewards.add(pending);
			emit AccrualUpdated(_msgSender(), pending);
			return;
		}

		// Iterate twice to allocate rewards to each token.
		for (uint256 i = 0; i < _tokens.length(); i++) {
			address token = _tokens.at(i);
			TokenData storage td = _tokenData[token];
			td.rewards += pendingSharesFor[i] / totalShares_;
			uint256 rewardsAccrued = totalRewardsAccruedFor(token);
			td.arpt = _accruedRewardsPerTokenFor(token, rewardsAccrued);
			td.lastRewardsAccrued = rewardsAccrued;
		}

		emit AccrualUpdated(_msgSender(), pending);
	}

	function updateReward() external virtual override {
		_updateAllRewardsFor(_msgSender());
	}

	function updateRewardFor(address token) external virtual override {
		_updateRewardFor(_msgSender(), token);
	}

	/* Internal Views */

	function _accruedRewardsPerTokenFor(address token, uint256 rewardsAccrued)
		internal
		view
		virtual
		returns (uint256)
	{
		TokenData storage td = _tokenData[token];
		// Gas savings
		uint256 totalStaked_ = td.totalStaked;

		if (totalStaked_ == 0) {
			return td.arpt;
		}

		// Overflow is OK
		uint256 delta = rewardsAccrued - td.lastRewardsAccrued;
		if (delta == 0) {
			return td.arpt;
		}

		// Use multiplier for better rounding
		uint256 rewardsPerToken = delta.mul(_MULTIPLIER) / totalStaked_;

		// Overflow is OK
		return td.arpt + rewardsPerToken;
	}

	function _allPendingRewardsFor(address account)
		internal
		view
		virtual
		returns (uint256 total)
	{
		EnumerableMap.AddressToUintMap storage staked = _users[account].staked;
		for (uint256 i = 0; i < staked.length(); i++) {
			(address token, uint256 amount) = staked.at(i);
			total += _pendingRewardsFor(account, token, amount);
		}
	}

	function _currentRewardsBalance() internal view virtual returns (uint256) {
		return IERC20(_rewardsToken).balanceOf(address(this));
	}

	function _pendingRewardsFor(
		address account,
		address token,
		uint256 amountStaked
	) internal view virtual returns (uint256) {
		uint256 arpt = accruedRewardsPerTokenFor(token);
		uint256 arptLast = accruedRewardsPerTokenLastFor(account, token);
		// Overflow is OK
		uint256 arptDelta = arpt - arptLast;

		return amountStaked.mul(arptDelta) / _MULTIPLIER;
	}

	function _shares(address token, uint256 amountStaked)
		internal
		view
		virtual
		returns (uint256)
	{
		if (!supportsStakingToken(token)) {
			return 0;
		}
		IValuePerToken vptHandle = IValuePerToken(valuePerTokenImpl(token));
		(uint256 numerator, uint256 denominator) = vptHandle.valuePerToken();
		if (denominator == 0) {
			return 0;
		}
		// Return a 1:1 ratio for value to shares
		return amountStaked.mul(numerator) / denominator;
	}

	function _totalSharesForToken(address token)
		internal
		view
		virtual
		returns (uint256)
	{
		return _shares(token, _tokenData[token].totalStaked);
	}

	/* Internal Mutators */

	function _redeemRewardFrom(
		address token,
		uint256 amount,
		bool asWETH
	) internal virtual {
		address account = _msgSender();
		UserData storage user = _users[account];
		UserTokenRewards storage rewards = user.rewardsFor[token];
		TokenData storage td = _tokenData[token];
		uint256 rewardLeft = rewards.pending - amount;

		rewards.pending = rewardLeft;
		if (rewardLeft == 0) {
			user.tokensWithRewards.remove(token);
		}

		td.rewards = td.rewards.sub(amount);
		td.rewardsRedeemed += amount;

		_totalRewardsRedeemed += amount;

		_sendRewards(account, amount, asWETH);
		emit RewardPaid(account, token, amount);
	}

	function _sendRewards(
		address to,
		uint256 amount,
		bool asWETH
	) internal virtual {
		if (asWETH) {
			IERC20(_rewardsToken).safeTransfer(to, amount);
		} else {
			IWETH(_rewardsToken).withdraw(amount);
			payable(to).sendValue(amount);
		}
	}

	function _unstake(address token, uint256 amount) internal virtual {
		address account = _msgSender();

		_updateRewardFor(account, token);

		TokenData storage td = _tokenData[token];
		td.totalStaked = td.totalStaked.sub(amount);

		UserData storage user = _users[account];
		EnumerableMap.AddressToUintMap storage staked = user.staked;

		uint256 stakeLeft = staked.get(token).sub(amount);
		if (stakeLeft == 0) {
			staked.remove(token);
			user.rewardsFor[token].arptLast = 0;
		} else {
			staked.set(token, stakeLeft);
		}

		IERC20(token).safeTransfer(account, amount);
		emit Unstaked(account, token, amount);
	}

	function _updateRewardFor(address account, address token)
		internal
		virtual
		returns (uint256)
	{
		UserData storage user = _users[account];
		UserTokenRewards storage rewards = user.rewardsFor[token];
		uint256 total = rewards.pending; // Save gas
		uint256 amountStaked = stakedBalanceOf(account, token);
		uint256 pending = _pendingRewardsFor(account, token, amountStaked);
		if (pending != 0) {
			total += pending;
			rewards.pending = total;
			user.tokensWithRewards.add(token);
		}
		rewards.arptLast = accruedRewardsPerTokenFor(token);
		return total;
	}

	function _updateAllRewardsFor(address account) internal virtual {
		EnumerableMap.AddressToUintMap storage staked = _users[account].staked;
		for (uint256 i = 0; i < staked.length(); i++) {
			(address token, ) = staked.at(i);
			_updateRewardFor(account, token);
		}
	}
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Copyright 2021 weiWard LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "../../libraries/EnumerableMap.sol";

abstract contract LPRewardsData {
	/* Structs */

	struct TokenData {
		uint256 arpt;
		uint256 lastRewardsAccrued;
		uint256 rewards;
		uint256 rewardsRedeemed;
		uint256 totalStaked;
		address valueImpl;
	}

	struct UserTokenRewards {
		uint256 pending;
		uint256 arptLast;
	}

	struct UserData {
		EnumerableSet.AddressSet tokensWithRewards;
		mapping(address => UserTokenRewards) rewardsFor;
		EnumerableMap.AddressToUintMap staked;
	}

	/* State */

	address internal _rewardsToken;
	uint256 internal _lastTotalRewardsAccrued;
	uint256 internal _totalRewardsRedeemed;
	uint256 internal _unredeemableRewards;
	EnumerableSet.AddressSet internal _tokens;
	mapping(address => TokenData) internal _tokenData;
	mapping(address => UserData) internal _users;

	uint256[43] private __gap;
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Copyright 2021 weiWard LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.7.6;

interface ILPRewards {
	/* Views */

	function accruedRewardsPerTokenFor(address token)
		external
		view
		returns (uint256);

	function accruedRewardsPerTokenLastFor(address account, address token)
		external
		view
		returns (uint256);

	function lastRewardsBalanceOf(address account)
		external
		view
		returns (uint256);

	function lastRewardsBalanceOfFor(address account, address token)
		external
		view
		returns (uint256);

	function lastTotalRewardsAccrued() external view returns (uint256);

	function lastTotalRewardsAccruedFor(address token)
		external
		view
		returns (uint256);

	function numStakingTokens() external view returns (uint256);

	function rewardsBalanceOf(address account) external view returns (uint256);

	function rewardsBalanceOfFor(address account, address token)
		external
		view
		returns (uint256);

	function rewardsForToken(address token) external view returns (uint256);

	function rewardsToken() external view returns (address);

	function sharesFor(address account, address token)
		external
		view
		returns (uint256);

	function sharesPerToken(address token) external view returns (uint256);

	function stakedBalanceOf(address account, address token)
		external
		view
		returns (uint256);

	function stakingTokenAt(uint256 index) external view returns (address);

	function supportsStakingToken(address token) external view returns (bool);

	function totalRewardsAccrued() external view returns (uint256);

	function totalRewardsAccruedFor(address token)
		external
		view
		returns (uint256);

	function totalRewardsRedeemed() external view returns (uint256);

	function totalRewardsRedeemedFor(address token)
		external
		view
		returns (uint256);

	function totalShares() external view returns (uint256);

	function totalSharesFor(address account) external view returns (uint256);

	function totalSharesForToken(address token) external view returns (uint256);

	function totalStaked(address token) external view returns (uint256);

	function unredeemableRewards() external view returns (uint256);

	function valuePerTokenImpl(address token) external view returns (address);

	/* Mutators */

	function addToken(address token, address tokenValueImpl) external;

	function changeTokenValueImpl(address token, address tokenValueImpl)
		external;

	function exit(bool asWETH) external;

	function exitFrom(address token, bool asWETH) external;

	function pause() external;

	function recoverUnredeemableRewards(address to, uint256 amount) external;

	function recoverUnstaked(
		address token,
		address to,
		uint256 amount
	) external;

	function redeemAllRewards(bool asWETH) external;

	function redeemAllRewardsFrom(address token, bool asWETH) external;

	function redeemReward(uint256 amount, bool asWETH) external;

	function redeemRewardFrom(
		address token,
		uint256 amount,
		bool asWETH
	) external;

	function removeToken(address token) external;

	function setRewardsToken(address token) external;

	function stake(address token, uint256 amount) external;

	function unpause() external;

	function unstake(address token, uint256 amount) external;

	function unstakeAll() external;

	function unstakeAllFrom(address token) external;

	function updateAccrual() external;

	function updateReward() external;

	function updateRewardFor(address token) external;

	/* Events */

	event AccrualUpdated(address indexed author, uint256 accruedRewards);
	event RecoveredUnredeemableRewards(
		address indexed author,
		address indexed to,
		uint256 amount
	);
	event RecoveredUnstaked(
		address indexed author,
		address indexed token,
		address indexed to,
		uint256 amount
	);
	event RewardPaid(
		address indexed account,
		address indexed token,
		uint256 amount
	);
	event RewardsTokenSet(address indexed author, address indexed token);
	event Staked(address indexed account, address indexed token, uint256 amount);
	event TokenAdded(
		address indexed author,
		address indexed token,
		address indexed tokenValueImpl
	);
	event TokenRemoved(address indexed author, address indexed token);
	event TokenValueImplChanged(
		address indexed author,
		address indexed token,
		address indexed tokenValueImpl
	);
	event Unstaked(
		address indexed account,
		address indexed token,
		uint256 amount
	);
}

// SPDX-License-Identifier: Apache-2.0

/**
 * Copyright 2021 weiWard LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.7.6;

interface IValuePerToken {
	/* Views */

	function token() external view returns (address);

	function valuePerToken()
		external
		view
		returns (uint256 numerator, uint256 denominator);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IWETH {
	function deposit() external payable;

	function withdraw(uint256) external;
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}