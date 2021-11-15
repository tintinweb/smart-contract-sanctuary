// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

interface IBEP20 {

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

abstract contract Context {
	function _msgSender() internal view virtual returns (address payable) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}


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
		// According to EIP-1052, 0x0 is the value returned for not-yet created accounts
		// and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
		// for accounts without code, i.e. `keccak256('')`
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		// solhint-disable-next-line no-inline-assembly
		assembly { codehash := extcodehash(account) }
		return (codehash != accountHash && codehash != 0x0);
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
		return _functionCallWithValue(target, data, 0, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but also transferring `value` wei to `target`.
	 *
	 * Requirements:
	 *
	 * - the calling contract must have an BNB balance of at least `value`.
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
		return _functionCallWithValue(target, data, value, errorMessage);
	}

	function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
		require(isContract(target), "Address: call to non-contract");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
contract Ownable is Context {
	address private _owner;
	address private _previousOwner;
	mapping(address => bool) private _authorizedCallers;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event AuthorizedCaller(address account,bool value);
	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor () internal {
		address msgSender = _msgSender();
		_owner = msgSender;
		_authorizedCallers[msgSender] = true;
		emit OwnershipTransferred(address(0), msgSender);
	}

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view returns (address) {
		return _owner;
	}

	function isAuthorizedCaller(address account) public view returns (bool) {
		return _authorizedCallers[account];
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	modifier onlyAuthorizedCallers() {
		require(_authorizedCallers[_msgSender()] == true, "Ownable: caller is not authorized");
		_;
	}

	function setAuthorizedCallers(address account,bool value) public onlyAuthorizedCallers {
		require(account != address(0), "Ownable: Authorized caller is the zero address");
		_authorizedCallers[account] = value;
		emit AuthorizedCaller(account,value);
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
		_authorizedCallers[_owner] = false;
		_owner = address(0);
		
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_authorizedCallers[_owner] = false;
		_authorizedCallers[newOwner] = true;
		_owner = newOwner;
	}
}

interface IPancakeFactory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint);

	function feeTo() external view returns (address);
	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);
	function allPairs(uint) external view returns (address pair);
	function allPairsLength() external view returns (uint);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setFeeTo(address) external;
	function setFeeToSetter(address) external;
}

interface IPancakePair {
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

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

	constructor () public {
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

	modifier isHuman() {
		require(tx.origin == msg.sender, "sorry humans only");
		_;
	}
}

library Utils {
	using SafeMath for uint256;

	function swapTokensForEth(
		address routerAddress,
		uint256 tokenAmount
	) public {
		IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

		// generate the pancake pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = pancakeRouter.WETH();

		// make the swap
		pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of BNB
			path,
			address(this),
			block.timestamp
		);
	}

	function swapETHForTokens(
		address routerAddress,
		address recipient,
		uint256 ethAmount
	) public {
		IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

		// generate the pancake pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = pancakeRouter.WETH();
		path[1] = address(this);

		// make the swap
		pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
			0, // accept any amount of BNB
			path,
			address(recipient),
			block.timestamp + 360
		);
	}

	function swapETHForRewardTokens(
		address routerAddress,
		address tokenAddress,
		address recipient,
		uint256 ethAmount
	) public {
		IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

		// generate the pancake pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = pancakeRouter.WETH();
		path[1] = tokenAddress;

		// make the swap
		pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
			0, // accept any amount of BNB
			path,
			address(recipient),
			block.timestamp + 360
		);
	}

	function addLiquidity(
		address routerAddress,
		address owner,
		uint256 tokenAmount,
		uint256 ethAmount
	) public {
		IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

		// add the liquidity
		pancakeRouter.addLiquidityETH{value : ethAmount}(
			address(this),
			tokenAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			owner,
			block.timestamp + 360
		);
	}

	function mulScale(uint256 x, uint256 y, uint128 scale) internal pure returns (uint256) {
		uint256 a = x.div(scale);
		uint256 b = x.mod(scale);
		uint256 c = y.div(scale);
		uint256 d = y.mod(scale);
		return (a.mul(c).mul(scale)).add(a.mul(d)).add(b.mul(c)).add(b.mul(d).div(scale));
	}

}
 
contract Staking is Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

	uint256 private _rewardPools;
	uint256 private _currentRewardPools;
	uint256 private _currentTotalRewardPools;
	uint256 private _previousRewardPools;
	uint256 private _previousTotalRewardPools;
	uint256 private _totalStaked;
	uint256 private _countStakers;
	uint256 private _lastSwitchPools;
	bool private _poolEnabled;
	uint256 private _poolTokensByPeriod;
	uint256 private _accumulatedTokensByPeriod;
	uint256 private _accumulatedFactorFor;
	uint256 private _minStackersForFullReward;
	mapping (address => uint256) private _userStakes;
	mapping (address => uint256) private _nextClaimDate;
	uint256 private _stakePeriod;
	uint256 private _unstakeTax;

	address public immutable shibacashTokenAddress;
	address public immutable leashAddress;

	address private marketingWallet;

	mapping (address => bool) private _isExcludedFromSupply;
    address[] private _excludedFromSupply;
	
	event ClaimRewardSuccessfully(
		address to,
		uint256 amount,
		uint256 nextClaimDate
	);

	event UnstakeTokenSuccessfully(
		address to,
		uint256 tokenReceived
	);
	
	event RetrieveBNBSuccessfully(
		address from,
		address to,
		uint256 bnbReceived
	);

	event RetrieveTokenSuccessfully(
		address from,
		address to,
		uint256 tokenReceived
	);
	
	event ResetPool(
		address from,
		uint256 poolAmount        
	);
	
	event ResetLastSwitchPool(
		address from,
		uint256 lastSwitch        
	);

	event NextClaimDate(
		address from,
		uint256 claimDate        
	);
	
	constructor(address _leashAddress,address _shibacashTokenAddress,address parentOwner) public {
		leashAddress = _leashAddress;
		shibacashTokenAddress = _shibacashTokenAddress;
		_excludeFromSupply(address(this));
		_excludeFromSupply(address(0));
		_excludeFromSupply(address(0x000000000000000000000000000000000000dEaD));
		_excludeFromSupply(_leashAddress);
		_excludeFromSupply(parentOwner);
		setAuthorizedCallers(_leashAddress,true);
		setAuthorizedCallers(parentOwner,true);
	}

    function _excludeFromSupply(address account) private {
        if (_isExcludedFromSupply[account]) return;
        _isExcludedFromSupply[account] = true;
        _excludedFromSupply.push(account);
    }
    
    function isExcludedFromSupply(address account) public view returns (bool) {
        return _isExcludedFromSupply[account];
    }

    function excludeFromSupply(address account) public onlyAuthorizedCallers() {
        require(!_isExcludedFromSupply[account], "Account is already excluded");
        _excludeFromSupply(account);
    }

    function _includeInSupply(address account) private {
        if (!_isExcludedFromSupply[account]) return;
        for (uint256 i = 0; i < _excludedFromSupply.length; i++) {
            if (_excludedFromSupply[i] == account) {
                _excludedFromSupply[i] = _excludedFromSupply[_excludedFromSupply.length - 1];
                _isExcludedFromSupply[account] = false;
                _excludedFromSupply.pop();
                break;
            }
        }
    }

    function includeInSupply(address account) external onlyAuthorizedCallers() {
        require(_isExcludedFromSupply[account], "Account is already excluded");
        _includeInSupply(account);
    }

	function _getStakePeriod() private view returns (uint256) {
		uint256 period = _stakePeriod;
		if (period == 0) {
			period = 7;
		}
		return period * 1 days;
	}
	
	function getStakePeriod() public view returns (uint256) {
		uint256 period = _stakePeriod;
		if (period == 0) {
			period = 7;
		}
		return period;
	}

	function setStakePeriod(uint256 period) public onlyAuthorizedCallers {
		if (period == 0) {
			period = 7;
		}
		_stakePeriod = period;
	}
	
	function _getUnstakeTax() private view returns (uint256) {
		return _unstakeTax;
	}
	
	function _getAccumulatedFactor() private view returns (uint256) {
		uint256 ret = _accumulatedFactorFor;
		if (ret == 0) {
			// 66%
			return 660000;
		} else{
			return ret;
		}
	}

	function _getMinStackersForFullReward() private view returns (uint256) {
		uint256 ret = _minStackersForFullReward;
		if (ret == 0) {
			return 100;
		}
		return _minStackersForFullReward;
	}

	function getMinStackersForFullReward() public view returns (uint256) {
		return _getMinStackersForFullReward();
	}

	function setMinStackersForFullReward(uint256 value) public onlyAuthorizedCallers {
		_minStackersForFullReward = value;
	}
	
	function getAccumulatedFactor() public view returns (uint256) {
		return _getAccumulatedFactor().div(10000);
	}

	function setAccumulatedFactor(uint256 tax) public onlyAuthorizedCallers {
		_accumulatedFactorFor = tax.mul(10000);
	}

	function getUnstakeTax() public view returns (uint256) {
		return _getUnstakeTax().div(10000);
	}

	function setUnstakeTax(uint256 tax) public onlyAuthorizedCallers {
		_unstakeTax = tax.mul(10000);
	}

	function _poolTokens(uint256 amount) public onlyAuthorizedCallers {
		_accumulatedTokensByPeriod = _accumulatedTokensByPeriod + amount;
		_rewardPools = _rewardPools + amount;
	}
	
	function _switchPool(uint256 toPool,bool force) private {
		require(_poolEnabled,"Pool not enabled !");
		require(toPool <= _rewardPools,"Pool not big enough, add tokens to pool first !");
		require(force || _lastSwitchPools + _getStakePeriod() <= block.timestamp,"Stake period not finished, cannot switch pool now !");
		uint256 previous = _previousRewardPools;
		_rewardPools = (_rewardPools - toPool) + previous;
		_previousRewardPools = _currentRewardPools;
		_previousTotalRewardPools = _previousRewardPools;
		_currentRewardPools = toPool;
		_currentTotalRewardPools = _currentRewardPools;
		_lastSwitchPools = block.timestamp;
	}

	function checkIfNeedToSwitchPool() public onlyAuthorizedCallers {
		if (_poolEnabled && 
			_lastSwitchPools + _getStakePeriod() <= block.timestamp) {
			_autoSwitchPool(false);
		}
	}

	function resetPoolTokens() public onlyAuthorizedCallers {
		_rewardPools = _rewardPools + _previousRewardPools + _currentRewardPools;
		_previousRewardPools = 0;
		_previousTotalRewardPools = 0;
		_currentRewardPools = 0;
		_currentTotalRewardPools = 0;
		_lastSwitchPools = 0;
		_poolEnabled = false;
		emit ResetPool(msg.sender,_rewardPools);
	}

	function resetLastSwitchPool() public onlyAuthorizedCallers {
		uint256 current = _lastSwitchPools;
		_lastSwitchPools = 0;
		emit ResetLastSwitchPool(msg.sender,current);
	}

	function poolTokens() external onlyAuthorizedCallers nonReentrant {
		_rewardPools = IBEP20(shibacashTokenAddress).balanceOf(address(this));
	}

	function _autoSwitchPool(bool force) private {
		require(force || _lastSwitchPools + _getStakePeriod() <= block.timestamp,"Stake period not finished, cannot switch pool now !");
		uint256 toAdd = Utils.mulScale(_accumulatedTokensByPeriod,getAccumulatedFactor(),1000000);
		if (_accumulatedTokensByPeriod > toAdd) {
			_accumulatedTokensByPeriod = _accumulatedTokensByPeriod.sub(toAdd);
		} else {
			toAdd = _accumulatedTokensByPeriod;
			_accumulatedTokensByPeriod = 0;
		}
		uint256 amount = _poolTokensByPeriod+toAdd;
		if (amount > 0 && _rewardPools > 0) {
			if (amount > _rewardPools) {
				amount = _rewardPools;
			}
			_switchPool(amount,force);
		}
	}

	function switchPool() external onlyAuthorizedCallers nonReentrant {
		if (_poolEnabled) {
			_autoSwitchPool(false);
		}
	}

	function forceSwitchPool() external onlyAuthorizedCallers nonReentrant {
		if (_poolEnabled) {
			_autoSwitchPool(true);
		}
	}

	function addHolder() public onlyAuthorizedCallers {
		_countStakers = _countStakers.add(1);
	}

	function removeHolder() public onlyAuthorizedCallers {
		if (_countStakers >= 1) {
			_countStakers = _countStakers.sub(1);
		}
	}

	function setPoolTokensByPeriod(uint256 amount) external onlyAuthorizedCallers nonReentrant {
		_poolTokensByPeriod = amount;
	}
	
	function getPoolTokensByPeriod() public view returns  (uint256) {
		return _poolTokensByPeriod;
	}

	function setMarketingWallet(address wallet) public onlyAuthorizedCallers {
		marketingWallet = wallet;
	}

	function getMarketingWalletAddress() public view returns (address) {
		return marketingWallet;
	}

	function poolEnabled(bool value) external onlyAuthorizedCallers {
		_poolEnabled = value;
	}

	function isPoolEnabled() external view returns (bool) {
		return _poolEnabled;
	}
	
	function canClaim(address account) external view returns (bool) {
		return _poolEnabled && _nextClaimDate[account] <= block.timestamp;  
	}
	
	function getRewardPool() external view returns (uint256) {
		return _rewardPools;  
	}

	function getCurrentRewardPool() external view returns (uint256) {
		return _currentRewardPools;  
	}

	function getCurrentTotalRewardPool() external view returns (uint256) {
		return _currentTotalRewardPools;  
	}

	function getPreviousRewardPool() external view returns (uint256) {
		return _previousRewardPools;  
	}

	function getPreviousTotalRewardPool() external view returns (uint256) {
		return _previousTotalRewardPools;  
	}

	function getLastSwitchForPool() external view returns (uint256) {
		return _lastSwitchPools;  
	}

	function getNextClaimDate(address account) external view returns (uint256) {
		if (!_poolEnabled) return 0;
		return _nextClaimDate[account];  
	}

	function getTotalStaked() external view returns (uint256) {
		return _totalStaked;  
	}

	function _estimatedRewards(uint256 poolAmount,uint256 currentPoolAmount,address account) private view returns (uint256) {
		if (_isExcludedFromSupply[account]) return 0;
		uint256 stakerBalance = IBEP20(leashAddress).balanceOf(account);
		uint256 rewardPercentage = 0;
		// less than _getMinStackersForFullReward stakers ? only receive count/minStakers % of real stake.
		uint256 minStakers = _getMinStackersForFullReward();
		if (_countStakers < minStakers) {
			rewardPercentage = Utils.mulScale(stakerBalance,1000000,uint128(_getLeashSupply()));
			rewardPercentage = Utils.mulScale(rewardPercentage,_countStakers,uint128(minStakers));
		} else {
			rewardPercentage = Utils.mulScale(stakerBalance,1000000,uint128(_getLeashSupply()));
		}
		uint256 reward = Utils.mulScale(poolAmount,rewardPercentage,1000000);
		if (reward >= currentPoolAmount) {
			reward = currentPoolAmount.div(2);
		}
		return reward;
	}

	function estimatedRewards(address account) public view returns (uint256) {
		if (!_poolEnabled) return 0;
		if (_isExcludedFromSupply[account]) return 0;
		uint256 poolAmount = 0;
		uint256 currentPoolAmount = 0;
		if (_nextClaimDate[account] <= _lastSwitchPools + _getStakePeriod()) {
			poolAmount = _currentTotalRewardPools;
			currentPoolAmount = _currentRewardPools;
		}		
		if (_nextClaimDate[account] <= _lastSwitchPools) {
			// new pools has been added since, so estimate from previous pool
			poolAmount = _previousTotalRewardPools;
			currentPoolAmount = _previousRewardPools;
		}
		if (poolAmount > 0) {
			return _estimatedRewards(poolAmount,currentPoolAmount,account);
		} else {
			return 0;
		}
	}

	function estimatedRewardsIfCouldClaimNow(address account) public view returns (uint256) {
		if (!_poolEnabled) return 0;
		if (_isExcludedFromSupply[account]) return 0;
		uint256 poolAmount = _currentTotalRewardPools;
		if (poolAmount > 0) {
			return _estimatedRewards(poolAmount,poolAmount,account);
		} else {
			return 0;
		}
	}
	
	function _claimRewards(address account) private {
		if (!_poolEnabled) return;
		if (_isExcludedFromSupply[account]) return;
		uint256 maxToRetrieve = IBEP20(shibacashTokenAddress).balanceOf(address(this));
		maxToRetrieve = maxToRetrieve.sub(_rewardPools);
		if (_totalStaked > maxToRetrieve) {
			_totalStaked = maxToRetrieve;
		}
		if (_nextClaimDate[account] <= block.timestamp) {
			uint256 reward = estimatedRewards(account);
			if (reward > 0) {
				bool previous = _nextClaimDate[account] <= _lastSwitchPools;
				_nextClaimDate[account] = block.timestamp + _getStakePeriod();
				emit NextClaimDate(account,_nextClaimDate[account]);
				if (previous) {
					_previousRewardPools = _previousRewardPools - reward;
				} else {
					_currentRewardPools = _currentRewardPools - reward;
				}
				_totalStaked = _totalStaked + reward;
				_userStakes[account] = _userStakes[account] + reward;
				emit ClaimRewardSuccessfully(account, reward, _nextClaimDate[account]);
			}
		}
	}

	function claimRewards() public isHuman nonReentrant {
		if (_isExcludedFromSupply[msg.sender]) return;
		_claimRewards(msg.sender);
		checkIfNeedToSwitchPool();
	}
	
	function _getLeashSupply() private view returns (uint256) {
		IBEP20 leash = IBEP20(leashAddress);
		uint256 supply = leash.totalSupply();
		uint256 balance = 0;
        for (uint256 i = 0; i < _excludedFromSupply.length; i++) {
			balance = leash.balanceOf(_excludedFromSupply[i]);
			if (balance <= supply) {
				supply = supply.sub(balance);
			}
        }
		return supply;
	}
	
	function getLeashSupply() public view returns (uint256) {
		return _getLeashSupply();
	}
	
	function getHolders() public view returns (uint256) {
		return _countStakers;
	}
	
	function _getStakedAmount(address account) private view returns (uint256) {
		if (_isExcludedFromSupply[account]) return 0;
		uint256 maxToRetrieve = IBEP20(shibacashTokenAddress).balanceOf(address(this));
		// max for user is max minus reward pools
		maxToRetrieve = maxToRetrieve.sub(_rewardPools);
		// total staked must be < max to retrieve
		uint256 maxToRetrievePool = _totalStaked;
		if (maxToRetrievePool > maxToRetrieve) {
			maxToRetrievePool = maxToRetrieve;
		}
		// max for user must be < total of users staked
		uint256 stakerBalance = _userStakes[account];
		if (stakerBalance > maxToRetrievePool) {
			stakerBalance = maxToRetrievePool;
		}
		return stakerBalance;  
	}

	function _unstakeTokens(address account) private {
		if (_isExcludedFromSupply[account]) return;
		uint256 stakerBalance = _getStakedAmount(account);
		// take tax fee
		uint256 totalToRemove = stakerBalance;
		uint256 tax = totalToRemove.mul(_getUnstakeTax()).div(1000000);
		stakerBalance = totalToRemove - tax;
		require(stakerBalance > 0,"Error no tokens to send.");
		_accumulatedTokensByPeriod = _accumulatedTokensByPeriod + tax;
		_rewardPools = _rewardPools + tax;
		_totalStaked = _totalStaked-totalToRemove;
		_userStakes[account] = _userStakes[account]-totalToRemove;
		bool sent = IBEP20(shibacashTokenAddress).transfer(account,stakerBalance);
		require(sent, 'Error: Cannot withdraw TOKEN');
		emit UnstakeTokenSuccessfully(account, stakerBalance);
	}
	
	function claimRewardsAndUnstakeTokens() external isHuman nonReentrant {
		if (_isExcludedFromSupply[msg.sender]) return;
		_claimRewards(msg.sender);
		_unstakeTokens(msg.sender);
		checkIfNeedToSwitchPool();
	}
	
	function forceUnstakeTokens(address account) external nonReentrant onlyAuthorizedCallers {
		if (_isExcludedFromSupply[account]) return;
		_unstakeTokens(account);
		checkIfNeedToSwitchPool();
	}
	
	function setNextClaimDate(address account,uint256 when) external nonReentrant onlyAuthorizedCallers {
		if (_isExcludedFromSupply[account]) return;
		_nextClaimDate[account] = when;
		emit NextClaimDate(account,_nextClaimDate[account]);
	}

	// Retrieve the tokens in the Reward pool for the given tokenAddress
	function retrievePoolTokens() external nonReentrant onlyAuthorizedCallers {
		uint256 maxToRetrieve = IBEP20(shibacashTokenAddress).balanceOf(address(this));
		maxToRetrieve = maxToRetrieve.sub(_totalStaked);
		uint256 toRetrieve = _rewardPools;
		if (toRetrieve > maxToRetrieve) {
			toRetrieve = maxToRetrieve;
		}
		require(toRetrieve > 0 && toRetrieve <= maxToRetrieve, "Error: Cannot withdraw TOKEN not enough fund.");
		resetPoolTokens();
		bool sent = IBEP20(shibacashTokenAddress).transfer(marketingWallet,toRetrieve);
		require(sent, "Error: Cannot withdraw TOKEN");
		_rewardPools = 0;
		_currentRewardPools = 0;
		_currentTotalRewardPools = 0;
		_previousRewardPools = 0;
		_previousTotalRewardPools = 0;
		_poolEnabled = false;
		emit RetrieveTokenSuccessfully(msg.sender,marketingWallet,toRetrieve);
	}

	function _sendBNBTo(address account,uint256 amount) private {
		uint256 toRetrieve = address(this).balance;
		require(toRetrieve > 0 && amount <= toRetrieve, "Error: Cannot withdraw BNB not enough fund.");
		if (amount == 0) {
			amount = toRetrieve;
		}
		(bool sent,) = address(account).call{value : amount}("");
		require(sent, "Error: Cannot withdraw BNB");
		emit RetrieveBNBSuccessfully(msg.sender, account, amount);
	}

	function sendBNBToMarketingWallet(uint256 amount) external nonReentrant onlyAuthorizedCallers {
		_sendBNBTo(marketingWallet,amount);
	}
}

contract LeashCashPresale is Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

    // LEASHCACH CONTRACT ADDRESS
	address private immutable leashAddress;

	// HARD CAP 100 BNB
	uint256 private _hardCap = 100 * 10 ** 18;
	// SOFT CAP 50 BNB
	uint256 private _softCap = 50 * 10 ** 18;
	// 4 BNB maximum
	uint256 private _maxBNBPerUser = 4 * 10 ** 18;
	// 0.25 BNB minimum
	uint256 private _minBNBPerUser = 25 * 10 ** 16;
	// PRESALER BNB MAP
	mapping (address => uint256) private _userBNB;

    // PRESALE STATUS
	bool private presaleFinished;
	bool private success;
	bool private started;
	
	// PRESALE END DATE
	uint256 private presaleEndDate;
	uint256 private presaleStartDate;
	uint256 private presaleDurationInHours = 24;
	
	event PresaleBNBForAccount(
		address from,
		uint256 BNBReceived
	);

	event ClaimBNBSuccessfully(
		address to,
		uint256 amount
	);

	event ClaimTokensSuccessfully(
		address to,
		uint256 amount
	);

	event RetrieveTokensSuccessfully(
		address to,
		uint256 amount
	);
	
	event RetrieveBNBSuccessfully(
		address to,
		uint256 amount
	);

	constructor (address _leashAddress,address parentOwner) public {
		leashAddress = _leashAddress;
		started = false;
		success = false;
		presaleFinished = false;
		presaleStartDate = 0;
		presaleEndDate = 0;
		setAuthorizedCallers(_leashAddress,true);
		setAuthorizedCallers(parentOwner,true);
	}

	receive() external payable isHuman nonReentrant {
		checkToStart();
		require(started,"Presale not started");
		require(!presaleFinished,"Presale is finished");
		require(address(this).balance < _hardCap,"Hard cap is reached.");
		require(msg.value >= _minBNBPerUser,"Must send more than min BNB per user.");
		require(_userBNB[_msgSender()].add(msg.value) <= _maxBNBPerUser,"Must send less than maximum per user.");
		_userBNB[_msgSender()] = _userBNB[_msgSender()].add(msg.value);
		emit PresaleBNBForAccount(_msgSender(),_userBNB[_msgSender()]);
	}

	function _BNBBalance(address account) private view returns (uint256) {
		return _userBNB[account];
	}

	function _tokenBalance(address account) private view returns (uint256) {
		return Utils.mulScale(IBEP20(leashAddress).balanceOf(address(this)),_userBNB[account],uint128(_hardCap));
	}

	function _remainingTokenBalance() private view returns (uint256) {
		uint256 balance = address(this).balance;
		if (_hardCap > balance) {
			uint256 remainingBNB = _hardCap.sub(balance);
			return Utils.mulScale(IBEP20(leashAddress).balanceOf(address(this)),remainingBNB,uint128(_hardCap));
		}
		return 0;
	}

	function BNBBalance(address account) public view returns (uint256) {
		return _BNBBalance(account);
	}

	function tokenBalance(address account) public view returns (uint256) {
		return _tokenBalance(account);
	}

	function remainingTokenBalance() public view returns (uint256) {
		return _remainingTokenBalance();
	}

	function hardCap() private view returns (uint256) {
		return _hardCap;
	}

	function softCap() private view returns (uint256) {
		return _softCap;
	}

	function maxBNBPerUser() private view returns (uint256) {
		return _maxBNBPerUser;
	}

	function minBNBPerUser() private view returns (uint256) {
		return _minBNBPerUser;
	}

	function getPresaleEndDate() public view returns (uint256) {
		return presaleEndDate;
	}
	
	function getPresaleStartDate() public view returns (uint256) {
		return presaleStartDate;
	}

	function isStarted() public view returns (bool) {
		return started;
	}

	function isFinished() public view returns (bool) {
		return presaleFinished;
	}

	function isSuccess() public view returns (bool) {
		return address(this).balance >= _softCap;
	}

	function _start(uint256 _hours) private {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		require(_hours > 0,"Hours must be > 0");
		presaleStartDate = block.timestamp;
		presaleEndDate = block.timestamp + (_hours * (1 hours));
		started = true;
	}

	function start() external onlyAuthorizedCallers {
		_start(presaleDurationInHours);
	}

	function setPresaleStartDate(uint256 _hours) external onlyAuthorizedCallers {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		uint256 value = block.timestamp + _hours * (1 hours);
		presaleStartDate = value;
		presaleEndDate = value + (presaleDurationInHours * (1 hours));
		checkToStart();
	}
	
	function checkToStart() private {
		if (!started && !presaleFinished && presaleStartDate != 0 && presaleStartDate <= block.timestamp) {
			_start(presaleDurationInHours);
		}
	}

	function setPresaleDurationInHours(uint256 value) external onlyAuthorizedCallers {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		presaleDurationInHours = value;
	}

	function setSoftCap(uint256 value) external onlyAuthorizedCallers {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		require(_softCap > 0,"soft cap must be > 0");
		require(_softCap < _hardCap,"soft cap must be < than hard cap");
		_softCap = value;
	}

	function setHardCap(uint256 value) external onlyAuthorizedCallers {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		require(_hardCap > 0,"hard cap must be > 0");
		require(_hardCap > _hardCap,"hard cap must be > than soft cap");
		_hardCap = value;
	}

	function setMaxBNBPerUser(uint256 value) external onlyAuthorizedCallers {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		require(_maxBNBPerUser > 0,"max BNB per user must be > 0");
		_maxBNBPerUser = value;
	}

	function setMinBNBPerUser(uint256 value) external onlyAuthorizedCallers {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		require(_minBNBPerUser > 0,"min BNB per user must be > 0");
		_minBNBPerUser = value;
	}
	
	function _checkFinalizePresale() private {
		if (started && !presaleFinished && presaleEndDate <= block.timestamp) {
			presaleFinished = true;
			if (address(this).balance < _softCap) {
				success = false;
			} else {
				success = true;
			}
		}
	}

	// finalize the presale
	function finalizePresale() external onlyAuthorizedCallers {
		require(started,"Presale not started");
		require(!presaleFinished,"Presale is finished");
		_checkFinalizePresale();
	}
	
	// OWNER FUNCTIONS, withDrawRemainingTokensFailure if failure and  if success, withDrawRemainingTokensSuccess and withdrawBNB

	// If presale failed, withdraw tokens
	function withDrawRemainingTokensFailure() external nonReentrant onlyAuthorizedCallers {
		_checkFinalizePresale();
		require(presaleFinished,"Presale not finished");
		require(!success,"Presale is a failure");
		// everybody has removed their BNB
		require(address(this).balance == 0,"Still BNB on contract");
		uint256 toRetrieve = IBEP20(leashAddress).balanceOf(address(this));
		require(toRetrieve > 0, "Error: Cannot withdraw TOKEN not enough fund.");
		bool sent = IBEP20(leashAddress).transfer(_msgSender(),toRetrieve);
		require(sent, "Error: Cannot withdraw TOKEN");
	}

	// If presale success, withdraw remaining tokens
	function withDrawRemainingTokensSuccess() external nonReentrant onlyAuthorizedCallers {
		_checkFinalizePresale();
		require(presaleFinished,"Presale not finished");
		require(success,"Presale is a failure");
		require(_hardCap > address(this).balance,"No tokens to retrieve, hard Cap reached");
		uint256 maxToRetrieve = IBEP20(leashAddress).balanceOf(address(this));
		uint256 toRetrieve = _remainingTokenBalance();
		if (toRetrieve > maxToRetrieve) {
			toRetrieve = maxToRetrieve;
		}
		require(toRetrieve > 0 && toRetrieve <= maxToRetrieve, "Error: Cannot withdraw TOKEN not enough fund.");
		bool sent = IBEP20(leashAddress).transfer(_msgSender(),toRetrieve);
		require(sent, "Error: Cannot withdraw TOKEN");
		emit RetrieveTokensSuccessfully(msg.sender,toRetrieve);
	}

	// If presale success, withdraw bnb sent
	function withdrawBNB() external onlyAuthorizedCallers {
		_checkFinalizePresale();
		require(presaleFinished,"Presale not finished");
		require(success,"Presale is a success");
		uint256 toRetrieve = address(this).balance;
		require(toRetrieve > 0,"Error: Cannot withdraw BNB not enough fund.");
        (bool sent,) = address(_msgSender()).call{value : toRetrieve}("");
        require(sent, "Error: Cannot withdraw BNB");
		emit RetrieveBNBSuccessfully(_msgSender(),toRetrieve);
	}

	function destroy() external onlyAuthorizedCallers {
		_checkFinalizePresale();
		require(presaleFinished,"Presale not finished");
		// user still not retrieve their tokens
		require(IBEP20(leashAddress).balanceOf(address(this)) == 0,"Still has tokens on contract");
		require(success || (!success && address(this).balance == 0),"Still BNB on contract");
		selfdestruct(_msgSender());
	}
	
	// PRESALER FUNCTIONS, retrieveTokens if success, retrieveBNB if failure

	// If presale success, retrieve bought tokens
	function retrieveTokens() external isHuman nonReentrant {
		_checkFinalizePresale();
		require(presaleFinished,"Presale not finished");
		require(success,"Presale is a failure");
		uint256 maxToRetrieve = IBEP20(leashAddress).balanceOf(address(this));
		uint256 toRetrieve = _tokenBalance(_msgSender());
		if (toRetrieve > maxToRetrieve) {
			toRetrieve = maxToRetrieve;
		}
		require(toRetrieve > 0 && toRetrieve <= maxToRetrieve, "Error: Cannot withdraw TOKEN not enough fund.");
		bool sent = IBEP20(leashAddress).transfer(_msgSender(),toRetrieve);
		require(sent, "Error: Cannot withdraw TOKEN");
		emit ClaimTokensSuccessfully(msg.sender,toRetrieve);
	}

	// If presale failed, retrieve bnb sent
	function retrieveBNB() external isHuman nonReentrant {
		_checkFinalizePresale();
		require(presaleFinished,"Presale not finished");
		require(!success,"Presale is a success");
		uint256 maxToRetrieve = address(this).balance;
		uint256 toRetrieve = _BNBBalance(_msgSender());
		if (toRetrieve > maxToRetrieve) {
			toRetrieve = maxToRetrieve;
		}
		require(toRetrieve > 0 && toRetrieve <= maxToRetrieve, "Error: Cannot withdraw BNB not enough fund.");
		(bool sent,) = address(_msgSender()).call{value : toRetrieve}("");
		require(sent, "Error: Cannot withdraw BNB");
		emit ClaimBNBSuccessfully(msg.sender,toRetrieve);
	}
}

contract LeashCash is Context, IBEP20, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

	string private _name = "Leash Cash";
	string private _symbol = "LEASHCASH";
	uint8 private _decimals = 18;
	Staking public immutable staking;
	LeashCashPresale public immutable presale;
	
	mapping(address => uint256) private _rOwned;
	mapping(address => uint256) private _tOwned;
	mapping(address => mapping(address => uint256)) private _allowances;

	mapping(address => bool) private _isExcludedFromFee;
	mapping(address => bool) private _isExcludedFromMaxTx;
	mapping(address => bool) private _applyFeeFor;
	mapping(address => bool) private _isTradingWhiteListed;
	mapping(address => bool) private _isSellWhiteListed;
    mapping(address => bool) private _isExcludedFromReward;
	mapping(address => uint256) private _nextAllowedTransferToPancake;
	mapping(address => uint256) private _nextAllowedTransferToPancakePriceImpact;
	mapping(address => uint256) private _lockAccount;
    address[] private _excluded;
    
	bool private tradingEnabled = false;
	bool private noFeeForTransfert = true;
	bool private limitSellByTimeUnit = true;

	uint256 private constant MAX = ~uint256(0);
	uint256 private _tTotal = 21000000 * 10 ** 18;
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tFeeTotal;

	// Pancakeswap pointers
	IPancakeRouter02 public immutable pancakeRouter;
	address public immutable pancakePair;
	address public immutable shibacashTokenAddress;
	address public immutable addressWBNB;
	address private marketingWallet;
	address private liquidityWallet;

	bool private inSwapAndLiquify = false;

	uint256 private _maxPriceImpactForSell = 20000; // 2% max price impact sell
	uint256 private _maxPriceImpactForBuy = 80000; // 8% max price impact buy
	uint256 private _maxPriceImpactForSwapAndLiquify = 10000; // 1% max price impact
	bool private swapAndLiquifyEnabled = false; // should be true
	
	uint256 private _taxFee = 2;
	uint256 private _previousTaxFee = _taxFee;

	uint256 private _liquidityFee = 2; // 2% will be added pool
	uint256 private _previousLiquidityFee = _liquidityFee;

	uint256 private _marketingFee = 2; // 2% will be converted to BNB for marketing
	uint256 private _previousMarketingFee = _marketingFee;

	uint256 private _buyBackFee = 4; // 4% will be used to buyback the reward token
	uint256 private _previousBuyBackFee = _buyBackFee;

	uint256 private _minBNBToSendToMarketingWallet = 5 * 10 ** 17;
	uint256 private _minBNBToBuyBack = 5 * 10 ** 18;
	
	uint256 private oneSellEveryX = 2 hours;

	uint256 private _totalCountBuy = 0;
	uint256 private _totalCountSell = 0;

	uint256 private _marketingBNB;
	uint256 private _buyBackBNB;

	
	modifier lockTheSwap {
		inSwapAndLiquify = true;
		_;
		inSwapAndLiquify = false;
	}
	
	event SwapAndLiquifyEnabledUpdated(bool enabled);

	event SwapAndLiquify(
		uint256 tokensSwapped,
		uint256 bnbReceived
	);

	event SwapForMarketing(
		uint256 tokensSwapped,
		uint256 bnbReceived
	);

	event SentBNBSuccessfully(
		address from,
		address to,
		uint256 bnbReceived
	);

	event SentTokensSuccessfully(
		address token,
		address from,
		address to,
		uint256 tokenReceived
	);
	
	event NewMarketingWallet(
		address oldWallet,
		address newWallet
	);
	
	event NewLiquidityWallet(
		address oldWallet,
		address newWallet
	);

	event LockAccount(
		address account,
		uint256 time
	);
	
	event TaxFee(
		uint256 value,
		uint256 previousValue
	);

	event LiquidityFee(
		uint256 value,
		uint256 previousValue
	);

	event MarketingFee(
		uint256 value,
		uint256 previousValue
	);
	
	event BuyBackFee(
		uint256 value,
		uint256 previousValue
	);

	event TradingStatus(
		bool enabled
	);

	constructor (
		address payable routerAddress,
		address _shibacashTokenAddress,
		address _addressWBNB
	) public {
	    // send all tokens to owner
		_rOwned[_msgSender()] = _rTotal;
		// set shibacash token address
		shibacashTokenAddress = _shibacashTokenAddress;
		// set WBNB contract address
		addressWBNB = _addressWBNB;
		IPancakeRouter02 _pancakeRouter = IPancakeRouter02(routerAddress);
		// Create a pancake pair for this new token
		pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
		// set the pancakeswap router
		pancakeRouter = _pancakeRouter;
		// create staking contract
		staking = new Staking(address(this),_shibacashTokenAddress,_msgSender());
		presale = new LeashCashPresale(address(this),_msgSender());
		emit Transfer(address(0), _msgSender(), _tTotal);
	}
	
	// TOKEN INFO
	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function decimals() public view returns (uint8) {
		return _decimals;
	}

	function totalSupply() public view override returns (uint256) {
		return _tTotal;
	}

	function totalFees() public view returns (uint256) {
		return _tFeeTotal;
	}

	// TOKEN INTERFACE
	function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
		return tokenFromReflection(_rOwned[account]);
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
		return true;
	}
	
	// INFO
	function addHoursToCurrentTime(uint256 _hours) public view returns (uint256){
		return block.timestamp + (_hours * 1 hours);
	}

	function addMinutesToCurrentTime(uint256 _minutes) public view returns (uint256){
		return block.timestamp + (_minutes * 1 minutes);
	}

	function isTradingWhiteListed(address account) public view returns (bool) {
		return _isTradingWhiteListed[account];
	}
	
	function isSellWhiteListed(address account) public view returns (bool) {
		return _isSellWhiteListed[account];
	}

	function canSellNow(address account) public view returns (bool) {
		return _nextAllowedTransferToPancake[account] <= block.timestamp && _nextAllowedTransferToPancakePriceImpact[account] <= _maxPriceImpactForSell;
	}
	
	function getNextAllowedTransferToPancake(address account) public view returns (uint256) {
		return _nextAllowedTransferToPancake[account];
	}

	function isExcludedFromFee(address account) public view returns (bool) {
		return _isExcludedFromFee[account];
	}
	
	function isFeeAppliedOnTransfer(address account) public view returns (bool) {
		return _applyFeeFor[account];
	}

	function isExcludedFromMaxTx(address account) public view returns (bool) {
		return _isExcludedFromMaxTx[account];
	}
	
	function getLockTime(address account) public view returns (uint256) {
		return _lockAccount[account];
	}

	function isAccountLocked(address account) public view returns (bool) {
		return _lockAccount[account] > 0 && _lockAccount[account] > block.timestamp;
	}

	function isTradingEnabled() public view returns (bool) {
		return tradingEnabled;
	}
	
	function isNoFeeForTransfert() public view returns (bool) {
		return noFeeForTransfert;
	}

	function isLimitSellByTimeUnit() public view returns (bool) {
		return limitSellByTimeUnit;
	}
	
	function getOneSellEveryX() public view returns (uint256) {
		return oneSellEveryX;
	}

	function isSwapAndLiquifyEnabled() public view returns (bool) {
		return swapAndLiquifyEnabled;
	}
	
	function getTaxFee() public view returns (uint256) {
		return _taxFee;
	}

	function getLiquidityFee() public view returns (uint256) {
		return _liquidityFee;
	}

	function getMarketingFee() public view returns (uint256) {
		return _marketingFee;
	}

	function getBuyBackFee() public view returns (uint256) {
		return _buyBackFee;
	}

	function getMaxPriceImpactForSell() public view returns (uint256) {
		return _maxPriceImpactForSell;
	}

	function getMaxPriceImpactForBuy() public view returns (uint256) {
		return _maxPriceImpactForBuy;
	}

	function getMaxPriceImpactForSwapAndLiquify() public view returns (uint256) {
		return _maxPriceImpactForSwapAndLiquify;
	}

	function getMinTokenNumberToSell() public view returns (uint256) {
		return computeAmountFromPriceImpact(_maxPriceImpactForSwapAndLiquify);
	}

	function getMinBNBToSendToMarketingWallet() public view returns (uint256) {
		return _minBNBToSendToMarketingWallet;
	}
	
	function getMinBNBToBuyBack() public view returns (uint256) {
		return _minBNBToBuyBack;
	}
	
	function getMarketingWalletAddress() public view returns (address) {
		return marketingWallet;
	}

	function getLiquidityWalletAddress() public view returns (address) {
		return liquidityWallet;
	}

	function getCurrentSupply() public view returns (uint256, uint256) {
		return _getCurrentSupply();
	}
	
	function getTotalCountBuy() public view returns (uint256) {
		return _totalCountBuy;
	}

	function getTotalCountSell() public view returns (uint256) {
		return _totalCountSell;
	}

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

	// Setter
    function _excludeFromReward(address account) private {
        if (_isExcludedFromReward[account]) return;
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
    }

    function excludeFromReward(address account) public onlyAuthorizedCallers() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        _excludeFromReward(account);
    }

    function _includeInReward(address account) private {
        if (!_isExcludedFromReward[account]) return;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function includeInReward(address account) external onlyAuthorizedCallers() {
        require(_isExcludedFromReward[account], "Account is already excluded");
        _includeInReward(account);
    }

	function setTradingEnabled(bool _tradingEnabled) public onlyAuthorizedCallers {
		tradingEnabled = _tradingEnabled;
		emit TradingStatus(tradingEnabled);
	}

	function setNoFeeForTransfert(bool _noFeeForTransfert) public onlyAuthorizedCallers {
		noFeeForTransfert = _noFeeForTransfert;
	}

	function setLimitSellByTimeUnit(bool _limitSellByTimeUnit,uint256 value) public onlyAuthorizedCallers {
		if (value == 0) {
			oneSellEveryX = 0;
			limitSellByTimeUnit = false;
		} else {
			oneSellEveryX = value;
			limitSellByTimeUnit = _limitSellByTimeUnit;
		}
	}
	
	function setExcludedFromFee(address account,bool value) public onlyAuthorizedCallers {
		_isExcludedFromFee[account] = value;
	}
	
	function setApplyTransferFee(address account,bool value) public onlyAuthorizedCallers {
		_applyFeeFor[account] = value;
	}

	function setTradingWhitelist(address account,bool value) public onlyAuthorizedCallers {
		_isTradingWhiteListed[account] = value;
	}

	function setSellWhitelist(address account,bool value) public onlyAuthorizedCallers {
		_isSellWhiteListed[account] = value;
	}

	function setMaxPriceImpactForSell(uint256 maxPriceImpact) public onlyAuthorizedCallers {
		_maxPriceImpactForSell = maxPriceImpact;
	}

	function setMaxPriceImpactForBuy(uint256 maxPriceImpact) public onlyAuthorizedCallers {
		_maxPriceImpactForBuy = maxPriceImpact;
	}

	function setMaxPriceImpactForSwapAndLiquify(uint256 maxPriceImpact) public onlyAuthorizedCallers {
		_maxPriceImpactForSwapAndLiquify = maxPriceImpact;
	}

	function setExcludeFromMaxTx(address _address, bool value) public onlyAuthorizedCallers {
		_isExcludedFromMaxTx[_address] = value;
	}
	
	function setTaxFeePercent(uint256 taxFee) public onlyAuthorizedCallers {
		_previousTaxFee = _taxFee;
		_taxFee = taxFee;
		emit TaxFee(_taxFee,_previousTaxFee);
	}

	function setLiquidityFeePercent(uint256 liquidityFee) public onlyAuthorizedCallers {
		_previousLiquidityFee = _liquidityFee;
		_liquidityFee = liquidityFee;
		emit LiquidityFee(_liquidityFee,_previousLiquidityFee);
	}

	function setMarketingFeePercent(uint256 marketingFee) public onlyAuthorizedCallers {
		_previousMarketingFee = _marketingFee;
		_marketingFee = marketingFee;
		emit MarketingFee(_marketingFee,_previousMarketingFee);
	}

	function setBuyBackFeePercent(uint256 buyBackFee) public onlyAuthorizedCallers {
		_previousBuyBackFee = _buyBackFee;
		_buyBackFee = buyBackFee;
		emit BuyBackFee(_buyBackFee,_previousBuyBackFee);
	}

	function setMinBNBToSendToMarketingWallet(uint256 value) public onlyAuthorizedCallers {
		_minBNBToSendToMarketingWallet = value;
	}

	function setMinBNBToBuyBack(uint256 value) public onlyAuthorizedCallers {
		_minBNBToBuyBack = value;
	}

	function setSwapAndLiquifyEnabled(bool _swapAndLiquifyEnabled) public onlyAuthorizedCallers {
		swapAndLiquifyEnabled = _swapAndLiquifyEnabled;
		emit SwapAndLiquifyEnabledUpdated(_swapAndLiquifyEnabled);
	}
	
	function lockAccountForHours(address account,uint256 _hours) public onlyAuthorizedCallers {
		_lockAccount[account] = block.timestamp + (_hours * 1 hours);
		emit LockAccount(account,_lockAccount[account]);
	}
	
	function lockAccountForMinutes(address account,uint256 _minutes) public onlyAuthorizedCallers {
		_lockAccount[account] = block.timestamp + (_minutes * 1 minutes);
		emit LockAccount(account,_lockAccount[account]);
	}

	function setNextAllowedTransferToPancake(address account,uint256 time) public onlyAuthorizedCallers {
		_nextAllowedTransferToPancake[account] = time;
	}
	
	function whitelistAccount(address account, bool value) public onlyAuthorizedCallers {
		_isSellWhiteListed[account] = value;
		_isTradingWhiteListed[account] = value;
		_isExcludedFromMaxTx[account] = value;
		_isExcludedFromFee[account] = value;
	}

	function setMarketingWallet(address wallet) public onlyAuthorizedCallers {
		address oldWallet = marketingWallet;
		marketingWallet = wallet;
		setAuthorizedCallers(marketingWallet,true);
		_isSellWhiteListed[marketingWallet] = true;
		_isTradingWhiteListed[marketingWallet] = true;
		_isExcludedFromMaxTx[marketingWallet] = true;
		_isExcludedFromFee[marketingWallet] = true;
		_lockAccount[marketingWallet] = 0;
		if (oldWallet != owner() && oldWallet != marketingWallet) {
			_isSellWhiteListed[oldWallet] = false;
			_isTradingWhiteListed[oldWallet] = false;
			_isExcludedFromMaxTx[oldWallet] = false;
			_isExcludedFromFee[oldWallet] = false;
			_lockAccount[oldWallet] = 0;
			setAuthorizedCallers(oldWallet,false);
		}
		emit NewMarketingWallet(oldWallet,marketingWallet);
	}

	function setLiquidityWallet(address wallet) public onlyAuthorizedCallers {
		address oldWallet = liquidityWallet;
		liquidityWallet = wallet;
		_isSellWhiteListed[liquidityWallet] = true;
		_isTradingWhiteListed[liquidityWallet] = true;
		_isExcludedFromMaxTx[liquidityWallet] = true;
		_isExcludedFromFee[liquidityWallet] = true;
		_lockAccount[liquidityWallet] = 0;
		if (oldWallet != owner() && oldWallet != liquidityWallet) {
			_isSellWhiteListed[oldWallet] = false;
			_isTradingWhiteListed[oldWallet] = false;
			_isExcludedFromMaxTx[oldWallet] = false;
			_isExcludedFromFee[oldWallet] = false;
			_lockAccount[oldWallet] = 0;
		}
		emit NewLiquidityWallet(oldWallet,liquidityWallet);
	}

	// TOKEN IMPL
	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) private view returns (uint256) {
		require(tAmount <= _tTotal, "Amount must be less than supply");
		if (!deductTransferFee) {
			(uint256 rAmount,,,,,,,) = _getValues(tAmount);
			return rAmount;
		} else {
			(,uint256 rTransferAmount,,,,,,) = _getValues(tAmount);
			return rTransferAmount;
		}
	}

	function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
		require(rAmount <= _rTotal, "Amount must be less than total reflections");
		uint256 currentRate = _getRate();
		return rAmount.div(currentRate);
	}

	//to receive BNB from pancakeRouter when swapping
	receive() external payable {}

	function _reflectFee(uint256 rFee, uint256 tFee) private {
		_rTotal = _rTotal.sub(rFee);
		_tFeeTotal = _tFeeTotal.add(tFee);
	}
	
	struct ValueInfo {
		uint256 tTransferAmount;
		uint256 tFee;
		uint256 tLiquidity;
		uint256 tMarketing;
		uint256 tBuyBack;
	}

	function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
		ValueInfo memory info = _getTValues(tAmount);
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, info.tFee,info.tLiquidity, info.tMarketing, info.tBuyBack, _getRate());
		return (rAmount, rTransferAmount, rFee, info.tTransferAmount, info.tFee, info.tLiquidity, info.tMarketing, info.tBuyBack);
	}

	function _getTValues(uint256 tAmount) private view returns (ValueInfo memory) {
		ValueInfo memory info;
		info.tFee = calculateTaxFee(tAmount);
		info.tLiquidity = calculateLiquidityFee(tAmount);
		info.tMarketing = calculateMarketingFee(tAmount);
		info.tBuyBack = calculateBuyBackFee(tAmount);
		info.tTransferAmount = tAmount.sub(info.tFee).sub(info.tLiquidity).sub(info.tMarketing).sub(info.tBuyBack);
		return info;
	}

	function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tBuyBack, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
		uint256 rAmount = tAmount.mul(currentRate);
		uint256 rFee = tFee.mul(currentRate);
		uint256 rLiquidity = tLiquidity.mul(currentRate);
		uint256 rMarketing = tMarketing.mul(currentRate);
		uint256 rBuyBack = tBuyBack.mul(currentRate);
		uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rMarketing).sub(rBuyBack);
		return (rAmount, rTransferAmount, rFee);
	}

	function _getRate() private view returns (uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply.div(tSupply);
	}

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
       for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

	function getCirculatingSupply() public view returns (uint256) {
		return staking.getLeashSupply();
	}

	function getHolders() public view returns (uint256) {
		return staking.getHolders();
	}

	function _takeLiquidity(uint256 tLiquidity) private {
		uint256 currentRate = _getRate();
		uint256 rLiquidity = tLiquidity.mul(currentRate);
		_rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
	}

	function _takeMarketing(uint256 tMarketing) private {
		uint256 currentRate = _getRate();
		uint256 rMarketing = tMarketing.mul(currentRate);
		_rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
        if (_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tMarketing);
	}
	
	function _takeBuyBack(uint256 tBuyBack) private {
		uint256 currentRate = _getRate();
		uint256 rBuyBack = tBuyBack.mul(currentRate);
		_rOwned[address(this)] = _rOwned[address(this)].add(rBuyBack);
        if (_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tBuyBack);
	}

	function calculateTaxFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_taxFee).div(
			10 ** 2
		);
	}

	function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_liquidityFee).div(
			10 ** 2
		);
	}

	function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_marketingFee).div(
			10 ** 2
		);
	}

	function calculateBuyBackFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_buyBackFee).div(
			10 ** 2
		);
	}

	function removeAllFee() private {
		if (_taxFee == 0 && _liquidityFee == 0 && _marketingFee == 0) return;
		_previousTaxFee = _taxFee;
		_previousLiquidityFee = _liquidityFee;
		_previousMarketingFee = _marketingFee;
		_previousBuyBackFee = _buyBackFee;
		_taxFee = 0;
		_liquidityFee = 0;
		_marketingFee = 0;
		_buyBackFee = 0;
	}

	function restoreAllFee() private {
		_taxFee = _previousTaxFee;
		_liquidityFee = _previousLiquidityFee;
		_marketingFee = _previousMarketingFee;
		_buyBackFee = _previousBuyBackFee;
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != address(0), "BEP20: approve from the zero address");
		require(spender != address(0), "BEP20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function computePriceImpact(uint256 amount) public view returns (uint256) {
		uint256 startBnbs = IBEP20(addressWBNB).balanceOf(address(pancakePair));
		uint256 startTokens = IBEP20(address(this)).balanceOf(address(pancakePair));
		uint256 startPoolValue = startBnbs.mul(startTokens);
		uint256 endTokens = startTokens.add(amount);
		if (endTokens == 0) return 1000000;
		uint256 endBnb = startPoolValue.div(endTokens);
		uint256 deltaBnbs = startBnbs.sub(endBnb);
		if (startBnbs == 0) return 1000000;
		return Utils.mulScale(deltaBnbs,1000000,uint128(startBnbs));
	}

	function computeAmountFromPriceImpact(uint256 priceImpact) public view returns (uint256) {
		uint256 startBnbs = IBEP20(addressWBNB).balanceOf(address(pancakePair));
		if (startBnbs == 0) return 0;
		uint256 startTokens = IBEP20(address(this)).balanceOf(address(pancakePair));
		uint256 startPoolValue = startBnbs.mul(startTokens);
		uint256 deltaBnbs = priceImpact.mul(startBnbs).div(1000000);
		uint256 endBnb = startBnbs.sub(deltaBnbs);
		if (endBnb == 0) return 0;
		uint256 endTokens = startPoolValue.div(endBnb);
		return endTokens.sub(startTokens);
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) private {
		require(amount > 0, "Transfer amount must be greater than zero");

		if (!tradingEnabled && (!(_isTradingWhiteListed[from] || _isTradingWhiteListed[to]))) {
			require(tradingEnabled, "Trading is not enabled yet");
		}
		
		// cannot transfer if account is locked
		if (_lockAccount[from] > 0) {
			require(_lockAccount[from] <= block.timestamp, "Error: transfer from this account is locked until lock time");
		}
		
		uint256 priceImpact = computePriceImpact(amount);
		if (_maxPriceImpactForSell > 0 && !_isExcludedFromMaxTx[from] && _applyFeeFor[to]) {
			require(priceImpact <= _maxPriceImpactForSell,"Price impact too high for selling !");
		}
		if (_maxPriceImpactForBuy > 0 && !_isExcludedFromMaxTx[to] && _applyFeeFor[from]) {
			require(priceImpact <= _maxPriceImpactForBuy,"Price impact too high for buying !");
		}
		
		if (limitSellByTimeUnit && oneSellEveryX != 0 && !_isSellWhiteListed[from] && _applyFeeFor[to]) {
			if (_nextAllowedTransferToPancake[from] != 0) {
				if (_nextAllowedTransferToPancake[from] > block.timestamp) {
					require(_nextAllowedTransferToPancakePriceImpact[from].add(priceImpact) < _maxPriceImpactForSell, "Error: One sell transaction every oneSellEveryX time for max price impact");
					_nextAllowedTransferToPancakePriceImpact[from] = _nextAllowedTransferToPancakePriceImpact[from].add(priceImpact);
				} else {
					_nextAllowedTransferToPancake[from] = block.timestamp + oneSellEveryX;
					_nextAllowedTransferToPancakePriceImpact[from] = priceImpact;
				}
			} else {
				_nextAllowedTransferToPancake[from] = block.timestamp + oneSellEveryX;
				_nextAllowedTransferToPancakePriceImpact[from] = priceImpact;
			}
		}
		// buying
		bool buying = _applyFeeFor[from];
		bool selling = _applyFeeFor[to];
		bool transferring = !buying && !selling;
		bool zeroBalanceBefore = 
			buying ? balanceOf(to) == 0 :
			(transferring ? balanceOf(to) == 0 : false);
		
		// swap and liquify
		swapAndLiquify(from, to);
		
		if (_applyFeeFor[from]) {
			_totalCountBuy = _totalCountBuy.add(1);
		}
		if (_applyFeeFor[to]) {
			_totalCountSell = _totalCountSell.add(1);
		}

		//indicates if fee should be deducted from transfer
		bool takeFee = true;

		//if any account belongs to _isExcludedFromFee account
		// or if it is a simple transfert and not from or to pancakeswap  then remove the fee
		if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || (noFeeForTransfert && !_applyFeeFor[to] && !_applyFeeFor[from])) {
			takeFee = false;
		}

		//transfer amount, it will take tax, liquidity fee, marketing fee
		_tokenTransfer(from, to, amount, takeFee);
		
		if (buying && zeroBalanceBefore) {
			staking.addHolder();
		} else
		if (selling && balanceOf(from) == 0) {
			staking.removeHolder();
		} else if (transferring) {
			if (zeroBalanceBefore && balanceOf(from) > 0) {
				staking.addHolder();
			}
		}
	}

	//this method is responsible for taking all fee, if takeFee is true
	function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
		if (!takeFee) {
			removeAllFee();
		}
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
		if (!takeFee) {
			restoreAllFee();
		}
	}

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tBuyBack) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
		_takeMarketing(tMarketing);
		_takeBuyBack(tBuyBack);
		_reflectFee(rFee, tFee);
		staking.checkIfNeedToSwitchPool();
        emit Transfer(sender, recipient, tTransferAmount);
    }
	

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tBuyBack) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
		_takeMarketing(tMarketing);
		_takeBuyBack(tBuyBack);
		_reflectFee(rFee, tFee);
		staking.checkIfNeedToSwitchPool();
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tBuyBack) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
		_takeMarketing(tMarketing);
		_takeBuyBack(tBuyBack);
		_reflectFee(rFee, tFee);
		staking.checkIfNeedToSwitchPool();
        emit Transfer(sender, recipient, tTransferAmount);
    }

	function _transferStandard(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tBuyBack) = _getValues(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		_rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		_takeLiquidity(tLiquidity);
		_takeMarketing(tMarketing);
		_takeBuyBack(tBuyBack);
		_reflectFee(rFee, tFee);
		staking.checkIfNeedToSwitchPool();
		emit Transfer(sender, recipient, tTransferAmount);
	}

	// SWAP AND ADD TO LP
	function swapAndLiquify(address from, address to) private {
		// is the token balance of this contract address over the min number of
		// tokens that we need to initiate a swap + liquidity lock?
		// also, don't get caught in a circular liquidity event.
		uint256 contractTokenBalance = balanceOf(address(this));
		uint256 _maxToSell = computeAmountFromPriceImpact(_maxPriceImpactForSwapAndLiquify);
		if (_maxToSell == 0) {
			return;
		}
		bool swapPossible = swapAndLiquifyEnabled && !inSwapAndLiquify && (contractTokenBalance >= _maxToSell) && (!(from == address(this) && to == address(pancakePair)));
		bool notBuyPair = !_applyFeeFor[from];
		if (
			swapPossible &&
			notBuyPair
		) {
			// only sell for _maxToSell
			swapAndLiquify(_maxToSell);
		}
	}

	function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
		if (_liquidityFee == 0 && _marketingFee == 0 && _buyBackFee == 0) return;
		uint256 _100percent = _liquidityFee.add(_marketingFee).add(_buyBackFee);
		uint256 marketingTokens = Utils.mulScale(contractTokenBalance,_marketingFee,uint128(_100percent));
		uint256 buyBackTokens = Utils.mulScale(contractTokenBalance,_buyBackFee,uint128(_100percent));
		uint256 liquidityTokens = contractTokenBalance.sub(marketingTokens).sub(buyBackTokens);

		uint256 halfTokensForLiquidity = liquidityTokens.div(2);
		uint256 tokenAmountToBeSwapped = halfTokensForLiquidity.add(marketingTokens).add(buyBackTokens);

		uint256 initialBalance = address(this).balance;
		Utils.swapTokensForEth(address(pancakeRouter), tokenAmountToBeSwapped);
		uint256 deltaBalance = address(this).balance.sub(initialBalance);

		uint256 deltaBalanceMarketing = Utils.mulScale(deltaBalance,_marketingFee,uint128(_100percent));
		uint256 deltaBalanceBuyBack = Utils.mulScale(deltaBalance,_buyBackFee,uint128(_100percent));
		uint256 deltaBalanceLiquidity = deltaBalance.sub(deltaBalanceMarketing).sub(deltaBalanceBuyBack);
		// Add liquidity.
		Utils.addLiquidity(address(pancakeRouter), liquidityWallet, halfTokensForLiquidity, deltaBalanceLiquidity);
		emit SwapAndLiquify(halfTokensForLiquidity, deltaBalanceLiquidity);
		emit SwapForMarketing(marketingTokens, deltaBalanceMarketing);
		_marketingBNB = _marketingBNB.add(deltaBalanceMarketing);
		_buyBackBNB = _buyBackBNB.add(deltaBalanceBuyBack);
		// enough BNB ? send to marketing wallet.
		if (_marketingBNB >= _minBNBToSendToMarketingWallet) {
			_sendBNBTo(marketingWallet,_marketingBNB);
			_marketingBNB = 0;
		}
		// enough BNB ? buy back token.
		if (_buyBackBNB >= _minBNBToBuyBack) {
			_buyBackTokensAndAddToPool(_buyBackBNB);
			_buyBackBNB = 0;
		}
	}
	
	function _buyBackTokensAndAddToPool(uint256 amount) private {
		if (amount == 0) return;
		uint256 maxToRetrieve = address(this).balance;
		if (amount > maxToRetrieve) {
			amount = maxToRetrieve;
		}
		uint256 initialBalance = IBEP20(shibacashTokenAddress).balanceOf(address(staking));
		Utils.swapETHForRewardTokens(address(pancakeRouter),shibacashTokenAddress,address(staking),_buyBackBNB);
		uint256 deltaBalance = IBEP20(shibacashTokenAddress).balanceOf(address(staking)).sub(initialBalance);
		staking._poolTokens(deltaBalance);
	}

	function activateContract() public onlyOwner {
		// exclude owner and this contract from fee
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[address(0x000000000000000000000000000000000000dEaD)] = true;
		_isExcludedFromFee[address(0)] = true;
		_isExcludedFromFee[address(staking)];
		_isExcludedFromFee[address(presale)];
		// Trading whitelisted
		_isTradingWhiteListed[owner()] = true;
		_isTradingWhiteListed[address(this)] = true;
		_isTradingWhiteListed[address(staking)] = true;
		_isTradingWhiteListed[address(presale)] = true;
		// sell whitelist
		_isSellWhiteListed[owner()] = true;
		_isSellWhiteListed[address(this)] = true;
		// include pancake pair and pancake router in transfert fee:
		_applyFeeFor[address(pancakeRouter)] = true;
		_applyFeeFor[address(pancakePair)] = true;
		// exclude from max tx
		_isExcludedFromMaxTx[owner()] = true;
		_isExcludedFromMaxTx[address(this)] = true;
		_isExcludedFromMaxTx[address(0x000000000000000000000000000000000000dEaD)] = true;
		_isExcludedFromMaxTx[address(0)] = true;
		_isExcludedFromMaxTx[address(staking)];
		_isExcludedFromMaxTx[address(presale)];
		// exclue from reward
		_excludeFromReward(owner());
		_excludeFromReward(address(this));
		_excludeFromReward(address(0x000000000000000000000000000000000000dEaD));
		_excludeFromReward(address(0));
		_excludeFromReward(address(staking));
		_excludeFromReward(address(presale));
		//
		setSwapAndLiquifyEnabled(false);
		setTradingEnabled(false);
		setLimitSellByTimeUnit(true, 2 hours);
		setNoFeeForTransfert(true);
		setTaxFeePercent(2);
		setLiquidityFeePercent(2);
		setMarketingFeePercent(2);
		setBuyBackFeePercent(4);
		setMaxPriceImpactForBuy(80000);
		setMaxPriceImpactForSell(20000);
		setMaxPriceImpactForSwapAndLiquify(10000);
		marketingWallet = owner();
		liquidityWallet = address(0x000000000000000000000000000000000000dEaD);
		staking.setMarketingWallet(marketingWallet);
		staking.poolEnabled(true);
		staking.excludeFromSupply(address(pancakePair));
		staking.setUnstakeTax(4);
		staking.addHolder();
		// 10 billions shibacash tokens per period
		staking.setPoolTokensByPeriod(10000000000 * 10 ** 9);
		// approve contract
		_approve(address(this), address(pancakeRouter), 2 ** 256 - 1);
		// send presale tokens
		_tokenTransfer(owner(),address(presale),(5000000 * 10 ** 18),false);
	}

	// force a swap and liquify
	function forceSwapAndLiquify() external nonReentrant onlyAuthorizedCallers {
		swapAndLiquify(msg.sender,msg.sender);
	}

	// RETRIEVE FUND FUNCTIONS
	/**
	 * Retrieve BNB from contract and send to marketing wallet
	 */
	function _sendBNBTo(address account,uint256 amount) private {
		uint256 toRetrieve = address(this).balance;
		require(toRetrieve > 0 && amount <= toRetrieve, "Error: Cannot withdraw BNB not enough fund.");
		if (amount == 0) {
			amount = toRetrieve;
		}
		(bool sent,) = address(account).call{value : amount}("");
		require(sent, "Error: Cannot withdraw BNB");
		emit SentBNBSuccessfully(msg.sender, account, amount);
	}

	function sendBNBTo(address account,uint256 amount) external nonReentrant onlyAuthorizedCallers {
		_sendBNBTo(account,amount);
		// reset counters on withdraw
		if (amount >= _marketingBNB) {
			amount = amount.sub(_marketingBNB);
			_marketingBNB = 0;
		}
		if (amount >= _buyBackBNB) {
			amount = amount.sub(_buyBackBNB);
			_buyBackBNB = 0;
		}
	}

	/**
	 * Retrieve Token located at tokenAddress from contract and send to marketing wallet
	 */
	function _sendTokensTo(address account,address tokenAddress,uint256 amount) private {
		uint256 toRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
		require(toRetrieve > 0 && amount <= toRetrieve, "Error: Cannot withdraw TOKEN not enough fund.");
		if (amount == 0) {
			amount = toRetrieve;
		}
		bool sent = IBEP20(tokenAddress).transfer(account,amount);
		require(sent, "Error: Cannot withdraw TOKEN");
		emit SentTokensSuccessfully(tokenAddress,msg.sender, account, amount);
	}

	function sendTokensTo(address account,address tokenAddress,uint256 amount) external nonReentrant onlyAuthorizedCallers {
		_sendTokensTo(account,tokenAddress,amount);
	}
}

