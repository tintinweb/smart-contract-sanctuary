/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

//SPDX-License-Identifier: MIT 
pragma solidity 0.6.11; 
pragma experimental ABIEncoderV2;


// File: contracts\@openzeppelin\contracts\GSN\Context.sol
// License: MIT

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

// File: contracts\@openzeppelin\contracts\access\Ownable.sol
// License: MIT


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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
}

// File: contracts\@openzeppelin\contracts\token\ERC20\IERC20.sol
// License: MIT

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

// File: contracts\@openzeppelin\contracts\math\SafeMath.sol
// License: MIT

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

// File: contracts\@openzeppelin\contracts\utils\Address.sol
// License: MIT

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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

// File: contracts\@openzeppelin\contracts\token\ERC20\SafeERC20.sol
// License: MIT




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

// File: contracts\@uniswap\IUniswapV2Pair.sol
// License: MIT

// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
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
  function transferFrom(
    address from,
    address to,
    uint value
  ) external returns (bool);
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);
  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
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
  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);
  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;
  function skim(address to) external;
  function sync() external;
  function initialize(address, address) external;
}

// File: contracts\@uniswap\IUniswapV2Factory.sol
// License: MIT

// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
interface IUniswapV2Factory {
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

// File: contracts\@uniswap\IUniswapV2Router01.sol
// License: MIT

// https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
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
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  )
    external
    payable
    returns (
      uint amountToken,
      uint amountETH,
      uint liquidity
    );
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
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
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
  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);
  function swapTokensForExactETH(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapETHForExactTokens(
    uint amountOut,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);
  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) external pure returns (uint amountB);
  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountOut);
  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path)
    external
    view
    returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path)
    external
    view
    returns (uint[] memory amounts);
}

// File: contracts\@libs\UniswapUtils.sol
//License: MIT








contract UniswapUtils  { 
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 public constant PERCENT = 10000;  
    struct LiquidityItem{
        //remove 
        uint256 tokenRemoved;
        uint256 currencyRemoved;
        uint256 liquidityRemoved;
        //swap
        uint256 currencyIn;
        uint256 tokenOut;
        //add
        uint256 tokenAdded;
        uint256 currencyAdded;
        uint256 liquidityAdded;       
    }
    event LiquidityInfo(address token,address currency,uint256 lpp,uint256 cp,LiquidityItem q,uint256 burnAmount);
    function _getPair(address router,address token0,address token1) internal view returns(address){
        address _factory =  IUniswapV2Router01(router).factory();
        return IUniswapV2Factory(_factory).getPair(token0,token1);
    }
    function _checkOrApproveRouter(address _router,address _token,uint256 _amount) internal{
        if(IERC20(_token).allowance(address(this),_router) < _amount){
            IERC20(_token).safeApprove(_router,0);
            IERC20(_token).safeApprove(_router,uint256(-1));
        }        
    }
    function _swapToken(address router,address tokenIn,address tokenOut,uint256 amountIn) internal returns (uint256){
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut; 
        uint256 exptime = block.timestamp+60;
        _checkOrApproveRouter(router,tokenIn,amountIn); 
        return IUniswapV2Router01(router).swapExactTokensForTokens(amountIn,0,path,address(this),exptime)[1];
    }
    function _addLiquidity(
        address router,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB, uint liquidity){
         uint256 exptime = block.timestamp+60;
        _checkOrApproveRouter(router,tokenA,amountADesired);
        _checkOrApproveRouter(router,tokenB,amountBDesired);
        return IUniswapV2Router01(router).addLiquidity(tokenA,tokenB,amountADesired,amountBDesired,amountAMin,amountBMin,address(this), exptime);
    }
    function _removeLiquidity(
        address router,
        address pair,
        address tokenA,
        address tokenB,
        uint256 lpp 
    ) internal returns (uint amountA, uint amountB,uint256 liquidity){
        uint256 exptime = block.timestamp+60;
        liquidity = IERC20(pair).balanceOf(address(this)).mul(lpp).div(PERCENT);
        _checkOrApproveRouter(router,pair,liquidity);
        (amountA, amountB) = IUniswapV2Router01(router).removeLiquidity(tokenA,tokenB,liquidity,0,0,address(this),exptime);
    }
    function getPairToken(address _pair,address _rewardToken) public view returns(address){
        address token0 = IUniswapV2Pair(_pair).token0();
        address token1 = IUniswapV2Pair(_pair).token1(); 
        require(token0 == _rewardToken || token1 == _rewardToken,"!_rewardToken");
        return _rewardToken == token0 ? token1 : token0;
    } 
}

// File: contracts\@libs\IRewardToken.sol
// License: MIT


interface IRewardToken is IERC20 {
    function cap() external view returns (uint256);
    function mint(address _to, uint256 _amount) external; 
    function burn(uint256 amount) external;
}

// File: contracts\@libs\Authorizable.sol
// License: MIT


contract Authorizable is Ownable {
    mapping(address => bool) public authorized;
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender,"!auth");
        _;
    }
    function addAuthorized(address _toAdd) onlyOwner public {
        authorized[_toAdd] = true;
    }
    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}

// File: contracts\FEIIMasterChef.sol
// License: MIT








// MasterChef is the master of rewardToken. He can make rewardToken and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once rewardToken is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract FEIIMasterChef is Authorizable,UniswapUtils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of rewardTokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accrewardTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accrewardTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. rewardTokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that rewardTokens distribution occurs.
        uint256 accrewardTokenPerShare; // Accumulated rewardTokens per share, times 1e12. See below.
    } 
    // The rewardToken TOKEN!
    IRewardToken public rewardToken;
    address public uniswapRouter;
    // Dev address.
    address public devAddr;
    uint256 public protocolFee = 1000; //1%
    uint256 public devRewardAmount; 
    // rewardToken tokens created per block.
    uint256 public rewardTokenPerBlock; 
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when rewardToken mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount,uint256 rewardToken);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount,uint256 rewardToken);
    constructor(
        address _uniswapRouter,
        address _rewardToken,     
        uint256 _rewardTokenPerBlock,
        uint256 _startBlock 
    ) public {
        rewardToken = IRewardToken(_rewardToken);
        devAddr = msg.sender;
        uniswapRouter = _uniswapRouter;
        rewardTokenPerBlock = _rewardTokenPerBlock; 
        startBlock = _startBlock;    
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyAuthorized {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accrewardTokenPerShare: 0
            })
        );
    }
    // Update the given pool's rewardToken allocation point. Can only be called by the owner.
    function set(uint256 _pid,uint256 _allocPoint, bool _withUpdate) public onlyAuthorized {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }
    function updateDevAddr(address _dev,uint256 _fee) public onlyAuthorized{
        devAddr = _dev;
        protocolFee = _fee;
    }
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256){
        return _to.sub(_from);
    }
    // View function to see pending rewardTokens on frontend.
    function pendingrewardToken(uint256 _pid, address _user)external view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accrewardTokenPerShare = pool.accrewardTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 rewardTokenReward =
                multiplier.mul(rewardTokenPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accrewardTokenPerShare = accrewardTokenPerShare.add(
                rewardTokenReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accrewardTokenPerShare).div(1e12).sub(user.rewardDebt);
    }
    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rewardTokenReward = multiplier.mul(rewardTokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        devRewardAmount = devRewardAmount.add(rewardTokenReward.div(10));
        rewardToken.mint(address(this), rewardTokenReward);
        pool.accrewardTokenPerShare = pool.accrewardTokenPerShare.add(
            rewardTokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }
    // Deposit LP tokens to MasterChef for rewardToken allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        require(block.number >= startBlock,"!start");
        uint256 pending = 0;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender]; 
        updatePool(_pid);
        if (user.amount > 0) {
            pending = user.amount.mul(pool.accrewardTokenPerShare).div(1e12).sub(user.rewardDebt);
            safeRewardTokenTransfer(msg.sender, pending);
        }
        //save gas for claimReward
        if(_amount > 0){
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount); 
            user.amount = user.amount.add(_amount); 
        }
        user.rewardDebt = user.amount.mul(pool.accrewardTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount,pending);
    }
    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        UserInfo storage dever = userInfo[_pid][devAddr];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accrewardTokenPerShare).div(1e12).sub(user.rewardDebt);
        safeRewardTokenTransfer(msg.sender, pending); 
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accrewardTokenPerShare).div(1e12);
        uint256 _fee = _amount.mul(protocolFee).div(PERCENT);
        dever.amount = dever.amount.add(_fee); 
        pool.lpToken.safeTransfer(address(msg.sender), _amount.sub(_fee));
        emit Withdraw(msg.sender, _pid, _amount,pending);
    }
    function claimReward(uint256 _pid) public {
        deposit(_pid,0);
    } 
    function rewardTokenLiquidity(address _pair,uint256 _lpp,uint256 _cp) public onlyAuthorized{ 
        address _token = address(rewardToken);
        //only guard rewardToken 
        address _currency = getPairToken(_pair,_token); 
        LiquidityItem memory q =  LiquidityItem(0,0,0,0,0,0,0,0);
        //removeLiquidity  
        (q.tokenRemoved,q.currencyRemoved,q.liquidityRemoved) = _removeLiquidity(uniswapRouter, _pair, _token, _currency,_lpp);
        //swap rewardToken
        q.currencyIn = q.currencyRemoved.mul(_cp).div(PERCENT);
        q.tokenOut = _swapToken(uniswapRouter,_currency,_token,q.currencyIn);
        //addLiquidity
        uint256 tokenRemain  = q.tokenRemoved.add(q.tokenOut);  
        uint256 currencyRemain =  q.currencyRemoved.sub(q.currencyIn);       
        (q.tokenAdded, q.currencyAdded, q.liquidityAdded) = _addLiquidity(uniswapRouter, _token,_currency,
                                                                         tokenRemain,currencyRemain,
                                                                         0,currencyRemain);
        tokenRemain = tokenRemain.sub(q.tokenAdded);
        //burn rewardToken
        rewardToken.burn(tokenRemain);
        emit LiquidityInfo(_token,_currency,_lpp,_cp,q,tokenRemain); 
    }
    // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough rewardTokens.
    function safeRewardTokenTransfer(address _to, uint256 _amount) internal {
        uint256 rewardTokenBal = rewardToken.balanceOf(address(this));
        if (_amount > rewardTokenBal) {
            rewardToken.transfer(_to, rewardTokenBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }
    function claimDevReward(uint256 _p) public onlyAuthorized{
        require(devRewardAmount > 0,"No community rate"); 
        uint256 _community_amount = devRewardAmount.mul(_p).div(PERCENT);
        devRewardAmount = devRewardAmount.sub(_community_amount);
        rewardToken.mint(msg.sender,_community_amount);   
    } 
    function updateRewardRate(uint256 _rewardTokenPerBlock,uint256 _startBlock) public onlyAuthorized{ 
        rewardTokenPerBlock = _rewardTokenPerBlock;
        startBlock = _startBlock;
    }
}