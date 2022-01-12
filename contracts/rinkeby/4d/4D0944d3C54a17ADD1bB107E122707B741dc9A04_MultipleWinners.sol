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

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
library SafeMathUpgradeable {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import "./PeriodicPrizeStrategy.sol";
import "./interfaces/ITulipArt.sol";

contract MultipleWinners is PeriodicPrizeStrategy {
    uint256 internal __numberOfWinners;

    event NumberOfWinnersSet(uint256 numberOfWinners);
    event NoWinners();

    /// @notice Initialize the contract with default variables.
    /// @param _prizePeriodStart: The starting timestamp of the prize period.
    /// @param _prizePeriodSeconds: The duration of the prize period in seconds.
    /// @param _tulipArt: The staking contract used to draw winners.
    /// @param _rng: The RNG service to use.
    /// @param _numberOfWinners: Number of winners of the lottery prize draw.
    constructor(
        uint256 _prizePeriodStart,
        uint256 _prizePeriodSeconds,
        ITulipArt _tulipArt,
        RNGInterface _rng,
        uint256 _numberOfWinners
    ) public {
        PeriodicPrizeStrategy.initialize(
            _prizePeriodStart,
            _prizePeriodSeconds,
            _tulipArt,
            _rng
        );

        _setNumberOfWinners(_numberOfWinners);
    }

    /// @param _count: number of winners that the lottery will have.
    function setNumberOfWinners(uint256 _count)
        external
        onlyOwner
        requireRngNotInFlight
    {
        _setNumberOfWinners(_count);
    }

    /// @return returns the amount of winners per lottery round.
    function numberOfWinners() external view returns (uint256) {
        return __numberOfWinners;
    }

    /// @notice Sets the number of possible winners for the lottery.
    /// @param _count: new number of winners to be set. Must be more than 1.
    function _setNumberOfWinners(uint256 _count) internal {
        require(_count > 0, "MultipleWinners/winners-gte-one");

        __numberOfWinners = _count;
        emit NumberOfWinnersSet(_count);
    }

    /// @notice Chooses the winners and sets their prizes based on %staked and
    /// random numbers.
    /// @param _randomNumber: number generated by the Chainlink VRF node.
    function _distribute(uint256 _randomNumber) internal override {
        // main winner is simply the first that is drawn
        address mainWinner = tulipArt.draw(_randomNumber);

        // If drawing yields no winner, then there is no one to pick
        // @NOTE with the way the staking contract is done this is unreachable
        // This is kept here just incase any future changes occur
        if (mainWinner == address(0)) {
            emit NoWinners();
            return;
        }

        address[] memory winners = new address[](__numberOfWinners);
        uint256[] memory randomNumbers = new uint256[](__numberOfWinners);
        winners[0] = mainWinner;
        randomNumbers[0] = _randomNumber;
        uint256 nextRandom = _randomNumber;
        for (
            uint256 winnerCount = 1;
            winnerCount < __numberOfWinners;
            winnerCount++
        ) {
            // add some arbitrary numbers to the previous random number to
            // ensure no matches with the UniformRandomNumber lib
            bytes32 nextRandomHash = keccak256(
                abi.encodePacked(nextRandom + 499 + winnerCount * 521)
            );
            nextRandom = uint256(nextRandomHash);
            winners[winnerCount] = tulipArt.draw(nextRandom);
            randomNumbers[winnerCount] = nextRandom;
        }

        // Set the winners for the round
        for (uint256 i = 0; i < winners.length; i++) {
            // SET WINNERS the NFT numbers should be by the minter contract
            tulipArt.setWinner(winners[i], randomNumbers[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/ITulipArt.sol";
import "./interfaces/RNGInterface.sol";
import "./libraries/FixedPoint.sol";

/* solium-disable security/no-block-members */
abstract contract PeriodicPrizeStrategy is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeCastUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    event PrizeLotteryOpened(
        address indexed operator,
        uint256 indexed prizePeriodStartedAt
    );

    event RngRequestFailed();

    event PrizeLotteryAwardStarted(
        address indexed operator,
        uint32 indexed rngRequestId,
        uint32 rngLockBlock
    );

    event PrizeLotteryAwardCancelled(
        address indexed operator,
        uint32 indexed rngRequestId,
        uint32 rngLockBlock
    );

    event PrizePoolAwarded(address indexed operator, uint256 randomNumber);

    event RngServiceUpdated(RNGInterface indexed rngService);

    event RngRequestTimeoutSet(uint32 rngRequestTimeout);

    event PrizePeriodSecondsUpdated(uint256 prizePeriodSeconds);

    event Initialized(
        uint256 prizePeriodStart,
        uint256 prizePeriodSeconds,
        ITulipArt tulipArt,
        RNGInterface rng
    );

    struct RngRequest {
        uint32 id;
        uint32 lockBlock;
        uint32 requestedAt;
    }

    // Contract Interfaces
    ITulipArt public tulipArt;
    RNGInterface public rng;

    // Current RNG Request
    RngRequest internal rngRequest;

    /// @notice RNG Request Timeout. In fact, this is really a "complete award" timeout.
    /// If the rng completes the award can still be cancelled.
    uint32 public rngRequestTimeout;

    // Prize period
    uint256 public prizePeriodSeconds;
    uint256 public prizePeriodStartedAt;

    /// @notice Initializes a new prize period startegy.
    /// @param _prizePeriodStart The starting timestamp of the prize period.
    /// @param _prizePeriodSeconds The duration of the prize period in seconds.
    /// @param _tulipArt The staking contract used to draw winners.
    /// @param _rng The RNG service to use.
    function initialize(
        uint256 _prizePeriodStart,
        uint256 _prizePeriodSeconds,
        ITulipArt _tulipArt,
        RNGInterface _rng
    ) public initializer {
        require(
            address(_tulipArt) != address(0),
            "PeriodicPrizeStrategy/lottery-not-zero"
        );
        require(
            address(_rng) != address(0),
            "PeriodicPrizeStrategy/rng-not-zero"
        );
        tulipArt = _tulipArt;
        rng = _rng;

        _setPrizePeriodSeconds(_prizePeriodSeconds);

        __Ownable_init();

        prizePeriodSeconds = _prizePeriodSeconds;
        prizePeriodStartedAt = _prizePeriodStart;

        // 30 min timeout
        _setRngRequestTimeout(1800);

        emit Initialized(
            _prizePeriodStart,
            _prizePeriodSeconds,
            _tulipArt,
            _rng
        );
    }

    /// @notice Starts the award process by starting random number request.
    /// The prize period must have ended.
    /// @dev The RNG-Request-Fee is expected to be held within this contract
    /// before calling this function.
    function startAward() external requireCanStartAward {
        (address feeToken, uint256 requestFee) = rng.getRequestFee();
        if (feeToken != address(0) && requestFee > 0) {
            IERC20Upgradeable(feeToken).safeApprove(address(rng), requestFee);
        }

        (uint32 requestId, uint32 lockBlock) = rng.requestRandomNumber();
        rngRequest.id = requestId;
        rngRequest.lockBlock = lockBlock;
        rngRequest.requestedAt = _currentTime().toUint32();

        // Tell the TulipArt contract to pause deposits and withdrawals
        // until the RNG winners have been selected
        tulipArt.startDraw();

        emit PrizeLotteryAwardStarted(_msgSender(), requestId, lockBlock);
    }

    /// @notice Completes the award process and awards the winners.
    /// The random number must have been requested and is now available.
    function completeAward() external requireCanCompleteAward {
        uint256 randomNumber = rng.randomNumber(rngRequest.id);
        delete rngRequest;

        _distribute(randomNumber);

        // To avoid clock drift, we should calculate the start time based on
        // the previous period start time.
        prizePeriodStartedAt = _calculateNextPrizePeriodStartTime(
            _currentTime()
        );

        // Tell TulipArt contracts that deposits/withdrawals are live again
        tulipArt.finishDraw();

        emit PrizePoolAwarded(_msgSender(), randomNumber);
        emit PrizeLotteryOpened(_msgSender(), prizePeriodStartedAt);
    }

    /// @notice Sets the RNG service that the Prize Strategy is connected to.
    /// @param rngService The address of the new RNG service interface.
    function setRngService(RNGInterface rngService)
        external
        onlyOwner
        requireRngNotInFlight
    {
        require(!isRngRequested(), "PeriodicPrizeStrategy/rng-in-flight");

        rng = rngService;
        emit RngServiceUpdated(rngService);
    }

    /// @notice Allows the owner to set the RNG request timeout in seconds.
    /// This is the time that must elapsed before the RNG request can be cancelled
    /// and the pool unlocked.
    /// @param _rngRequestTimeout The RNG request timeout in seconds.
    function setRngRequestTimeout(uint32 _rngRequestTimeout)
        external
        onlyOwner
        requireRngNotInFlight
    {
        _setRngRequestTimeout(_rngRequestTimeout);
    }

    /// @notice Allows the owner to set the prize period in seconds.
    /// @param _prizePeriodSeconds The new prize period in seconds. Must be greater than zero.
    function setPrizePeriodSeconds(uint256 _prizePeriodSeconds)
        external
        onlyOwner
        requireRngNotInFlight
    {
        _setPrizePeriodSeconds(_prizePeriodSeconds);
    }

    /// @notice Returns the block number that the current RNG request has been locked to.
    ///@return The block number that the RNG request is locked to.
    function getLastRngLockBlock() external view returns (uint32) {
        return rngRequest.lockBlock;
    }

    /// @notice Returns the current RNG Request ID.
    /// @return The current Request ID.
    function getLastRngRequestId() external view returns (uint32) {
        return rngRequest.id;
    }

    /// @notice Returns the number of seconds remaining until the prize can be awarded.
    /// @return The number of seconds remaining until the prize can be awarded.
    function prizePeriodRemainingSeconds() external view returns (uint256) {
        return _prizePeriodRemainingSeconds();
    }

    /// @notice Returns whether the prize period is over.
    /// @return True if the prize period is over, false otherwise.
    function isPrizePeriodOver() external view returns (bool) {
        return _isPrizePeriodOver();
    }

    /// @notice Returns the timestamp at which the prize period ends.
    /// @return The timestamp at which the prize period ends.
    function prizePeriodEndAt() external view returns (uint256) {
        // current prize started at is non-inclusive, so add one
        return _prizePeriodEndAt();
    }

    /// @notice Calculates when the next prize period will start.
    /// @param currentTime The timestamp to use as the current time.
    /// @return The timestamp at which the next prize period would start.
    function calculateNextPrizePeriodStartTime(uint256 currentTime)
        external
        view
        returns (uint256)
    {
        return _calculateNextPrizePeriodStartTime(currentTime);
    }

    /// @notice Returns whether an award process can be started.
    /// @return True if an award can be started, false otherwise.
    function canStartAward() external view returns (bool) {
        return _isPrizePeriodOver() && !isRngRequested();
    }

    /// @notice Returns whether an award process can be completed.
    /// @return True if an award can be completed, false otherwise.
    function canCompleteAward() external view returns (bool) {
        return isRngRequested() && isRngCompleted();
    }

    /// @notice Can be called by anyone to unlock the tickets if the RNG has timed out.
    function cancelAward() public {
        require(isRngTimedOut(), "PeriodicPrizeStrategy/rng-not-timedout");
        uint32 requestId = rngRequest.id;
        uint32 lockBlock = rngRequest.lockBlock;
        delete rngRequest;

        // Tell TulipArt contracts that deposits/withdrawals are live again
        tulipArt.finishDraw();

        emit RngRequestFailed();
        emit PrizeLotteryAwardCancelled(msg.sender, requestId, lockBlock);
    }

    /// @notice Estimates the remaining blocks until the prize given a number of
    /// seconds per block.
    /// @param secondsPerBlockMantissa The number of seconds per block to use
    /// for the calculation. Should be a fixed point 18 number like Ether.
    /// @return The estimated number of blocks remaining until the prize can be awarded.
    function estimateRemainingBlocksToPrize(uint256 secondsPerBlockMantissa)
        public
        view
        returns (uint256)
    {
        return
            FixedPoint.divideUintByMantissa(
                _prizePeriodRemainingSeconds(),
                secondsPerBlockMantissa
            );
    }

    /// @notice Returns whether a random number has been requested.
    /// @return True if a random number has been requested, false otherwise.
    function isRngRequested() public view returns (bool) {
        return rngRequest.id != 0;
    }

    /// @notice Returns whether the random number request has completed.
    /// @return True if a random number request has completed, false otherwise.
    function isRngCompleted() public view returns (bool) {
        return rng.isRequestComplete(rngRequest.id);
    }

    /// @notice checks if the rng request sent to the CL VRF has timed out.
    /// @return True if it has timed out, False if it hasn't or hasn't been requested.
    function isRngTimedOut() public view returns (bool) {
        if (rngRequest.requestedAt == 0) {
            return false;
        } else {
            return
                _currentTime() >
                uint256(rngRequestTimeout).add(rngRequest.requestedAt);
        }
    }

    /// @notice Sets the RNG request timeout in seconds.  This is the time that must
    /// elapsed before the RNG request can be cancelled and the pool unlocked.
    /// @param _rngRequestTimeout The RNG request timeout in seconds.
    function _setRngRequestTimeout(uint32 _rngRequestTimeout) internal {
        require(
            _rngRequestTimeout > 60,
            "PeriodicPrizeStrategy/rng-timeout-gt-60-secs"
        );
        rngRequestTimeout = _rngRequestTimeout;
        emit RngRequestTimeoutSet(rngRequestTimeout);
    }

    /// @notice Sets the prize period in seconds.
    /// @param _prizePeriodSeconds The new prize period in seconds.
    /// Must be greater than zero.
    function _setPrizePeriodSeconds(uint256 _prizePeriodSeconds) internal {
        require(
            _prizePeriodSeconds > 0,
            "PeriodicPrizeStrategy/prize-period-greater-than-zero"
        );
        prizePeriodSeconds = _prizePeriodSeconds;

        emit PrizePeriodSecondsUpdated(prizePeriodSeconds);
    }

    /// @notice Returns the number of seconds remaining until the prize can be awarded.
    /// @return The number of seconds remaining until the prize can be awarded.
    function _prizePeriodRemainingSeconds() internal view returns (uint256) {
        uint256 endAt = _prizePeriodEndAt();
        uint256 time = _currentTime();
        if (time > endAt) {
            return 0;
        }
        return endAt.sub(time);
    }

    /// @notice Returns whether the prize period is over.
    /// @return True if the prize period is over, false otherwise.
    function _isPrizePeriodOver() internal view returns (bool) {
        return _currentTime() >= _prizePeriodEndAt();
    }

    /// @notice Returns the timestamp at which the prize period ends.
    /// @return The timestamp at which the prize period ends.
    function _prizePeriodEndAt() internal view returns (uint256) {
        // current prize started at is non-inclusive, so add one
        return prizePeriodStartedAt.add(prizePeriodSeconds);
    }

    /// @notice returns the current time.  Used for testing.
    /// @return The current time (block.timestamp).
    function _currentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @notice returns the current time.  Used for testing.
    /// @return The current time (block.timestamp).
    function _currentBlock() internal view virtual returns (uint256) {
        return block.number;
    }

    /// @return calculates and returns the next prize period start time.
    function _calculateNextPrizePeriodStartTime(uint256 currentTime)
        internal
        view
        returns (uint256)
    {
        uint256 elapsedPeriods = currentTime.sub(prizePeriodStartedAt).div(
            prizePeriodSeconds
        );
        return prizePeriodStartedAt.add(elapsedPeriods.mul(prizePeriodSeconds));
    }

    /// @notice ensure that the award period is currently not in progress.
    function _requireRngNotInFlight() internal view {
        uint256 currentBlock = _currentBlock();
        require(
            rngRequest.lockBlock == 0 || currentBlock < rngRequest.lockBlock,
            "PeriodicPrizeStrategy/rng-in-flight"
        );
    }

    function _distribute(uint256 randomNumber) internal virtual;

    modifier requireRngNotInFlight() {
        _requireRngNotInFlight();
        _;
    }

    modifier requireCanStartAward() {
        require(
            _isPrizePeriodOver(),
            "PeriodicPrizeStrategy/prize-period-not-over"
        );
        require(
            !isRngRequested(),
            "PeriodicPrizeStrategy/rng-already-requested"
        );
        _;
    }

    modifier requireCanCompleteAward() {
        require(isRngRequested(), "PeriodicPrizeStrategy/rng-not-requested");
        require(isRngCompleted(), "PeriodicPrizeStrategy/rng-not-complete");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface ITulipArt {
    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function setWinner(address _winner, uint256 randomNumber) external;

    function startDraw() external;

    function finishDraw() external;

    function chanceOf(address user) external view returns (uint256);

    function userStake(address user) external view returns (uint256);

    function draw(uint256 randomNumber) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

/// @title Random Number Generator Interface
/// @notice Provides an interface for requesting random numbers from
/// 3rd-party RNG services (Chainlink VRF, Starkware VDF, etc..)
interface RNGInterface {
    /// @notice Emitted when a new request for a random number has been submitted
    /// @param requestId The indexed ID of the request used to get the results of the RNG service
    /// @param sender The indexed address of the sender of the request
    event RandomNumberRequested(
        uint32 indexed requestId,
        address indexed sender
    );

    /// @notice Emitted when an existing request for a random number has been completed
    /// @param requestId The indexed ID of the request used to get the results of the RNG service
    /// @param randomNumber The random number produced by the 3rd-party service
    event RandomNumberCompleted(uint32 indexed requestId, uint256 randomNumber);

    /// @notice Gets the last request id used by the RNG service
    /// @return requestId The last request id used in the last request
    function getLastRequestId() external view returns (uint32 requestId);

    /// @notice Gets the Fee for making a Request against an RNG service
    /// @return feeToken The address of the token that is used to pay fees
    /// @return requestFee The fee required to be paid to make a request
    function getRequestFee()
        external
        view
        returns (address feeToken, uint256 requestFee);

    /// @notice Sends a request for a random number to the 3rd-party service
    /// @dev Some services will complete the request immediately, others may have a time-delay
    /// @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
    /// @return requestId The ID of the request used to get the results of the RNG service
    /// @return lockBlock The block number at which the RNG service will start
    /// generating time-delayed randomness.  The calling contract
    /// should "lock" all activity until the result is available via the `requestId`
    function requestRandomNumber()
        external
        returns (uint32 requestId, uint32 lockBlock);

    /// @notice Checks if the request for randomness from the 3rd-party service has completed
    /// @dev For time-delayed requests, this function is used to check/confirm completion
    /// @param requestId The ID of the request used to get the results of the RNG service
    /// @return isCompleted True if the request has completed and a random number is available, false otherwise
    function isRequestComplete(uint32 requestId)
        external
        view
        returns (bool isCompleted);

    /// @notice Gets the random number produced by the 3rd-party service
    /// @param requestId The ID of the request used to get the results of the RNG service
    /// @return randomNum The random number
    function randomNumber(uint32 requestId)
        external
        returns (uint256 randomNum);
}

// SPDX-License-Identifier: UNLICENSED

/**
Copyright 2020 PoolTogether Inc.

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.0 <0.8.0;

import "./OpenZeppelinSafeMath_V3_3_0.sol";

/**
 * @author Brendan Asselstine
 * @notice Provides basic fixed point math calculations.
 *
 * This library calculates integer fractions by scaling values by 1e18 then performing standard integer math.
 */
library FixedPoint {
    using OpenZeppelinSafeMath_V3_3_0 for uint256;

    // The scale to use for fixed point numbers.  Same as Ether for simplicity.
    uint256 internal constant SCALE = 1e18;

    /**
     * Calculates a Fixed18 mantissa given the numerator and denominator
     *
     * The mantissa = (numerator * 1e18) / denominator
     *
     * @param numerator The mantissa numerator
     * @param denominator The mantissa denominator
     * @return The mantissa of the fraction
     */
    function calculateMantissa(uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256)
    {
        uint256 mantissa = numerator.mul(SCALE);
        mantissa = mantissa.div(denominator);
        return mantissa;
    }

    /**
     * Multiplies a Fixed18 number by an integer.
     *
     * @param b The whole integer to multiply
     * @param mantissa The Fixed18 number
     * @return An integer that is the result of multiplying the params.
     */
    function multiplyUintByMantissa(uint256 b, uint256 mantissa)
        internal
        pure
        returns (uint256)
    {
        uint256 result = mantissa.mul(b);
        result = result.div(SCALE);
        return result;
    }

    /**
     * Divides an integer by a fixed point 18 mantissa
     *
     * @param dividend The integer to divide
     * @param mantissa The fixed point 18 number to serve as the divisor
     * @return An integer that is the result of dividing an integer by a fixed point 18 mantissa
     */
    function divideUintByMantissa(uint256 dividend, uint256 mantissa)
        internal
        pure
        returns (uint256)
    {
        uint256 result = SCALE.mul(dividend);
        result = result.div(mantissa);
        return result;
    }
}

// SPDX-License-Identifier: MIT

// NOTE: Copied from OpenZeppelin Contracts version 3.3.0

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
library OpenZeppelinSafeMath_V3_3_0 {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}