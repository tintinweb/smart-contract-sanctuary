// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.8;
pragma abicoder v2;

interface IforbitspaceX {
	event AggregateSwapped(
		address indexed recipient,
		address indexed tokenIn,
		address indexed tokenOut,
		uint amountIn,
		uint amountOut
	);

	struct AggregateParam {
		address tokenIn;
		address tokenOut;
		uint amountInTotal;
		address recipient;
		SwapParam[] sParams;
	}

	struct SwapParam {
		address addressToApprove;
		address exchangeTarget;
		address tokenIn; // tokenFrom
		address tokenOut; // tokenTo
		bytes swapData;
	}

	function version() external pure returns (string memory);

	function aggregate(AggregateParam calldata aParam)
		external
		payable
		returns (uint amountInAcutual, uint amountOutAcutual);
}

//
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint);

	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address account) external view returns (uint);

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address recipient, uint amount) external returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender) external view returns (uint);

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
	function approve(address spender, uint amount) external returns (bool);

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
		uint amount
	) external returns (bool);

	/**
	 * @dev Emitted when `value` tokens are moved from one account (`from`) to
	 * another (`to`).
	 *
	 * Note that `value` may be zero.
	 */
	event Transfer(address indexed from, address indexed to, uint value);

	/**
	 * @dev Emitted when the allowance of a `spender` for an `owner` is set by
	 * a call to {approve}. `value` is the new allowance.
	 */
	event Approval(address indexed owner, address indexed spender, uint value);
}

//
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

		uint size;
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
	function sendValue(address payable recipient, uint amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");

		(bool success, ) = recipient.call{ value: amount }("");
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
		uint value
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
		uint value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{ value: value }(data);
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

library SafeERC20 {
	using Address for address;

	function safeTransfer(
		IERC20 token,
		address to,
		uint value
	) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}

	function safeTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint value
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
		uint value
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
		uint value
	) internal {
		uint newAllowance = token.allowance(address(this), spender) + value;
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}

	function safeDecreaseAllowance(
		IERC20 token,
		address spender,
		uint value
	) internal {
		unchecked {
			uint oldAllowance = token.allowance(address(this), spender);
			require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
			uint newAllowance = oldAllowance - value;
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

library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryAdd(uint a, uint b) internal pure returns (bool, uint) {
		unchecked {
			uint c = a + b;
			if (c < a) return (false, 0);
			return (true, c);
		}
	}

	/**
	 * @dev Returns the substraction of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function trySub(uint a, uint b) internal pure returns (bool, uint) {
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
	function tryMul(uint a, uint b) internal pure returns (bool, uint) {
		unchecked {
			// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
			// benefit is lost if 'b' is also tested.
			// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
			if (a == 0) return (true, 0);
			uint c = a * b;
			if (c / a != b) return (false, 0);
			return (true, c);
		}
	}

	/**
	 * @dev Returns the division of two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryDiv(uint a, uint b) internal pure returns (bool, uint) {
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
	function tryMod(uint a, uint b) internal pure returns (bool, uint) {
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
	function add(uint a, uint b) internal pure returns (uint) {
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
	function sub(uint a, uint b) internal pure returns (uint) {
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
	function mul(uint a, uint b) internal pure returns (uint) {
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
	function div(uint a, uint b) internal pure returns (uint) {
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
	function mod(uint a, uint b) internal pure returns (uint) {
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
		uint a,
		uint b,
		string memory errorMessage
	) internal pure returns (uint) {
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
		uint a,
		uint b,
		string memory errorMessage
	) internal pure returns (uint) {
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
		uint a,
		uint b,
		string memory errorMessage
	) internal pure returns (uint) {
		unchecked {
			require(b > 0, errorMessage);
			return a % b;
		}
	}
}

interface IWETH is IERC20 {
	/// @notice Deposit ether to get wrapped ether
	function deposit() external payable;

	/// @notice Withdraw wrapped ether to get ether
	function withdraw(uint) external;
}

//
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

//
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

	function __Context_init_unchained() internal initializer {}

	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}

	uint[50] private __gap;
}

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

	uint[49] private __gap;
}

interface IStorage {
	event FeeToTransfered(address indexed oldFeeTo, address indexed newFeeTo);

	function setFeeTo(address newFeeTo) external;

	function feeTo() external view returns (address);

	function ETH() external view returns (address);

	function WETH() external view returns (address);
}

abstract contract Storage is IStorage, OwnableUpgradeable {
	address private _feeTo_;
	address private _WETH_;
	address private _ETH_;

	function initialize(address _WETH, address _feeTo) public initializer {
		__Ownable_init();
		setFeeTo(_feeTo);
		setWETH(_WETH);
		setETH(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
	}

	function setFeeTo(address _feeTo) public override onlyOwner {
		address newFeeTo = _feeTo == address(0) ? owner() : _feeTo;
		address oldFeeTo = _feeTo_;
		_feeTo_ = newFeeTo;
		emit FeeToTransfered(oldFeeTo, newFeeTo);
	}

	function setETH(address _ETH) private initializer {
		require(_ETH != address(0), "Z");
		_ETH_ = _ETH;
	}

	function setWETH(address _WETH) private initializer {
		require(_WETH != address(0), "Z");
		_WETH_ = _WETH;
	}

	function feeTo() public view override returns (address) {
		return _feeTo_;
	}

	function ETH() public view override returns (address) {
		return _ETH_;
	}

	function WETH() public view override returns (address) {
		return _WETH_;
	}
}

interface IPayment is IStorage {
	event FeeCollected(address indexed feeTo, address indexed token, uint amount);

	function collectETH() external returns (uint amount);

	function collectTokens(address token) external returns (uint amount);
}

abstract contract Payment is IPayment, Storage {
	using SafeMath for uint;
	using SafeERC20 for IERC20;

	receive() external payable {}

	function approve(
		address addressToApprove,
		address token,
		uint amount
	) internal {
		if (IERC20(token).allowance(address(this), addressToApprove) < amount) {
			IERC20(token).safeApprove(addressToApprove, 0);
			IERC20(token).safeIncreaseAllowance(addressToApprove, type(uint).max);
		}
	}

	function balanceOf(address token) internal view returns (uint bal) {
		bal = IERC20(token == ETH() ? WETH() : token).balanceOf(address(this));
	}

	function pay(
		address recipient,
		address token,
		uint amount
	) internal {
		if (amount > 0) {
			if (recipient == address(this)) {
				if (token == ETH()) {
					IWETH(WETH()).deposit{ value: amount }();
				} else {
					IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
				}
			} else {
				if (token == ETH()) {
					if (balanceOf(WETH()) > 0) {
						IWETH(WETH()).withdraw(balanceOf(WETH()));
					}
					Address.sendValue(payable(recipient), amount);
				} else {
					IERC20(token).safeTransfer(recipient, amount);
				}
			}
		}
	}

	function collectETH() public override returns (uint amount) {
		if (balanceOf(WETH()) > 0) {
			IWETH(WETH()).withdraw(balanceOf(WETH()));
		}

		if ((amount = address(this).balance) > 0) {
			Address.sendValue(payable(feeTo()), amount);
		}
	}

	function collectTokens(address token) public override returns (uint amount) {
		if (token == ETH()) {
			amount = collectETH();
		} else if ((amount = balanceOf(token)) > 0) {
			IERC20(token).safeTransfer(feeTo(), amount);
		}

		if (amount > 0) {
			emit FeeCollected(feeTo(), token, amount);
		}
	}
}

//
/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
	/**
	 * @dev Must return an address that can be used as a delegate call target.
	 *
	 * {BeaconProxy} will check that this address is a contract.
	 */
	function implementation() external view returns (address);
}

//
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

		uint size;
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
	function sendValue(address payable recipient, uint amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");

		(bool success, ) = recipient.call{ value: amount }("");
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
		uint value
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
		uint value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{ value: value }(data);
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

//
/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
	struct AddressSlot {
		address value;
	}

	struct BooleanSlot {
		bool value;
	}

	struct Bytes32Slot {
		bytes32 value;
	}

	struct Uint256Slot {
		uint value;
	}

	/**
	 * @dev Returns an `AddressSlot` with member `value` located at `slot`.
	 */
	function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
		assembly {
			r.slot := slot
		}
	}

	/**
	 * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
	 */
	function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
		assembly {
			r.slot := slot
		}
	}

	/**
	 * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
	 */
	function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
		assembly {
			r.slot := slot
		}
	}

	/**
	 * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
	 */
	function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
		assembly {
			r.slot := slot
		}
	}
}

//
/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
	function __ERC1967Upgrade_init() internal initializer {
		__ERC1967Upgrade_init_unchained();
	}

	function __ERC1967Upgrade_init_unchained() internal initializer {}

	// This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
	bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

	/**
	 * @dev Storage slot with the address of the current implementation.
	 * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
	 * validated in the constructor.
	 */
	bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

	/**
	 * @dev Emitted when the implementation is upgraded.
	 */
	event Upgraded(address indexed implementation);

	/**
	 * @dev Returns the current implementation address.
	 */
	function _getImplementation() internal view returns (address) {
		return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
	}

	/**
	 * @dev Stores a new address in the EIP1967 implementation slot.
	 */
	function _setImplementation(address newImplementation) private {
		require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
		StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
	}

	/**
	 * @dev Perform implementation upgrade
	 *
	 * Emits an {Upgraded} event.
	 */
	function _upgradeTo(address newImplementation) internal {
		_setImplementation(newImplementation);
		emit Upgraded(newImplementation);
	}

	/**
	 * @dev Perform implementation upgrade with additional setup call.
	 *
	 * Emits an {Upgraded} event.
	 */
	function _upgradeToAndCall(
		address newImplementation,
		bytes memory data,
		bool forceCall
	) internal {
		_upgradeTo(newImplementation);
		if (data.length > 0 || forceCall) {
			_functionDelegateCall(newImplementation, data);
		}
	}

	/**
	 * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
	 *
	 * Emits an {Upgraded} event.
	 */
	function _upgradeToAndCallSecure(
		address newImplementation,
		bytes memory data,
		bool forceCall
	) internal {
		address oldImplementation = _getImplementation();

		// Initial upgrade and setup call
		_setImplementation(newImplementation);
		if (data.length > 0 || forceCall) {
			_functionDelegateCall(newImplementation, data);
		}

		// Perform rollback test if not already in progress
		StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(
			_ROLLBACK_SLOT
		);
		if (!rollbackTesting.value) {
			// Trigger rollback using upgradeTo from the new implementation
			rollbackTesting.value = true;
			_functionDelegateCall(newImplementation, abi.encodeWithSignature("upgradeTo(address)", oldImplementation));
			rollbackTesting.value = false;
			// Check rollback was effective
			require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
			// Finally reset to the new implementation and log the upgrade
			_upgradeTo(newImplementation);
		}
	}

	/**
	 * @dev Storage slot with the admin of the contract.
	 * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
	 * validated in the constructor.
	 */
	bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

	/**
	 * @dev Emitted when the admin account has changed.
	 */
	event AdminChanged(address previousAdmin, address newAdmin);

	/**
	 * @dev Returns the current admin.
	 */
	function _getAdmin() internal view returns (address) {
		return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
	}

	/**
	 * @dev Stores a new address in the EIP1967 admin slot.
	 */
	function _setAdmin(address newAdmin) private {
		require(newAdmin != address(0), "ERC1967: new admin is the zero address");
		StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
	}

	/**
	 * @dev Changes the admin of the proxy.
	 *
	 * Emits an {AdminChanged} event.
	 */
	function _changeAdmin(address newAdmin) internal {
		emit AdminChanged(_getAdmin(), newAdmin);
		_setAdmin(newAdmin);
	}

	/**
	 * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
	 * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
	 */
	bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

	/**
	 * @dev Emitted when the beacon is upgraded.
	 */
	event BeaconUpgraded(address indexed beacon);

	/**
	 * @dev Returns the current beacon.
	 */
	function _getBeacon() internal view returns (address) {
		return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
	}

	/**
	 * @dev Stores a new beacon in the EIP1967 beacon slot.
	 */
	function _setBeacon(address newBeacon) private {
		require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
		require(
			AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
			"ERC1967: beacon implementation is not a contract"
		);
		StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
	}

	/**
	 * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
	 * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
	 *
	 * Emits a {BeaconUpgraded} event.
	 */
	function _upgradeBeaconToAndCall(
		address newBeacon,
		bytes memory data,
		bool forceCall
	) internal {
		_setBeacon(newBeacon);
		emit BeaconUpgraded(newBeacon);
		if (data.length > 0 || forceCall) {
			_functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
		}
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
	 * but performing a delegate call.
	 *
	 * _Available since v3.4._
	 */
	function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
		require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
	}

	uint[50] private __gap;
}

abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
	function __UUPSUpgradeable_init() internal initializer {
		__ERC1967Upgrade_init_unchained();
		__UUPSUpgradeable_init_unchained();
	}

	function __UUPSUpgradeable_init_unchained() internal initializer {}

	/// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
	address private immutable __self = address(this);

	/**
	 * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
	 * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
	 * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
	 * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
	 * fail.
	 */
	modifier onlyProxy() {
		require(address(this) != __self, "Function must be called through delegatecall");
		require(_getImplementation() == __self, "Function must be called through active proxy");
		_;
	}

	/**
	 * @dev Upgrade the implementation of the proxy to `newImplementation`.
	 *
	 * Calls {_authorizeUpgrade}.
	 *
	 * Emits an {Upgraded} event.
	 */
	function upgradeTo(address newImplementation) external virtual onlyProxy {
		_authorizeUpgrade(newImplementation);
		_upgradeToAndCallSecure(newImplementation, new bytes(0), false);
	}

	/**
	 * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
	 * encoded in `data`.
	 *
	 * Calls {_authorizeUpgrade}.
	 *
	 * Emits an {Upgraded} event.
	 */
	function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
		_authorizeUpgrade(newImplementation);
		_upgradeToAndCallSecure(newImplementation, data, true);
	}

	/**
	 * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
	 * {upgradeTo} and {upgradeToAndCall}.
	 *
	 * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
	 *
	 * ```solidity
	 * function _authorizeUpgrade(address) internal override onlyOwner {}
	 * ```
	 */
	function _authorizeUpgrade(address newImplementation) internal virtual;

	uint[50] private __gap;
}

//
contract forbitspaceX is IforbitspaceX, Payment {
	using SafeMath for uint;
	using Address for address;

	// Z: zero-address
	// I_P: invalid path
	// I_V: invalid value
	// I_A_T_A: invalid actual total amounts
	// I_A_A: invalid actual amounts
	// I_T_I: invalid token in
	// I_T_O: invalid token out
	// N_E_T: not enough tokens
	// L_C_F: low-level call failed

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() initializer {}

	function version() public pure virtual override returns (string memory) {
		return "2.0.0";
	}

	function aggregate(AggregateParam calldata aParam)
		public
		payable
		returns (uint amountInActual, uint amountOutActual)
	{
		address tokenIn = aParam.tokenIn == address(0) ? ETH() : aParam.tokenIn;
		address tokenOut = aParam.tokenOut == address(0) ? ETH() : aParam.tokenOut;
		address recipient = aParam.recipient == address(0) ? _msgSender() : aParam.recipient;
		uint amountInTotal = tokenIn == ETH() ? msg.value : aParam.amountInTotal;

		if (tokenIn != ETH()) {
			require(msg.value == 0, "I_V");
		}
		require(amountInTotal > 0, "I_V");
		require(!(tokenIn == tokenOut), "I_P");
		require(!(tokenIn == ETH() && tokenOut == WETH()), "I_P");
		require(!(tokenIn == WETH() && tokenOut == ETH()), "I_P");

		// receive tokens
		pay(address(this), tokenIn, amountInTotal);

		// amountActual before
		amountInActual = balanceOf(tokenIn);
		amountOutActual = balanceOf(tokenOut);

		// call swap on multi dexs
		performSwap(aParam.sParams);

		// amountActual after
		amountInActual = amountInActual.sub(balanceOf(tokenIn));
		amountOutActual = balanceOf(tokenOut).sub(amountOutActual);

		require((amountInActual > 0) && (amountOutActual > 0), "I_A_T_A");

		// take 0.05% fee
		amountOutActual = amountOutActual.mul(9995).div(10000);

		// refund tokens
		pay(_msgSender(), tokenIn, amountInTotal.sub(amountInActual, "N_E_T"));
		pay(recipient, tokenOut, amountOutActual);

		// sweep tokens for owner
		collectTokens(tokenIn);
		collectTokens(tokenOut);

		emit AggregateSwapped(recipient, tokenIn, tokenOut, amountInActual, amountOutActual);
	}

	function performSwap(SwapParam[] calldata params) private {
		for (uint i = 0; i < params.length; i++) {
			address addressToApprove = params[i].addressToApprove;
			address exchangeTarget = params[i].exchangeTarget;
			address tokenIn = params[i].tokenIn;
			address tokenOut = params[i].tokenOut;

			require(addressToApprove != address(0) && exchangeTarget != address(0), "Z");
			require(tokenIn != address(0) && tokenIn != ETH(), "I_T_I");
			require(tokenOut != address(0) && tokenOut != ETH(), "I_T_O");
			require(tokenIn != tokenOut, "I_P");

			approve(addressToApprove, tokenIn, type(uint).max);

			// amountActual before
			uint amountInActual = balanceOf(tokenIn);
			uint amountOutActual = balanceOf(tokenOut);

			exchangeTarget.functionCall(params[i].swapData, "L_C_F");

			// amountActual after
			amountInActual = amountInActual.sub(balanceOf(tokenIn));
			amountOutActual = balanceOf(tokenOut).sub(amountOutActual);

			require((amountInActual > 0) && (amountOutActual > 0), "I_A_A");
		}
	}
}

// contract forbitspaceX_Transparent is forbitspaceX {}
contract forbitspaceX_UUPS is forbitspaceX, UUPSUpgradeable {
	function _authorizeUpgrade(address newImplementation) internal virtual override {}
}