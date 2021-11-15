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
	bool private _useMultipleCallers;
	address private _owner;
	mapping(address => bool) private _authorizedCallers;
	uint256 private _countAuthorizedCallers;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event AuthorizedCaller(address account,bool value);
	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor () internal {
		_owner = _msgSender();
		_useMultipleCallers = true;
		_setAuthorizedCallers(_owner,true);
		emit OwnershipTransferred(address(0), _owner);
	}

	function owner() public view returns (address) {
		return _owner;
	}

	function isAuthorizedCaller(address account) public view returns (bool) {
		return _useMultipleCallers && _authorizedCallers[account];
	}

	modifier onlyOwner() {
		require(_owner == _msgSender() || (_useMultipleCallers && _authorizedCallers[_msgSender()] == true), "Ownable: caller is not authorized");
		_;
	}

	function _setAuthorizedCallers(address account,bool value) private {
		if (account == address(0)) return;
		if (value && !_useMultipleCallers) return;
		if (value && _authorizedCallers[account]) return;
		if (!value && !_authorizedCallers[account]) return;
		if (value) _countAuthorizedCallers++; else _countAuthorizedCallers--;
		_authorizedCallers[account] = value;
		emit AuthorizedCaller(account,value);
	}

	function setAuthorizedCallers(address account,bool value) public onlyOwner {
	    _setAuthorizedCallers(account,value);
	}
	
	function countAuthorizedCallers() public view returns (uint256) {
	    return _countAuthorizedCallers;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_setAuthorizedCallers(_owner,false);
		_owner = address(0);
		
	}

	function fullRenounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_countAuthorizedCallers = 0;
		_useMultipleCallers = false;
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
	    _setAuthorizedCallers(_owner,false);
	    _setAuthorizedCallers(newOwner,true);
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

abstract contract ReentrancyGuard {
	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;

	uint256 private _status;

	constructor () public {
		_status = _NOT_ENTERED;
	}

	modifier nonReentrant() {
		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
		_status = _ENTERED;
		_;
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

contract LeashStake is Context, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

	// Pool
	mapping(uint256 => address) private _rewardTokenAddress;
	mapping(uint256 => address) private _stakedTokenAddress;

	// Tax handling
	mapping(uint256 => uint256) private _stakeTaxpoolIndex;
	mapping(uint256 => uint256) private _unstakeRewardTax;
	mapping(uint256 => uint256) private _stakeTokenTax;
	mapping(uint256 => uint256) private _unstakeTokenTax;

	// Total reward for pool
	mapping(uint256 => uint256) private _rewardPools;
	// last time the reward pool was switched
	mapping(uint256 => uint256) private _lastSwitchPools;
	mapping(uint256 => uint256) private _stakePeriod;
	mapping(uint256 => uint256) private _rewardTokensByPeriod;

	mapping(uint256 => uint256) private _currentRewardPools;
	mapping(uint256 => uint256) private _currentTotalRewardPools;
	mapping(uint256 => uint256) private _previousRewardPools;
	mapping(uint256 => uint256) private _previousTotalRewardPools;

	mapping(uint256 => uint256) private _totalStaked;
	mapping(uint256 => uint256) private _totalRewards;
	mapping(uint256 => uint256) private _countStakers;
	mapping(uint256 => uint256) private _accumulatedTokensByPeriod;
	mapping(uint256 => uint256) private _minUserStakesForReward;
	mapping(uint256 => uint256) private _minTotalStakedForFullReward;
	mapping(uint256 => uint256) private _minStakersForFullReward;
	mapping(uint256 => mapping(address => uint256)) private _userStakes;
	mapping(uint256 => mapping(address => uint256)) private _userRewards;
	mapping(uint256 => mapping(address => uint256)) private _nextClaimDate;

	struct Pool {
		string poolName;
		uint256 poolIndex;
		address stakedToken;
		address rewardToken;
		uint256 unstakeRewardTax;
		uint256 stakePeriod;
		uint256 rewardTokensByPeriod;
	}

    Pool[] private availablePools;

	address private retrieveFundWallet;

	event PoolAddedSuccessfully(
		string poolName,
		uint256 poolIndex,
		address stakedToken,
		address rewardToken,
		uint256 unstakeRewardTax,
		uint256 stakePeriod,
		uint256 rewardTokensByPeriod
	);

	event RewardAddedSuccessfully (
		uint256 poolIndex,
		address rewardToken,
		uint256 amount
	);

	event PoolSwitchedSuccessfully (
		uint256 poolIndex,
		uint256 amount,
		uint256 switchDate
	);

	event StakeTokenSuccessfully(
		uint256 poolIndex,
		address from,
		uint256 totalAmount,
		uint256 tax,
		uint256 amount,
		uint256 nextClaimDate
	);

	event ClaimRewardSuccessfully(
		uint256 poolIndex,
		address from,
		uint256 amount,
		uint256 nextClaimDate
	);

	event RetrieveRewardSuccessfully(
		uint256 poolIndex,
		address to,
		uint256 rewardBalance
	);

	event UnstakeTokenSuccessfully(
		uint256 poolIndex,
		address to,
		uint256 amount
	);

	constructor (address _leashAddress,address parentOwner) public {
		setAuthorizedCallers(_leashAddress,true);
		setAuthorizedCallers(parentOwner,true);
		retrieveFundWallet = parentOwner;
	}

	function mulScale(uint x, uint y, uint128 scale) internal pure returns (uint) {
		uint256 a = x.div(scale);
		uint256 b = x.mod(scale);
		uint256 c = y.div(scale);
		uint256 d = y.mod(scale);
		return (a.mul(c).mul(scale)).add(a.mul(d)).add(b.mul(c)).add(b.mul(d).div(scale));
	}
	
	function getRewardTokenAddress(uint256 poolIndex) external view returns (address) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _rewardTokenAddress[poolIndex];
	}

	function getStakeTokenAddress(uint256 poolIndex) external view returns (address) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _stakedTokenAddress[poolIndex];
	}
	
	function getMinStakersForFullReward(uint256 poolIndex) public view returns (uint256) {
		uint256 ret = _minStakersForFullReward[poolIndex];
		if (ret == 0) {
			return 100;
		}
		return _minStakersForFullReward[poolIndex];
	}

	function getMinTotalStakedForFullReward(uint256 poolIndex) external view returns (uint256) {
		return _minTotalStakedForFullReward[poolIndex];
	}

	function getMinUserStakesForReward(uint256 poolIndex) external view returns (uint256) {
		return _minUserStakesForReward[poolIndex];
	}

	function getUserStakes(uint256 poolIndex,address account) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _userStakes[poolIndex][account];
	}

	function getUserRewards(uint256 poolIndex,address account) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _userRewards[poolIndex][account];
	}

	function getNextClaimDate(uint256 poolIndex,address account) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _nextClaimDate[poolIndex][account];
	}

	function getUnstakeRewardTax(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _unstakeRewardTax[poolIndex];
	}

	function getStakeTokenTax(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		uint256 stakeTaxpoolIndex = _stakeTaxpoolIndex[poolIndex];
		return _stakeTokenTax[stakeTaxpoolIndex];
	}

	function getUnstakeTokenTax(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		uint256 stakeTaxpoolIndex = _stakeTaxpoolIndex[poolIndex];
		return _unstakeTokenTax[stakeTaxpoolIndex];
	}

	function getRewardPool(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _rewardPools[poolIndex];
	}

	function getLastSwitchDate(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _lastSwitchPools[poolIndex];
	}

	function getStakePeriod(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _stakePeriod[poolIndex];
	}

	function getRewardTokensByPeriod(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _rewardTokensByPeriod[poolIndex];
	}

	function getCurrentRewardPools(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _currentRewardPools[poolIndex];
	}

	function getCurrentTotalRewardPools(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _currentTotalRewardPools[poolIndex];
	}

	function getPreviousRewardPools(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _previousRewardPools[poolIndex];
	}

	function getPreviousTotalRewardPools(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _previousTotalRewardPools[poolIndex];
	}

	function getTotalStaked(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _totalStaked[poolIndex];
	}

	function getTotalRewards(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _totalRewards[poolIndex];
	}

	function getCountStakers(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _countStakers[poolIndex];
	}

	function getAccumulatedTokensByPeriod(uint256 poolIndex) external view returns (uint256) {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		return _accumulatedTokensByPeriod[poolIndex];
	}

	function toHours(uint256 amount) external pure returns (uint256) {
		return amount * (1 hours);
	}

	function toMinutes(uint256 amount) external pure returns (uint256) {
		return amount * (1 minutes);
	}

	function toDays(uint256 amount) external pure returns (uint256) {
		return amount * (1 days);
	}

	/**
	 * Create a new staking pool
	 */
	function createPool(string memory poolName,uint256 poolIndex,address stakedToken,address rewardToken,uint256 unstakeRewardTax,uint256 stakePeriod,uint256 rewardTokensByPeriod) public onlyOwner returns (Pool memory) {
		require(poolIndex != 0,"Pool index 0 is reserved !");
		require(_stakedTokenAddress[poolIndex] == address(0),"Pool already exists !");
		require(stakePeriod > 0,"Staking period must be greater than 0");
		_stakedTokenAddress[poolIndex] = stakedToken;
		_rewardTokenAddress[poolIndex] = rewardToken;
		if (stakedToken == rewardToken) {
			_unstakeRewardTax[poolIndex] = 0;
		} else {
			_unstakeRewardTax[poolIndex] = unstakeRewardTax;
		}
		_stakePeriod[poolIndex] = stakePeriod;
		_rewardTokensByPeriod[poolIndex] = rewardTokensByPeriod;
		emit PoolAddedSuccessfully(poolName,poolIndex,stakedToken,rewardToken,_unstakeRewardTax[poolIndex],stakePeriod,rewardTokensByPeriod);
		Pool memory pool;
		pool.poolName = poolName;
		pool.poolIndex = poolIndex;
		pool.stakedToken = stakedToken;
		pool.rewardToken = rewardToken;
		pool.unstakeRewardTax = _unstakeRewardTax[poolIndex];
		pool.stakePeriod = stakePeriod;
		pool.rewardTokensByPeriod = rewardTokensByPeriod;
		availablePools.push(pool);
		return pool;
	}
	
	function listPools() external view returns (Pool [] memory) {
		return availablePools;
	}

	function setStakeTaxPool(uint256 poolIndex,uint256 stakeTaxpoolIndex,uint256 stakeTokenTax,uint256 unstakeTokenTax) external onlyOwner {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		_stakeTaxpoolIndex[poolIndex] = stakeTaxpoolIndex;
        if (stakeTaxpoolIndex == 0) {
			_stakeTokenTax[stakeTaxpoolIndex] = 0;
			_unstakeTokenTax[stakeTaxpoolIndex] = 0;
		} else {
			_stakeTokenTax[stakeTaxpoolIndex] = stakeTokenTax;
			_unstakeTokenTax[stakeTaxpoolIndex] = unstakeTokenTax;
		}
	}
	
	function setUnstakeRewardTax(uint256 poolIndex,uint256 tax) external onlyOwner {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		_unstakeRewardTax[poolIndex] = tax;
	}
	

	/**
	 * Add tokens to the reward pool, anybody can add rewards
	 */
	function addRewardToPool(uint256 poolIndex,uint256 amount) external nonReentrant {
		address rewardToken = _rewardTokenAddress[poolIndex];
		require(rewardToken != address(0),"Pool does not exists !");
		// transfer the amount !! the contract should be approved by the sender on the reward token contract.
		IBEP20(rewardToken).transferFrom(msg.sender,address(this),amount);
		_rewardPools[poolIndex] = _rewardPools[poolIndex] + amount;
		uint256 maxToRetrieve = IBEP20(rewardToken).balanceOf(address(this));
		if (_rewardPools[poolIndex] > maxToRetrieve) {
			_rewardPools[poolIndex] = maxToRetrieve;
		}
		emit RewardAddedSuccessfully(poolIndex,rewardToken,amount);
	}

	/**
	 * Switch the reward for the period
	 */
	function _switchPool(uint256 poolIndex) private {
		// pool must exist
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		// switch can be done ?
		if (_lastSwitchPools[poolIndex] + _stakePeriod[poolIndex] > block.timestamp) {
			// "Stake period not finished, cannot switch pool now !"
			return;
		}
		// NO REWARDS IN POOL, DO NOT SWITCH
		if (_rewardPools[poolIndex] == 0) return;
		address rewardToken = _rewardTokenAddress[poolIndex];
		uint256 maxToRetrieve = IBEP20(rewardToken).balanceOf(address(this));
		if (_rewardPools[poolIndex] > maxToRetrieve) {
			_rewardPools[poolIndex] = maxToRetrieve;
		}
		// NO TOKEN REWARD IN CONTRACT, DO NOT SWITCH
		if (maxToRetrieve == 0) return;
		// compute amount
		uint256 amountToReward = _rewardTokensByPeriod[poolIndex];
		uint256 accumulatedReward = _accumulatedTokensByPeriod[poolIndex];
		amountToReward = amountToReward + accumulatedReward.div(2);
		if (amountToReward > _rewardPools[poolIndex]) {
			// if pool is depleted, reward is half of the reward pool
			amountToReward = _rewardPools[poolIndex].div(2);
		} else
		// at least reward should be 1/20 of reward pool
		if (amountToReward < _rewardPools[poolIndex].div(20)) {
			amountToReward = _rewardPools[poolIndex].div(20);
		}
		_accumulatedTokensByPeriod[poolIndex] = 0;
		uint256 previous = _previousRewardPools[poolIndex];
		// adding back previous pool to global reward pool and remove amountToReward
		_rewardPools[poolIndex] = (_rewardPools[poolIndex] - amountToReward) + previous;
		// previous reward pool is current reward pool
		_previousRewardPools[poolIndex] = _currentRewardPools[poolIndex];
		_previousTotalRewardPools[poolIndex] = _previousRewardPools[poolIndex];
		// set current as amountToReward
		_currentRewardPools[poolIndex] = amountToReward;
		_currentTotalRewardPools[poolIndex] = _currentRewardPools[poolIndex];
		// set last switch date
		_lastSwitchPools[poolIndex] = block.timestamp;
		emit PoolSwitchedSuccessfully(poolIndex,amountToReward,_lastSwitchPools[poolIndex]);
	}

	/**
	 * Switch the reward for the period
	 */
	function switchPool(uint256 poolIndex) external onlyOwner {
		checkIfNeedToSwitchPool(poolIndex);
	}
	
	function checkIfNeedToSwitchPool(uint256 poolIndex) private {
		if (_lastSwitchPools[poolIndex] + _stakePeriod[poolIndex] <= block.timestamp) {
			_switchPool(poolIndex);
		}
	}
	
	/**
	 * Stake amount tokens into pool
	 */
	function stakeTokens(uint256 poolIndex,uint256 amount) external isHuman nonReentrant {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		checkIfNeedToSwitchPool(poolIndex);
		require(_lastSwitchPools[poolIndex] > 0,"Pool not opened for staking.");
		address tokenAddress = _stakedTokenAddress[poolIndex];
		// transfer the amount !! the contract should be approved by the sender on the reward token contract.
		IBEP20(tokenAddress).transferFrom(msg.sender,address(this),amount);
		// take tax fee
	    uint256 stakeTax = 0;
        if (_stakeTaxpoolIndex[poolIndex] != 0) {
        	stakeTax = _stakeTokenTax[_stakeTaxpoolIndex[poolIndex]];
        }
		uint256 totalAmount = amount;
		uint256 tax = stakeTax == 0 ? 0 : mulScale(amount,stakeTax,1000000);
		if (tax != 0) {
			// remove tax from staked amount
			amount = amount - tax;
			// add tax to accumulated token by period
			_accumulatedTokensByPeriod[_stakeTaxpoolIndex[poolIndex]] = _accumulatedTokensByPeriod[_stakeTaxpoolIndex[poolIndex]] + tax;
			// add tax to reward pool
			_rewardPools[_stakeTaxpoolIndex[poolIndex]] = _rewardPools[_stakeTaxpoolIndex[poolIndex]] + tax;
		}
		// add stake to user stakes
		_userStakes[poolIndex][msg.sender] = _userStakes[poolIndex][msg.sender] + amount;
		// update total staked
		_totalStaked[poolIndex] = _totalStaked[poolIndex] + amount;
		// update next claim date
		if (_lastSwitchPools[poolIndex] + _stakePeriod[poolIndex].div(3).mul(2) > block.timestamp) {
			_nextClaimDate[poolIndex][msg.sender] = block.timestamp + _stakePeriod[poolIndex];
		} else {
			// staking too late, scheduling to next period
			_nextClaimDate[poolIndex][msg.sender] = _lastSwitchPools[poolIndex] + _stakePeriod[poolIndex].mul(2);
		}
		_countStakers[poolIndex] = _countStakers[poolIndex].add(1);
		emit StakeTokenSuccessfully(poolIndex,msg.sender, totalAmount, tax, amount, _nextClaimDate[poolIndex][msg.sender]);
	}

	function setRewardTokensByPeriod(uint256 poolIndex,uint256 amount) external onlyOwner {
		_rewardTokensByPeriod[poolIndex] = amount;
	}

	function setMinStakersForFullReward(uint256 poolIndex,uint256 count) external onlyOwner {
		_minStakersForFullReward[poolIndex] = count;
	}

	function setMinTotalStakedForFullReward(uint256 poolIndex,uint256 amount) external onlyOwner {
		_minTotalStakedForFullReward[poolIndex] = amount;
	}

	function setMinUserStakesForReward(uint256 poolIndex,uint256 amount) external onlyOwner {
		_minUserStakesForReward[poolIndex] = amount;
	}

	/**
	 * Estimate how much reward the staker can get when the stake period is over
	 */
	function _estimatedRewards(uint256 poolIndex,address account) private view returns (uint256) {
		if (_stakedTokenAddress[poolIndex] == address(0)) {
			// "Pool does not exists !"
			return 0;
		}
		uint256 stakerBalance = _userStakes[poolIndex][msg.sender];
		uint256 minUserStake = _minUserStakesForReward[poolIndex];
		if (stakerBalance < minUserStake) {
			return 0;
		}
		uint256 poolAmount = 0;
		uint256 currentPoolAmount = 0;
		if (_nextClaimDate[poolIndex][account] <= _lastSwitchPools[poolIndex] + _stakePeriod[poolIndex]) {
			poolAmount = _currentTotalRewardPools[poolIndex];
			currentPoolAmount = _currentRewardPools[poolIndex];
		}		
		bool previous = false;
		if (_nextClaimDate[poolIndex][account] <= _lastSwitchPools[poolIndex]) {
			// new pools has been added since, so estimate from previous pool
			poolAmount = _previousTotalRewardPools[poolIndex];
			currentPoolAmount = _previousRewardPools[poolIndex];
			previous = true;
		}
		if (poolAmount > 0) {
			uint256 rewardPercentage = 0;
			// less than getMinStackersForFullReward stakers ? only receive count/minStakers % of real stake.
			uint256 minStakers = getMinStakersForFullReward(poolIndex);
			uint256 minTotalStaked = _minTotalStakedForFullReward[poolIndex];
			if (_totalStaked[poolIndex] >= minTotalStaked) {
				minTotalStaked = _totalStaked[poolIndex];
			}
			if (_countStakers[poolIndex] < minStakers) {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
				// not enough stakers, only get countstaker/minstakers * rewardPercentage
				rewardPercentage = mulScale(rewardPercentage,_countStakers[poolIndex],uint128(minTotalStaked));
			} else {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
			}
			uint256 reward = mulScale(poolAmount,rewardPercentage,1000000);
			// initial percentage changed, take as mush as current pool amount.
			if (reward > currentPoolAmount) {
				if (_totalStaked[poolIndex] == stakerBalance) {
					reward = currentPoolAmount;	
				} else {
					reward = mulScale(currentPoolAmount,rewardPercentage,1000000);
				}
			}
			return reward;
		} else {
			return 0;
		}
	}

	/**
	 * Estimate how much reward the staker could get at claim date
	 */
	function estimatedRewards(uint256 poolIndex,address account) public view returns (uint256) {
		if (_stakedTokenAddress[poolIndex] == address(0)) {
			// "Pool does not exists !"
			return 0;
		}
		if (_nextClaimDate[poolIndex][account] != 0 && _nextClaimDate[poolIndex][account] <= block.timestamp) {
			return _estimatedRewards(poolIndex,account);
		}
		uint256 stakerBalance = _userStakes[poolIndex][msg.sender];
		uint256 minUserStakes = _minUserStakesForReward[poolIndex];
		if (stakerBalance < minUserStakes) {
			return 0;
		}
		uint256 poolAmount = _currentTotalRewardPools[poolIndex];
		if (poolAmount > 0) {
			uint256 rewardPercentage = 0;
			// less than getMinStackersForFullReward stakers ? only receive count/minStakers % of real stake.
			uint256 minStakers = getMinStakersForFullReward(poolIndex);
			uint256 minTotalStaked = _minTotalStakedForFullReward[poolIndex];
			if (_totalStaked[poolIndex] >= minTotalStaked) {
				minTotalStaked = _totalStaked[poolIndex];
			}
			if (_countStakers[poolIndex] < minStakers) {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
				// not enough stakers, only get countstaker/minstakers * rewardPercentage
				rewardPercentage = mulScale(rewardPercentage,_countStakers[poolIndex],uint128(minTotalStaked));
			} else {
				rewardPercentage = mulScale(stakerBalance,1000000,uint128(minTotalStaked));
			}
			return mulScale(poolAmount,rewardPercentage,1000000);
		} else {
			return 0;
		}
	}

	function _claimRewards(uint256 poolIndex,address account) private {
		if (_stakedTokenAddress[poolIndex] == address(0)) {
			// "Pool does not exists !"
			return;
		}
		checkIfNeedToSwitchPool(poolIndex);
		address rewardTokenAddress = _rewardTokenAddress[poolIndex];
		address tokenAddress = _stakedTokenAddress[poolIndex];
		if (_nextClaimDate[poolIndex][account] <= block.timestamp) {
			uint256 reward = _estimatedRewards(poolIndex,account);
			bool previous = _nextClaimDate[poolIndex][account] <= _lastSwitchPools[poolIndex];
			_nextClaimDate[poolIndex][account] = _nextClaimDate[poolIndex][account] + _stakePeriod[poolIndex];
			if (reward > 0) {
				if (previous) {
					_previousRewardPools[poolIndex] = _previousRewardPools[poolIndex] - reward;
				} else {
					_currentRewardPools[poolIndex] = _currentRewardPools[poolIndex] - reward;
				}
				_totalRewards[poolIndex] = _totalRewards[poolIndex] + reward;
				if (rewardTokenAddress == tokenAddress) {
					// add automatically to user stakes
					_userStakes[poolIndex][account] = _userStakes[poolIndex][account] + reward;
					_userRewards[poolIndex][account] = _userRewards[poolIndex][account] + reward;
				} else {
					_userRewards[poolIndex][account] = _userRewards[poolIndex][account] + reward;
				}
			}
			emit ClaimRewardSuccessfully(poolIndex, account, reward, _nextClaimDate[poolIndex][account]);
		}
	}

	function claimRewards(uint256 poolIndex) public isHuman nonReentrant {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		_claimRewards(poolIndex,msg.sender);
	}

	function retrieveRewards(uint256 poolIndex,address account) public isHuman nonReentrant {
		require(_rewardTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		address rewardTokenAddress = _rewardTokenAddress[poolIndex];
		address tokenAddress = _stakedTokenAddress[poolIndex];
		require(rewardTokenAddress != tokenAddress,"You must unstake to retrieve rewards !");
		_claimRewards(poolIndex,msg.sender);
		uint256 rewardBalance = _userRewards[poolIndex][account];
		require(rewardBalance > 0,"No reward to unstake");
		uint256 unstakeTax = _unstakeRewardTax[poolIndex];
		// take tax fee
		uint256 totalToRemove = rewardBalance;
		uint256 tax = unstakeTax == 0 ? 0 : mulScale(totalToRemove,unstakeTax,1000000);
		if (tax != 0) {
			rewardBalance = totalToRemove - tax;
			require(rewardBalance > 0,"Error no tokens to send.");
			// add tax to accumulated tokens for the current period
			_accumulatedTokensByPeriod[poolIndex] = _accumulatedTokensByPeriod[poolIndex] + tax;
			// add tax to reward pool
			_rewardPools[poolIndex] = _rewardPools[poolIndex] + tax;
		}
		// remove reward from user reward
		_userRewards[poolIndex][account] = 0;
		// send token
		bool sent = IBEP20(rewardTokenAddress).transfer(account,rewardBalance);
		require(sent, 'Error: Cannot withdraw TOKEN');
		emit RetrieveRewardSuccessfully(poolIndex,account, rewardBalance);
	}

	function unstakeTokens(uint256 poolIndex,address account) public isHuman nonReentrant {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		address rewardTokenAddress = _rewardTokenAddress[poolIndex];
		address tokenAddress = _stakedTokenAddress[poolIndex];
		_claimRewards(poolIndex,msg.sender);
		uint256 stakerBalance = _userStakes[poolIndex][account];
		require(stakerBalance > 0,"No tokens to unstake");
		// take tax fee
		uint256 stakeTaxpoolIndex = _stakeTaxpoolIndex[poolIndex];
	    uint256 unstakeTax = 0;
        if (stakeTaxpoolIndex != 0) {
	        unstakeTax = _unstakeTokenTax[stakeTaxpoolIndex];
        }
		uint256 totalToRemove = stakerBalance;
		uint256 tax = unstakeTax == 0 ? 0 : mulScale(stakerBalance,unstakeTax,1000000);
		// remove tax from staked amount
		if (tax > 0) {
			stakerBalance = stakerBalance - tax;
			require(stakerBalance > 0,"No tokens to unstake.");
			_accumulatedTokensByPeriod[stakeTaxpoolIndex] = _accumulatedTokensByPeriod[stakeTaxpoolIndex] + tax;
			_rewardPools[stakeTaxpoolIndex] = _rewardPools[stakeTaxpoolIndex] + tax;
		}
		_totalStaked[poolIndex] = _totalStaked[poolIndex]-totalToRemove;
		_userStakes[poolIndex][account] = 0;
		if (tokenAddress == rewardTokenAddress) {
			_totalRewards[poolIndex] = _totalRewards[poolIndex] - _userRewards[poolIndex][account];
			_userRewards[poolIndex][account] = 0;
		}
		bool sent = IBEP20(tokenAddress).transfer(account,stakerBalance);
		require(sent, 'Error: Cannot withdraw TOKEN');
		if (_countStakers[poolIndex] >= 1) {
			_countStakers[poolIndex] = _countStakers[poolIndex].sub(1);
		}
		emit UnstakeTokenSuccessfully(poolIndex,account, stakerBalance);
	}

	// Retrieve BNB sent to this contract
	function retrieveBNB(uint256 amount) external nonReentrant onlyOwner {
		uint256 toRetrieve = address(this).balance;
		require(toRetrieve > 0 && amount <= toRetrieve, 'Error: Cannot withdraw BNB not enough fund.');
		(bool sent,) = address(retrieveFundWallet).call{value : amount}("");
		require(sent, 'Error: Cannot withdraw BNB');
	}

	// Retrieve the tokens in the Reward pool for the given tokenAddress
	function retrieveRewardTokens(uint256 poolIndex) external nonReentrant onlyOwner {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		address tokenAddress = _rewardTokenAddress[poolIndex];
		uint256 maxToRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
		uint256 toRetrieve = _rewardPools[poolIndex];
		if (toRetrieve > maxToRetrieve) {
			toRetrieve = maxToRetrieve;
		}
		require(toRetrieve > 0 && toRetrieve <= maxToRetrieve, 'Error: Cannot withdraw TOKEN not enough fund.');
		_rewardPools[poolIndex] = 0;
		bool sent = IBEP20(tokenAddress).transfer(retrieveFundWallet,toRetrieve);
		require(sent, 'Error: Cannot withdraw TOKEN');
	}

	/** 
	 * Retrieve the tokens in the contract balance for the given tokenAddress
	 * CALL RESET POOL BEFORE RETRIEVING ANYTHING
	 * WARNING THIS FUNCTION CAN BREAK THE POOL
	 * ONLY FOR EMERGENCY
	 */
	function retrieveTokens(address tokenAddress,uint256 amount) external nonReentrant onlyOwner {
		uint256 toRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
		if (amount > toRetrieve) {
			amount = toRetrieve;
		}
		require(amount > 0, 'Error: Cannot withdraw TOKEN not enough fund.');
		bool sent = IBEP20(tokenAddress).transfer(retrieveFundWallet,amount);
		require(sent, 'Error: Cannot withdraw TOKEN');
	}

	/** 
	 * WARNING THIS FUNCTION WILL BREAK THE POOL
	 * ONLY FOR EMERGENCY
	 * DO NOT CREATE A POOL WITH SAME NAME AGAIN
	 */
	function resetPool(uint256 poolIndex) public onlyOwner {
		require(_stakedTokenAddress[poolIndex] != address(0),"Pool does not exists !");
		require(_totalStaked[poolIndex] == 0,"User must unstake everything first");
		require(_totalRewards[poolIndex] == 0,"User must unstake everything first");
		_stakedTokenAddress[poolIndex] = address(0);
		_rewardTokenAddress[poolIndex] = address(0);
		_rewardPools[poolIndex] = 0;
		_currentRewardPools[poolIndex] = 0;
		_currentTotalRewardPools[poolIndex] = 0;
		_previousRewardPools[poolIndex] = 0;
		_previousTotalRewardPools[poolIndex] = 0;
		_minTotalStakedForFullReward[poolIndex] = 0;
		_minUserStakesForReward[poolIndex] = 0;
		_countStakers[poolIndex] = 0;
		_lastSwitchPools[poolIndex] = 0;
		_stakeTaxpoolIndex[poolIndex] = poolIndex;
		if (availablePools.length == 1) {
		    availablePools.pop();
		} else {
    		for (uint256 i=0;i<availablePools.length;i++) {
                if (availablePools[i].poolIndex == poolIndex) {
                    availablePools[i] = availablePools[availablePools.length-1];
                    availablePools.pop();
                }
    		}
		}
	}
}
 
contract LeashCashPresale is Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using Address for address;

    // LEASHCACH CONTRACT ADDRESS
	address private immutable leashAddress;

	// HARD CAP 300 BNB
	uint256 private _hardCap = 300 * 10 ** 18;
	// SOFT CAP 150 BNB
	uint256 private _softCap = 150 * 10 ** 18;
	// 4 BNB maximum
	uint256 private _maxBNBPerUser = 4 * 10 ** 18;
	// 0.1 BNB minimum
	uint256 private _minBNBPerUser = 1 * 10 ** 17;
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
		_checkToStart();
		_checkFinalizePresale();
		require(started,"Presale not started");
		require(!presaleFinished,"Presale is finished");
		uint256 totBalance = address(this).balance.add(msg.value);
		uint256 userBalance = _userBNB[_msgSender()].add(msg.value);
		require(totBalance <= _hardCap,"Hard cap is reached.");
		require(userBalance <= _maxBNBPerUser,"Must send less or equal to maximum per user.");
		if (totBalance < _hardCap) {
			// only check minimum if less than hardcap
			require(userBalance >= _minBNBPerUser,"Must send more or equal than min BNB per user.");
		}
		_userBNB[_msgSender()] = userBalance;
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

	function start() external onlyOwner {
		_start(presaleDurationInHours);
	}

	function setPresaleStartDate(uint256 _hours) external onlyOwner {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		uint256 value = block.timestamp + _hours * (1 hours);
		presaleStartDate = value;
		presaleEndDate = value + (presaleDurationInHours * (1 hours));
		_checkToStart();
	}
	
	function _checkToStart() private {
		if (!started && !presaleFinished && presaleStartDate != 0 && presaleStartDate <= block.timestamp) {
			_start(presaleDurationInHours);
		}
	}

	function setPresaleDurationInHours(uint256 value) external onlyOwner {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		presaleDurationInHours = value;
	}

	function setSoftCap(uint256 value) external onlyOwner {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		require(_softCap > 0,"soft cap must be > 0");
		require(_softCap <= _hardCap,"soft cap must be <= than hard cap");
		_softCap = value;
	}

	function setHardCap(uint256 value) external onlyOwner {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		require(_hardCap > 0,"hard cap must be > 0");
		require(_hardCap >= _softCap,"hard cap must be >= than soft cap");
		_hardCap = value;
	}

	function setMaxBNBPerUser(uint256 value) external onlyOwner {
		require(!started,"Presale already started");
		require(!presaleFinished,"Presale is finished");
		require(_maxBNBPerUser > 0,"max BNB per user must be > 0");
		_maxBNBPerUser = value;
	}

	function setMinBNBPerUser(uint256 value) external onlyOwner {
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
	function finalizePresale() external onlyOwner {
		require(started,"Presale not started");
		require(!presaleFinished,"Presale is finished");
		_checkFinalizePresale();
	}
	
	// OWNER FUNCTIONS, withDrawRemainingTokensFailure if failure and  if success, withDrawRemainingTokensSuccess and withdrawBNB

	// If presale failed, withdraw tokens
	function withDrawRemainingTokensFailure() external nonReentrant onlyOwner {
		_checkFinalizePresale();
		require(presaleFinished,"Presale not finished");
		require(!success,"Presale is a success");
		// everybody has removed their BNB
		require(address(this).balance == 0,"Still BNB on contract");
		uint256 toRetrieve = IBEP20(leashAddress).balanceOf(address(this));
		require(toRetrieve > 0, "Error: Cannot withdraw TOKEN not enough fund.");
		bool sent = IBEP20(leashAddress).transfer(_msgSender(),toRetrieve);
		require(sent, "Error: Cannot withdraw TOKEN");
	}

	// If presale success, withdraw remaining tokens
	function withDrawRemainingTokensSuccess() external nonReentrant onlyOwner {
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
	function withdrawBNB() external onlyOwner {
		_checkFinalizePresale();
		require(presaleFinished,"Presale not finished");
		require(success,"Presale is a success");
		uint256 toRetrieve = address(this).balance;
		require(toRetrieve > 0,"Error: Cannot withdraw BNB not enough fund.");
        (bool sent,) = address(_msgSender()).call{value : toRetrieve}("");
        require(sent, "Error: Cannot withdraw BNB");
		emit RetrieveBNBSuccessfully(_msgSender(),toRetrieve);
	}

	function destroy() external onlyOwner {
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
	
	mapping(address => uint256) private _rOwned;
	mapping(address => uint256) private _tOwned;
	mapping(address => mapping(address => uint256)) private _allowances;

	mapping(address => bool) private _isExcludedFromFee;
	mapping(address => bool) private _applyFeeFor;
	mapping(address => bool) private _isTradingWhiteListed;
    mapping(address => bool) private _isExcludedFromReward;
	mapping(address => uint256) private _lockAccount;
    address[] private _excluded;
    
	bool private tradingEnabled;
	bool private noFeeForTransfert;
	bool private noFee;

	uint256 private constant MAX = ~uint256(0);
	uint256 private _tTotal = 21 * 10**6 * 10**18;
	uint256 private _rTotal = (MAX - (MAX % _tTotal));
	uint256 private _tFeeTotal;

	// Pancakeswap pointers
	IPancakeRouter02 public immutable pancakeRouter;
	address public immutable pancakePair;
	address public immutable addressWBNB;
	LeashCashPresale public immutable presale;
	LeashStake public immutable staking;
	address private marketingWallet;
	address private buyBackWallet;
	address private liquidityWallet;

	bool private inSwapAndLiquify = false;

	uint256 private _maxPriceImpactForSwapAndLiquify;
	bool private swapAndLiquifyEnabled;
	
	uint256 private _taxFee;
	uint256 private _liquidityFee;
	uint256 private _marketingFee;
	uint256 private _buyBackFee;

	uint256 private _minBNBToSendToMarketingWallet = 5 * 10 ** 17;
	uint256 private _minBNBToBuyBack = 5 * 10 ** 17;
	
	uint256 private _totalCountBuy;
	uint256 private _totalCountSell;

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
	
	event NewBuyBackWallet(
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
	
	event TradingStatus(
		bool enabled
	);

	constructor (
		address payable routerAddress,
		address _addressWBNB
	) public {
	    // send all tokens to owner
		_rOwned[_msgSender()] = _rTotal;
		// set WBNB contract address
		addressWBNB = _addressWBNB;
		IPancakeRouter02 _pancakeRouter = IPancakeRouter02(routerAddress);
		// Create a pancake pair for this new token
		pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
		// set the pancakeswap router
		pancakeRouter = _pancakeRouter;
		presale = new LeashCashPresale(address(this),_msgSender());
		staking = new LeashStake(address(this),_msgSender());
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
	function isTradingWhiteListed(address account) public view returns (bool) {
		return _isTradingWhiteListed[account];
	}
	
	function isExcludedFromFee(address account) public view returns (bool) {
		return _isExcludedFromFee[account];
	}
	
	function isFeeAppliedOnTransfer(address account) public view returns (bool) {
		return _applyFeeFor[account];
	}

	function getLockTime(address account) public view returns (uint256) {
		return _lockAccount[account];
	}

	function isAccountLocked(address account) public view returns (bool) {
		return _lockAccount[account] > block.timestamp;
	}

	function isTradingEnabled() public view returns (bool) {
		return tradingEnabled;
	}
	
	function isNoFeeForTransfert() public view returns (bool) {
		return noFeeForTransfert;
	}

	function isNoFee() public view returns (bool) {
		return noFee;
	}

	function isSwapAndLiquifyEnabled() public view returns (bool) {
		return swapAndLiquifyEnabled;
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

	function getBuyBackWalletAddress() public view returns (address) {
		return buyBackWallet;
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

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        _excludeFromReward(account);
    }

    function _includeInReward(address account) private {
        if (!_isExcludedFromReward[account]) return;
		if (_excluded.length == 1) {
			_excluded.pop();
			_tOwned[account] = 0;
			_isExcludedFromReward[account] = false;
			return;
		}
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

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already not excluded");
        _includeInReward(account);
    }

	function setTradingEnabled(bool _tradingEnabled) public onlyOwner {
	    // cannot stop trading once launched !
	    if (tradingEnabled) return;
		tradingEnabled = _tradingEnabled;
		emit TradingStatus(tradingEnabled);
	}

	function setNoFeeForTransfert(bool _noFeeForTransfert) public onlyOwner {
		noFeeForTransfert = _noFeeForTransfert;
	}

	function setNoFee(bool _noFee) public onlyOwner {
		noFee = _noFee;
	}

	function setExcludedFromFee(address account,bool value) public onlyOwner {
		_isExcludedFromFee[account] = value;
	}
	
	function setApplyTransferFee(address account,bool value) public onlyOwner {
		_applyFeeFor[account] = value;
	}

	function setTradingWhitelist(address account,bool value) public onlyOwner {
		_isTradingWhiteListed[account] = value;
	}

	function setMaxPriceImpactForSwapAndLiquify(uint256 maxPriceImpact) public onlyOwner {
		_maxPriceImpactForSwapAndLiquify = maxPriceImpact;
	}

	function setMinBNBToSendToMarketingWallet(uint256 value) public onlyOwner {
		_minBNBToSendToMarketingWallet = value;
	}

	function setMinBNBToBuyBack(uint256 value) public onlyOwner {
		_minBNBToBuyBack = value;
	}

	function setSwapAndLiquifyEnabled(bool _swapAndLiquifyEnabled) public onlyOwner {
		swapAndLiquifyEnabled = _swapAndLiquifyEnabled;
		emit SwapAndLiquifyEnabledUpdated(_swapAndLiquifyEnabled);
	}
	
	/**
	 * Once locked an account cannot be unlocked before the locked time
	 */
	function lockAccountForHours(address account,uint256 _hours) public onlyOwner {
		if (_lockAccount[account] < block.timestamp) {
			_lockAccount[account] = block.timestamp + (_hours * 1 hours);
		} else {
			_lockAccount[account] = _lockAccount[account] + (_hours * 1 hours);
		}
		emit LockAccount(account,_lockAccount[account]);
	}
	
	/**
	 * Once locked an account cannot be unlocked before the locked time
	 */
	function lockAccountForMinutes(address account,uint256 _minutes) public onlyOwner {
		if (_lockAccount[account] < block.timestamp) {
			_lockAccount[account] = block.timestamp + (_minutes * 1 minutes);
		} else {
			_lockAccount[account] = _lockAccount[account] + (_minutes * 1 minutes);
		}
		emit LockAccount(account,_lockAccount[account]);
	}

	function whitelistAccount(address account, bool value) public onlyOwner {
		_isTradingWhiteListed[account] = value;
		_isExcludedFromFee[account] = value;
	}

	function setMarketingWallet(address wallet) public onlyOwner {
		address oldWallet = marketingWallet;
		marketingWallet = wallet;
		_isTradingWhiteListed[marketingWallet] = true;
		_isExcludedFromFee[marketingWallet] = true;
		_lockAccount[marketingWallet] = 0;
		if (oldWallet != owner() && oldWallet != marketingWallet) {
			_isTradingWhiteListed[oldWallet] = false;
			_isExcludedFromFee[oldWallet] = false;
			_lockAccount[oldWallet] = 0;
		}
		emit NewMarketingWallet(oldWallet,marketingWallet);
	}

	function setBuyBackWallet(address wallet) public onlyOwner {
		address oldWallet = buyBackWallet;
		buyBackWallet = wallet;
		_isTradingWhiteListed[buyBackWallet] = true;
		_isExcludedFromFee[buyBackWallet] = true;
		_lockAccount[buyBackWallet] = 0;
		if (oldWallet != owner() && oldWallet != buyBackWallet) {
			_isTradingWhiteListed[oldWallet] = false;
			_isExcludedFromFee[oldWallet] = false;
			_lockAccount[oldWallet] = 0;
		}
		emit NewBuyBackWallet(oldWallet,buyBackWallet);
	}

	function setLiquidityWallet(address wallet) public onlyOwner {
		address oldWallet = liquidityWallet;
		liquidityWallet = wallet;
		_isTradingWhiteListed[liquidityWallet] = true;
		_isExcludedFromFee[liquidityWallet] = true;
		_lockAccount[liquidityWallet] = 0;
		if (oldWallet != owner() && oldWallet != liquidityWallet) {
			_isTradingWhiteListed[oldWallet] = false;
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
		
		// cannot transfer or sell if account is locked
		if (_lockAccount[from] > 0) {
			require(_lockAccount[from] <= block.timestamp, "Error: transfer from this account is locked until lock time");
		}
		
		if (noFee || _isExcludedFromFee[from] || _isExcludedFromFee[to] || (noFeeForTransfert && !_applyFeeFor[to] && !_applyFeeFor[from])) {
			_taxFee = 0;
			_liquidityFee = 0;
			_marketingFee = 0;
			_buyBackFee = 0;
		} else {
			uint256 priceImpact = computePriceImpact(amount);
			_taxFee = 3;
			_liquidityFee = 3;
			_marketingFee = 2;
			_buyBackFee = 2;
			// selling
			if (_applyFeeFor[to]) {
			    if (priceImpact >= 20000 && priceImpact < 30000) {
					_taxFee = 4;
					_liquidityFee = 4;
					_marketingFee = 2;
					_buyBackFee = 2;
			    } else
			    if (priceImpact >= 30000 && priceImpact < 50000) {
			        _taxFee = 4;
					_liquidityFee = 4;
					_marketingFee = 3;
					_buyBackFee = 3;
			    } else
			    if (priceImpact >= 50000 && priceImpact < 80000) {
			       _taxFee = 5;
			       _liquidityFee = 5;
					_marketingFee = 3;
					_buyBackFee = 3;
			    } else
			    if (priceImpact >= 80000) {
			        _taxFee = 5;
			        _liquidityFee = 5;
			        _marketingFee = 4;
			        _buyBackFee = 4;
			    }
			} else
			// buying
			if (_applyFeeFor[from]) {
			    if (priceImpact >= 30000 && priceImpact < 50000) {
					_taxFee = 4;
					_liquidityFee = 4;
					_marketingFee = 2;
					_buyBackFee = 2;
			    } else
			    if (priceImpact >= 50000 && priceImpact < 80000) {
			       	_taxFee = 4;
					_liquidityFee = 4;
					_marketingFee = 3;
					_buyBackFee = 3;
			    } else
			    if (priceImpact >= 80000 && priceImpact < 110000) {
			       	_taxFee = 5;
			        _liquidityFee = 5;
			        _marketingFee = 3;
			        _buyBackFee = 3;
			    } else
			    if (priceImpact >= 110000) {
			    	_taxFee = 5;
			        _liquidityFee = 5;
			        _marketingFee = 4;
			        _buyBackFee = 4;
			    }
			}
		}
		// if no fee, no swap and liquify
		if (!noFee) {
			// swap and liquify
			swapAndLiquify(from, to);
		}
		
		if (_applyFeeFor[from]) {
			_totalCountBuy = _totalCountBuy.add(1);
		} else
		if (_applyFeeFor[to]) {
			_totalCountSell = _totalCountSell.add(1);
		}

		//transfer amount, it will take tax, liquidity fee, marketing fee
		_tokenTransfer(from, to, amount);
	}

	//this method is responsible for taking all fee, if takeFee is true
	function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
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
			_sendBNBTo(buyBackWallet,_buyBackBNB);
			_buyBackBNB = 0;
		}
	}
	
	function activateContract() public onlyOwner {
		// exclude owner and this contract from fee
		_isExcludedFromFee[owner()] = true;
		_isExcludedFromFee[address(this)] = true;
		_isExcludedFromFee[address(0x000000000000000000000000000000000000dEaD)] = true;
		_isExcludedFromFee[address(0)] = true;
		_isExcludedFromFee[address(presale)];
		_isExcludedFromFee[address(staking)];
		// Trading whitelisted
		_isTradingWhiteListed[owner()] = true;
		_isTradingWhiteListed[address(this)] = true;
		_isTradingWhiteListed[address(presale)] = true;
		_isTradingWhiteListed[address(staking)] = true;
		// include pancake pair and pancake router in transfert fee:
		_applyFeeFor[address(pancakeRouter)] = true;
		_applyFeeFor[address(pancakePair)] = true;
		// exclude from reward
		_excludeFromReward(owner());
		_excludeFromReward(address(this));
		_excludeFromReward(address(presale));
		_excludeFromReward(address(staking));
		//
		setSwapAndLiquifyEnabled(false);
		setTradingEnabled(false);
		setNoFeeForTransfert(true);
		// once going full trading, fee should be applied, at activation no fees will be applied
		setNoFee(true);
		setMaxPriceImpactForSwapAndLiquify(20000);
		marketingWallet = owner();
		buyBackWallet = owner();
		// LP Tokens are burned by default !
		liquidityWallet = address(0x000000000000000000000000000000000000dEaD);
		// approve contract
		_approve(address(this), address(pancakeRouter), 2 ** 256 - 1);
	}

	// force a swap and liquify
	function forceSwapAndLiquify() external nonReentrant onlyOwner {
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

	function sendBNBTo(address account,uint256 amount) external nonReentrant onlyOwner {
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

	function sendTokensTo(address account,address tokenAddress,uint256 amount) external nonReentrant onlyOwner {
		_sendTokensTo(account,tokenAddress,amount);
	}
}

