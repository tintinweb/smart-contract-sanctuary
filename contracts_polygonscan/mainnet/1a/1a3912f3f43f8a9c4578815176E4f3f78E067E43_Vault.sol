/**
 *Submitted for verification at polygonscan.com on 2021-08-22
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @openzeppelin/contracts/utils/math/[email protected]

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

pragma solidity ^0.8.0;


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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

pragma solidity ^0.8.0;




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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}


// File contracts/interfaces/IStrategy.sol

pragma solidity ^0.8.0;

interface IStrategy {

    function unsalvagableTokens(address tokens) external view returns (bool);
    
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}


// File contracts/interfaces/IVault.sol

pragma solidity ^0.8.0;

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address) external;
    function setVaultFractionToInvest(uint256) external;

    function deposit(uint256) external;

    function withdrawAll() external;
    function withdraw(uint256) external;

    function getReward() external;
    function getRewardByToken(address) external;
    function notifyRewardAmount(address, uint256) external;

    function getPricePerFullShare() external view returns (uint256);
    function underlyingBalanceWithInvestmentForHolder(address) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
    function rebalance() external;
}


// File contracts/interfaces/IController.sol

pragma solidity ^0.8.0;

interface IController {
    function whitelist(address) external view returns (bool);
    function feeExemptAddresses(address) external view returns (bool);
    function greyList(address) external view returns (bool);
    function keepers(address) external view returns (bool);

    function doHardWork(address) external;
    function batchDoHardWork(address[] memory) external;

    function salvage(address, uint256) external;
    function salvageStrategy(address, address, uint256) external;

    function notifyFee(address, uint256) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);
}


// File contracts/interfaces/IUpgradeSource.sol

pragma solidity ^0.8.0;

interface IUpgradeSource {
  function shouldUpgrade() external view returns (bool, address);
  function finalizeUpgrade() external;
}


// File contracts/Storage.sol

pragma solidity ^0.8.0;

contract Storage {

  address public governance;
  address public controller;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Storage: Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "Storage: New governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "Storage: New controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}


// File contracts/GovernableInit.sol

pragma solidity ^0.8.0;
/**
 * @dev Contract for access control where the governance address specified
 * in the Storage contract can be granted access to specific functions
 * on a contract that inherits this contract.
 *
 * The difference between GovernableInit and Governable is that GovernableInit supports proxy
 * smart contracts.
 */

contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Governable: Not governance");
    _;
  }

  constructor() {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function __Governable_init_(address _store) public initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}


// File contracts/ControllableInit.sol

pragma solidity ^0.8.0;
contract ControllableInit is GovernableInit {

  constructor() {}

  function __Controllable_init(address _storage) public initializer {
    __Governable_init_(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Controllable: Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "Controllable: The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}


// File contracts/VaultStorage.sol

pragma solidity 0.8.6;
/// @title Vault Storage
/// @author Chainvisions
/// @notice Contract that handles storage for primitive types in the Vault contract.

abstract contract VaultStorage is Initializable, IVault {
    mapping(bytes32 => uint256) private uint256Storage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private boolStorage;

    function __VaultStorage_init(
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _underlyingUnit,
        uint256 _timelockDelay,
        bool _allowLossesOnHarvest,
        uint256 _depositMaturityTime,
        uint256 _exitFee
    ) internal initializer {
        _setUnderlying(_underlying);
        _setFractionToInvestNumerator(_toInvestNumerator);
        _setUnderlyingUnit(_underlyingUnit);
        _setTimelockDelay(_timelockDelay);
        _setAllowLossesOnHarvest(_allowLossesOnHarvest);
        _setDepositMaturityTime(_depositMaturityTime);
        _setExitFee(_exitFee);
    }

    /// @dev Strategy used for yield optimization.
    function strategy() public view override returns (address) {
        return _getAddress("strategy");
    }

    /// @dev Underlying token of the vault.
    function underlying() public view override returns (address) {
        return _getAddress("underlying");
    }

    /// @dev Unit of the underlying token.
    function underlyingUnit() public view returns (uint256) {
        return _getUint256("underlyingUnit");
    }

    /// @dev Buffer for investing.
    function fractionToInvestNumerator() public view returns (uint256) {
        return _getUint256("fractionToInvestNumerator");
    }

    /// @dev Next implementation contract for the proxy.
    function nextImplementation() public view returns (address) {
        return _getAddress("nextImplementation");
    }

    /// @dev Timestamp of when the next upgrade can be executed.
    function nextImplementationTimestamp() public view returns (uint256) {
        return _getUint256("nextImplementationTimestamp");
    }

    /// @dev Timelock delay for strategy switches and upgrades.
    function timelockDelay() public view returns (uint256) {
        return _getUint256("timelockDelay");
    }

    /// @dev Next strategy contract for the vault.
    function futureStrategy() public view returns (address) {
        return _getAddress("futureStrategy");
    }

    /// @dev Timestamp of when the strategy switch can be executed.
    function strategyUpdateTime() public view returns (uint256) {
        return _getUint256("strategyUpdateTime");
    }

    /// @dev Allows for preventing losses from faulty strategies.
    /// Not recommended to be enabled for complex strategies.
    function allowLossesOnHarvest() public view returns (bool) {
        return _getBool("allowLossesOnHarvest");
    }

    /// @dev Minimum time since deposit to be able to exit without
    /// an exit penalty.
    function depositMaturityTime() public view returns (uint256) {
        return _getUint256("depositMaturityTime");
    }

    /// @dev Fee charged on exit if exiting the vault before
    /// the user's bTokens have matured.
    function exitFee() public view returns (uint256) {
        return _getUint256("exitFee");
    }

    /// @dev New exit fee after the timelock goes through.
    function nextExitFee() public view returns (uint256) {
        return _getUint256("nextExitFee");
    }

    /// @dev When the exit fee change can be finalized.
    function nextExitFeeTimestamp() internal view returns (uint256) {
        return _getUint256("nextExitFeeTimestamp");
    }

    function _setStrategy(address _address) internal {
        _setAddress("strategy", _address);
    }

    function _setUnderlying(address _address) internal {
        _setAddress("underlying", _address);
    }

    function _setUnderlyingUnit(uint256 _value) internal {
        _setUint256("underlyingUnit", _value);
    }

    function _setFractionToInvestNumerator(uint256 _value) internal {
        _setUint256("fractionToInvestNumerator", _value);
    }

    function _setNextImplementation(address _address) internal {
        _setAddress("nextImplementation", _address);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        _setUint256("nextImplementationTimestamp", _value);
    }

    function _setTimelockDelay(uint256 _value) internal {
        _setUint256("timelockDelay", _value);
    }

    function _setFutureStrategy(address _address) internal {
        _setAddress("futureStrategy", _address);
    }

    function _setStrategyUpdateTime(uint256 _value) internal {
        _setUint256("strategyUpdateTime", _value);
    }

    function _setAllowLossesOnHarvest(bool _value) internal {
        _setBool("allowLossesOnHarvest", _value);
    }

    function _setDepositMaturityTime(uint256 _value) internal {
        _setUint256("depositMaturityTime", _value);
    }

    function _setExitFee(uint256 _value) internal {
        _setUint256("exitFee", _value);
    }

    function _setNextExitFee(uint256 _value) internal {
        _setUint256("nextExitFee", _value);
    }

    function _setNextExitFeeTimestamp(uint256 _value) internal {
        _setUint256("nextExitFeeTimestamp", _value);
    }

    function _setUint256(string memory _key, uint256 _value) private {
        uint256Storage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _getUint256(string memory _key) private view returns (uint256) {
        return uint256Storage[keccak256(abi.encodePacked(_key))];
    }

    function _setAddress(string memory _key, address _value) private {
        addressStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _getAddress(string memory _key) private view returns (address) {
        return addressStorage[keccak256(abi.encodePacked(_key))];
    }

    function _setBool(string memory _key, bool _value) private {
        boolStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _getBool(string memory _key) private view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked(_key))];
    }

    uint256[50] private ______gap;
}


// File contracts/Vault.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;
/// @title Beluga Vault
/// @author Chainvisions
/// @notice Vault used for Beluga's yield optimization mechanisms.

contract Vault is ERC20Upgradeable, IUpgradeSource, ControllableInit, VaultStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // Reward Info
    mapping(address => bool) public rewardDistribution;
    address[] public rewardTokens;
    mapping(address => uint256) public durationForToken;
    mapping(address => uint256) public periodFinishForToken;
    mapping(address => uint256) public rewardRateForToken;
    mapping(address => uint256) public lastUpdateTimeForToken;
    mapping(address => uint256) public rewardPerTokenStoredForToken;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaidForToken;
    mapping(address => mapping(address => uint256)) public rewardsForToken;

    mapping(address => uint256) public lastDepositTimestamp;

    event Withdraw(address indexed beneficiary, uint256 amount);
    event Deposit(address indexed beneficiary, uint256 amount);
    event Invest(uint256 amount);
    event StrategyAnnounced(address newStrategy, uint256 time);
    event StrategyChanged(address newStrategy, address oldStrategy);
    event UpgradeAnnounced(address newImplementation);
    event ExitFeeChangeQueued(uint256 newFee, uint256 time);
    event ExitFeeChange(uint256 newFee, uint256 oldFee);
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 amount);
    event RewardInjection(address indexed rewardToken, uint256 rewardAmount);

    function initializeVault(
        address _storage,
        address _underlying,
        uint256 _toInvestNumerator,
        bool _allowLossesOnHarvest,
        uint256 _exitFee
    ) external initializer {
        require(_toInvestNumerator <= 10000, "Vault: Cannot invest more than 100%");

        __ERC20_init(
            string(abi.encodePacked("BELUGA ", ERC20Upgradeable(_underlying).symbol())),
            string(abi.encodePacked("b", ERC20Upgradeable(_underlying).symbol()))
        );
        __Controllable_init(_storage);

        uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
        __VaultStorage_init(
            _underlying,
            _toInvestNumerator,
            underlyingUnit,
            12 hours,
            _allowLossesOnHarvest,
            8 hours,
            _exitFee
        );
    }

    modifier whenStrategyDefined {
        require(address(strategy()) != address(0), "Vault: Strategy must be defined");
        _;
    }

    modifier defense {
        require(
            msg.sender == tx.origin ||
            IController(controller()).whitelist(msg.sender),
            "Vault: This smart contract is not whitelisted"
        );
        _;
    }

    modifier updateRewards(address _account) {
      for(uint256 i = 0; i < rewardTokens.length; i++ ){
        address rewardToken = rewardTokens[i];
        rewardPerTokenStoredForToken[rewardToken] = rewardPerToken(rewardToken);
        lastUpdateTimeForToken[rewardToken] = lastTimeRewardApplicable(rewardToken);
        if (_account != address(0)) {
            rewardsForToken[rewardToken][_account] = earned(rewardToken, _account);
            userRewardPerTokenPaidForToken[rewardToken][_account] = rewardPerTokenStoredForToken[rewardToken];
        }
      }
      _;
    }

    modifier updateReward(address _account, address _rewardToken){
      rewardPerTokenStoredForToken[_rewardToken] = rewardPerToken(_rewardToken);
      lastUpdateTimeForToken[_rewardToken] = lastTimeRewardApplicable(_rewardToken);
      if (_account != address(0)) {
          rewardsForToken[_rewardToken][_account] = earned(_rewardToken, _account);
          userRewardPerTokenPaidForToken[_rewardToken][_account] = rewardPerTokenStoredForToken[_rewardToken];
      }
      _;
    }

    /// @notice Deposits `underlying` into the vault and mints shares to the user.
    /// @param _amount Amount of `underlying` to deposit into the vault.
    function deposit(uint256 _amount) external override {
        _deposit(_amount, msg.sender, msg.sender);
    }
    /// @notice Withdraws `underlying` from the vault.
    /// @param _numberOfShares Shares to burn for `underlying`.
    function withdraw(uint256 _numberOfShares) external override defense {
        require(totalSupply() > 0, "Vault: Vault has no shares");
        require(_numberOfShares > 0, "Vault: numberOfShares must be greater than 0");
        uint256 supplySnapshot = totalSupply();
        _burn(msg.sender, _numberOfShares);

        uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
            .mul(_numberOfShares)
            .div(supplySnapshot);
        if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
            // Withdraw everything from the strategy to accurately check the share value.
            if (_numberOfShares == supplySnapshot) {
                IStrategy(strategy()).withdrawAllToVault();
            } else {
                uint256 missing = (underlyingAmountToWithdraw - underlyingBalanceInVault());
                IStrategy(strategy()).withdrawToVault(missing);
            }
            // Recalculate to improve accuracy.
            underlyingAmountToWithdraw = Math.min(underlyingBalanceWithInvestment()
                .mul(_numberOfShares)
                .div(supplySnapshot), underlyingBalanceInVault());
        }


        // Check if the user can exit without a penalty and if not, charge the exit penalty.
        if(
            exitFee() > 0 
            && lastDepositTimestamp[msg.sender] + depositMaturityTime() > block.timestamp
            && !IController(controller()).feeExemptAddresses(msg.sender)
        ) {
            // Calculate fee.
            uint256 feeFromUnderlying = (underlyingAmountToWithdraw * exitFee()) / 10000;

            // Calculate split.
            uint256 protocolFee = (feeFromUnderlying * 5000) / 10000;
            uint256 depositorFee = totalSupply() != 0   // We need to determine the fee by if there are existing depositors post-withdrawal.
                ? (feeFromUnderlying * 5000) / 10000      // This is to ensure dust is not left-over in the vault afterwards.
                : 0;

            // Perform split.
            if(depositorFee > 0) {
                // If deposits exist post-withdrawal, collect protocol fees + reward existing deposits.
                IERC20(underlying()).safeTransfer(controller(), protocolFee);
                IERC20(underlying()).safeTransfer(msg.sender, (underlyingAmountToWithdraw - feeFromUnderlying));
            } else {
                // Else, no other depositors exist and the protocol gets the full fee.
                IERC20(underlying()).safeTransfer(controller(), feeFromUnderlying);
                IERC20(underlying()).safeTransfer(msg.sender, (underlyingAmountToWithdraw - feeFromUnderlying));
            }
        } else {
            IERC20(underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);
        }

        // Update the withdrawal amount for the holder.
        emit Withdraw(msg.sender, underlyingAmountToWithdraw);
    }

    /// @notice Collects all earned rewards from the vault for the user.
    function getReward() external override defense updateRewards(msg.sender) {
        for(uint256 i = 0; i < rewardTokens.length; i++) {
            _getReward(rewardTokens[i]);
        }
    }

    /// @notice Collects the user's rewards of the specified reward token.
    /// @param _rewardToken Reward token to claim.
    function getRewardByToken(
        address _rewardToken
    ) external override defense updateReward(msg.sender, _rewardToken) {
        _getReward(_rewardToken);
    }

    /// @notice Invests `underlying` into the strategy to generate yields for the vault.
    function doHardWork() external override whenStrategyDefined onlyControllerOrGovernance {
        if(!allowLossesOnHarvest()) {
            uint256 prevSharePrice = getPricePerFullShare();
            _invest();
            IStrategy(strategy()).doHardWork();
            uint256 sharePriceAfter = getPricePerFullShare();
            require(sharePriceAfter >= prevSharePrice, "Vault: Losses occured on doHardWork");
        } else {
            _invest();
            IStrategy(strategy()).doHardWork();
        }
    }

    /// @notice Function used for rebalancing on the strategy.
    function rebalance() external override onlyControllerOrGovernance {
        withdrawAll();
        _invest();
    }

    /// @notice Finalizes or cancels upgrades by setting the next implementation address to 0.
    function finalizeUpgrade() external override onlyGovernance {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }

    /// @notice Determines if the vault can be upgraded.
    /// @return If the vault can be upgraded and the new implementation address.
    function shouldUpgrade() external view override returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0
                && block.timestamp > nextImplementationTimestamp()
                && nextImplementation() != address(0),
            nextImplementation()
        );
    }

    /// @notice Gets the total value of the user's shares.
    /// @param _holder Address of the user.
    /// @return The user's shares in `underlying`.
    function underlyingBalanceWithInvestmentForHolder(address _holder) external view override returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return (underlyingBalanceWithInvestment() * balanceOf(_holder)) / totalSupply();
    }

    /// @notice Schedules an upgrade to the vault.
    /// @param _impl Address of the new implementation.
    function scheduleUpgrade(address _impl) public onlyGovernance {
        _setNextImplementation(_impl);
        _setNextImplementationTimestamp(block.timestamp + timelockDelay());
        emit UpgradeAnnounced(_impl);
    }

    /// @notice Queues a strategy switch on the vault.
    /// @param _strategy Address of the strategy.
    function announceStrategyUpdate(address _strategy) public onlyControllerOrGovernance {
        // Records a new timestamp
        uint256 when = (block.timestamp + timelockDelay());
        _setStrategyUpdateTime(when);
        _setFutureStrategy(_strategy);
        emit StrategyAnnounced(_strategy, when);
    }

    /// @notice Finalizes or cancels strategy updates, sets the pending strategy to 0.
    function finalizeStrategyUpdate() public onlyControllerOrGovernance {
        _setStrategyUpdateTime(0);
        _setFutureStrategy(address(0));
    }

    /// @notice Updates the current strategy address, the vault's timelock applies if
    /// the current strategy address is not 0x00.
    /// @param _strategy Address of the new strategy.
    function setStrategy(address _strategy) public override onlyControllerOrGovernance {
        require(canUpdateStrategy(_strategy),
        "Vault: The strategy exists and switch timelock did not elapse yet");
        require(_strategy != address(0), "Vault: New _strategy cannot be empty");
        require(IStrategy(_strategy).underlying() == address(underlying()), "Vault: Vault underlying must match Strategy underlying");
        require(IStrategy(_strategy).vault() == address(this), "Vault: The strategy does not belong to this vault");

        emit StrategyChanged(_strategy, strategy());
        if(address(_strategy) != address(strategy())) {
            if(address(strategy()) != address(0)) {
                IERC20(underlying()).safeApprove(address(strategy()), 0);
                IStrategy(strategy()).withdrawAllToVault();
            }
            _setStrategy(_strategy);
            IERC20(underlying()).safeApprove(address(strategy()), 0);
            IERC20(underlying()).safeApprove(address(strategy()), type(uint256).max);
        }
        finalizeStrategyUpdate();
    }

    /// @notice Withdraws all tokens from the strategy to the vault.
    function withdrawAll() public override onlyControllerOrGovernance whenStrategyDefined {
        IStrategy(strategy()).withdrawAllToVault();
    }

    /// @notice Injects rewards into the vault.
    /// @param _rewardToken Token to reward, must be in the rewardTokens array.
    /// @param _amount Amount of `_rewardToken` to inject.
    function notifyRewardAmount(
        address _rewardToken,
        uint256 _amount
    ) public override updateRewards(address(0)) {
        require(
            msg.sender == governance() 
            || rewardDistribution[msg.sender], 
            "Vault: Caller not governance or reward distribution"
        );

        require(_amount < type(uint256).max / 1e18, "Vault: Notified amount invokes an overflow error");

        uint256 i = rewardTokenIndex(_rewardToken);
        require(i != type(uint256).max, "rewardTokenIndex not found");

        if (block.timestamp >= periodFinishForToken[_rewardToken]) {
            rewardRateForToken[_rewardToken] = _amount / durationForToken[_rewardToken];
        } else {
            uint256 remaining = periodFinishForToken[_rewardToken] - block.timestamp;
            uint256 leftover = (remaining * rewardRateForToken[_rewardToken]);
            rewardRateForToken[_rewardToken] = (_amount + leftover) / durationForToken[_rewardToken];
        }
        lastUpdateTimeForToken[_rewardToken] = block.timestamp;
        periodFinishForToken[_rewardToken] = block.timestamp + durationForToken[_rewardToken];
    }

    /// @notice Gives the specified address the ability to inject rewards.
    /// @param _rewardDistribution Address to get reward distribution privileges 
    function addRewardDistribution(address _rewardDistribution) public onlyGovernance {
        rewardDistribution[_rewardDistribution] = true;
    }

    /// @notice Removes the specified address' ability to inject rewards.
    /// @param _rewardDistribution Address to lose reward distribution privileges
    function removeRewardDistribution(address _rewardDistribution) public onlyGovernance {
        rewardDistribution[_rewardDistribution] = false;
    }

    /// @notice Adds a reward token to the vault.
    /// @param _rewardToken Reward token to add.
    function addRewardToken(address _rewardToken, uint256 _duration) public onlyGovernance {
        require(rewardTokenIndex(_rewardToken) == type(uint256).max, "Vault: Reward token already exists");
        require(_duration > 0, "Vault: Duration cannot be 0");
        rewardTokens.push(_rewardToken);
        durationForToken[_rewardToken] = _duration;
    }

    /// @notice Removes a reward token from the vault.
    /// @param _rewardToken Reward token to remove from the vault.
    function removeRewardToken(address _rewardToken) public onlyGovernance {
        uint256 rewardIndex = rewardTokenIndex(_rewardToken);

        require(rewardIndex != type(uint256).max, "Vault: Reward token does not exist");
        require(periodFinishForToken[_rewardToken] < block.timestamp, "Vault: Reward period has not ended for the token");
        require(rewardTokens.length > 1, "Vault: Cannot remove the last reward token from the vault");
        uint256 lastIndex = rewardTokens.length - 1;

        rewardTokens[rewardIndex] = rewardTokens[lastIndex];

        rewardTokens.pop();
    }

    /// @notice Sets the vault's buffer.
    /// @param _numerator New buffer for the vault, precision 1000.
    function setVaultFractionToInvest(uint256 _numerator) public override onlyGovernance {
        require(_numerator <= 1000, "Vault: Denominator must be greater than or equal to the numerator");
        _setFractionToInvestNumerator(_numerator);
    }

    /// @notice Sets the reward distribution duration for `_rewardToken`.
    /// @param _rewardToken Reward token to set the duration of.
    function setDurationForToken(address _rewardToken, uint256 _duration) public onlyGovernance {
        uint256 i = rewardTokenIndex(_rewardToken);
        require(i != type(uint256).max, "Vault: Reward token does not exist");
        require(periodFinishForToken[_rewardToken] < block.timestamp, "Vault: Reward period has not ended for the token");
        require(_duration > 0, "Vault: Duration cannot be 0");
        durationForToken[_rewardToken] = _duration;
    }

    /// @notice Sets if the vault can have losses on doHardWork.
    /// @param _allowLosses Whether or not the vault can lose `underlying` on doHardWork.
    function setAllowLossesOnHarvest(bool _allowLosses) public onlyGovernance {
        _setAllowLossesOnHarvest(_allowLosses);
    }

    /// @notice Queues an update to the exit fee.
    /// @param _newExitFee New exit fee for the vault.
    function queueExitFeeChange(uint256 _newExitFee) public onlyGovernance {
        _setNextExitFee(_newExitFee);
        _setNextExitFeeTimestamp(block.timestamp + timelockDelay());
    }

    /// @notice Finalizes or cancels the exit fee change by setting the new fee to 0.
    function finalizeExitFeeChange() public onlyGovernance {
        _setNextExitFee(0);
        _setNextExitFeeTimestamp(0);
    }

    /// @notice Sets the exit fee of the vault. Should be called once `timelockDelay()` is over.
    /// @param _exitFee New exit fee, should be `nextExitFee()`
    function setExitFee(uint256 _exitFee) public onlyGovernance {
        require(canUpdateExitFee(_exitFee), "Vault: Unable to update the exit fee");
        uint256 oldFee = exitFee();
        _setExitFee(_exitFee);
        finalizeExitFeeChange();
        emit ExitFeeChange(_exitFee, oldFee);
    }

    function canUpdateExitFee(uint256 _exitFee) public view returns (bool) {
        return exitFee() == 0
            || (_exitFee == nextExitFee()
                && block.timestamp > nextExitFeeTimestamp()
                && nextExitFeeTimestamp() > 0);
    }

    /// @notice Returns the amount of `underlying` in the vault.
    /// @return How much `underlying` held in the vault itself.
    function underlyingBalanceInVault() public view override returns (uint256) {
        return IERC20(underlying()).balanceOf(address(this));
    }

    /* Returns the current underlying (e.g., DAI's) balance together with
    * the invested amount (if DAI is invested elsewhere by the strategy).
    */
    function underlyingBalanceWithInvestment() public view override returns (uint256) {
        if (address(strategy()) == address(0)) {
            // Initial state, when not set
            return underlyingBalanceInVault();
        }
        return (underlyingBalanceInVault() + IStrategy(strategy()).investedUnderlyingBalance());
    }

    /// @notice Returns the price of 1 share in the vault.
    /// @return The vault share price.
    function getPricePerFullShare() public view override returns (uint256) {
        return totalSupply() == 0
            ? underlyingUnit()
            : (underlyingUnit() * underlyingBalanceWithInvestment()) / totalSupply();
    }

    function canUpdateStrategy(address _strategy) public view returns (bool) {
        return strategy() == address(0) // No strategy was set yet
        || (_strategy == futureStrategy()
            && block.timestamp > strategyUpdateTime()
            && strategyUpdateTime() > 0); // or the timelock has passed
    }

    /// @notice The amount available for investing into the strategy
    /// @return The amount that can be invested.
    function availableToInvestOut() public view returns (uint256) {
        uint256 wantInvestInTotal = (underlyingBalanceWithInvestment() * fractionToInvestNumerator()) / 10000;
        uint256 alreadyInvested = IStrategy(strategy()).investedUnderlyingBalance();
        if (alreadyInvested >= wantInvestInTotal) {
            return 0;
        } else {
            uint256 remainingToInvest = (wantInvestInTotal - alreadyInvested);
            // wantInvestInTotal - alreadyInvested
            return remainingToInvest <= underlyingBalanceInVault()
                ? remainingToInvest : underlyingBalanceInVault();
        }
    }

    /// @notice Gets the index of `_rewardToken` in the `rewardTokens` array.
    /// @param _rewardToken Reward token to get the index of.
    /// @return The index of the reward token, it will return the max uint256 if it does not exist.
    function rewardTokenIndex(address _rewardToken) public view returns (uint256) {
        for(uint256 i = 0; i < rewardTokens.length; i++) {
            if(rewardTokens[i] == _rewardToken) {
                return i;
            }
        }
        return type(uint256).max;
    } 

    function lastTimeRewardApplicable(address _rewardToken) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinishForToken[_rewardToken]);
    }

    /// @notice Gets the rewards per bToken by index.
    /// @param _i Index to fetch from.
    /// @return Amount of `rewardTokens[_i]` per bToken.
    function rewardPerTokenByIndex(uint256 _i) public view returns (uint256) {
        return rewardPerToken(rewardTokens[_i]);
    }

    /// @notice Gets the amount of rewards per bToken for a specified reward token.
    /// @param _rewardToken Reward token to get the amount of rewards for.
    /// @return Amount of `_rewardToken` per bToken.
    function rewardPerToken(address _rewardToken) public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStoredForToken[_rewardToken];
        }
        return
            rewardPerTokenStoredForToken[_rewardToken].add(
                lastTimeRewardApplicable(_rewardToken)
                    .sub(lastUpdateTimeForToken[_rewardToken])
                    .mul(rewardRateForToken[_rewardToken])
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    /// @notice Gets the user's earnings by reward token index.
    /// @param _i Index in `rewardTokens`.
    /// @param _account Address to get the earnings of.
    /// @return The address' `rewardTokens[_i]` earnings.
    function earnedByIndex(uint256 _i, address _account) public view returns (uint256) {
        return earned(rewardTokens[_i], _account);
    }

    /// @notice Gets the user's earnings by reward token address.
    /// @param _rewardToken Reward token to get earnings from.
    /// @param _account Address to get the earnings of.
    function earned(address _rewardToken, address _account) public view returns (uint256) {
        return
            balanceOf(_account)
                .mul(rewardPerToken(_rewardToken).sub(userRewardPerTokenPaidForToken[_rewardToken][_account]))
                .div(1e18)
                .add(rewardsForToken[_rewardToken][_account]);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        _to;
        _amount;
        if(
            _from != address(0) &&
            _to != address(0) &&
            !IController(controller()).feeExemptAddresses(_from)
        ) {
            // Prevents loophole from transferring bTokens to another
            // address to avoid the exit penalty.
            require(
                block.timestamp >= lastDepositTimestamp[_from] + depositMaturityTime(),
                "Vault: Cannot transfer tokens have not matured"
            );
            super._beforeTokenTransfer(_from, _to, _amount);
        }
    }

    function _invest() internal whenStrategyDefined {
        uint256 availableAmount = availableToInvestOut();
        if (availableAmount > 0) {
            IERC20(underlying()).safeTransfer(address(strategy()), availableAmount);
            emit Invest(availableAmount);
        }
    }

    function _deposit(uint256 _amount, address _sender, address _beneficiary) internal defense updateRewards(_beneficiary) {
        require(_amount > 0, "Vault: Cannot deposit 0");
        require(_beneficiary != address(0), "Vault: Holder must be defined");

        if(address(strategy()) != address(0)) {
            require(IStrategy(strategy()).depositArbCheck(), "Vault: Too much arb");
        }

        uint256 toMint = totalSupply() == 0
            ? _amount
            : (_amount * totalSupply()) / underlyingBalanceWithInvestment();
        _mint(_beneficiary, toMint);

        lastDepositTimestamp[msg.sender] = block.timestamp;

        IERC20(underlying()).safeTransferFrom(_sender, address(this), _amount);

        // Update the contribution amount for the beneficiary
        emit Deposit(_beneficiary, _amount);
    }

    function _getReward(address _rewardToken) internal {
        uint256 rewards = earned(_rewardToken, msg.sender);
        if(rewards > 0) {
            rewardsForToken[_rewardToken][msg.sender] = 0;
            IERC20(_rewardToken).safeTransfer(msg.sender, rewards);
            emit RewardPaid(msg.sender, _rewardToken, rewards);
        }
    }
}