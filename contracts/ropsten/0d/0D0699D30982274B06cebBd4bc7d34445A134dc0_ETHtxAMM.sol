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

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ETHtxAMMData.sol";
import "../interfaces/IETHtxAMM.sol";
import "../../tokens/interfaces/IETHtx.sol";
import "../../tokens/interfaces/IERC20TxFee.sol";
import "../../tokens/interfaces/IWETH.sol";
import "../../rewards/interfaces/IFeeLogic.sol";
import "../../oracles/interfaces/IGasPrice.sol";
import "../../access/OwnableUpgradeable.sol";

contract ETHtxAMM is
	Initializable,
	ContextUpgradeable,
	OwnableUpgradeable,
	PausableUpgradeable,
	ETHtxAMMData,
	IETHtxAMM
{
	using Address for address payable;
	using SafeERC20 for IERC20;
	using SafeMath for uint128;
	using SafeMath for uint256;

	struct ETHtxAMMArgs {
		address ethtx;
		address gasOracle;
		address weth;
		uint128 targetCRatioNum;
		uint128 targetCRatioDen;
	}

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

	function postInit(ETHtxAMMArgs memory _args) external virtual onlyOwner {
		address sender = _msgSender();

		_ethtx = _args.ethtx;
		emit ETHtxSet(sender, _args.ethtx);

		_gasOracle = _args.gasOracle;
		emit GasOracleSet(sender, _args.gasOracle);

		_weth = _args.weth;
		emit WETHSet(sender, _args.weth);

		_targetCRatioNum = _args.targetCRatioNum;
		_targetCRatioDen = _args.targetCRatioDen;
		emit TargetCRatioSet(sender, _args.targetCRatioNum, _args.targetCRatioDen);
	}

	/* Fallbacks */

	receive() external payable {
		// Only accept ETH via fallback from the WETH contract
		address weth_ = weth();
		if (msg.sender != weth_) {
			// Otherwise try to convert it to WETH
			IWETH(weth_).deposit{ value: msg.value }();
		}
	}

	/* Modifiers */

	modifier ensure(uint256 deadline) {
		// solhint-disable-next-line not-rely-on-time
		require(deadline >= block.timestamp, "ETHtxAMM: expired");
		_;
	}

	modifier priceIsFresh() {
		require(
			!IGasPrice(gasOracle()).hasPriceExpired(),
			"ETHtxAMM: gas price is outdated"
		);
		_;
	}

	/* External Mutators */

	function swapEthForEthtx(uint256 deadline)
		external
		payable
		virtual
		override
	{
		_swapEthForEthtxRaw(msg.value, deadline, false);
	}

	function swapWethForEthtx(uint256 amountIn, uint256 deadline)
		external
		virtual
		override
	{
		_swapEthForEthtxRaw(amountIn, deadline, true);
	}

	function swapEthForExactEthtx(uint256 amountOut, uint256 deadline)
		external
		payable
		virtual
		override
	{
		uint256 amountInMax = msg.value;
		uint256 amountIn =
			_swapEthForExactEthtx(amountInMax, amountOut, deadline, false);
		// refund leftover ETH
		if (amountInMax != amountIn) {
			payable(_msgSender()).sendValue(amountInMax - amountIn);
		}
	}

	function swapWethForExactEthtx(
		uint256 amountInMax,
		uint256 amountOut,
		uint256 deadline
	) external virtual override {
		_swapEthForExactEthtx(amountInMax, amountOut, deadline, true);
	}

	function swapExactEthForEthtx(uint256 amountOutMin, uint256 deadline)
		external
		payable
		virtual
		override
	{
		_swapExactEthForEthtx(msg.value, amountOutMin, deadline, false);
	}

	function swapExactWethForEthtx(
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline
	) external virtual override {
		_swapExactEthForEthtx(amountIn, amountOutMin, deadline, true);
	}

	function swapEthtxForEth(
		uint256 amountIn,
		uint256 deadline,
		bool asWETH
	) external virtual override ensure(deadline) priceIsFresh {
		require(amountIn != 0, "ETHtxAMM: cannot swap zero");
		uint256 amountOut = exactEthtxToEth(amountIn);
		_swapEthtxForEth(_msgSender(), amountIn, amountOut, asWETH);
	}

	function swapEthtxForExactEth(
		uint256 amountInMax,
		uint256 amountOut,
		uint256 deadline,
		bool asWETH
	) external virtual override ensure(deadline) priceIsFresh {
		require(amountInMax != 0, "ETHtxAMM: cannot swap zero");
		uint256 amountIn = ethtxToExactEth(amountOut);
		require(amountIn <= amountInMax, "ETHtxAMM: amountIn exceeds max");
		_swapEthtxForEth(_msgSender(), amountIn, amountOut, asWETH);
	}

	function swapExactEthtxForEth(
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline,
		bool asWETH
	) external virtual override ensure(deadline) priceIsFresh {
		require(amountIn != 0, "ETHtxAMM: cannot swap zero");
		uint256 amountOut = exactEthtxToEth(amountIn);
		require(amountOut >= amountOutMin, "ETHtxAMM: amountOut below min");
		_swapEthtxForEth(_msgSender(), amountIn, amountOut, asWETH);
	}

	function pause() external virtual override onlyOwner whenNotPaused {
		_pause();
	}

	function recoverUnsupportedERC20(
		address token,
		address to,
		uint256 amount
	) external virtual override onlyOwner {
		require(token != weth(), "ETHtxAMM: cannot recover WETH");
		require(token != ethtx(), "ETHtxAMM: cannot recover ETHtx");

		IERC20(token).safeTransfer(to, amount);
		emit RecoveredUnsupported(_msgSender(), token, to, amount);
	}

	function setEthtx(address account) public virtual override onlyOwner {
		require(account != address(0), "ETHtxAMM: ETHtx zero address");
		_ethtx = account;
		emit ETHtxSet(_msgSender(), account);
	}

	function setGasOracle(address account) public virtual override onlyOwner {
		require(account != address(0), "ETHtxAMM: gasOracle zero address");
		_gasOracle = account;
		emit GasOracleSet(_msgSender(), account);
	}

	function setTargetCRatio(uint128 numerator, uint128 denominator)
		public
		virtual
		override
		onlyOwner
	{
		require(numerator != 0, "ETHtxAMM: targetCRatio numerator is zero");
		require(denominator != 0, "ETHtxAMM: targetCRatio denominator is zero");
		_targetCRatioNum = numerator;
		_targetCRatioDen = denominator;
		emit TargetCRatioSet(_msgSender(), numerator, denominator);
	}

	function setWETH(address account) public virtual override onlyOwner {
		require(account != address(0), "ETHtxAMM: WETH zero address");
		_weth = account;
		emit WETHSet(_msgSender(), account);
	}

	function unpause() external virtual override onlyOwner whenPaused {
		_unpause();
	}

	/* Public Pure */

	function gasPerETHtx() public pure virtual override returns (uint256) {
		return 21000; // Per 1e18
	}

	/* Public Views */

	function cRatio()
		public
		view
		virtual
		override
		returns (uint256 numerator, uint256 denominator)
	{
		numerator = ethSupply();
		denominator = ethToExactEthtx(ethtxOutstanding());
	}

	function cRatioBelowTarget() public view virtual override returns (bool) {
		(uint256 cRatioNum, uint256 cRatioDen) = cRatio();
		if (cRatioDen == 0) {
			return false;
		}

		uint256 current = cRatioNum.mul(1e18) / cRatioDen;

		(uint256 targetNum, uint256 targetDen) = targetCRatio();
		uint256 target = targetNum.mul(1e18).div(targetDen);

		return current < target;
	}

	function ethNeeded() external view virtual override returns (uint256) {
		(uint256 ethSupply_, uint256 ethOut) = cRatio();
		(uint128 targetNum, uint128 targetDen) = targetCRatio();

		uint256 target = ethOut.mul(targetNum).div(targetDen);

		if (ethSupply_ > target) {
			return 0;
		}

		return target - ethSupply_;
	}

	function ethtx() public view virtual override returns (address) {
		return _ethtx;
	}

	function exactEthToEthtx(uint256 amountEthIn)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _ethToEthtx(gasPrice(), amountEthIn);
	}

	function ethToExactEthtx(uint256 amountEthtxOut)
		public
		view
		virtual
		override
		returns (uint256)
	{
		return _ethtxToEth(gasPrice(), amountEthtxOut);
	}

	function exactEthtxToEth(uint256 amountEthtxIn)
		public
		view
		virtual
		override
		returns (uint256)
	{
		// Account for fee
		uint256 fee =
			IFeeLogic(feeLogic()).getFee(_msgSender(), address(this), amountEthtxIn);

		return _ethtxToEth(gasPriceAtRedemption(), amountEthtxIn.sub(fee));
	}

	function ethtxToExactEth(uint256 amountEthOut)
		public
		view
		virtual
		override
		returns (uint256)
	{
		uint256 amountEthtx = _ethToEthtx(gasPriceAtRedemption(), amountEthOut);

		// Account for fee
		uint256 amountBeforeFee =
			IFeeLogic(feeLogic()).undoFee(_msgSender(), address(this), amountEthtx);

		return amountBeforeFee;
	}

	function ethSupply() public view virtual override returns (uint256) {
		return IERC20(weth()).balanceOf(address(this));
	}

	function ethSupplyTarget() external view virtual override returns (uint256) {
		(uint128 targetNum, uint128 targetDen) = targetCRatio();
		return ethToExactEthtx(ethtxOutstanding()).mul(targetNum).div(targetDen);
	}

	function ethtxAvailable() public view virtual override returns (uint256) {
		return IERC20(ethtx()).balanceOf(address(this));
	}

	function ethtxOutstanding() public view virtual override returns (uint256) {
		return IERC20(ethtx()).totalSupply().sub(ethtxAvailable());
	}

	function feeLogic() public view virtual override returns (address) {
		return IERC20TxFee(ethtx()).feeLogic();
	}

	function gasOracle() public view virtual override returns (address) {
		return _gasOracle;
	}

	function gasPrice() public view virtual override returns (uint256) {
		return IGasPrice(gasOracle()).gasPrice();
	}

	function gasPriceAtRedemption()
		public
		view
		virtual
		override
		returns (uint256)
	{
		// Apply cap when collateral below target
		uint256 gasPrice_ = gasPrice();
		uint256 maxGasPrice_ = maxGasPrice();
		if (gasPrice_ > maxGasPrice_) {
			gasPrice_ = maxGasPrice_;
		}
		return gasPrice_;
	}

	function maxGasPrice() public view virtual override returns (uint256) {
		uint256 liability = ethtxOutstanding();
		if (liability == 0) {
			return gasPrice();
		}

		(uint128 targetNum, uint128 targetDen) = targetCRatio();

		uint256 numerator = ethSupply().mul(1e18).mul(targetDen);
		uint256 denominator = liability.mul(gasPerETHtx()).mul(targetNum);
		return numerator.div(denominator);
	}

	function targetCRatio()
		public
		view
		virtual
		override
		returns (uint128 numerator, uint128 denominator)
	{
		numerator = _targetCRatioNum;
		denominator = _targetCRatioDen;
	}

	function weth() public view virtual override returns (address) {
		return _weth;
	}

	/* Internal Pure */

	function _ethtxToEth(uint256 gasPrice_, uint256 amountETHtx)
		internal
		pure
		virtual
		returns (uint256)
	{
		return gasPrice_.mul(amountETHtx).mul(gasPerETHtx()) / 1e18;
	}

	function _ethToEthtx(uint256 gasPrice_, uint256 amountETH)
		internal
		pure
		virtual
		returns (uint256)
	{
		require(gasPrice_ != 0, "ETHtxAMM: gasPrice is zero");
		return amountETH.mul(1e18) / gasPrice_.mul(gasPerETHtx());
	}

	/* Internal Mutators */

	function _swapEthForEthtxRaw(
		uint256 amountIn,
		uint256 deadline,
		bool useWETH
	) internal virtual ensure(deadline) priceIsFresh {
		require(amountIn != 0, "ETHtxAMM: cannot swap zero");
		uint256 amountOut = exactEthToEthtx(amountIn);
		_swapEthForEthtx(_msgSender(), amountIn, amountOut, useWETH);
	}

	function _swapEthForExactEthtx(
		uint256 amountInMax,
		uint256 amountOut,
		uint256 deadline,
		bool useWETH
	) internal virtual ensure(deadline) priceIsFresh returns (uint256 amountIn) {
		require(amountInMax != 0, "ETHtxAMM: cannot swap zero");
		// Add 1 to account for rounding (can't get ETHtx for 0 wei)
		amountIn = ethToExactEthtx(amountOut).add(1);
		require(amountIn <= amountInMax, "ETHtxAMM: amountIn exceeds max");
		_swapEthForEthtx(_msgSender(), amountIn, amountOut, useWETH);
	}

	function _swapExactEthForEthtx(
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline,
		bool useWETH
	) internal virtual ensure(deadline) priceIsFresh {
		require(amountIn != 0, "ETHtxAMM: cannot swap zero");
		uint256 amountOut = exactEthToEthtx(amountIn);
		require(amountOut >= amountOutMin, "ETHtxAMM: amountOut below min");
		_swapEthForEthtx(_msgSender(), amountIn, amountOut, useWETH);
	}

	function _swapEthForEthtx(
		address account,
		uint256 amountIn,
		uint256 amountOut,
		bool useWETH
	) internal virtual {
		uint256 availableSupply = IERC20(ethtx()).balanceOf(address(this));
		require(
			availableSupply >= amountOut,
			"ETHtxAMM: not enough ETHtx available"
		);

		if (useWETH) {
			IERC20(weth()).safeTransferFrom(account, address(this), amountIn);
		} else {
			IWETH(weth()).deposit{ value: amountIn }();
		}

		// Bypass fee by setting exemption for AMM contract
		IERC20(ethtx()).safeTransfer(account, amountOut);
	}

	function _swapEthtxForEth(
		address account,
		uint256 amountIn,
		uint256 amountOut,
		bool asWETH
	) internal virtual {
		// Apply fee
		IERC20(ethtx()).safeTransferFrom(account, address(this), amountIn);

		if (asWETH) {
			IERC20(weth()).safeTransfer(account, amountOut);
		} else {
			IWETH(weth()).withdraw(amountOut);
			payable(account).sendValue(amountOut);
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

abstract contract ETHtxAMMData {
	address internal _gasOracle;
	uint128 internal _targetCRatioNum;
	uint128 internal _targetCRatioDen;
	address internal _ethtx;
	address internal _weth;

	uint256[46] private __gap;
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

interface IGasPrice {
	/* Views */

	function gasPrice() external view returns (uint256);

	function hasPriceExpired() external view returns (bool);

	function updateThreshold() external view returns (uint256);

	function updatedAt() external view returns (uint256);

	/* Mutators */

	function setGasPrice(uint256 _gasPrice) external;

	function setUpdateThreshold(uint256 _updateThreshold) external;

	/* Events */

	event GasPriceUpdate(address indexed author, uint256 newValue);
	event UpdateThresholdSet(address indexed author, uint256 value);
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

interface IFeeLogic {
	/* Types */

	struct ExemptData {
		address account;
		bool isExempt;
	}

	/* Views */

	function exemptsAt(uint256 index) external view returns (address);

	function exemptsLength() external view returns (uint256);

	function feeRate()
		external
		view
		returns (uint128 numerator, uint128 denominator);

	function getFee(
		address sender,
		address recipient_,
		uint256 amount
	) external view returns (uint256);

	function isExempt(address account) external view returns (bool);

	function recipient() external view returns (address);

	function undoFee(
		address sender,
		address recipient_,
		uint256 amount
	) external view returns (uint256);

	/* Mutators */

	function notify(uint256 amount) external;

	function setExempt(address account, bool isExempt_) external;

	function setExemptBatch(ExemptData[] memory batch) external;

	function setFeeRate(uint128 numerator, uint128 denominator) external;

	function setRecipient(address account) external;

	/* Events */

	event ExemptAdded(address indexed author, address indexed account);
	event ExemptRemoved(address indexed author, address indexed account);
	event FeeRateSet(
		address indexed author,
		uint128 numerator,
		uint128 denominator
	);
	event RecipientSet(address indexed author, address indexed account);
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

interface IERC20TxFee {
	/* Views */

	function feeLogic() external view returns (address);
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