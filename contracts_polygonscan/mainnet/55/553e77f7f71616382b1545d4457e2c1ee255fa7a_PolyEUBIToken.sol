/**
 *Submitted for verification at polygonscan.com on 2021-12-21
*/

// File: contracts/utils/math/SafeCast.sol


// OpenZeppelin Contracts v4.3.2 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

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
library SafeCast {
	/**
	 * @dev Returns the downcasted uint224 from uint256, reverting on
	 * overflow (when the input is greater than largest uint224).
	 *
	 * Counterpart to Solidity's `uint224` operator.
	 *
	 * Requirements:
	 *
	 * - input must fit into 224 bits
	 */
	function toUint224(uint256 value) internal pure returns (uint224) {
		require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
		return uint224(value);
	}

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
		require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
		return uint128(value);
	}

	/**
	 * @dev Returns the downcasted uint96 from uint256, reverting on
	 * overflow (when the input is greater than largest uint96).
	 *
	 * Counterpart to Solidity's `uint96` operator.
	 *
	 * Requirements:
	 *
	 * - input must fit into 96 bits
	 */
	function toUint96(uint256 value) internal pure returns (uint96) {
		require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
		return uint96(value);
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
		require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
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
		require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
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
		require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
		require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
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
		require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
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
		require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
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
		require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
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
		require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
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
		require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
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
		// Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
		require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
		return int256(value);
	}
}

// File: contracts/utils/Address.sol


// OpenZeppelin Contracts v4.3.2 (utils/Address.sol)

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

// File: contracts/utils/Context.sol


// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

// File: contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

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

// File: contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.3.2 (token/ERC20/utils/SafeERC20.sol)

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

// File: contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.3.2 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// File: contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
	constructor(string memory name_, string memory symbol_) {
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
	 * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
}

// File: contracts/interfaces/IERC3156FlashBorrower.sol


// OpenZeppelin Contracts v4.3.2 (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
	/**
	 * @dev Receive a flash loan.
	 * @param initiator The initiator of the loan.
	 * @param token The loan currency.
	 * @param amount The amount of tokens lent.
	 * @param fee The additional amount of tokens to repay.
	 * @param data Arbitrary data structure, intended to contain user-defined parameters.
	 * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
	 */
	function onFlashLoan(
		address initiator,
		address token,
		uint256 amount,
		uint256 fee,
		bytes calldata data
	) external returns (bytes32);
}

// File: contracts/interfaces/IERC3156FlashLender.sol


// OpenZeppelin Contracts v4.3.2 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
	/**
	 * @dev The amount of currency available to be lended.
	 * @param token The loan currency.
	 * @return The amount of `token` that can be borrowed.
	 */
	function maxFlashLoan(address token) external view returns (uint256);

	/**
	 * @dev The fee to be charged for a given loan.
	 * @param token The loan currency.
	 * @param amount The amount of tokens lent.
	 * @return The amount of `token` to be charged for the loan, on top of the returned principal.
	 */
	function flashFee(address token, uint256 amount) external view returns (uint256);

	/**
	 * @dev Initiate a flash loan.
	 * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
	 * @param token The loan currency.
	 * @param amount The amount of tokens lent.
	 * @param data Arbitrary data structure, intended to contain user-defined parameters.
	 */
	function flashLoan(
		IERC3156FlashBorrower receiver,
		address token,
		uint256 amount,
		bytes calldata data
	) external returns (bool);
}

// File: contracts/interfaces/IERC3156.sol


// OpenZeppelin Contracts v4.3.2 (interfaces/IERC3156.sol)

pragma solidity ^0.8.0;



// File: contracts/token/ERC20/extensions/ERC20FlashMint.sol


// OpenZeppelin Contracts v4.3.2 (token/ERC20/extensions/ERC20FlashMint.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the ERC3156 Flash loans extension, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * Adds the {flashLoan} method, which provides flash loan support at the token
 * level. By default there is no fee, but this can be changed by overriding {flashFee}.
 *
 * _Available since v4.1._
 */
abstract contract ERC20FlashMint is ERC20, IERC3156FlashLender {
	bytes32 private constant _RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");

	/**
	 * @dev Returns the maximum amount of tokens available for loan.
	 * @param token The address of the token that is requested.
	 * @return The amont of token that can be loaned.
	 */
	function maxFlashLoan(address token) public view override returns (uint256) {
		return token == address(this) ? type(uint256).max - ERC20.totalSupply() : 0;
	}

	/**
	 * @dev Returns the fee applied when doing flash loans. By default this
	 * implementation has 0 fees. This function can be overloaded to make
	 * the flash loan mechanism deflationary.
	 * @param token The token to be flash loaned.
	 * @param amount The amount of tokens to be loaned.
	 * @return The fees applied to the corresponding flash loan.
	 */
	function flashFee(address token, uint256 amount) public view virtual override returns (uint256) {
		require(token == address(this), "ERC20FlashMint: wrong token");
		// silence warning about unused variable without the addition of bytecode.
		amount;
		return 0;
	}

	/**
	 * @dev Performs a flash loan. New tokens are minted and sent to the
	 * `receiver`, who is required to implement the {IERC3156FlashBorrower}
	 * interface. By the end of the flash loan, the receiver is expected to own
	 * amount + fee tokens and have them approved back to the token contract itself so
	 * they can be burned.
	 * @param receiver The receiver of the flash loan. Should implement the
	 * {IERC3156FlashBorrower.onFlashLoan} interface.
	 * @param token The token to be flash loaned. Only `address(this)` is
	 * supported.
	 * @param amount The amount of tokens to be loaned.
	 * @param data An arbitrary datafield that is passed to the receiver.
	 * @return `true` is the flash loan was successful.
	 */
	function flashLoan(
		IERC3156FlashBorrower receiver,
		address token,
		uint256 amount,
		bytes calldata data
	) public virtual override returns (bool) {
		uint256 fee = flashFee(token, amount);
		_mint(address(receiver), amount);
		require(
			receiver.onFlashLoan(msg.sender, token, amount, fee, data) == _RETURN_VALUE,
			"ERC20FlashMint: invalid return value"
		);
		uint256 currentAllowance = allowance(address(receiver), address(this));
		require(currentAllowance >= amount + fee, "ERC20FlashMint: allowance does not allow refund");
		_approve(address(receiver), address(this), currentAllowance - amount - fee);
		_burn(address(receiver), amount + fee);
		return true;
	}
}

// File: contracts/PolyEUBI.sol


pragma solidity ^0.8.0;




//PolyEUBI token contract
contract PolyEUBIToken is ERC20FlashMint{
	constructor() ERC20('PolyEUBI Token: Be owner of the insurance company', 'PolyEUBI'){
		//Mint 900,000 PolyEUBI to Bela Balog
		_mint(0x77c4529FC9D0446642EB29cE33b8B2afD43926d0, 900000 ether);
		//Mint 100,000 PolyEUBI to Jessie Lesbian
		_mint(0xA199cB65F0B53B092DE8A792BF330eA093507115, 100000 ether);
	}

	//Infinite Approval Optimizations
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public override returns (bool) {
		if(allowance(sender, msg.sender) == 115792089237316195423570985008687907853269984665640564039457584007913129639935){
			_transfer(sender, recipient, amount);
			return true;
		} else{
			return super.transferFrom(sender, recipient, amount);
		}
	}
}