// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
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

// SPDX-License-Identifier: MIT

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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./LotteryUtils.sol";
import "./interface/ILotteryOffice.sol";

contract Lottery is OwnableUpgradeable {
    // Libraries
    // Safe math
    using SafeMathUpgradeable for uint256;

    // Safe ERC20
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Address functionality
    using AddressUpgradeable for address;

    // Counter for lottery IDs
    uint256 private lotteryIdCounter_;

    IERC20Upgradeable internal lotto_;
    address internal lottoAddress_;

    IERC20Upgradeable internal stable_;
    address internal stableAddress_;

    IUniswapV2Router02 internal uniswapRouter_;

    ILotteryOffice internal lotteryOffice_;

    // Address for uniswap v2 factory
    address factory_;

    struct BuyLotteryInfo {
        uint16 lotteryNumber;
        uint256 amount;
    }

    // Lottery ID's to info
    mapping(uint256 => LotteryUtils.LotteryInfo) internal allLotteries_;
    // Max reward multiplier
    uint256 internal maxRewardMultiplier_;
    // Max multiplier slippage tolerance / max percentage that allow reward multiplier to be changed
    uint256 internal maxMultiplierSlippageTolerancePercentage_;
    // Total lottery number (100 for 2 digits / 1000 for 3 digits)
    uint16 internal totalLotteryNumber_;
    // Number of winning number
    uint8 internal totalWinningNumber_;
    // Mapping of gambler's reward in lotto token
    mapping(address => uint256) internal gamblerReward_;
    // Wei with 18 Decimals
    uint256 internal constant WEI = 1 * (10**18);
    // fee keeper
    address internal feeKeeper_;
    // fee percentage
    uint256 internal feePercentage_;

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------
    constructor() { }

    function initialize(
        address _lotto,
        address _stable,
        address _factory,
        address _router,
        address _lotteryOffice,
        uint256 _maxRewardMultiplier,
        uint16 _totalLotteryNumber,
        uint256 _maxMultiplierSlippageTolerancePercentage,
        uint8 _totalWinningNumber,
        uint256 _feePercentage
    )  public initializer {
        __Ownable_init();
        lotto_ = IERC20Upgradeable(_lotto);
        lottoAddress_ = _lotto;
        stable_ = IERC20Upgradeable(_stable);
        stableAddress_ = _stable;
        factory_ = _factory;
        uniswapRouter_ = IUniswapV2Router02(_router);
        lotteryOffice_ = ILotteryOffice(_lotteryOffice);
        maxRewardMultiplier_ = _maxRewardMultiplier;
        maxMultiplierSlippageTolerancePercentage_ = _maxMultiplierSlippageTolerancePercentage;
        totalLotteryNumber_ = _totalLotteryNumber;
        lotteryIdCounter_ = 0;
        allLotteries_[lotteryIdCounter_].lotteryStatus = LotteryUtils
            .Status
            .Open;
        totalWinningNumber_ = _totalWinningNumber;
        feeKeeper_ = msg.sender;
        feePercentage_ = _feePercentage;
    }

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    modifier notContract() {
        require(!address(msg.sender).isContract(), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event BuyLottery(
        address indexed gambler,
        uint16 lotteryNumber,
        uint256 amount,
        uint256 lotteryId
    );

    event NewRoundLottery(address indexed owner, uint256 newLotteryId);

    event CloseLottery(address indexed owner, uint256 lotteryId);
    event ReopenLottery(address indexed owner, uint256 lotteryId);

    event SetWinningNumbers(
        address indexed owner,
        uint256 lotteryId,
        uint16[] numbers,
        uint16 totalLotteryNumber
    );

    event Debug(string message, uint256 value);

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getAllGamblingInfo(address _gambler)
        external
        view
        returns (LotteryUtils.GamblingInfo[] memory allGamblingInfo)
    {
        allGamblingInfo = allLotteries_[lotteryIdCounter_]
            .lottoGamblerByAddress[_gambler];
    }

    function getWinningNumbers()
        external
        view
        returns (uint16[] memory winningNumbers)
    {
        winningNumbers = allLotteries_[lotteryIdCounter_].winningNumbers.values;
    }

    function getRewardMultiplier(uint16 _number)
        external
        view
        returns (uint256 multiplier)
    {
        uint256 currentBetAmount = allLotteries_[lotteryIdCounter_]
            .totalAmountByNumber[_number];
        multiplier = LotteryUtils.getRewardMultiplier(
            _getAvailableStakedAmount(),
            currentBetAmount,
            allLotteries_[lotteryIdCounter_].totalAmount,
            totalLotteryNumber_,
            maxRewardMultiplier_
        );
    }

    function getMaxAllowBetAmount(uint16 _number)
        external
        view
        returns (uint256 maxAllowBetAmount)
    {
        uint256 currentBetAmount = allLotteries_[lotteryIdCounter_]
            .totalAmountByNumber[_number];
        maxAllowBetAmount = LotteryUtils.getMaxAllowBetAmount(
            _getAvailableStakedAmount(),
            currentBetAmount,
            allLotteries_[lotteryIdCounter_].totalAmount,
            totalLotteryNumber_,
            maxRewardMultiplier_,
            maxMultiplierSlippageTolerancePercentage_
        );
    }

    function getClaimableReward(address _gambler)
        external
        view
        returns (uint256 claimableReward)
    {
        claimableReward = gamblerReward_[_gambler];
    }

    //-------------------------------------------------------------------------
    // General Access Functions
    //-------------------------------------------------------------------------

    function buyLotteries(BuyLotteryInfo[] calldata _lotteries)
        external
        notContract
    {
        require(
            allLotteries_[lotteryIdCounter_].lotteryStatus ==
                LotteryUtils.Status.Open,
            "Current lottery should be Status.Open"
        );
        // Looping for each lottery info
        uint256 totalAmount = 0;
        for (uint16 index = 0; index < _lotteries.length; index++) {
            totalAmount += _buyLottery(_lotteries[index]);
        }

        // Transfer stable to contract
        stable_.safeTransferFrom(msg.sender, address(this), totalAmount);
    }

    function claimReward() external notContract {
        uint256 claimableReward = gamblerReward_[msg.sender];
        require(claimableReward > 0, "No claimable reward");
        stable_.safeTransfer(msg.sender, claimableReward);
        gamblerReward_[msg.sender] = 0;
    }

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    // Restricted Access Functions (onlyOwner)
    //-------------------------------------------------------------------------
    function setFeeKeeperAddress(address _newAddress) external onlyOwner {
        feeKeeper_ = _newAddress;
    }

    function setMaxMultiplierSlippageTolerancePercentage(
        uint256 _maxMultiplierSlippageTolerancePercentage
    ) external onlyOwner {
        require(
            _maxMultiplierSlippageTolerancePercentage <= 100,
            "Invalid percentage"
        );
        maxMultiplierSlippageTolerancePercentage_ = _maxMultiplierSlippageTolerancePercentage;
    }

    function setFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 100, "Invalid percentage");
        feePercentage_ = _newPercentage;
    }

    function adjustMaxRewardMultiplier(uint256 _maxRewardMultiplier)
        external
        onlyOwner
    {
        maxRewardMultiplier_ = _maxRewardMultiplier;
    }

    function adjustTotalWinningNumber(uint8 _totalWinningNumber)
        external
        onlyOwner
    {
        totalWinningNumber_ = _totalWinningNumber;
    }

    function closeLottery() external onlyOwner {
        require(
            allLotteries_[lotteryIdCounter_].lotteryStatus ==
                LotteryUtils.Status.Open,
            "Current lottery should be Status.Open"
        );
        allLotteries_[lotteryIdCounter_].lotteryStatus = LotteryUtils
            .Status
            .Closed;
        emit CloseLottery(msg.sender, lotteryIdCounter_);
    }

    function reopenLottery() external onlyOwner {
        require(
            allLotteries_[lotteryIdCounter_].lotteryStatus ==
                LotteryUtils.Status.Closed,
            "Current lottery should be Status.Closed"
        );
        allLotteries_[lotteryIdCounter_].lotteryStatus = LotteryUtils
            .Status
            .Open;
        emit ReopenLottery(msg.sender, lotteryIdCounter_);
    }

    function resetLotteryAndStartNewRound() external onlyOwner {
        require(
            allLotteries_[lotteryIdCounter_].lotteryStatus ==
                LotteryUtils.Status.RewardCompleted,
            "Current lottery reward should be calculated before start new round"
        );
        lotteryIdCounter_ = lotteryIdCounter_.add(1);
        allLotteries_[lotteryIdCounter_].lotteryStatus = LotteryUtils
            .Status
            .Open;
        emit NewRoundLottery(msg.sender, lotteryIdCounter_);
    }

    function setWinningNumbers(uint16[] calldata _numbers) external onlyOwner {
        require(
            _numbers.length == totalWinningNumber_,
            "Total winning numbers is not corrected"
        );
        require(
            allLotteries_[lotteryIdCounter_].lotteryStatus ==
                LotteryUtils.Status.Closed,
            "Current lottery should be Status.Closed"
        );

        LotteryUtils.Set storage winningNumbers = allLotteries_[
            lotteryIdCounter_
        ].winningNumbers;
        _setWinningNumber(winningNumbers, _numbers, totalLotteryNumber_);
        emit SetWinningNumbers(
            msg.sender,
            lotteryIdCounter_,
            winningNumbers.values,
            totalLotteryNumber_
        );

        uint256 totalReward = _calculateRewards(winningNumbers);
        _calculateBankerProfitLoss(totalReward);
        // Set lottery Status to RewardCompleted
        allLotteries_[lotteryIdCounter_].lotteryStatus = LotteryUtils
            .Status
            .RewardCompleted;
        // Unlock staked amount that was locked for reward
        _unlockCurrentRoundStakedAmount();
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    function _buyLottery(BuyLotteryInfo calldata _lottery)
        internal
        returns (uint256 amount)
    {
        uint16 lotteryNumber = _lottery.lotteryNumber;
        uint256 currentBetAmount = allLotteries_[lotteryIdCounter_]
            .totalAmountByNumber[lotteryNumber];
        uint256 maxAllowBetAmount = LotteryUtils.getMaxAllowBetAmount(
            _getAvailableStakedAmount(),
            currentBetAmount,
            allLotteries_[lotteryIdCounter_].totalAmount,
            totalLotteryNumber_,
            maxRewardMultiplier_,
            maxMultiplierSlippageTolerancePercentage_
        );
        amount = _lottery.amount;
        require(
            amount <= maxAllowBetAmount,
            "Lottery amount exceed max allowance"
        );

        uint256 multiplier = LotteryUtils.getRewardMultiplier(
            _getAvailableStakedAmount(),
            currentBetAmount,
            allLotteries_[lotteryIdCounter_].totalAmount,
            totalLotteryNumber_,
            maxRewardMultiplier_
        );
        uint256 rewardAmount = multiplier.mul(amount);
        // Create gambling info
        LotteryUtils.GamblingInfo memory gamblingInfo = LotteryUtils
            .GamblingInfo(msg.sender, lotteryNumber, amount, multiplier);
        // Add lottery gambling info to state
        allLotteries_[lotteryIdCounter_]
            .lottoGamblerByNumber[lotteryNumber]
            .push(gamblingInfo);
        allLotteries_[lotteryIdCounter_].lottoGamblerByAddress[msg.sender].push(
                gamblingInfo
            );
        allLotteries_[lotteryIdCounter_].totalAmountByNumber[
            lotteryNumber
        ] += amount;
        allLotteries_[lotteryIdCounter_].totalRewardAmountByNumber[
                lotteryNumber
            ] += rewardAmount;
        allLotteries_[lotteryIdCounter_].totalAmount += amount;

        // calculate locked stable and save into state
        _calculateAndLockedStableAmount(lotteryNumber);

        emit BuyLottery(msg.sender, lotteryNumber, amount, lotteryIdCounter_);
    }

    function _calculateAndLockedStableAmount(uint16 lotteryNumber) internal {
        uint256 totalRewardAmountByNumber = allLotteries_[lotteryIdCounter_]
            .totalRewardAmountByNumber[lotteryNumber];
        uint256 totalBetAmount = allLotteries_[lotteryIdCounter_].totalAmount;

        // if total reward amount is more than bet amount
        // we need to lock some staked stable
        if (totalRewardAmountByNumber > totalBetAmount) {
            uint256 totalReward = totalRewardAmountByNumber -
                totalBetAmount;
            uint256 lockedStableAmount = allLotteries_[lotteryIdCounter_]
                .lockedStableAmount;
            if (totalReward > lockedStableAmount) {
                //Lock more staked amount at Lottery Office
                lotteryOffice_.lockBankerAmount(totalReward.sub(lockedStableAmount));
                //And then update curent locked amount
                allLotteries_[lotteryIdCounter_]
                    .lockedStableAmount = totalReward;
            }
        }
    }

    function _setWinningNumber(
        LotteryUtils.Set storage _set,
        uint16[] calldata _numbers,
        uint16 _totalLotteryNumber
    ) internal {
        for (uint16 index = 0; index < _numbers.length; index++) {
            uint16 number = _numbers[index];
            require(number < _totalLotteryNumber, "Invalid winning number");
            if (!_set.isExists[number]) {
                _set.values.push(number);
                _set.isExists[number] = true;
            }
        }
        require(
            _set.values.length == totalWinningNumber_,
            "Total winning numbers is not corrected"
        );
    }

    function _calculateRewards(LotteryUtils.Set storage _set)
        internal
        returns (uint256 totalReward)
    {
        for (uint16 i = 0; i < _set.values.length; i++) {
            uint16 winningNumber = _set.values[i];
            LotteryUtils.GamblingInfo[] memory gamblings = allLotteries_[
                lotteryIdCounter_
            ].lottoGamblerByNumber[winningNumber];
            for (uint256 j = 0; j < gamblings.length; j++) {
                LotteryUtils.GamblingInfo memory gambling = gamblings[j];
                require(
                    winningNumber == gambling.lotteryNumber,
                    "Lottery number not match"
                );
                uint256 reward = gambling.amount.mul(gambling.rewardMultiplier);
                gamblerReward_[gambling.gambler] += reward;
                totalReward += reward;
            }
        }
    }

    function _calculateBankerProfitLoss(uint256 _totalReward) internal {
        uint256 totalBetAmount = allLotteries_[lotteryIdCounter_].totalAmount;
        // if total reward less than total bet amount, then banker not loss any money
        // banker profit = totalBetAmount - totalReward - platform fee (to feeKeeper_)
        if (_totalReward < totalBetAmount) {
            uint256 remainingAmount = totalBetAmount - _totalReward;
            uint256 feeAmount = feePercentage_.mul(remainingAmount).div(100);
            // transfer fee to feeKeeper
            stable_.safeTransfer(feeKeeper_, feeAmount);
            // add reward to banker
            uint256 bankerReward = remainingAmount - feeAmount;
            // increase banker current stake stable amount
            stable_.safeIncreaseAllowance(address(lotteryOffice_), bankerReward);
            lotteryOffice_.depositBankerAmount(bankerReward);
        } else if (_totalReward > totalBetAmount) {
            // else if total reward is more than total bet amount,
            // banker will loss staked amount in percentage of (totalReward - totalBetAmount)/total staked amount
            uint256 stableNeeded = _totalReward - totalBetAmount;
            // remove stable from bankers
            lotteryOffice_.withdrawBankerAmount(stableNeeded);
        }
    }

    function _unlockCurrentRoundStakedAmount() internal {
        lotteryOffice_.unlockBankerAmount(allLotteries_[lotteryIdCounter_].lockedStableAmount);
        allLotteries_[lotteryIdCounter_].lockedStableAmount = 0;
    }

    function _getAvailableStakedAmount() internal view returns (uint256 availableStakedAmount){
        availableStakedAmount = lotteryOffice_.getAvailableBankerAmount().add(allLotteries_[lotteryIdCounter_].lockedStableAmount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UniswapV2Library.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LotteryUtils {
    // Libraries
    // Safe math
    using SafeMath for uint256;

    struct Set {
        uint16[] values;
        mapping(uint16 => bool) isExists;
    }

    // Represents the status of the lottery
    enum Status {
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no closed for new round
        RewardCompleted // The lottery reward has been calculated
    }

    struct GamblingInfo {
        address gambler;
        uint16 lotteryNumber;
        uint256 amount;
        uint256 rewardMultiplier;
    }

    // All the needed info around a lottery
    struct LotteryInfo {
        uint256 lotteryId; // ID for lotto
        Status lotteryStatus; // Status for lotto
        mapping(uint16 => GamblingInfo[]) lottoGamblerByNumber; // Mapping of lotteryNumber -> array of GamblingInfo
        mapping(address => GamblingInfo[]) lottoGamblerByAddress; // Mapping of gambler's address -> array of GamblingInfo
        mapping(uint16 => uint256) totalAmountByNumber; // Mapping of lotteryNumber -> total amount
        mapping(uint16 => uint256) totalRewardAmountByNumber; // Mapping of lotteryNumber -> total reward amount
        uint256 totalAmount; // Total bet amount
        Set winningNumbers; // Two digit winning
        uint256 lockedStableAmount; // Stable coin amount that was locked
    }

    uint256 internal constant Q = 1 * (10**8);

    function getLottoStablePairInfo(
        address _factory,
        address _stable,
        address _lotto
    )
        public
        view
        returns (
            uint256 reserveStable,
            uint256 reserveLotto,
            uint256 totalSupply
        )
    {
        IUniswapV2Pair _pair = IUniswapV2Pair(
            UniswapV2Library.pairFor(_factory, _stable, _lotto)
        );
        totalSupply = _pair.totalSupply();
        (uint256 reserves0, uint256 reserves1, ) = _pair.getReserves();
        (reserveStable, reserveLotto) = _stable == _pair.token0()
            ? (reserves0, reserves1)
            : (reserves1, reserves0);
    }

    function getStableOutputWithDirectPrice(
        uint256 _lottoAmount,
        address _factory,
        address _stable,
        address _lotto
    ) public view returns (uint256 stableOutput) {
        (
            uint256 reserveStable,
            uint256 reserveLotto,

        ) = getLottoStablePairInfo(_factory, _stable, _lotto);
        stableOutput = reserveStable.mul(_lottoAmount).div(reserveLotto);
    }

    function getLottoOutputWithDirectPrice(
        uint256 _stableAmount,
        address _factory,
        address _stable,
        address _lotto
    ) public view returns (uint256 lottoOutput) {
        (
            uint256 reserveStable,
            uint256 reserveLotto,

        ) = getLottoStablePairInfo(_factory, _stable, _lotto);
        lottoOutput = reserveLotto.mul(_stableAmount).div(reserveStable);
    }

    function getRequiredStableForExpectedLotto(
        uint256 _expectedLotto,
        address _factory,
        address _stable,
        address _lotto
    ) public view returns (uint256 requiredStable) {
        (
            uint256 reserveStable,
            uint256 reserveLotto,

        ) = getLottoStablePairInfo(_factory, _stable, _lotto);
        require(_expectedLotto < reserveLotto, "Insufficient lotto in lp");
        requiredStable = UniswapV2Library.getAmountIn(
            _expectedLotto,
            reserveStable,
            reserveLotto
        );
    }

    function getPossibleStableOutputForInputLotto(
        uint256 _lottoAmount,
        address _factory,
        address _stable,
        address _lotto
    ) public view returns (uint256 stableOutput) {
        (
            uint256 reserveStable,
            uint256 reserveLotto,

        ) = getLottoStablePairInfo(_factory, _stable, _lotto);
        stableOutput = UniswapV2Library.getAmountOut(
            _lottoAmount,
            reserveLotto,
            reserveStable
        );
    }

    function getRemainingPoolAmount(
        uint256 _currentStakedStableAmount,
        uint256 _currentBetAmount,
        uint256 _currentTotalBetAmount,
        uint256 _totalLotteryNumber
    ) public pure returns (uint256 remainingPoolAmount) {
        uint256 currentPoolAmount = _currentStakedStableAmount.div(
            _totalLotteryNumber
        );
        require(
            currentPoolAmount > 0,
            "Staked stable amount should be greater than zero"
        );
        require(
            _currentBetAmount <= currentPoolAmount,
            "Invalid current bet amount greater than pool amount"
        );
        uint256 averageBetAmount = _currentTotalBetAmount.div(
            _totalLotteryNumber
        );
        if (_currentBetAmount > averageBetAmount) {
            uint256 diffAmount = _currentBetAmount.sub(averageBetAmount);
            remainingPoolAmount = currentPoolAmount.sub(diffAmount);
        } else {
            uint256 diffAmount = averageBetAmount.sub(_currentBetAmount);
            remainingPoolAmount = currentPoolAmount.add(diffAmount);
        }
    }

    function getRewardMultiplier(
        uint256 _currentStakedStableAmount,
        uint256 _currentBetAmount,
        uint256 _currentTotalBetAmount,
        uint256 _totalLotteryNumber,
        uint256 _maxRewardMultiplier
    ) public pure returns (uint256 multiplier) {
        uint256 currentPoolAmount = _currentStakedStableAmount.div(
            _totalLotteryNumber
        );
        uint256 remainingPoolAmount = getRemainingPoolAmount(
            _currentStakedStableAmount,
            _currentBetAmount,
            _currentTotalBetAmount,
            _totalLotteryNumber
        );

        multiplier = remainingPoolAmount.mul(_maxRewardMultiplier).div(
            currentPoolAmount
        );
    }

    function getMaxAllowBetAmount(
        uint256 _currentStakedStableAmount,
        uint256 _currentBetAmount,
        uint256 _currentTotalBetAmount,
        uint256 _totalLotteryNumber,
        uint256 _maxRewardMultiplier,
        uint256 _maxMultiplierSlippageTolerancePercentage
    ) public pure returns (uint256 maxAllowBetAmount) {
        uint256 remainingPoolAmount = getRemainingPoolAmount(
            _currentStakedStableAmount,
            _currentBetAmount,
            _currentTotalBetAmount,
            _totalLotteryNumber
        );
        uint256 currentMultiplierQ = getRewardMultiplier(
            _currentStakedStableAmount,
            _currentBetAmount,
            _currentTotalBetAmount,
            _totalLotteryNumber,
            _maxRewardMultiplier
        ).mul(Q);
        uint256 maxMultiplierSlippageToleranceAmountQ = _maxMultiplierSlippageTolerancePercentage
                .mul(currentMultiplierQ)
                .div(100);
        uint256 targetMultiplierQ = currentMultiplierQ -
            maxMultiplierSlippageToleranceAmountQ;
        maxAllowBetAmount =
            remainingPoolAmount -
            targetMultiplierQ.mul(remainingPoolAmount).div(currentMultiplierQ);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                 hex'03f6509a2bb88d26dc77ecc6fc204e95089e30cb99667b85e653280b735767c8' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILotteryOffice {
    event LotteryCreated(
        string lotteryName,
        uint256 maxRewardMultiplier,
        uint16 totalLotteryNumber,
        uint8 totalWinningNumber
    );

    event StakeStableCoin(
        address indexed banker,
        uint256 amount,
        uint256 total
    );

    event UnstakeStableCoin(
        address indexed banker,
        uint256 actualStakedAmount,
        uint256 amountWithReward,
        uint256 remaining
    );

    event DepositStableCoin(
        address indexed lotteryContract,
        string lotteryName,
        uint256 amount,
        uint256 currentStakedAmount
    );

    event WithdrawStableCoin(
        address indexed lotteryContract,
        string lotteryName,
        uint256 amount,
        uint256 currentStakedAmount
    );

    function createNewLottery(
        string calldata _lotteryName,
        address _lotto,
        address _stable,
        address _factory,
        address _router,
        uint256 _maxRewardMultiplier,
        uint16 _totalLotteryNumber,
        uint256 _maxMultiplierSlippageTolerancePercentage,
        uint8 _totalWinningNumber,
        uint256 _feePercentage
    ) external returns (address lottery);

    function lockBankerAmount(uint256 _amount) external;
    function unlockBankerAmount(uint256 _amount) external;
    function withdrawBankerAmount(uint256 _amount) external;
    function depositBankerAmount(uint256 _amount) external;
    function stake(uint256 _amount) external;
    function unstake(uint256 _amount) external;
    
    function getAvailableBankerAmount() external view returns (uint256 availableAmount);
    function getStakedAmount(address _banker) external view returns (uint256 tvl);
    function getTvl() external view returns (uint256 tvl);
    function getEstimatedApy() external view returns (uint256 estimatedApy);
    function getLockedAmountPercentage() external view returns (uint256 lockedAmountPercentage);
}

