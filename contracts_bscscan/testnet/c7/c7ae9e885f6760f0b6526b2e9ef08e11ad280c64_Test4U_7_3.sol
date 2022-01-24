/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Made By: 0xb8628ca507A58681F926C87320335D0DdFAa8f24
// Date: 01-01-2022
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.11;





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Interface
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);
  
  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);
 
  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);
  
  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);
 
  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);
 
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
  function allowance(address _owner, address spender) external view returns (uint256);

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





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Contract context
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Library: SafeMath
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;

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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Library: Address
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage
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
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Interface: IUniswapV2Pair
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Collection of functions for UniSwap
 */
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





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Interface: IUniswapV2Factory
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Collection of functions for UniSwap
 */
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





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Interface: IUniswapV2Router01
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Collection of functions for UniswapRouter01
 */
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





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Interface: IUniswapV2Router02
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Collections of functions for UniswapRouter02
 */
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





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Ownable Contract
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
  constructor () {
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
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Contract Test4U: values in constructor
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract Test4U_7_3 is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => bool) private _isExcludedFromFees; // Exclude fees for addresses
  mapping (address => uint256) private _firstBuyTimestamp; // First buy of holder timestamp
  mapping (address => bool) private _blacklist; // Put address on blacklist
  mapping (address => bool) public swapPairAddresses; // Store address that the automatic market maker pairs with

  // Addresses
  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;
  address public constant deadAddress = address(0xfA6d28CAa4b3c0E95d7e48B14e9C840179512Ca6);
  address public developerWallet;
  address public marketingWallet;
  address public liquidityWallet;
  
  // Constant numbers - initialised once
  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
 
  // Booleans
  bool public tradingActive = false;
  bool public swapEnabled = false;
  bool public earlySellFee = true;
  bool public swapping = false;

  // Fees
  uint256 public buyDeveloperFee;          // 3%
  uint256 public buyMarketingFee;          // 3%
  uint256 public buyLiquidityFee;          // 3%
  uint256 public buyTotalFee;              // 9%

  uint256 public sellDeveloperFee;         // 3%
  uint256 public sellMarketingFee;         // 3%
  uint256 public sellLiquidityFee;         // 3%
  uint256 public sellTotalFee;             // 9%

  uint256 public earlySellDeveloperFee;    // 10%
  uint256 public earlySellMarketingFee;    // 10%
  uint256 public earlySellLiquidityFee;    // 10%

  // With release change these 3 to private
  uint256 public previousSellDeveloperFee;
  uint256 public previousSellMarketingFee;
  uint256 public previousSellLiquidityFee;

  uint256 private totalFee;                // Keep track of total fees gathered
  uint256 private totalDeveloperFee;
  uint256 private totalMarketingFee;
  uint256 private totalLiquidityFee;

  // Limits
  uint256 public maxTokenTransferAmount;   // 1% of total supply
  uint256 public maxTokenInWallet;         // 2% of total supply
  uint256 public maxFeeTokenSwap;          // 0.05% of total supply

  // Tokenomics
  uint256 private tokensDeveloper;    // Team - NFT - Game  = 5% of total supply
  uint256 private tokensMarketing;    // Airdrop            = 5% of total supply
  uint256 private tokensLiquidity;    // Pancakeswap        = 40% of total supply

  // Time - block number when trading opened
  uint256 activatedAt;

  //Events
  event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
  event ExcludeFromFees(address indexed account, bool isExcluded);
  event InBlacklist(address indexed account, bool isExcluded);
  event SetSwapPairAddresses(address indexed pair, bool indexed value);
  event DeveloperWalletUpdated(address indexed newWallet, address indexed oldWallet);
  event MarketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
  event LiquidityWalletUpdated(address indexed newWallet, address indexed oldWallet);
  //event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
  //event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);

  constructor() {
    // Initialization
    _name = "Test4U_7_3";
    _symbol = "Test4U_73";
    _decimals = 18;
    _totalSupply = 1 * 1e15 * 1e18;
    _balances[msg.sender] = _totalSupply;

    // If full convert tokens to BNB and send to other wallet
    maxFeeTokenSwap = _totalSupply * 5 / 10000; // 0.05% of total token supply for swap

    // Uniswap
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //TESTNET
    //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    _setSwapPairAddresses(address(uniswapV2Pair), true);

    // Fee values
    uint256 _buyDeveloperFee = 3;
    uint256 _buyMarketingFee = 3;
    uint256 _buyLiquidityFee = 3;
    
    uint256 _sellDeveloperFee = 3;
    uint256 _sellMarketingFee = 3;
    uint256 _sellLiquidityFee = 3;

    uint256 _earlySellDeveloperFee = 10;
    uint256 _earlySellMarketingFee = 10;
    uint256 _earlySellLiquidityFee = 10;

    buyDeveloperFee = _buyDeveloperFee;
    buyMarketingFee = _buyMarketingFee;
    buyLiquidityFee = _buyLiquidityFee;
    buyTotalFee = buyDeveloperFee + buyMarketingFee + buyLiquidityFee;

    sellDeveloperFee = _sellDeveloperFee;
    sellMarketingFee = _sellMarketingFee;
    sellLiquidityFee = _sellLiquidityFee;
    sellTotalFee = sellDeveloperFee + sellMarketingFee + sellLiquidityFee;

    previousSellDeveloperFee = sellDeveloperFee;
    previousSellMarketingFee = sellMarketingFee;
    previousSellLiquidityFee = sellLiquidityFee;

    earlySellDeveloperFee = _earlySellDeveloperFee;
    earlySellMarketingFee = _earlySellMarketingFee;
    earlySellLiquidityFee = _earlySellLiquidityFee;

    // Limits
    uint256 _maxTokenTransferAmount = 1;
    uint256 _maxTokenInWallet = 2;   

    maxTokenTransferAmount = _maxTokenTransferAmount.mul(_totalSupply).div(100);
    maxTokenInWallet = _maxTokenInWallet.mul(_totalSupply).div(100); 


    // Wallets
    developerWallet = address(owner());
    marketingWallet = address(owner());
    liquidityWallet = address(owner());

    // Exclusions
    excludeFromFees(address(owner()), true);
    excludeFromFees(address(this), true);

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  receive() external payable {
    //It executes on calls to the contract 
    //with no data (calldata), e.g. calls made via send() or transfer().
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() public view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
  * @dev Returns total fees gathered.
  */
  function totalFees() public view returns (uint256) {
        return totalFee;
  }

  /**
  * @dev Returns total fees gathered.
  */
  function totalDeveloperFees() public view returns (uint256) {
        return totalDeveloperFee;
  }

 /**
  * @dev Returns total fees gathered.
  */
  function totalMarketingFees() public view returns (uint256) {
        return totalMarketingFee;
  }

 /**
  * @dev Returns total fees gathered.
  */
  function totalLiquidityFees() public view returns (uint256) {
        return totalLiquidityFee;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  // /**
  //  * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
  //  * the total supply.
  //  *
  //  * Requirements
  //  * - `msg.sender` must be the token owner
  //  */
  // function mint(uint256 amount) public onlyOwner returns (bool) {
  //   _mint(_msgSender(), amount);
  //   return true;
  // }





  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // Transfer
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  function _transfer(address from, address to, uint256 amount) private {
    require(from != address(0), "BEP20: transfer from the zero address");
    require(to != address(0), "BEP20: transfer to the zero address");    
    require(!_blacklist[to] && !_blacklist[from], "You have been blacklisted from transfering tokens");
    require(amount <= _balances[from],"You are trying to transfer more than your current balance");
    require(amount > 0, "Transfer amount must be greater than zero");

    // Non-owners will have these restrictions
    if (from != owner() && to != owner() && to != address(0) && to != address(deadAddress) && !swapping) {
        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }
        else {
            // When buy
            if (swapPairAddresses[from]) {
                require(amount <= maxTokenTransferAmount, "Transfer amount is to high");
                require(_balances[to] + amount <= maxTokenInWallet, "Reached max allowed tokens in wallet");
            }
            // When sell
            if (swapPairAddresses[to]) {
                require(amount <= maxTokenTransferAmount, "Transfer amount is to high");
            }
        }
    }

    // set last buy/sell date to first purchase date for new wallet    
    if(!_isExcludedFromFees[to]){
        if(_firstBuyTimestamp[to] == 0) {
            _firstBuyTimestamp[to] == block.timestamp;
        }
    }

    // anti bot logic
    if (block.number <= (activatedAt + 1) && !swapPairAddresses[to] && to != address(uniswapV2Router)) { 
        _blacklist[to] = true;
    }

/////////////////TODO FIX TIMESTAMP
    // Early sell transfer
    bool isSell = swapPairAddresses[to];
    uint256 timeSinceFirstBuy = (block.timestamp.sub(_firstBuyTimestamp[from])).div(24 hours);
    if (isSell && earlySellFee) { // if sell and early sell fees is enabled
        if (_firstBuyTimestamp[from] != 0 && timeSinceFirstBuy < 2) { // If less than 2 days pay more fee
            // Before changing fees remember fee values
            if (sellDeveloperFee != earlySellDeveloperFee && sellMarketingFee != earlySellMarketingFee && sellLiquidityFee != earlySellLiquidityFee) {
                previousSellDeveloperFee = sellDeveloperFee;
                previousSellMarketingFee = sellMarketingFee;
                previousSellLiquidityFee = sellLiquidityFee;
            }     
            // Change fee values to early fee values
            sellDeveloperFee = earlySellDeveloperFee;
            sellMarketingFee = earlySellMarketingFee;
            sellLiquidityFee = earlySellLiquidityFee;
            sellTotalFee = sellDeveloperFee + sellMarketingFee + sellLiquidityFee;
        } else {
            sellDeveloperFee = previousSellDeveloperFee;
            sellMarketingFee = previousSellMarketingFee;
            sellLiquidityFee = previousSellLiquidityFee;
            sellTotalFee = sellDeveloperFee + sellMarketingFee + sellLiquidityFee;
        }
    } else { // if early sell fee disabled
        if (_firstBuyTimestamp[to] == 0) { // set first buy to zero after new purchase
            _firstBuyTimestamp[to] = block.timestamp;
        }

        if (!earlySellFee) {
            sellDeveloperFee = previousSellDeveloperFee;
            sellMarketingFee = previousSellMarketingFee;
            sellLiquidityFee = previousSellLiquidityFee;
            sellTotalFee = sellDeveloperFee + sellMarketingFee + sellLiquidityFee;
        }
    }

    // When limit reached convert fee tokens to bnb and send to external wallet
    if (swapEnabled && !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
         swapping = true;
         transferFeeETH();
         swapping = false;
    }

    // if any account belongs to _isExcludedFromFee account then remove the fee
    bool takeFee = true;
    if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
        takeFee = false;
    }

    // only take fees on buys/sells, not on wallet transfers
    uint256 fees = 0;
    uint256 totalTokens;
    if (takeFee) {
        // on sell
        if (/*swapPairAddresses[to] &&*/ sellTotalFee > 0){
            fees = amount.mul(sellTotalFee).div(100);
            tokensDeveloper = (fees.mul(sellDeveloperFee).div(sellTotalFee));
            tokensMarketing = (fees.mul(sellMarketingFee).div(sellTotalFee));
            tokensLiquidity = (fees.mul(sellLiquidityFee).div(sellTotalFee));

            totalTokens = tokensDeveloper.add(tokensMarketing).add(tokensLiquidity);

            _firstBuyTimestamp[from] = block.timestamp; // update last sale date on sell
        }
        // on buy
        else if (/*swapPairAddresses[from] &&*/ buyTotalFee > 0) {
            fees = amount.mul(buyTotalFee).div(100);
            tokensDeveloper = (fees.mul(buyDeveloperFee).div(buyTotalFee));
            tokensMarketing = (fees.mul(buyMarketingFee).div(buyTotalFee));
            tokensLiquidity = (fees.mul(buyLiquidityFee).div(buyTotalFee));

            totalTokens = tokensDeveloper.add(tokensMarketing).add(tokensLiquidity);
        }

        if (fees > 0){
            _tokenTransfer(from, address(this), totalTokens);
            
            //_tokenTransfer(from, developerWallet, tokensDeveloper);
            //_tokenTransfer(from, marketingWallet, tokensMarketing);
            //_tokenTransfer(from, liquidityWallet, tokensLiquidity);

            totalFee = totalFee.add(fees);  // Only to keep track of fees in contract read
            totalDeveloperFee = totalDeveloperFee.add(tokensDeveloper);
            totalMarketingFee = totalMarketingFee.add(tokensMarketing);
            totalLiquidityFee = totalLiquidityFee.add(tokensLiquidity);
        }
      amount = amount.sub(fees);
    }
     _tokenTransfer(from, to, amount);
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // END: Transfer
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  


  /**
   * @dev The transfer of fees and main transfer
   */
  function _tokenTransfer(address sender, address recipient, uint256 amount) private {
    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);

    emit Transfer(sender, recipient, amount);
  }

  
  /**
   * @dev Function for swapping eth and tokens with wallets
   */
  function swapTokensForEth(uint256 tokenAmount) private {
      // generate the uniswap pair path of token -> weth
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapV2Router.WETH();

      _approve(address(this), address(uniswapV2Router), tokenAmount);

      // make the swap
      uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
          tokenAmount,
          0, // accept any amount of ETH
          path,
          address(this),
          block.timestamp
      );
  }

  // /**
  //  * @dev Function for swapping eth and tokens with smart contract
  //  */
  // function swapETHForTokens(uint256 amount) private {
  //   // generate the uniswap pair path of token -> weth
  //   address[] memory path = new address[](2);
  //   path[0] = uniswapV2Router.WETH();
  //   path[1] = address(this);

  //   // make the swap
  //   uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
  //       0, // accept any amount of Tokens
  //       path,
  //       deadAddress, // Burn address
  //       block.timestamp.add(300)
  //   );
  // }

  // /**
  //  * @dev Add amount of eth to the smart contract
  //  */
  // function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
  //     // approve token transfer to cover all possible scenarios
  //     _approve(address(this), address(uniswapV2Router), tokenAmount);

  //     // add the liquidity
  //     uniswapV2Router.addLiquidityETH{value: ethAmount}(
  //         address(this),
  //         tokenAmount,
  //         0, // slippage is unavoidable
  //         0, // slippage is unavoidable
  //         deadAddress,
  //         block.timestamp
  //     );
  // }

  /**
   * @dev Transfer tokens to BNB when total fee gathered reached limit
   */
  function transferFeeETH() private {
      uint256 developerFeeTokenBalance = totalDeveloperFee;
      uint256 marketingFeeTokenBalance = totalMarketingFee;
      uint256 liquidityFeeTokenBalance = totalLiquidityFee;
      
      uint256 totalFeeTokenBalance = developerFeeTokenBalance + marketingFeeTokenBalance + liquidityFeeTokenBalance;
      uint256 contractBalance = balanceOf(address(this));

      if(totalFeeTokenBalance == 0 || contractBalance == 0) {
        return;
      }

      if(contractBalance > maxFeeTokenSwap.mul(20)) {
          contractBalance = maxFeeTokenSwap.mul(20);
      }

      bool success;
      bool overMaxFeeTokenSwap = totalFeeTokenBalance >= maxFeeTokenSwap;
      if (overMaxFeeTokenSwap && contractBalance > maxFeeTokenSwap) {
         
          uint256 initialETHBalance = address(this).balance;
          
          swapTokensForEth(totalFeeTokenBalance);

          uint256 ethBalance = address(this).balance.sub(initialETHBalance);
          uint256 ethForDeveloper = ethBalance.mul(developerFeeTokenBalance).div(totalFeeTokenBalance);
          uint256 ethForMarketing = ethBalance.mul(marketingFeeTokenBalance).div(totalFeeTokenBalance);
          uint256 ethForLiquidity = ethBalance.mul(liquidityFeeTokenBalance).div(totalFeeTokenBalance);
           
          // Change wallet to bitvavo wallet 
          (success,) = address(developerWallet).call{value: ethForDeveloper}("");
          (success,) = address(marketingWallet).call{value: ethForMarketing}("");
          (success,) = address(liquidityWallet).call{value: ethForLiquidity}("");

          totalDeveloperFee = 0; // Set back to 0
          totalLiquidityFee = 0;
          totalMarketingFee = 0;
      }
  }


  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) private {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }

  /**
   * Once enabled it can never be turned off
   */
  function enableTrading(bool enabled) external onlyOwner {
      tradingActive = enabled;
      swapEnabled = enabled;
      activatedAt = block.number;
  }

  /**
   * Enable and disable converting tokens to BNB
   */
  function enableSwap(bool enabled) external onlyOwner {
      swapEnabled = enabled;
  }

  /**
   * Update tokens to swap
   */
  function updateMaxFeeTokenSwap(uint256 amount) external onlyOwner{
        maxFeeTokenSwap = amount;
    }


  /**
   * Update max tokens you can transfer in one transfer
   */
  function updateMaxTokenTransferAmount(uint256 percOfTotalsupply) external onlyOwner{
        maxTokenTransferAmount = percOfTotalsupply.mul(_totalSupply).div(100);
    }

  /**
   * Update max tokens you can have in your wallet
   */
  function updateMaxTokenInWallet(uint256 percOfTotalsupply) external onlyOwner{
        maxTokenInWallet = percOfTotalsupply.mul(_totalSupply).div(100);
    }

  /**
   * Turn on or off the early sell fee
   */
  function setEarlySellFee(bool onoff) external onlyOwner  {
        earlySellFee = onoff;
    }

  /**
   * Update all buy fees
   */
  function updateBuyFees(uint256 _developerFee, uint256 _marketingFee, uint256 _liquidityFee) external onlyOwner {
        buyDeveloperFee = _developerFee;
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFee = buyDeveloperFee + buyMarketingFee + buyLiquidityFee;

        require(buyTotalFee <= 20, "Must keep fees at 20% or less");
    }

  /**
   * Update all sell fees
   */
  function updateSellFees(uint256 _developerFee, uint256 _marketingFee, uint256 _liquidityFee, 
                          uint256 _earlySellDeveloperFee, uint256 _earlySellMarketingFee, uint256 _earlySellLiquidityFee) external onlyOwner {
        sellDeveloperFee = _developerFee;
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        earlySellDeveloperFee = _earlySellDeveloperFee;
        earlySellMarketingFee = _earlySellMarketingFee;
        earlySellLiquidityFee = _earlySellLiquidityFee;
        previousSellDeveloperFee = _developerFee;
        previousSellMarketingFee = _marketingFee;
        previousSellLiquidityFee = _liquidityFee;
        sellTotalFee = sellDeveloperFee + sellMarketingFee + sellLiquidityFee;
        
        require(sellTotalFee <= 99, "Must keep fees at 99% or less");
    }  

  /**
   * Exclude addresses from buy and sell fees
   */
  function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

  /**
   * Add address to blacklist
   */
  function blacklistAddress (address account, bool isBlacklisted) public onlyOwner {
        _blacklist[account] = isBlacklisted;
        emit InBlacklist(account, isBlacklisted);
    }

  /**
   * Check if address is excluded from fees
   */
  function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

  /**
   * Check if address is excluded from fees
   */
  function inBlacklist(address account) public view returns(bool) {
        return _blacklist[account];
    }

  /**
   * Check if address is excluded from fees
   */
  function isSwapPairAddress(address pair) public view returns(bool) {
        return swapPairAddresses[pair];
    }  

  /**
   * Set the automated market maker pair
   */
  function setSwapPairAddresses(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from swapPairAddresses");
        _setSwapPairAddresses(pair, value);
    }

  /**
   * Set automated market maker pair private
   */
  function _setSwapPairAddresses(address pair, bool value) private {
        swapPairAddresses[pair] = value;
        emit SetSwapPairAddresses(pair, value);
    }

  /**
   * Update developer wallet address
   */
  function updateDeveloperWallet(address payable newWallet) external onlyOwner {
        emit DeveloperWalletUpdated(newWallet, developerWallet);
        developerWallet = newWallet;
        excludeFromFees(address(developerWallet), true);
    }

  /**
   * Update marketing wallet address
   */
  function updateMarketingWallet(address payable newMarketingWallet) external onlyOwner {
        emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
        excludeFromFees(address(marketingWallet), true);
    }

  /**
   * Update liquidity wallet address
   */
  function updateLiquidityWallet(address payable newLiquidityWallet) external onlyOwner {
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
        excludeFromFees(address(liquidityWallet), true);
    }


  // TEST THIS AND MAYBE REMOVE FOR FINAL VERSION
  // We are exposing these functions to be able to manual swap and send
  // in case the token is highly valued
  function manualSwap() external onlyOwner() {
      uint256 contractBalance = balanceOf(address(this));
      swapTokensForEth(contractBalance);
  }
 
  /**
   * @dev Function to send ether directly from contract
   */ 
  function sendViaCall(address payable _to) public payable {
      // Call returns a boolean value indicating success or failure.
      // This is the current recommended method to use.
      
      //uint256 contractETHBalance = address(this).balance;
      (bool sent,) = _to.call{value: msg.value}("");
      require(sent, "Failed to send Ether");
    }


  /**
   * @dev Update router address in case of pancakeswap migration
   */
  function updateUniswapV2Router(address newRouter) external onlyOwner {
      require(newRouter != address(uniswapV2Router));
      IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
      address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
      if (get_pair == address(0)) {
          uniswapV2Pair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
      }
      else {
          uniswapV2Pair = get_pair;
      }
      uniswapV2Router = _newRouter;
  }

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// END
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////