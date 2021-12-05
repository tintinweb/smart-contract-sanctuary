/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

// File: contracts\interface\ITokenHub.sol

pragma solidity ^0.6.0;

interface ITokenHub {

  function getMiniRelayFee() external view returns(uint256);

  function transferOut(address contractAddr, address recipient, uint256 amount, uint64 expireTime)
    external payable returns (bool);
}

// File: contracts\interface\IVault.sol

pragma solidity ^0.6.0;

interface IVault {

    function claimBNB(uint256 amount, address payable recipient) external returns(uint256);

}

// File: contracts\interface\IMintBurnToken.sol

pragma solidity ^0.6.0;

interface IMintBurnToken {

    function mintTo(address to, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);
}

// File: node_modules\openzeppelin-solidity\contracts\utils\Context.sol

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

// File: openzeppelin-solidity\contracts\GSN\Context.sol



pragma solidity >=0.6.0 <0.8.0;

// File: openzeppelin-solidity\contracts\math\SafeMath.sol



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

// File: openzeppelin-solidity\contracts\utils\ReentrancyGuard.sol



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

// File: node_modules\openzeppelin-solidity\contracts\utils\Address.sol



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

// File: openzeppelin-solidity\contracts\proxy\Initializable.sol



// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


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
        return !Address.isContract(address(this));
    }
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\IERC20.sol



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

// File: node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol



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

// File: openzeppelin-solidity\contracts\token\ERC20\SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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

// File: contracts\HyBankImpl.sol

pragma solidity 0.6.12;









contract HyBankImpl is Context, Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant public ZERO_ADDR = 0x0000000000000000000000000000000000000000;
    address constant public TOKENHUB_ADDR = 0x0000000000000000000000000000000000001004;

    uint8 constant public BREATHE_PERIOD = 0;
    uint8 constant public NORMAL_PERIOD = 1;

    uint256 constant public MINIMUM_STAKE_AMOUNT = 1 * 1e18; // 1:BNB
    uint256 constant public MINIMUM_UNSTAKE_AMOUNT = 8 * 1e17; // 0.8:BNB
    uint256 constant public EXCHANGE_RATE_PRECISION = 1e9;
    uint256 constant public PRICE_TO_ACCELERATE_UNSTAKE_PRECISION = 1e9;

    address public LBNB;
    address public SBF;
    address public bcStakingTSS;
    address payable public communityTaxVault;
    address payable public stakingRewardVault;
    address payable public unstakeVault;

    address public admin;
    address public pendingAdmin;

    bool private _paused;

    struct Unstake {
        address payable staker;
        uint256 amount;
        uint256 timestamp;
    }

    uint256 public lbnbMarketCapacityCountByBNB;
    uint256 public lbnbToBNBExchangeRate;

    mapping(uint256 => Unstake) public unstakesMap;
    mapping(address => uint256[]) public accountUnstakeSeqsMap;
    uint256 public headerIdx;
    uint256 public tailIdx;

    uint256 public priceToAccelerateUnstake;
    uint256 public stakeFeeMolecular;
    uint256 public stakeFeeDenominator;
    uint256 public unstakeFeeMolecular;
    uint256 public unstakeFeeDenominator;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event LogStake(address indexed staker, uint256 lbnbAmount, uint256 bnbAmount);
    event LogUnstake(address indexed staker, uint256 lbnbAmount, uint256 bnbAmount, uint256 index);
    event ClaimedUnstake(address indexed staker, uint256 amount, uint256 index);
    event LogUpdateLBNBToBNBExchangeRate(uint256 LBNBTotalSupply, uint256 LBNBMarketCapacityCountByBNB, uint256 LBNBToBNBExchangeRate);
    event Paused(address account);
    event Unpaused(address account);
    event ReceiveDeposit(address from, uint256 amount);
    event AcceleratedUnstakedBNB(address AcceleratedStaker, uint256 AcceleratedUnstakeIdx);
    event Deposit(address from, uint256 amount);

    constructor() public {}

    /* solium-disable-next-line */
    receive () external payable {
        emit Deposit(msg.sender, msg.value);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin is allowed");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    modifier mustInPeriod(uint8 expectedPeriod) {
        require(getPeriod() == expectedPeriod, "Wrong period");
        _;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "contract is not allowed");
        require(msg.sender == tx.origin, "no proxy contract is allowed");
        _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getPeriod() public view returns (uint8) {
        uint256 UTCTime = block.timestamp%86400;
        if (UTCTime<=600 || UTCTime>85200) {
            return BREATHE_PERIOD;
        } else {
            return NORMAL_PERIOD;
        }
    }

    function initialize(
        address _admin,
        address _LBNB,
        address _SBF,
        address _bcStakingTSS,
        address payable _communityTaxVault,
        address payable _stakingRewardVault,
        address payable _unstakeVault,
        uint256 _priceToAccelerateUnstake
    ) external initializer{
        admin = _admin;

        lbnbToBNBExchangeRate = EXCHANGE_RATE_PRECISION;
        LBNB = _LBNB;
        SBF = _SBF;

        bcStakingTSS = _bcStakingTSS;

        communityTaxVault = _communityTaxVault;
        stakingRewardVault = _stakingRewardVault;
        unstakeVault = _unstakeVault;

        priceToAccelerateUnstake = _priceToAccelerateUnstake;
        stakeFeeMolecular = 1;
        stakeFeeDenominator = 1000;
        unstakeFeeMolecular = 1;
        unstakeFeeDenominator = 1000;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function pause() external onlyAdmin whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() external onlyAdmin whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) external {
        require(msg.sender == admin, "setPendingAdmin: Call must come from admin.");
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function setCommunityTaxVault(address payable newCommunityTaxVault) onlyAdmin external {
        communityTaxVault = newCommunityTaxVault;
    }

    function setPriceToAccelerateUnstake(uint256 newPriceToAccelerateUnstake) onlyAdmin external {
        priceToAccelerateUnstake = newPriceToAccelerateUnstake;
    }

     function setStakeFeeRate(uint256 newStakeFeeMolecular, uint256 newStakeFeeDenominator) onlyAdmin external {
        require(newStakeFeeDenominator>0, "stakeFeeDenominator must be positive");
        if (newStakeFeeMolecular>0) {
            require(newStakeFeeDenominator.div(newStakeFeeMolecular)>200, "stake fee rate must be less than 0.5%");
        }
        stakeFeeMolecular = newStakeFeeMolecular;
        stakeFeeDenominator = newStakeFeeDenominator;
    }

    function setUnstakeFeeRate(uint256 newUnstakeFeeMolecular, uint256 newUnstakeFeeDenominator) onlyAdmin external {
        require(newUnstakeFeeDenominator>0, "unstakeFeeDenominator must be positive");
        if (newUnstakeFeeMolecular>0) {
            require(newUnstakeFeeDenominator.div(newUnstakeFeeMolecular)>200, "unstake fee rate must be less than 0.5%");
        }
        unstakeFeeMolecular = newUnstakeFeeMolecular;
        unstakeFeeDenominator = newUnstakeFeeDenominator;
    }

    function stake(uint256 amount) nonReentrant mustInPeriod(NORMAL_PERIOD) notContract whenNotPaused external payable returns (bool) {

        uint256 miniRelayFee = ITokenHub(TOKENHUB_ADDR).getMiniRelayFee();

        require(msg.value == amount.add(miniRelayFee), "msg.value must equal to amount + miniRelayFee");
        require(amount%1e10==0 && amount>=MINIMUM_STAKE_AMOUNT, "stake amount must be N * 1e10 and more than 1:BNB");

        uint256 stakeFee = amount.mul(stakeFeeMolecular).div(stakeFeeDenominator);
        communityTaxVault.transfer(stakeFee);
        uint256 stakeAmount = amount.sub(stakeFee);
        lbnbMarketCapacityCountByBNB = lbnbMarketCapacityCountByBNB.add(stakeAmount);
        uint256 lbnbAmount = stakeAmount.mul(EXCHANGE_RATE_PRECISION).div(lbnbToBNBExchangeRate);

        uint256 stakeAmountDust = stakeAmount.mod(1e10);
        if (stakeAmountDust != 0) {
            unstakeVault.transfer(stakeAmountDust);
            stakeAmount = stakeAmount.sub(stakeAmountDust);
        }

        ITokenHub(TOKENHUB_ADDR).transferOut{value:miniRelayFee.add(stakeAmount)}(ZERO_ADDR, bcStakingTSS, stakeAmount, uint64(block.timestamp + 3600));

        IMintBurnToken(LBNB).mintTo(msg.sender, lbnbAmount);
        emit LogStake(msg.sender, lbnbAmount, stakeAmount);

        return true;
    }

    function unstake(uint256 amount) nonReentrant mustInPeriod(NORMAL_PERIOD) notContract whenNotPaused external returns (bool) {
        require(amount>=MINIMUM_UNSTAKE_AMOUNT, "unstake amount must be more than 0.8:LBNB");
        uint256 unstakeFee = amount.mul(unstakeFeeMolecular).div(unstakeFeeDenominator);
        IERC20(LBNB).safeTransferFrom(msg.sender, communityTaxVault, unstakeFee);

        uint256 unstakeAmount = amount.sub(unstakeFee);
        IERC20(LBNB).safeTransferFrom(msg.sender, address(this), unstakeAmount);
        IMintBurnToken(LBNB).burn(unstakeAmount);

        uint256 bnbAmount = unstakeAmount.mul(lbnbToBNBExchangeRate).div(EXCHANGE_RATE_PRECISION);
        bnbAmount = bnbAmount.sub(bnbAmount.mod(1e10));
        lbnbMarketCapacityCountByBNB = lbnbMarketCapacityCountByBNB.sub(bnbAmount);
        unstakesMap[tailIdx] = Unstake({
            staker: msg.sender,
            amount: bnbAmount,
            timestamp: block.timestamp
        });
        uint256[] storage unstakes = accountUnstakeSeqsMap[msg.sender];
        unstakes.push(tailIdx);

        emit LogUnstake(msg.sender, unstakeAmount, bnbAmount, tailIdx);
        tailIdx++;
        return true;
    }

    function estimateSBFCostForAccelerate(uint256 unstakeIndex, uint256 steps) external view returns (uint256, uint256) {
        if (steps == 0) return (0, 0);
        if (unstakeIndex<steps) return (0, 0);
        if ((unstakeIndex.sub(steps))<headerIdx || unstakeIndex>=tailIdx) return (0, 0);

        Unstake memory unstake = unstakesMap[unstakeIndex];
        uint256 timestampThreshold = unstake.timestamp.sub(unstake.timestamp.mod(86400));
        uint256 sbfBurnAmount = 0;
        uint256 actualSteps = 0;
        for (uint256 idx = unstakeIndex.sub(1) ; idx >= unstakeIndex.sub(steps); idx--) {
            Unstake memory priorUnstake = unstakesMap[idx];
            if (priorUnstake.timestamp<timestampThreshold) {
                break;
            }
            actualSteps++;
            sbfBurnAmount = sbfBurnAmount.add(priorUnstake.amount.mul(priceToAccelerateUnstake));
        }
        sbfBurnAmount = sbfBurnAmount.add(unstake.amount.mul(actualSteps).mul(priceToAccelerateUnstake));
        return (actualSteps, sbfBurnAmount.div(PRICE_TO_ACCELERATE_UNSTAKE_PRECISION));
    }

    function accelerateUnstakedMature(uint256 unstakeIndex, uint256 steps, uint256 sbfMaxCost) nonReentrant whenNotPaused external returns (bool) {
        require(steps > 0, "accelerate steps must be greater than zero");
        require(unstakeIndex.sub(steps)>=headerIdx && unstakeIndex<tailIdx, "unstakeIndex is out of valid accelerate range");

        Unstake memory unstake = unstakesMap[unstakeIndex];
        require(unstake.staker==msg.sender, "only staker can accelerate itself");
        uint256 timestampThreshold = unstake.timestamp.sub(unstake.timestamp.mod(86400));

        uint256 sbfBurnAmount = unstake.amount.mul(steps).mul(priceToAccelerateUnstake);
        for (uint256 idx = unstakeIndex.sub(1) ; idx >= unstakeIndex.sub(steps); idx--) {
            Unstake memory priorUnstake = unstakesMap[idx];
            require(priorUnstake.timestamp>=timestampThreshold, "forbid to exceed unstake in prior day");
            unstakesMap[idx+1] = priorUnstake;
            sbfBurnAmount = sbfBurnAmount.add(priorUnstake.amount.mul(priceToAccelerateUnstake));
            uint256[] storage priorUnstakeSeqs = accountUnstakeSeqsMap[priorUnstake.staker];
            bool found = false;
            for(uint256 i=0; i < priorUnstakeSeqs.length; i++) {
                if (priorUnstakeSeqs[i]==idx) {
                    priorUnstakeSeqs[i]=idx+1;
                    found = true;
                    break;
                }
            }
            require(found, "failed to find matched unstake sequence");
        }
        sbfBurnAmount = sbfBurnAmount.div(PRICE_TO_ACCELERATE_UNSTAKE_PRECISION);

        uint256[] storage unstakeSeqs = accountUnstakeSeqsMap[msg.sender];
        unstakesMap[unstakeIndex.sub(steps)] = unstake;
        bool found = false;
        for(uint256 idx=0; idx < unstakeSeqs.length; idx++) {
            if (unstakeSeqs[idx]==unstakeIndex) {
                unstakeSeqs[idx] = unstakeIndex.sub(steps);
                found = true;
                break;
            }
        }
        require(found, "failed to find matched unstake sequence");

        require(sbfBurnAmount<=sbfMaxCost, "cost too much SBF");
        IERC20(SBF).safeTransferFrom(msg.sender, address(this), sbfBurnAmount);
        IMintBurnToken(SBF).burn(sbfBurnAmount);

        emit AcceleratedUnstakedBNB(msg.sender, unstakeIndex);

        return true;
    }

    function getUnstakeSeqsLength(address addr) external view returns (uint256) {
        return accountUnstakeSeqsMap[addr].length;
    }

    function getUnstakeSequence(address addr, uint256 idx) external view returns (uint256) {
        return accountUnstakeSeqsMap[addr][idx];
    }

    function isUnstakeClaimable(uint256 unstakeSeq) external view returns (bool) {
        if (unstakeSeq < headerIdx || unstakeSeq >= tailIdx) {
            return false;
        }
        uint256 totalUnstakeAmount = 0;
        for(uint256 idx=headerIdx; idx <= unstakeSeq; idx++) {
            Unstake memory unstake = unstakesMap[idx];
            totalUnstakeAmount=totalUnstakeAmount.add(unstake.amount);
        }
        return unstakeVault.balance >= totalUnstakeAmount;
    }

    function batchClaimPendingUnstake(uint256 batchSize) nonReentrant whenNotPaused external {
        for(uint256 idx=0; idx < batchSize && headerIdx < tailIdx; idx++) {
            Unstake memory unstake = unstakesMap[headerIdx];
            uint256 unstakeBNBAmount = unstake.amount;
            if (unstakeVault.balance < unstakeBNBAmount) {
                return;
            }
            delete unstakesMap[headerIdx];
            uint256 actualAmount = IVault(unstakeVault).claimBNB(unstakeBNBAmount, unstake.staker);
            require(actualAmount==unstakeBNBAmount, "amount mismatch");
            emit ClaimedUnstake(unstake.staker, unstake.amount, headerIdx);

            uint256[] storage unstakeSeqs = accountUnstakeSeqsMap[unstake.staker];
            uint256 lastSeq = unstakeSeqs[unstakeSeqs.length-1];
            if (lastSeq != headerIdx) {
                bool found = false;
                for(uint256 index=0; index < unstakeSeqs.length; index++) {
                    if (unstakeSeqs[index]==headerIdx) {
                        unstakeSeqs[index] = lastSeq;
                        found = true;
                        break;
                    }
                }
                require(found, "failed to find matched unstake sequence");
            }
            unstakeSeqs.pop();

            headerIdx++;
        }
    }

    function rebaseLBNBToBNB() whenNotPaused external returns(bool) {
        uint256 rewardVaultBalance = stakingRewardVault.balance;
        require(rewardVaultBalance>0, "stakingRewardVault has no BNB");
        uint256 actualAmount = IVault(stakingRewardVault).claimBNB(rewardVaultBalance, unstakeVault);
        require(rewardVaultBalance==actualAmount, "reward amount mismatch");

        uint256 lbnbTotalSupply = IERC20(LBNB).totalSupply();
        lbnbMarketCapacityCountByBNB = lbnbMarketCapacityCountByBNB.add(rewardVaultBalance);
        if (lbnbTotalSupply == 0) {
            lbnbToBNBExchangeRate = EXCHANGE_RATE_PRECISION;
        } else {
            lbnbToBNBExchangeRate = lbnbMarketCapacityCountByBNB.mul(EXCHANGE_RATE_PRECISION).div(lbnbTotalSupply);
        }
        emit LogUpdateLBNBToBNBExchangeRate(lbnbTotalSupply, lbnbMarketCapacityCountByBNB, lbnbToBNBExchangeRate);
        return true;
    }

    function resendBNBToBCStakingTSS(uint256 amount) mustInPeriod(NORMAL_PERIOD) whenNotPaused external payable returns(bool) {

        uint256 miniRelayFee = ITokenHub(TOKENHUB_ADDR).getMiniRelayFee();

        require(msg.value == miniRelayFee, "msg.value must equal to miniRelayFee");
        require(address(this).balance >= amount, "BNB balance is not enough");
        require(amount%1e10==0, "amount must be N * 1e10");

        ITokenHub(TOKENHUB_ADDR).transferOut{value:miniRelayFee.add(amount)}(ZERO_ADDR, bcStakingTSS, amount, uint64(block.timestamp + 3600));

        return true;
    }
}