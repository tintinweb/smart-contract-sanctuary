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
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ETHmxMinterData.sol";
import "../../tokens/interfaces/IETHmx.sol";
import "../interfaces/IETHmxMinter.sol";
import "../../tokens/interfaces/IETHtx.sol";
import "../interfaces/IETHtxAMM.sol";
import "../../tokens/interfaces/IWETH.sol";
import "../../access/OwnableUpgradeable.sol";
import "../../libraries/UintLog.sol";

/* solhint-disable not-rely-on-time */

interface IPool {
	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);
}

contract ETHmxMinter is
	Initializable,
	ContextUpgradeable,
	OwnableUpgradeable,
	PausableUpgradeable,
	ETHmxMinterData,
	IETHmxMinter
{
	using EnumerableSet for EnumerableSet.AddressSet;
	using SafeERC20 for IERC20;
	using SafeMath for uint256;
	using SafeMath for uint32;
	using UintLog for uint256;

	struct ETHmxMinterArgs {
		address ethmx;
		address ethtx;
		address ethtxAMM;
		address weth;
		ETHmxMintParams ethmxMintParams;
		ETHtxMintParams ethtxMintParams;
		uint128 lpShareNumerator;
		uint128 lpShareDenominator;
		address[] lps;
		address lpRecipient;
	}

	uint256 internal constant _GAS_PER_ETHTX = 21000; // per 1e18
	uint256 internal constant _GENESIS_START = 1620655200; // 05/10/2021 1400 UTC
	uint256 internal constant _GENESIS_END = 1621260000; // 05/17/2021 1400 UTC
	uint256 internal constant _GENESIS_AMOUNT = 3e21; // 3k ETH

	/* Constructor */

	constructor(address owner_) {
		init(owner_);
	}

	/* Initializer */

	function init(address owner_) public virtual initializer {
		__Context_init_unchained();
		__Ownable_init_unchained(owner_);
		__Pausable_init_unchained();
	}

	function postInit(ETHmxMinterArgs memory _args) external virtual onlyOwner {
		address sender = _msgSender();

		_ethmx = _args.ethmx;
		emit EthmxSet(sender, _args.ethmx);

		_ethtx = _args.ethtx;
		emit EthtxSet(sender, _args.ethtx);

		_ethtxAMM = _args.ethtxAMM;
		emit EthtxAMMSet(sender, _args.ethtxAMM);

		_weth = _args.weth;
		emit WethSet(sender, _args.weth);

		_ethmxMintParams = _args.ethmxMintParams;
		emit EthmxMintParamsSet(sender, _args.ethmxMintParams);

		_inGenesis = block.timestamp <= _GENESIS_END;
		_minMintPrice = _args.ethtxMintParams.minMintPrice;
		_mu = _args.ethtxMintParams.mu;
		_lambda = _args.ethtxMintParams.lambda;
		emit EthtxMintParamsSet(sender, _args.ethtxMintParams);

		_lpShareNum = _args.lpShareNumerator;
		_lpShareDen = _args.lpShareDenominator;
		emit LpShareSet(sender, _args.lpShareNumerator, _args.lpShareDenominator);

		for (uint256 i = 0; i < _lps.length(); i++) {
			address lp = _lps.at(i);
			_lps.remove(lp);
			emit LpRemoved(sender, lp);
		}
		for (uint256 i = 0; i < _args.lps.length; i++) {
			address lp = _args.lps[i];
			_lps.add(lp);
			emit LpAdded(sender, lp);
		}

		_lpRecipient = _args.lpRecipient;
		emit LpRecipientSet(sender, _args.lpRecipient);
	}

	function addLp(address pool) external virtual override onlyOwner {
		bool added = _lps.add(pool);
		require(added, "ETHmxMinter: liquidity pool already added");
		emit LpAdded(_msgSender(), pool);
	}

	function mint() external payable virtual override whenNotPaused {
		require(block.timestamp >= _GENESIS_START, "ETHmxMinter: before genesis");
		uint256 amountIn = msg.value;
		require(amountIn != 0, "ETHmxMinter: cannot mint with zero amount");

		// Convert to WETH
		address weth_ = weth();
		IWETH(weth_).deposit{ value: amountIn }();

		// Check if we're in genesis
		bool exitingGenesis;
		uint256 ethToMintEthtx = amountIn;
		if (_inGenesis) {
			uint256 totalGiven_ = _totalGiven.add(amountIn);
			if (block.timestamp >= _GENESIS_END || totalGiven_ >= _GENESIS_AMOUNT) {
				// Exiting genesis
				ethToMintEthtx = totalGiven_;
				exitingGenesis = true;
			} else {
				ethToMintEthtx = 0;
			}
		}

		// Mint ETHtx and send ETHtx-WETH pair.
		_mintEthtx(ethToMintEthtx);

		// Mint ETHmx to sender.
		uint256 amountOut = ethmxFromEth(amountIn);
		_mint(_msgSender(), amountOut);
		_totalGiven += amountIn;
		// WARN this could cause re-entrancy if we ever called an unkown address
		if (exitingGenesis) {
			_inGenesis = false;
		}
	}

	function mintWithETHtx(uint256 amount)
		external
		virtual
		override
		whenNotPaused
	{
		require(amount != 0, "ETHmxMinter: cannot mint with zero amount");

		IETHtxAMM ammHandle = IETHtxAMM(ethtxAMM());
		uint256 amountETHIn = ammHandle.ethToExactEthtx(amount);
		require(
			ammHandle.ethNeeded() >= amountETHIn,
			"ETHmxMinter: ETHtx value burnt exceeds ETH needed"
		);

		address account = _msgSender();
		IETHtx(ethtx()).burn(account, amount);

		_mint(account, amountETHIn);
	}

	function mintWithWETH(uint256 amount)
		external
		virtual
		override
		whenNotPaused
	{
		require(block.timestamp >= _GENESIS_START, "ETHmxMinter: before genesis");
		require(amount != 0, "ETHmxMinter: cannot mint with zero amount");
		address account = _msgSender();

		// Need ownership for router
		IERC20(weth()).safeTransferFrom(account, address(this), amount);

		// Check if we're in genesis
		bool exitingGenesis;
		uint256 ethToMintEthtx = amount;
		if (_inGenesis) {
			uint256 totalGiven_ = _totalGiven.add(amount);
			if (block.timestamp >= _GENESIS_END || totalGiven_ >= _GENESIS_AMOUNT) {
				// Exiting genesis
				ethToMintEthtx = totalGiven_;
				exitingGenesis = true;
			} else {
				ethToMintEthtx = 0;
			}
		}

		// Mint ETHtx and send ETHtx-WETH pair.
		_mintEthtx(ethToMintEthtx);

		uint256 amountOut = ethmxFromEth(amount);
		_mint(account, amountOut);
		_totalGiven += amount;
		// WARN this could cause re-entrancy if we ever called an unkown address
		if (exitingGenesis) {
			_inGenesis = false;
		}
	}

	function pause() external virtual override onlyOwner {
		_pause();
	}

	function recoverERC20(
		address token,
		address to,
		uint256 amount
	) external virtual override onlyOwner {
		require(token != _weth, "ETHmxMinter: cannot recover WETH");
		IERC20(token).safeTransfer(to, amount);
		emit Recovered(_msgSender(), token, to, amount);
	}

	function removeLp(address pool) external virtual override onlyOwner {
		bool removed = _lps.remove(pool);
		require(removed, "ETHmxMinter: liquidity pool not present");
		emit LpRemoved(_msgSender(), pool);
	}

	function setEthmx(address addr) public virtual override onlyOwner {
		_ethmx = addr;
		emit EthmxSet(_msgSender(), addr);
	}

	function setEthmxMintParams(ETHmxMintParams memory mp)
		public
		virtual
		override
		onlyOwner
	{
		_ethmxMintParams = mp;
		emit EthmxMintParamsSet(_msgSender(), mp);
	}

	function setEthtxMintParams(ETHtxMintParams memory mp)
		public
		virtual
		override
		onlyOwner
	{
		_minMintPrice = mp.minMintPrice;
		_mu = mp.mu;
		_lambda = mp.lambda;
		emit EthtxMintParamsSet(_msgSender(), mp);
	}

	function setEthtx(address addr) public virtual override onlyOwner {
		_ethtx = addr;
		emit EthtxSet(_msgSender(), addr);
	}

	function setEthtxAMM(address addr) public virtual override onlyOwner {
		_ethtxAMM = addr;
		emit EthtxAMMSet(_msgSender(), addr);
	}

	function setLpRecipient(address account)
		external
		virtual
		override
		onlyOwner
	{
		_lpRecipient = account;
		emit LpRecipientSet(_msgSender(), account);
	}

	function setLpShare(uint128 numerator, uint128 denominator)
		external
		virtual
		override
		onlyOwner
	{
		// Also guarantees that the denominator cannot be zero.
		require(denominator > numerator, "ETHmxMinter: cannot set lpShare >= 1");
		_lpShareNum = numerator;
		_lpShareDen = denominator;
		emit LpShareSet(_msgSender(), numerator, denominator);
	}

	function setWeth(address addr) public virtual override onlyOwner {
		_weth = addr;
		emit WethSet(_msgSender(), addr);
	}

	function unpause() external virtual override onlyOwner {
		_unpause();
	}

	/* Public Views */

	function ethmx() public view virtual override returns (address) {
		return _ethmx;
	}

	function ethmxMintParams()
		public
		view
		virtual
		override
		returns (ETHmxMintParams memory)
	{
		return _ethmxMintParams;
	}

	function ethmxFromEth(uint256 amountETHIn)
		public
		view
		virtual
		override
		returns (uint256)
	{
		if (amountETHIn == 0) {
			return 0;
		}

		ETHmxMintParams memory mp = _ethmxMintParams;
		uint256 amountOut = _ethmxCurve(amountETHIn, mp);

		if (_inGenesis) {
			uint256 totalGiven_ = _totalGiven;
			uint256 totalEnd = totalGiven_.add(amountETHIn);

			if (totalEnd > _GENESIS_AMOUNT) {
				// Exiting genesis
				uint256 amtUnder = _GENESIS_AMOUNT - totalGiven_;
				amountOut -= amtUnder.mul(amountOut).div(amountETHIn);
				uint256 added =
					amtUnder.mul(2).mul(mp.zetaFloorNum).div(mp.zetaFloorDen);
				return amountOut.add(added);
			}

			return amountOut.mul(2);
		}

		return amountOut;
	}

	function ethmxFromEthtx(uint256 amountETHtxIn)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return IETHtxAMM(ethtxAMM()).ethToExactEthtx(amountETHtxIn);
	}

	function ethtx() public view virtual override returns (address) {
		return _ethtx;
	}

	function ethtxMintParams()
		public
		view
		virtual
		override
		returns (ETHtxMintParams memory)
	{
		return ETHtxMintParams(_minMintPrice, _mu, _lambda);
	}

	function ethtxAMM() public view virtual override returns (address) {
		return _ethtxAMM;
	}

	function ethtxFromEth(uint256 amountETHIn)
		public
		view
		virtual
		override
		returns (uint256)
	{
		if (amountETHIn == 0) {
			return 0;
		}

		IETHtxAMM ammHandle = IETHtxAMM(_ethtxAMM);
		(uint256 collat, uint256 liability) = ammHandle.cRatio();
		uint256 gasPrice = ammHandle.gasPrice();

		uint256 basePrice;
		uint256 lambda_;
		{
			uint256 minMintPrice_ = _minMintPrice;
			uint256 mu_ = _mu;
			lambda_ = _lambda;

			basePrice = mu_.mul(gasPrice).add(minMintPrice_);
		}

		if (liability == 0) {
			// If exiting genesis, flat 2x on minting price up to threshold
			if (_inGenesis) {
				uint256 totalGiven_ = _totalGiven;
				uint256 totalEnd = totalGiven_.add(amountETHIn);

				if (totalEnd > _GENESIS_AMOUNT) {
					uint256 amtOver = totalEnd - _GENESIS_AMOUNT;
					uint256 amtOut =
						_ethToEthtx(basePrice.mul(2), amountETHIn - amtOver);
					return amtOut.add(_ethToEthtx(basePrice, amtOver));
				}
				return _ethToEthtx(basePrice.mul(2), amountETHIn);
			}

			return _ethToEthtx(basePrice, amountETHIn);
		}

		uint256 ethTarget;
		{
			(uint256 cTargetNum, uint256 cTargetDen) = ammHandle.targetCRatio();
			ethTarget = liability.mul(cTargetNum).div(cTargetDen);
		}

		if (collat < ethTarget) {
			uint256 ethEnd = collat.add(amountETHIn);
			if (ethEnd <= ethTarget) {
				return 0;
			}
			amountETHIn = ethEnd - ethTarget;
			collat = ethTarget;
		}

		uint256 firstTerm = basePrice.mul(amountETHIn);

		uint256 collatDiff = collat - liability;
		uint256 coeffA = lambda_.mul(liability).mul(gasPrice);

		uint256 secondTerm =
			basePrice.mul(collatDiff).add(coeffA).mul(1e18).ln().mul(coeffA);
		secondTerm /= 1e18;

		uint256 thirdTerm = basePrice.mul(collatDiff.add(amountETHIn));
		// avoids stack too deep error
		thirdTerm = thirdTerm.add(coeffA).mul(1e18).ln().mul(coeffA) / 1e18;

		uint256 numerator = firstTerm.add(secondTerm).sub(thirdTerm).mul(1e18);
		uint256 denominator = _GAS_PER_ETHTX.mul(basePrice).mul(basePrice);
		return numerator.div(denominator);
	}

	function inGenesis() external view virtual override returns (bool) {
		return _inGenesis;
	}

	function numLiquidityPools()
		external
		view
		virtual
		override
		returns (uint256)
	{
		return _lps.length();
	}

	function liquidityPoolsAt(uint256 index)
		external
		view
		virtual
		override
		returns (address)
	{
		return _lps.at(index);
	}

	function lpRecipient() public view virtual override returns (address) {
		return _lpRecipient;
	}

	function lpShare()
		public
		view
		virtual
		override
		returns (uint128 numerator, uint128 denominator)
	{
		numerator = _lpShareNum;
		denominator = _lpShareDen;
	}

	function totalGiven() public view virtual override returns (uint256) {
		return _totalGiven;
	}

	function weth() public view virtual override returns (address) {
		return _weth;
	}

	/* Internal Views */

	function _ethmxCurve(uint256 amountETHIn, ETHmxMintParams memory mp)
		internal
		view
		virtual
		returns (uint256)
	{
		uint256 cRatioNum;
		uint256 cRatioDen;
		uint256 cTargetNum;
		uint256 cTargetDen;
		{
			IETHtxAMM ammHandle = IETHtxAMM(_ethtxAMM);
			(cRatioNum, cRatioDen) = ammHandle.cRatio();

			if (cRatioDen == 0) {
				// cRatio > cCap
				return amountETHIn.mul(mp.zetaFloorNum).div(mp.zetaFloorDen);
			}

			(cTargetNum, cTargetDen) = ammHandle.targetCRatio();
		}

		uint256 ethEnd = cRatioNum.add(amountETHIn);
		uint256 ethTarget = cRatioDen.mul(cTargetNum).div(cTargetDen);
		uint256 ethCap = cRatioDen.mul(mp.cCapNum).div(mp.cCapDen);
		if (cRatioNum >= ethCap) {
			// cRatio >= cCap
			return amountETHIn.mul(mp.zetaFloorNum).div(mp.zetaFloorDen);
		}

		if (cRatioNum < ethTarget) {
			// cRatio < cTarget
			if (ethEnd > ethCap) {
				// Add definite integral
				uint256 curveAmt =
					_ethmxDefiniteIntegral(
						ethCap - ethTarget,
						mp,
						cTargetNum,
						cTargetDen,
						ethTarget,
						cRatioDen
					);

				// Add amount past cap
				uint256 pastCapAmt =
					(ethEnd - ethCap).mul(mp.zetaFloorNum).div(mp.zetaFloorDen);

				// add initial amount
				uint256 flatAmt =
					(ethTarget - cRatioNum).mul(mp.zetaCeilNum).div(mp.zetaCeilDen);

				return flatAmt.add(curveAmt).add(pastCapAmt);
			} else if (ethEnd > ethTarget) {
				// Add definite integral for partial amount
				uint256 ethOver = ethEnd - ethTarget;
				uint256 curveAmt =
					_ethmxDefiniteIntegral(
						ethOver,
						mp,
						cTargetNum,
						cTargetDen,
						ethTarget,
						cRatioDen
					);

				uint256 ethBeforeCurve = amountETHIn - ethOver;
				uint256 flatAmt =
					ethBeforeCurve.mul(mp.zetaCeilNum).div(mp.zetaCeilDen);
				return flatAmt.add(curveAmt);
			}

			return amountETHIn.mul(mp.zetaCeilNum).div(mp.zetaCeilDen);
		}

		// cTarget < cRatio < cCap
		if (ethEnd > ethCap) {
			uint256 ethOver = ethEnd - ethCap;
			uint256 curveAmt =
				_ethmxDefiniteIntegral(
					amountETHIn - ethOver,
					mp,
					cTargetNum,
					cTargetDen,
					cRatioNum,
					cRatioDen
				);

			uint256 flatAmt = ethOver.mul(mp.zetaFloorNum).div(mp.zetaFloorDen);

			return curveAmt.add(flatAmt);
		}

		return
			_ethmxDefiniteIntegral(
				amountETHIn,
				mp,
				cTargetNum,
				cTargetDen,
				cRatioNum,
				cRatioDen
			);
	}

	function _ethmxDefiniteIntegral(
		uint256 amountETHIn,
		ETHmxMintParams memory mp,
		uint256 cTargetNum,
		uint256 cTargetDen,
		uint256 initCollateral,
		uint256 liability
	) internal pure virtual returns (uint256) {
		uint256 fctMulNum = mp.zetaFloorNum.mul(mp.zetaCeilDen).mul(cTargetDen);
		uint256 fctMulDen = mp.zetaFloorDen.mul(mp.zetaCeilNum).mul(cTargetNum);

		// prettier-ignore
		uint256 first =
			amountETHIn
			.mul(fctMulNum.mul(mp.cCapNum))
			.div(fctMulDen.mul(mp.cCapDen));

		uint256 second = amountETHIn.mul(mp.zetaFloorNum).div(mp.zetaFloorDen);

		uint256 tNum = fctMulNum.mul(amountETHIn);
		uint256 tDen = fctMulDen.mul(2).mul(liability);
		uint256 third = initCollateral.mul(2).add(amountETHIn);
		// avoids stack too deep error
		third = third.mul(tNum).div(tDen);

		return first.add(second).sub(third);
	}

	function _ethToEthtx(uint256 gasPrice, uint256 amountETH)
		internal
		pure
		virtual
		returns (uint256)
	{
		require(gasPrice != 0, "ETHmxMinter: gasPrice is zero");
		return amountETH.mul(1e18) / gasPrice.mul(_GAS_PER_ETHTX);
	}

	/* Internal Mutators */

	function _mint(address account, uint256 amount) internal virtual {
		IETHmx(ethmx()).mintTo(account, amount);
	}

	function _mintEthtx(uint256 amountEthIn) internal virtual {
		// Mint ETHtx.
		uint256 ethtxToMint = ethtxFromEth(amountEthIn);

		if (ethtxToMint == 0) {
			return;
		}

		address ethtx_ = ethtx();
		IETHtx(ethtx_).mint(address(this), ethtxToMint);

		// Lock portion into liquidity in designated pools
		(uint256 ethtxSentToLp, uint256 ethSentToLp) = _sendToLps(ethtxToMint);

		// Send the rest to the AMM.
		address ethtxAmm_ = ethtxAMM();
		IERC20(weth()).safeTransfer(ethtxAmm_, amountEthIn.sub(ethSentToLp));
		IERC20(ethtx_).safeTransfer(ethtxAmm_, ethtxToMint.sub(ethtxSentToLp));
	}

	function _sendToLps(uint256 ethtxTotal)
		internal
		virtual
		returns (uint256 totalEthtxSent, uint256 totalEthSent)
	{
		uint256 numLps = _lps.length();
		if (numLps == 0) {
			return (0, 0);
		}

		(uint256 lpShareNum, uint256 lpShareDen) = lpShare();
		if (lpShareNum == 0) {
			return (0, 0);
		}

		uint256 ethtxToLp = ethtxTotal.mul(lpShareNum).div(lpShareDen).div(numLps);
		uint256 ethToLp = IETHtxAMM(ethtxAMM()).ethToExactEthtx(ethtxToLp);
		address ethtx_ = ethtx();
		address weth_ = weth();
		address to = lpRecipient();

		for (uint256 i = 0; i < numLps; i++) {
			address pool = _lps.at(i);

			IERC20(ethtx_).safeIncreaseAllowance(pool, ethtxToLp);
			IERC20(weth_).safeIncreaseAllowance(pool, ethToLp);

			(uint256 ethtxSent, uint256 ethSent, ) =
				IPool(pool).addLiquidity(
					ethtx_,
					weth_,
					ethtxToLp,
					ethToLp,
					0,
					0,
					to,
					// solhint-disable-next-line not-rely-on-time
					block.timestamp
				);

			totalEthtxSent = totalEthtxSent.add(ethtxSent);
			totalEthSent = totalEthSent.add(ethSent);
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

import "../interfaces/IETHmxMinter.sol";

abstract contract ETHmxMinterData {
	address internal _ethmx;
	address internal _ethtx;
	address internal _ethtxAMM;
	address internal _weth;

	// ETHmx minting
	uint256 internal _totalGiven;
	IETHmxMinter.ETHmxMintParams internal _ethmxMintParams;

	// ETHtx minting
	uint128 internal _minMintPrice;
	uint64 internal _mu;
	uint64 internal _lambda;

	// Liquidity pool distribution
	uint128 internal _lpShareNum;
	uint128 internal _lpShareDen;
	EnumerableSet.AddressSet internal _lps;
	address internal _lpRecipient;

	bool internal _inGenesis;

	uint256[39] private __gap;
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
pragma abicoder v2;

interface IETHmxMinter {
	/* Types */

	struct ETHmxMintParams {
		// Uses a single 32 byte slot and avoids stack too deep errors
		uint32 cCapNum;
		uint32 cCapDen;
		uint32 zetaFloorNum;
		uint32 zetaFloorDen;
		uint32 zetaCeilNum;
		uint32 zetaCeilDen;
	}

	struct ETHtxMintParams {
		uint128 minMintPrice;
		uint64 mu;
		uint64 lambda;
	}

	/* Views */

	function ethmx() external view returns (address);

	function ethmxMintParams() external view returns (ETHmxMintParams memory);

	function ethmxFromEth(uint256 amountETHIn) external view returns (uint256);

	function ethmxFromEthtx(uint256 amountETHtxIn)
		external
		view
		returns (uint256);

	function ethtx() external view returns (address);

	function ethtxMintParams() external view returns (ETHtxMintParams memory);

	function ethtxAMM() external view returns (address);

	function ethtxFromEth(uint256 amountETHIn) external view returns (uint256);

	function inGenesis() external view returns (bool);

	function numLiquidityPools() external view returns (uint256);

	function liquidityPoolsAt(uint256 index) external view returns (address);

	function lpRecipient() external view returns (address);

	function lpShare()
		external
		view
		returns (uint128 numerator, uint128 denominator);

	function totalGiven() external view returns (uint256);

	function weth() external view returns (address);

	/* Mutators */

	function addLp(address pool) external;

	function mint() external payable;

	function mintWithETHtx(uint256 amountIn) external;

	function mintWithWETH(uint256 amountIn) external;

	function pause() external;

	function recoverERC20(
		address token,
		address to,
		uint256 amount
	) external;

	function removeLp(address pool) external;

	function setEthmx(address addr) external;

	function setEthmxMintParams(ETHmxMintParams memory mp) external;

	function setEthtxMintParams(ETHtxMintParams memory mp) external;

	function setEthtx(address addr) external;

	function setEthtxAMM(address addr) external;

	function setLpRecipient(address account) external;

	function setLpShare(uint128 numerator, uint128 denominator) external;

	function setWeth(address addr) external;

	function unpause() external;

	/* Events */

	event EthmxSet(address indexed author, address indexed addr);
	event EthmxMintParamsSet(address indexed author, ETHmxMintParams mp);
	event EthtxMintParamsSet(address indexed author, ETHtxMintParams mp);
	event EthtxSet(address indexed author, address indexed addr);
	event EthtxAMMSet(address indexed author, address indexed addr);
	event LpAdded(address indexed author, address indexed account);
	event LpRecipientSet(address indexed author, address indexed account);
	event LpRemoved(address indexed author, address indexed account);
	event LpShareSet(
		address indexed author,
		uint128 numerator,
		uint128 denominator
	);
	event Recovered(
		address indexed author,
		address indexed token,
		address indexed to,
		uint256 amount
	);
	event WethSet(address indexed author, address indexed addr);
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

interface IETHtxAMM {
	/* Views */

	function cRatio()
		external
		view
		returns (uint256 numerator, uint256 denominator);

	function cRatioBelowTarget() external view returns (bool);

	function ethNeeded() external view returns (uint256);

	function ethtx() external view returns (address);

	function exactEthToEthtx(uint256 amountEthIn)
		external
		view
		returns (uint256);

	function ethToExactEthtx(uint256 amountEthtxOut)
		external
		view
		returns (uint256);

	function exactEthtxToEth(uint256 amountEthtxIn)
		external
		view
		returns (uint256);

	function ethtxToExactEth(uint256 amountEthOut)
		external
		view
		returns (uint256);

	function ethSupply() external view returns (uint256);

	function ethSupplyTarget() external view returns (uint256);

	function ethtxAvailable() external view returns (uint256);

	function ethtxOutstanding() external view returns (uint256);

	function feeLogic() external view returns (address);

	function gasOracle() external view returns (address);

	function gasPerETHtx() external pure returns (uint256);

	function gasPrice() external view returns (uint256);

	function gasPriceAtRedemption() external view returns (uint256);

	function maxGasPrice() external view returns (uint256);

	function targetCRatio()
		external
		view
		returns (uint128 numerator, uint128 denominator);

	function weth() external view returns (address);

	/* Mutators */

	function swapEthForEthtx(uint256 deadline) external payable;

	function swapWethForEthtx(uint256 amountIn, uint256 deadline) external;

	function swapEthForExactEthtx(uint256 amountOut, uint256 deadline)
		external
		payable;

	function swapWethForExactEthtx(
		uint256 amountInMax,
		uint256 amountOut,
		uint256 deadline
	) external;

	function swapExactEthForEthtx(uint256 amountOutMin, uint256 deadline)
		external
		payable;

	function swapExactWethForEthtx(
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline
	) external;

	function swapEthtxForEth(
		uint256 amountIn,
		uint256 deadline,
		bool asWETH
	) external;

	function swapEthtxForExactEth(
		uint256 amountInMax,
		uint256 amountOut,
		uint256 deadline,
		bool asWETH
	) external;

	function swapExactEthtxForEth(
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline,
		bool asWETH
	) external;

	function pause() external;

	function recoverUnsupportedERC20(
		address token,
		address to,
		uint256 amount
	) external;

	function setEthtx(address account) external;

	function setGasOracle(address account) external;

	function setTargetCRatio(uint128 numerator, uint128 denominator) external;

	function setWETH(address account) external;

	function unpause() external;

	/* Events */

	event ETHtxSet(address indexed author, address indexed account);
	event GasOracleSet(address indexed author, address indexed account);
	event RecoveredUnsupported(
		address indexed author,
		address indexed token,
		address indexed to,
		uint256 amount
	);
	event TargetCRatioSet(
		address indexed author,
		uint128 numerator,
		uint128 denominator
	);
	event WETHSet(address indexed author, address indexed account);
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

library UintLog {
	uint256 internal constant _LOG2_E = 1442695040888963407;

	function ln(uint256 x) internal pure returns (uint256) {
		return (blog2(x) * 1e18) / _LOG2_E;
	}

	// Most significant bit
	// prettier-ignore
	function msb(uint256 x) internal pure returns (uint256 n) {
		if (x >= 0x100000000000000000000000000000000) { x >>= 128; n += 128; }
		if (x >= 0x10000000000000000) { x >>= 64; n += 64; }
		if (x >= 0x100000000) { x >>= 32; n += 32; }
		if (x >= 0x10000) { x >>= 16; n += 16; }
		if (x >= 0x100) { x >>= 8; n += 8; }
		if (x >= 0x10) { x >>= 4; n += 4; }
		if (x >= 0x4) { x >>= 2; n += 2; }
		if (x >= 0x2) { /* x >>= 1; */ n += 1; }
	}

	// Approximate binary log of uint
	// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
	// https://github.com/hifi-finance/prb-math/blob/5c6817860496ec40fd269934f3c531822402f1ce/contracts/PRBMathUD60x18.sol#L334-L380
	function blog2(uint256 x) internal pure returns (uint256 result) {
		require(x >= 1e18, "blog2 too small");
		uint256 n = msb(x / 1e18);

		result = n * 1e18;
		uint256 y = x >> n;

		if (y == 1e18) {
			return result;
		}

		for (uint256 delta = 5e17; delta > 0; delta >>= 1) {
			y = (y * y) / 1e18;
			if (y >= 2e18) {
				result += delta;
				y >>= 1;
			}
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

interface IETHmx {
	/* Views */

	function minter() external view returns (address);

	/* Mutators */

	function burn(uint256 amount) external;

	function mintTo(address account, uint256 amount) external;

	function pause() external;

	function recoverERC20(
		address token,
		address to,
		uint256 amount
	) external;

	function setMinter(address account) external;

	function unpause() external;

	/* Events */

	event MinterSet(address indexed author, address indexed account);
	event Recovered(
		address indexed author,
		address indexed token,
		address indexed to,
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

interface IETHtx {
	/* Views */

	function minter() external view returns (address);

	/* Mutators */

	function burn(address account, uint256 amount) external;

	function mint(address account, uint256 amount) external;

	function pause() external;

	function recoverERC20(
		address token,
		address to,
		uint256 amount
	) external;

	function setFeeLogic(address account) external;

	function setMinter(address account) external;

	function unpause() external;

	/* Events */

	event FeeLogicSet(address indexed author, address indexed account);
	event MinterSet(address indexed author, address indexed account);
	event Recovered(
		address indexed author,
		address indexed token,
		address indexed to,
		uint256 amount
	);
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