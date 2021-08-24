/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

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


// solhint-disable-next-line compiler-version




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






/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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




/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: node_modules\@openzeppelin\contracts\token\ERC721\IERC721.sol


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: node_modules\@openzeppelin\contracts\token\ERC721\IERC721Metadata.sol





/* ROOTKIT:
Allows recovery of unexpected tokens (airdrops, etc)
Inheriters can customize logic by overriding canRecoverTokens
*/




abstract contract TokensRecoverableUpg is OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function recoverTokens(IERC20Upgradeable token) public onlyOwner() 
    {
        require (canRecoverTokens(token));    
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverETH(uint256 amount) public onlyOwner() 
    {        
        msg.sender.transfer(amount);
    }

    function canRecoverTokens(IERC20Upgradeable token) internal virtual view returns (bool) 
    { 
        return address(token) != address(this); 
    }

}


abstract contract RewardsDistributionRecipient is OwnableUpgradeable {
    address public rewardsDistribution;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }
}

contract StakingRewards is Initializable, TokensRecoverableUpg, RewardsDistributionRecipient, ReentrancyGuardUpgradeable, PausableUpgradeable  {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    IERC20Upgradeable public rewardsToken1;
    IERC20Upgradeable public rewardsToken2;

    IERC20Upgradeable public stakingToken;
    IERC20Upgradeable public stakingTokenMultiplier;

    uint256 public periodFinish;
    
    uint256 public rewardRate1; 

    uint256 public rewardsDuration ;
    uint256 public lastUpdateTime;
    uint256 public rewardPerToken1Stored;
    uint256 public rewardPerToken2Stored;

    address public stakingPoolFeeAdd;
    address public devFundAdd;

    uint256 public stakingPoolFeeWithdraw;
    uint256 public devFundFeeWithdraw;

    mapping(address => uint256) public userRewardPerToken1Paid;

    mapping(address => uint256) public rewards1;

    uint256 private _totalSupply;
    uint256 private _totalSupplyMultiplier;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _balancesMultiplier;
    
    mapping(address => uint256) public lockingPeriodStaking;

    mapping(address => uint256) public multiplierFactor;

    uint256 public lockTimeStakingToken; 

    uint256 public totalToken1ForReward;
    
    uint256[3] public multiplierRewardToken1Amt;

    mapping(address=>uint256) public multiplierFactorNFT; // user address => NFT's M.F.
    mapping(address=>mapping(address=>bool)) public boostedByNFT; // user address => NFT contract => true if boosted by that particular NFT
    // avoids double boost 

    address[] NFTboostedAddresses; // all addresses who boosted by NFT

    mapping(address=>uint256) public totalNFTsBoostedBy; // total NFT boosts done by user

    mapping(address=>uint256) public boostPercentNFT; // set by owner 1*10^17 = 10% boost
    address[] public erc721NFTContracts;


    function initialize(        
        address _rewardsDistribution,
        address _rewardsToken1,
        address _stakingToken,
        address _stakingTokenMultiplier
        )  public initializer  {
        
        __Ownable_init_unchained();
        rewardsToken1 = IERC20Upgradeable(_rewardsToken1);

        stakingToken = IERC20Upgradeable(_stakingToken);
        stakingTokenMultiplier = IERC20Upgradeable(_stakingTokenMultiplier);
        rewardsDistribution = _rewardsDistribution;

        periodFinish = 0;
        rewardRate1 = 0;
        totalToken1ForReward=0;
        rewardsDuration = 60 days; 

        multiplierRewardToken1Amt = [400 ether, 800 ether, 1200 ether];

        stakingPoolFeeAdd = 0x66e11Dc99B8f8e350e30d4Ec3EA480EC01D7a360;
        devFundAdd = 0xc840AcDf17949a7Ae56641aa88F72148D7B43b72;
        
        stakingPoolFeeWithdraw = 5000; 
        devFundFeeWithdraw = 0; 

        lockTimeStakingToken = 20 days;

    }

   
    /* ========== VIEWS ========== */
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalSupplyMultiplier() external view returns (uint256) {
        return _totalSupplyMultiplier;
    }

    function balanceOfMultiplier(address account) external view returns (uint256) {
        return _balancesMultiplier[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return MathUpgradeable.min(block.timestamp, periodFinish);
    }

    function rewardPerToken1() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerToken1Stored;
        }
        return
            rewardPerToken1Stored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate1).mul(1e18).div(_totalSupply)
            );
    }
    
   
    // divide by 10^6 and add decimals => 6 d.p.
    function getMultiplyingFactor(address account) public view returns (uint256) {
        if (multiplierFactor[account] == 0 && multiplierFactorNFT[account] == 0) {
            return 1000000;
        }
        uint256 MFwei = multiplierFactor[account].add(multiplierFactorNFT[account]);
        if(MFwei<1e18){
            MFwei = MFwei.add(1e18);
        }
        return MFwei.div(1e12);
    }


    function getMultiplyingFactorWei(address account) public view returns (uint256) {
        if (multiplierFactor[account] == 0 && multiplierFactorNFT[account] == 0) {
            return 1e18;
        }
        uint256 MFWei = multiplierFactor[account].add(multiplierFactorNFT[account]);
        if(MFWei<1e18){
            MFWei = MFWei.add(1e18);
        }
        return MFWei;
    }

    function earnedtokenRewardToken1(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken1().sub(userRewardPerToken1Paid[account]))
        .div(1e18).add(rewards1[account]);
    }
    
    
    function totalEarnedRewardToken1(address account) public view returns (uint256) {
        return (_balances[account].mul(rewardPerToken1().sub(userRewardPerToken1Paid[account]))
        .div(1e18).add(rewards1[account])).mul(getMultiplyingFactorWei(account)).div(1e18);
    }
    
    function getReward1ForDuration() external view returns (uint256) {
        return rewardRate1.mul(rewardsDuration);
    }


    function getRewardToken1APY() external view returns (uint256) {
        //3153600000 = 365*24*60*60
        if(block.timestamp>periodFinish) return 0;
        uint256 rewardForYear = rewardRate1.mul(31536000); 
        if(_totalSupply<=1e18) return rewardForYear.div(1e10);
        return rewardForYear.mul(1e8).div(_totalSupply); // put 6 dp
    }

  

    function getRewardToken1WPY() external view returns (uint256) {
        //60480000 = 7*24*60*60
        if(block.timestamp>periodFinish) return 0;
        uint256 rewardForWeek = rewardRate1.mul(604800); 
        if(_totalSupply<=1e18) return rewardForWeek.div(1e10);
        return rewardForWeek.mul(1e8).div(_totalSupply); // put 6 dp
    }


   


    /* ========== MUTATIVE FUNCTIONS ========== */

    // feeAmount = 100 => 1%
    function setTransferParams(address _stakingPoolFeeAdd, address _devFundAdd, uint256 _stakingPoolFeeStaking, uint256 _devFundFeeStaking
        ) external onlyOwner{

        stakingPoolFeeAdd = _stakingPoolFeeAdd;
        devFundAdd = _devFundAdd;
        stakingPoolFeeWithdraw = _stakingPoolFeeStaking;
        devFundFeeWithdraw = _devFundFeeStaking;
    }

    function setTimelockStakingToken(uint256 lockTime) external onlyOwner{
         lockTimeStakingToken=lockTime;   
    }
    
    function pause() external onlyOwner{
        _pause();
    }
    function unpause() external onlyOwner{
        _unpause();
    }


    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        
        lockingPeriodStaking[msg.sender]= block.timestamp.add(lockTimeStakingToken);

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function boostByToken(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Cannot stake 0");

        _totalSupplyMultiplier = _totalSupplyMultiplier.add(amount);
        _balancesMultiplier[msg.sender] = _balancesMultiplier[msg.sender].add(amount);
        
        // send the whole multiplier fee to dev fund address
        stakingTokenMultiplier.safeTransferFrom(msg.sender, devFundAdd, amount);
        getTotalMultiplier(msg.sender);
        emit BoostedStake(msg.sender, amount);
    }



    // _boostPercent = 10000 => 10% => 10^4 * 10^13
    function addNFTasMultiplier(address _erc721NFTContract, uint256 _boostPercent) external onlyOwner {
        
        require(block.timestamp >= periodFinish, 
            "Cannot set NFT boosts after staking starts"
        );
        
        erc721NFTContracts.push(_erc721NFTContract);
        boostPercentNFT[_erc721NFTContract] = _boostPercent.mul(1e13);
    }


    // if next cycle of staking starts it resets for all users
    function _resetNFTasMultiplierForUser() internal {

        for(uint i=0;i<NFTboostedAddresses.length;i++){
            totalNFTsBoostedBy[NFTboostedAddresses[i]]=0;

            for(uint j=0;j<erc721NFTContracts.length;j++)
                    boostedByNFT[NFTboostedAddresses[i]][erc721NFTContracts[j]]=false;

            multiplierFactorNFT[NFTboostedAddresses[i]]=0;
        }

        delete NFTboostedAddresses;
    }

    // reset possible after Previous rewards period finishes
    function resetNFTasMultiplier() external onlyOwner {
        require(block.timestamp > periodFinish,
            "Previous rewards period must be complete before resetting"
        );

        for(uint i=0;i<erc721NFTContracts.length;i++){
            boostPercentNFT[erc721NFTContracts[i]] = 0;
        }

        _resetNFTasMultiplierForUser();
        delete erc721NFTContracts;
    }


    // can get total boost possible by user's NFTs
    function getNFTBoostPossibleByAddress(address NFTowner) public view returns(uint256){

        uint256 multiplyFactor = 0;
        for(uint i=0;i<erc721NFTContracts.length;i++){

            if(IERC721(erc721NFTContracts[i]).balanceOf(NFTowner)>=1)
                multiplyFactor = multiplyFactor.add(boostPercentNFT[erc721NFTContracts[i]]);

        }

        uint256 boostWei= multiplierFactor[NFTowner].add(multiplyFactor);
        return boostWei.div(1e12);

    }


    // approve NFT to contract before you call this function
    function boostByNFT(address _erc721NFTContract, uint256 _tokenId) external nonReentrant whenNotPaused {
    
        require(block.timestamp <= periodFinish, 
            "Cannot use NFT boosts before staking starts"
        );
        
        uint256 multiplyFactor = boostPercentNFT[_erc721NFTContract];

        if(totalNFTsBoostedBy[msg.sender]==0){
            NFTboostedAddresses.push(msg.sender);
        }

        bool NFTallowed = false;
        for(uint i=0;i<erc721NFTContracts.length;i++){
            if(_erc721NFTContract == erc721NFTContracts[i]){
                NFTallowed=true;
                break;
            }
        }

        require(NFTallowed==true, "This NFT is not allowed for boosts");

        // CHECK already boosted by same NFT contract??
        require(boostedByNFT[msg.sender][_erc721NFTContract]==false,"Already boosted by this NFT");

        require(totalNFTsBoostedBy[msg.sender]<=erc721NFTContracts.length,"Total boosts cannot be more than MAX NfT boosts available");

        multiplierFactorNFT[msg.sender]= multiplierFactorNFT[msg.sender].add(multiplyFactor);
        IERC721(_erc721NFTContract).transferFrom(msg.sender, devFundAdd, _tokenId);

        totalNFTsBoostedBy[msg.sender]=totalNFTsBoostedBy[msg.sender].add(1);
        boostedByNFT[msg.sender][_erc721NFTContract] = true;

        emit NFTMultiplier(msg.sender, _erc721NFTContract, _tokenId);
    }

    
    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(amount<=_balances[msg.sender],"Staked amount is lesser");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        if(block.timestamp < lockingPeriodStaking[msg.sender]){
            uint256 devFee = amount.mul(devFundFeeWithdraw).div(100000); // feeWithdraw = 100000 = 100%
            stakingToken.safeTransfer(devFundAdd, devFee);
            uint256 stakingFee = amount.mul(stakingPoolFeeWithdraw).div(100000); // feeWithdraw = 100000 = 100%
            stakingToken.safeTransfer(stakingPoolFeeAdd, stakingFee);
            uint256 remAmount = amount.sub(devFee).sub(stakingFee);
            stakingToken.safeTransfer(msg.sender, remAmount);
        }
        else    
            stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }


    function getReward() public nonReentrant whenNotPaused updateReward(msg.sender) {
        uint256 reward1 = rewards1[msg.sender].mul(getMultiplyingFactorWei(msg.sender)).div(1e18);
        
        if (reward1 > 0) {
            rewards1[msg.sender] = 0;
            rewardsToken1.safeTransfer(msg.sender, reward1);
            totalToken1ForReward=totalToken1ForReward.sub(reward1);
        }       

        emit RewardPaid(msg.sender, reward1);
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    // reward 1  => DMagic
    function notifyRewardAmount(uint256 rewardToken1Amount) external onlyRewardsDistribution updateReward(address(0)) {

        totalToken1ForReward = totalToken1ForReward.add(rewardToken1Amount);

        // using x% of reward amount, remaining locked for multipliers 
        // x * 1.3 (max M.F.) = 100
        uint256 multiplyFactor = 1e18 + 3e17; // 130%
        for(uint i=0;i<erc721NFTContracts.length;i++){
                multiplyFactor = multiplyFactor.add(boostPercentNFT[erc721NFTContracts[i]]);
        }

        uint256 denominatorForMF = 1e20;

        // reward * 100 / 130 ~ 76% (if NO NFT boost)
        uint256 reward1Available = rewardToken1Amount.mul(denominatorForMF).div(multiplyFactor).div(100); 
        // uint256 reward2Available = rewardToken2.mul(denominatorForMF).div(multiplyFactor).div(100);

        if (block.timestamp >= periodFinish) {
            rewardRate1 = reward1Available.div(rewardsDuration);
            _resetNFTasMultiplierForUser();
        } 
        else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover1 = remaining.mul(rewardRate1);
            rewardRate1 = reward1Available.add(leftover1).div(rewardsDuration);
        }
        
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance1 = rewardsToken1.balanceOf(address(this));
        require(rewardRate1 <= balance1.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);

        emit RewardAdded(reward1Available);
    }


    // only left over reward provided by owner can be withdrawn after reward period finishes
    function withdrawNotified() external onlyOwner {
        require(block.timestamp >= periodFinish, 
            "Cannot withdraw before reward time finishes"
        );
        
        address owner = OwnableUpgradeable.owner();
        // only left over reward amount will be left
        IERC20Upgradeable(rewardsToken1).safeTransfer(owner, totalToken1ForReward);
        
        emit Recovered(address(rewardsToken1), totalToken1ForReward);
        
        totalToken1ForReward=0;
    }

    // only reward provided by owner can be withdrawn in emergency, user stakes are safe
    function withdrawNotifiedEmergency(uint256 reward1Amount) external onlyOwner {

        require(reward1Amount<=totalToken1ForReward,"Total reward left to distribute is lesser");

        address owner = OwnableUpgradeable.owner();
        // only left over reward amount will be left
        IERC20Upgradeable(rewardsToken1).safeTransfer(owner, reward1Amount);
        
        emit Recovered(address(rewardsToken1), reward1Amount);
        
        totalToken1ForReward=totalToken1ForReward.sub(reward1Amount);

    }
    
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Cannot recover the staking token or the rewards token
        require(
            tokenAddress != address(stakingToken) && tokenAddress != address(stakingTokenMultiplier) && tokenAddress != address(rewardsToken1) && tokenAddress != address(rewardsToken2),
            "Cannot withdraw the staking or rewards tokens"
        );
        address owner = OwnableUpgradeable.owner();
        IERC20Upgradeable(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }


    function setOnMultiplierAmount(uint256[3] calldata _values) external onlyOwner {
        multiplierRewardToken1Amt = _values;
    }

    // view function for input as multiplier token amount
    // returns Multiply Factor in 6 decimal place
    function getMultiplierForAmount(uint256 _amount) public view returns(uint256) {
        uint256 multiplier=0;        
        uint256 parts=0;
        uint256 totalParts=1;

        if(_amount>=multiplierRewardToken1Amt[0] && _amount < multiplierRewardToken1Amt[1]) {
            totalParts = multiplierRewardToken1Amt[1].sub(multiplierRewardToken1Amt[0]);
            parts = _amount.sub(multiplierRewardToken1Amt[0]); 
            multiplier = parts.mul(1e17).div(totalParts).add(10 ** 17); 
        }
        else if(_amount>=multiplierRewardToken1Amt[1] && _amount < multiplierRewardToken1Amt[2]) {
            totalParts = multiplierRewardToken1Amt[2].sub(multiplierRewardToken1Amt[1]);
            parts = _amount.sub(multiplierRewardToken1Amt[1]); 
            multiplier = parts.mul(1e17).div(totalParts).add(2 * 10 ** 17); 
        }
     
        else if(_amount>=multiplierRewardToken1Amt[2]){
            multiplier = 3 * 10 ** 17;
        }

      
         uint256 multiplyFactor = multiplier.add(1e18);
         return multiplyFactor.div(1e12);
    }


    function getTotalMultiplier(address account) internal{
        uint256 multiplier=0;        
        uint256 parts=0;
        uint256 totalParts=1;

        uint256 _amount = _balancesMultiplier[account];

        if(_amount>=multiplierRewardToken1Amt[0] && _amount < multiplierRewardToken1Amt[1]) {
            totalParts = multiplierRewardToken1Amt[1].sub(multiplierRewardToken1Amt[0]);
            parts = _amount.sub(multiplierRewardToken1Amt[0]); 
            multiplier = parts.mul(1e17).div(totalParts).add(10 ** 17); 
        }
        else if(_amount>=multiplierRewardToken1Amt[1] && _amount < multiplierRewardToken1Amt[2]) {
            totalParts = multiplierRewardToken1Amt[2].sub(multiplierRewardToken1Amt[1]);
            parts = _amount.sub(multiplierRewardToken1Amt[1]); 
            multiplier = parts.mul(1e17).div(totalParts).add(2 * 10 ** 17); 
        }

        else if(_amount>=multiplierRewardToken1Amt[2]){
            multiplier = 3 * 10 ** 17;
        }

         uint256 multiplyFactor = multiplier.add(1e18);
         multiplierFactor[msg.sender]=multiplyFactor;
    }
    
    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerToken1Stored = rewardPerToken1();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards1[account] = earnedtokenRewardToken1(account);
            userRewardPerToken1Paid[account] = rewardPerToken1Stored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward1);
    event Staked(address indexed user, uint256 amount);
    event BoostedStake(address indexed user, uint256 amount);
    event NFTMultiplier(address indexed user, address ERC721NFTContract, uint256 tokenId);
    
    event Withdrawn(address indexed user, uint256 amount);
    event WithdrawnMultiplier(address indexed user, uint256 amount);

    event RewardPaid(address indexed user, uint256 reward1);

    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
    

}