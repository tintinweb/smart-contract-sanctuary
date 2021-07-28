/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
 

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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

contract DogeBooty is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    address private _marketingWalletAddress = 0x37024940342307e195EAE82521B389182d510bE7;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 696969696969  * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Doge Booty";
    string private _symbol = "DogeBooty";
    uint8 private _decimals = 9;
    
    uint256 private _taxFee = 0;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 private _marketingFee = 0;
    uint256 private _previousmarketingFee = _marketingFee;
    uint256 private _liquidityFee = 0;
    uint256 private _previousLiquidityFee = _liquidityFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public _maxTxAmount = 13939393939 *  10**9;
    uint256 private numTokensSellToAddToLiquidity = 13939393939  * 10**9;

    mapping (address => bool) private _isBlackListedBot;
    address[] private _blackListedBots;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _rOwned[owner()] = _rTotal;

         //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);// BSC testnet        
        
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);// BSC mainnet

        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);// Ethereum mainnet for uniswap        

         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;


        // BLACKLIST
        _isBlackListedBot[address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce)] = true;
        _blackListedBots.push(address(0xE031b36b53E53a292a20c5F08fd1658CDdf74fce));

        _isBlackListedBot[address(0xe516bDeE55b0b4e9bAcaF6285130De15589B1345)] = true;
        _blackListedBots.push(address(0xe516bDeE55b0b4e9bAcaF6285130De15589B1345));

        _isBlackListedBot[address(0xa1ceC245c456dD1bd9F2815a6955fEf44Eb4191b)] = true;
        _blackListedBots.push(address(0xa1ceC245c456dD1bd9F2815a6955fEf44Eb4191b));

        _isBlackListedBot[address(0xd7d3EE77D35D0a56F91542D4905b1a2b1CD7cF95)] = true;
        _blackListedBots.push(address(0xd7d3EE77D35D0a56F91542D4905b1a2b1CD7cF95));

        _isBlackListedBot[address(0xFe76f05dc59fEC04184fA0245AD0C3CF9a57b964)] = true;
        _blackListedBots.push(address(0xFe76f05dc59fEC04184fA0245AD0C3CF9a57b964));

        _isBlackListedBot[address(0xDC81a3450817A58D00f45C86d0368290088db848)] = true;
        _blackListedBots.push(address(0xDC81a3450817A58D00f45C86d0368290088db848));

        _isBlackListedBot[address(0x45fD07C63e5c316540F14b2002B085aEE78E3881)] = true;
        _blackListedBots.push(address(0x45fD07C63e5c316540F14b2002B085aEE78E3881));

        _isBlackListedBot[address(0x27F9Adb26D532a41D97e00206114e429ad58c679)] = true;
        _blackListedBots.push(address(0x27F9Adb26D532a41D97e00206114e429ad58c679));
        
        _isBlackListedBot[address(0x37024940342307e195EAE82521B389182d510bE7)] = true;
        _blackListedBots.push(address(0x37024940342307e195EAE82521B389182d510bE7));        


_isBlackListedBot[address(0x34038D33efd1EE4AA2C67b1291413368813A39Cd)] = true;
_blackListedBots.push(address(0x34038D33efd1EE4AA2C67b1291413368813A39Cd));

_isBlackListedBot[address(0xf0031cA48C9D9c05c450bD60e47e359C6A681a48)] = true;
_blackListedBots.push(address(0xf0031cA48C9D9c05c450bD60e47e359C6A681a48));

_isBlackListedBot[address(0x6E556917c309B4BAe098b8202387176d5fC9AAa1)] = true;
_blackListedBots.push(address(0x6E556917c309B4BAe098b8202387176d5fC9AAa1));

_isBlackListedBot[address(0x462b1EaD409980905b276c2182b074d758B32d6e)] = true;
_blackListedBots.push(address(0x462b1EaD409980905b276c2182b074d758B32d6e));

_isBlackListedBot[address(0xA51484F9418600bA56102b5bDc485e7d2e6281FD)] = true;
_blackListedBots.push(address(0xA51484F9418600bA56102b5bDc485e7d2e6281FD));

_isBlackListedBot[address(0xe2A4C53d63f63869d68a2Ce7a0c92409dcd56021)] = true;
_blackListedBots.push(address(0xe2A4C53d63f63869d68a2Ce7a0c92409dcd56021));

_isBlackListedBot[address(0x870b771f5AC8794E982Dd6b88bcd6d055915eA66)] = true;
_blackListedBots.push(address(0x870b771f5AC8794E982Dd6b88bcd6d055915eA66));

_isBlackListedBot[address(0xef68D37f9b2B208155A3d6c6A34E721519208ce0)] = true;
_blackListedBots.push(address(0xef68D37f9b2B208155A3d6c6A34E721519208ce0));

_isBlackListedBot[address(0x476FB6c51f6451453730659cba91BC15Ef159c36)] = true;
_blackListedBots.push(address(0x476FB6c51f6451453730659cba91BC15Ef159c36));

_isBlackListedBot[address(0xC44142E99b138D477e88f40eD9bF45887aF7Cfc6)] = true;
_blackListedBots.push(address(0xC44142E99b138D477e88f40eD9bF45887aF7Cfc6));

_isBlackListedBot[address(0xAA0aFc9886d68480593526e2AF7b98291A4274f6)] = true;
_blackListedBots.push(address(0xAA0aFc9886d68480593526e2AF7b98291A4274f6));

_isBlackListedBot[address(0x48dBaa70ff8C1a831A0Ef285d56c6A20Dc41446f)] = true;
_blackListedBots.push(address(0x48dBaa70ff8C1a831A0Ef285d56c6A20Dc41446f));

_isBlackListedBot[address(0x60F4c76f71b5a5B1e34F488e247b1DB1d543aE03)] = true;
_blackListedBots.push(address(0x60F4c76f71b5a5B1e34F488e247b1DB1d543aE03));

_isBlackListedBot[address(0x99fec0D8A77C2580DEF83D8abA2B712068Be835C)] = true;
_blackListedBots.push(address(0x99fec0D8A77C2580DEF83D8abA2B712068Be835C));

_isBlackListedBot[address(0x2EC57D48c1ED4FA1C87062F5E127C91cdf5a2685)] = true;
_blackListedBots.push(address(0x2EC57D48c1ED4FA1C87062F5E127C91cdf5a2685));

_isBlackListedBot[address(0x71B20FE7CC112d766Bc214A814A5BFcfE4BB4F59)] = true;
_blackListedBots.push(address(0x71B20FE7CC112d766Bc214A814A5BFcfE4BB4F59));

_isBlackListedBot[address(0x0d5103360d5674902A24600a799e4cb142136E76)] = true;
_blackListedBots.push(address(0x0d5103360d5674902A24600a799e4cb142136E76));

_isBlackListedBot[address(0xB60CCb3f203419fC65C01Ed3b5B8A31421c68584)] = true;
_blackListedBots.push(address(0xB60CCb3f203419fC65C01Ed3b5B8A31421c68584));

_isBlackListedBot[address(0x9CD7026f9Bc1E9615B22EB6FB37E012A10257748)] = true;
_blackListedBots.push(address(0x9CD7026f9Bc1E9615B22EB6FB37E012A10257748));

_isBlackListedBot[address(0x78F89eF4a22dF1A78eFCb31a8799921fD99240aC)] = true;
_blackListedBots.push(address(0x78F89eF4a22dF1A78eFCb31a8799921fD99240aC));

_isBlackListedBot[address(0x1b761Fb1212aa31D29504BD44CEAbAF9F30b778a)] = true;
_blackListedBots.push(address(0x1b761Fb1212aa31D29504BD44CEAbAF9F30b778a));

_isBlackListedBot[address(0x43A3D9a87C1A2cc05091019d703a3AcBA9376A32)] = true;
_blackListedBots.push(address(0x43A3D9a87C1A2cc05091019d703a3AcBA9376A32));

_isBlackListedBot[address(0x9A54a433f9017B04d056932Ad9333394759EeE3f)] = true;
_blackListedBots.push(address(0x9A54a433f9017B04d056932Ad9333394759EeE3f));

_isBlackListedBot[address(0x8d1D8ad45e13116D9092A0BE4dcE4e065d7B4910)] = true;
_blackListedBots.push(address(0x8d1D8ad45e13116D9092A0BE4dcE4e065d7B4910));

_isBlackListedBot[address(0x065F5F762F85D590B6E579b3ef54EdF759bB36F6)] = true;
_blackListedBots.push(address(0x065F5F762F85D590B6E579b3ef54EdF759bB36F6));

_isBlackListedBot[address(0x00E9525174f2926f08f5dEE76dCcFF6cf0588022)] = true;
_blackListedBots.push(address(0x00E9525174f2926f08f5dEE76dCcFF6cf0588022));

_isBlackListedBot[address(0x95A45aE3fC8116E590AD5E10aD0032F3B0116eC9)] = true;
_blackListedBots.push(address(0x95A45aE3fC8116E590AD5E10aD0032F3B0116eC9));

_isBlackListedBot[address(0x063bA25AC8EE03b2cf2d171b70127a5145D95B9E)] = true;
_blackListedBots.push(address(0x063bA25AC8EE03b2cf2d171b70127a5145D95B9E));

_isBlackListedBot[address(0x7176FE56bfBe1c80862A5bb05c18F7Ab51240E74)] = true;
_blackListedBots.push(address(0x7176FE56bfBe1c80862A5bb05c18F7Ab51240E74));

_isBlackListedBot[address(0xB8f5Ac54BB1242E95fBa72004385ff6c427Ab4ba)] = true;
_blackListedBots.push(address(0xB8f5Ac54BB1242E95fBa72004385ff6c427Ab4ba));

_isBlackListedBot[address(0x3Dd7828Da661D2985A0426e72D30C50cc148bFe1)] = true;
_blackListedBots.push(address(0x3Dd7828Da661D2985A0426e72D30C50cc148bFe1));

_isBlackListedBot[address(0x717c9A6BAd70F1f06ED356599e2C38cA140F5e2E)] = true;
_blackListedBots.push(address(0x717c9A6BAd70F1f06ED356599e2C38cA140F5e2E));

_isBlackListedBot[address(0xCF2892C783447af78aa8EB9773746Fe2341952Ee)] = true;
_blackListedBots.push(address(0xCF2892C783447af78aa8EB9773746Fe2341952Ee));

_isBlackListedBot[address(0x10CDa37F1FBF77C74923005605d07034D5702b2f)] = true;
_blackListedBots.push(address(0x10CDa37F1FBF77C74923005605d07034D5702b2f));

_isBlackListedBot[address(0xbc840462b800dA2b50E062FeBDC4BF9837ed5e55)] = true;
_blackListedBots.push(address(0xbc840462b800dA2b50E062FeBDC4BF9837ed5e55));

_isBlackListedBot[address(0xE7F070675EF785AE33F8eC4a5D8625F68D67Dc83)] = true;
_blackListedBots.push(address(0xE7F070675EF785AE33F8eC4a5D8625F68D67Dc83));

_isBlackListedBot[address(0x2F62376D58651829773cE26F218230D5243336ed)] = true;
_blackListedBots.push(address(0x2F62376D58651829773cE26F218230D5243336ed));

_isBlackListedBot[address(0x1a34F414B71B73625E6743E836e69Db0A44b01fC)] = true;
_blackListedBots.push(address(0x1a34F414B71B73625E6743E836e69Db0A44b01fC));

_isBlackListedBot[address(0x331EaFa3f2b4973cB9eCe3A884Ccc3cB9C171ce7)] = true;
_blackListedBots.push(address(0x331EaFa3f2b4973cB9eCe3A884Ccc3cB9C171ce7));

_isBlackListedBot[address(0xf1be21dC09b451c13BA05B25F843c4F878fcAd0F)] = true;
_blackListedBots.push(address(0xf1be21dC09b451c13BA05B25F843c4F878fcAd0F));

_isBlackListedBot[address(0x055743f3806bc0D7CADa584829327dE4666110c6)] = true;
_blackListedBots.push(address(0x055743f3806bc0D7CADa584829327dE4666110c6));

_isBlackListedBot[address(0x483F664E0Dd55e79f41bDfAb77D473CE1E619a68)] = true;
_blackListedBots.push(address(0x483F664E0Dd55e79f41bDfAb77D473CE1E619a68));

_isBlackListedBot[address(0x23047fFc712b48Bb07440003B81ca49306c3EeBB)] = true;
_blackListedBots.push(address(0x23047fFc712b48Bb07440003B81ca49306c3EeBB));

_isBlackListedBot[address(0x1574066ee8117747E8C69a17df8518554abC100B)] = true;
_blackListedBots.push(address(0x1574066ee8117747E8C69a17df8518554abC100B));

_isBlackListedBot[address(0xeBF38EFE0D7baEEFC1C85Df31BC3509eE5c1b1CC)] = true;
_blackListedBots.push(address(0xeBF38EFE0D7baEEFC1C85Df31BC3509eE5c1b1CC));

_isBlackListedBot[address(0xb38666B4D6b9B2d063EF471b608223bB601fa1A4)] = true;
_blackListedBots.push(address(0xb38666B4D6b9B2d063EF471b608223bB601fa1A4));

_isBlackListedBot[address(0x62BE0a69E9e2b76843Fe722F55204db0616CFAEA)] = true;
_blackListedBots.push(address(0x62BE0a69E9e2b76843Fe722F55204db0616CFAEA));

_isBlackListedBot[address(0x000000000056880eCD46F9372bAA7695BF448029)] = true;
_blackListedBots.push(address(0x000000000056880eCD46F9372bAA7695BF448029));

_isBlackListedBot[address(0x72bE3046Db1FDd90c2E5934287AeeBF6ad2d6E43)] = true;
_blackListedBots.push(address(0x72bE3046Db1FDd90c2E5934287AeeBF6ad2d6E43));

_isBlackListedBot[address(0x0Ae38AA9D4B01be81E831D15Bc1D934ad6d08def)] = true;
_blackListedBots.push(address(0x0Ae38AA9D4B01be81E831D15Bc1D934ad6d08def));

_isBlackListedBot[address(0x2838f2c00e1B5677D10C387c0861d673e5e8dDB2)] = true;
_blackListedBots.push(address(0x2838f2c00e1B5677D10C387c0861d673e5e8dDB2));

_isBlackListedBot[address(0x57b1a1c3b57e0f7AdCf0E40DE2781516643571b3)] = true;
_blackListedBots.push(address(0x57b1a1c3b57e0f7AdCf0E40DE2781516643571b3));

_isBlackListedBot[address(0x830bC83E6881F18864734bc50fa1Dd29Ba3EAB29)] = true;
_blackListedBots.push(address(0x830bC83E6881F18864734bc50fa1Dd29Ba3EAB29));

_isBlackListedBot[address(0x576B10b946A3843395B3f8833A2AfdEfBbDDF572)] = true;
_blackListedBots.push(address(0x576B10b946A3843395B3f8833A2AfdEfBbDDF572));

_isBlackListedBot[address(0x84155A4344f4cb23a37717D3B30615FfB38B68A0)] = true;
_blackListedBots.push(address(0x84155A4344f4cb23a37717D3B30615FfB38B68A0));

_isBlackListedBot[address(0x370B62c1FB9aca457267CC7CDc5dfedDD7495B7d)] = true;
_blackListedBots.push(address(0x370B62c1FB9aca457267CC7CDc5dfedDD7495B7d));

_isBlackListedBot[address(0x19785e776741099F01e1BFAFCf8ECdc5CEb7311A)] = true;
_blackListedBots.push(address(0x19785e776741099F01e1BFAFCf8ECdc5CEb7311A));

_isBlackListedBot[address(0xf8A1021Ed947F3681052eff08B6908A4249255Af)] = true;
_blackListedBots.push(address(0xf8A1021Ed947F3681052eff08B6908A4249255Af));

_isBlackListedBot[address(0xA49a4e8Be6904165159700b247820D0b7658CA73)] = true;
_blackListedBots.push(address(0xA49a4e8Be6904165159700b247820D0b7658CA73));

_isBlackListedBot[address(0x02b660d80deBF2c0C5173657191bcE80c56e0151)] = true;
_blackListedBots.push(address(0x02b660d80deBF2c0C5173657191bcE80c56e0151));

_isBlackListedBot[address(0x97074175Ca2b09EA55bE1Bab2574D8e80eB6B77B)] = true;
_blackListedBots.push(address(0x97074175Ca2b09EA55bE1Bab2574D8e80eB6B77B));

_isBlackListedBot[address(0xbe52b2360BaDa23B742f84BB7751e1DFC358f3D0)] = true;
_blackListedBots.push(address(0xbe52b2360BaDa23B742f84BB7751e1DFC358f3D0));

_isBlackListedBot[address(0xaC8Fd90fb4e4946adfF5B644859BB8dbA0BaE52c)] = true;
_blackListedBots.push(address(0xaC8Fd90fb4e4946adfF5B644859BB8dbA0BaE52c));

_isBlackListedBot[address(0x7c1Bf85620C80F26F8218Bb5beB689CB65464f2A)] = true;
_blackListedBots.push(address(0x7c1Bf85620C80F26F8218Bb5beB689CB65464f2A));

_isBlackListedBot[address(0xeE356a4fC3316FBe053c840806D821385B438767)] = true;
_blackListedBots.push(address(0xeE356a4fC3316FBe053c840806D821385B438767));

_isBlackListedBot[address(0x6125290e835AB0F62BE45Ffe6f2851186Fd726c6)] = true;
_blackListedBots.push(address(0x6125290e835AB0F62BE45Ffe6f2851186Fd726c6));

_isBlackListedBot[address(0x1a694EfE6e1894D4D54D35588694E264130A2781)] = true;
_blackListedBots.push(address(0x1a694EfE6e1894D4D54D35588694E264130A2781));

_isBlackListedBot[address(0x4163C89Db72EF5F8ECdD20d3c6e1261246679f90)] = true;
_blackListedBots.push(address(0x4163C89Db72EF5F8ECdD20d3c6e1261246679f90));

_isBlackListedBot[address(0x62758c4307F72E76aD35b7d8623BB5a5Bb44eb1E)] = true;
_blackListedBots.push(address(0x62758c4307F72E76aD35b7d8623BB5a5Bb44eb1E));

_isBlackListedBot[address(0x58004AC8aD3CB738E3762137E8c502ff92A0C55A)] = true;
_blackListedBots.push(address(0x58004AC8aD3CB738E3762137E8c502ff92A0C55A));

_isBlackListedBot[address(0xc8D9d115e8fA59c815B96E484ab7b4b0A32CC7bE)] = true;
_blackListedBots.push(address(0xc8D9d115e8fA59c815B96E484ab7b4b0A32CC7bE));

_isBlackListedBot[address(0x472e24363D99964c001f43Dc31e98B782c3CEA98)] = true;
_blackListedBots.push(address(0x472e24363D99964c001f43Dc31e98B782c3CEA98));

_isBlackListedBot[address(0x57d69A828f8187113e757bEce68778D78FA328c3)] = true;
_blackListedBots.push(address(0x57d69A828f8187113e757bEce68778D78FA328c3));

_isBlackListedBot[address(0x4Fbb2102a1a790347422f9604a0acDbd1B0699B3)] = true;
_blackListedBots.push(address(0x4Fbb2102a1a790347422f9604a0acDbd1B0699B3));

_isBlackListedBot[address(0x98342aBf8b62D51580179ae65a04e523f54f20AB)] = true;
_blackListedBots.push(address(0x98342aBf8b62D51580179ae65a04e523f54f20AB));

_isBlackListedBot[address(0x152FA1816e8C4D212ffC7ac982eDb14E698C4cAB)] = true;
_blackListedBots.push(address(0x152FA1816e8C4D212ffC7ac982eDb14E698C4cAB));

_isBlackListedBot[address(0x6aB21A9B10d55197fd20015B565E4f9DdA92526c)] = true;
_blackListedBots.push(address(0x6aB21A9B10d55197fd20015B565E4f9DdA92526c));

_isBlackListedBot[address(0x14f8e88D8e0061A7D5a28419d7A8509c6E753E7e)] = true;
_blackListedBots.push(address(0x14f8e88D8e0061A7D5a28419d7A8509c6E753E7e));

_isBlackListedBot[address(0xC3340Ed99a5c473141DdC6bE20238C5454Bd670a)] = true;
_blackListedBots.push(address(0xC3340Ed99a5c473141DdC6bE20238C5454Bd670a));

_isBlackListedBot[address(0xA3eec546802Cedd1B16527C70E6d8728aa10eB64)] = true;
_blackListedBots.push(address(0xA3eec546802Cedd1B16527C70E6d8728aa10eB64));

_isBlackListedBot[address(0x41cEe9aB9683Fbfa63901C69dD1665Faffb91a1E)] = true;
_blackListedBots.push(address(0x41cEe9aB9683Fbfa63901C69dD1665Faffb91a1E));

_isBlackListedBot[address(0x440BD23858e50918895171F24D4e142E5A1Abe39)] = true;
_blackListedBots.push(address(0x440BD23858e50918895171F24D4e142E5A1Abe39));

_isBlackListedBot[address(0x6E657fEb306905446C7e2f4937A03938c9F5cE1f)] = true;
_blackListedBots.push(address(0x6E657fEb306905446C7e2f4937A03938c9F5cE1f));

_isBlackListedBot[address(0x0f5785E5Fa74586E17A2bFDC404a937B309417f4)] = true;
_blackListedBots.push(address(0x0f5785E5Fa74586E17A2bFDC404a937B309417f4));

_isBlackListedBot[address(0xf1101AF074054aBcC9F07e9E4329162dFA64f24a)] = true;
_blackListedBots.push(address(0xf1101AF074054aBcC9F07e9E4329162dFA64f24a));

_isBlackListedBot[address(0xA26e58cF73FF7AEB173D3f83cEa3d58b30039951)] = true;
_blackListedBots.push(address(0xA26e58cF73FF7AEB173D3f83cEa3d58b30039951));

_isBlackListedBot[address(0x64e7991c28BA8e85E245b925a56eA497b46D8559)] = true;
_blackListedBots.push(address(0x64e7991c28BA8e85E245b925a56eA497b46D8559));

_isBlackListedBot[address(0xE919a9FDD81AF9aB292f0C84f086B2bC48249256)] = true;
_blackListedBots.push(address(0xE919a9FDD81AF9aB292f0C84f086B2bC48249256));

_isBlackListedBot[address(0x67cE108D314c2e7338e5e8902E1b4e010dfB0C5e)] = true;
_blackListedBots.push(address(0x67cE108D314c2e7338e5e8902E1b4e010dfB0C5e));

_isBlackListedBot[address(0xD88291Aa7CB1De0aC1De924d7B3FE55E345635CE)] = true;
_blackListedBots.push(address(0xD88291Aa7CB1De0aC1De924d7B3FE55E345635CE));

_isBlackListedBot[address(0xB758B3B2a32b9259b00E8E07388DcF50EfB3797D)] = true;
_blackListedBots.push(address(0xB758B3B2a32b9259b00E8E07388DcF50EfB3797D));

_isBlackListedBot[address(0xa3fdE445572Cd9e925794228b11850fDAAf291eE)] = true;
_blackListedBots.push(address(0xa3fdE445572Cd9e925794228b11850fDAAf291eE));

_isBlackListedBot[address(0x146c23C6c749D680107a1bE9A2737DcA9AE619C6)] = true;
_blackListedBots.push(address(0x146c23C6c749D680107a1bE9A2737DcA9AE619C6));

_isBlackListedBot[address(0xc8FAd906ECa0e76ABD38bA25Cb9f757d8e146233)] = true;
_blackListedBots.push(address(0xc8FAd906ECa0e76ABD38bA25Cb9f757d8e146233));

_isBlackListedBot[address(0x193eFe650cdE3D4A87F9399F1B1ca644C38b5048)] = true;
_blackListedBots.push(address(0x193eFe650cdE3D4A87F9399F1B1ca644C38b5048));

_isBlackListedBot[address(0xC83165A9C3E9F181A37624EA3777871c5494db0c)] = true;
_blackListedBots.push(address(0xC83165A9C3E9F181A37624EA3777871c5494db0c));

_isBlackListedBot[address(0x448c16642B7FBd17d6364b888F17D754A36c7D6B)] = true;
_blackListedBots.push(address(0x448c16642B7FBd17d6364b888F17D754A36c7D6B));

_isBlackListedBot[address(0x8ebf66A56b757678795E52709658524cF14d44d6)] = true;
_blackListedBots.push(address(0x8ebf66A56b757678795E52709658524cF14d44d6));

_isBlackListedBot[address(0x07A9F831Fe34C91A69E7c19566A8E1E8F855E2B8)] = true;
_blackListedBots.push(address(0x07A9F831Fe34C91A69E7c19566A8E1E8F855E2B8));

_isBlackListedBot[address(0x8273e87C68E96DA0B89e9e9008463Db2f779BBe0)] = true;
_blackListedBots.push(address(0x8273e87C68E96DA0B89e9e9008463Db2f779BBe0));

_isBlackListedBot[address(0x4Ec758cf76cd3eD9B600B68d429BFC5ba0841D27)] = true;
_blackListedBots.push(address(0x4Ec758cf76cd3eD9B600B68d429BFC5ba0841D27));

_isBlackListedBot[address(0xf96206abAaa65246B57e1cA19c26b18ff4819c96)] = true;
_blackListedBots.push(address(0xf96206abAaa65246B57e1cA19c26b18ff4819c96));

_isBlackListedBot[address(0x0f1926bdE9a71A556c7AD8C8ec0A167182E33853)] = true;
_blackListedBots.push(address(0x0f1926bdE9a71A556c7AD8C8ec0A167182E33853));

_isBlackListedBot[address(0x6F6378101E34E5619A2612f70e53B61E6B8cD93D)] = true;
_blackListedBots.push(address(0x6F6378101E34E5619A2612f70e53B61E6B8cD93D));

_isBlackListedBot[address(0xd9874a8B47606Fa646778Bd9E93935c302a098C6)] = true;
_blackListedBots.push(address(0xd9874a8B47606Fa646778Bd9E93935c302a098C6));

_isBlackListedBot[address(0x07CefBA6aC7B583269f95EF8A24dE74835CE5Cb5)] = true;
_blackListedBots.push(address(0x07CefBA6aC7B583269f95EF8A24dE74835CE5Cb5));

_isBlackListedBot[address(0xbC44BcB433034eC5FaA2907D469f0be56dAa114f)] = true;
_blackListedBots.push(address(0xbC44BcB433034eC5FaA2907D469f0be56dAa114f));

_isBlackListedBot[address(0xdB6ea68095B89d0A6578AF20B23B95b4A6175127)] = true;
_blackListedBots.push(address(0xdB6ea68095B89d0A6578AF20B23B95b4A6175127));

_isBlackListedBot[address(0xe8199F30cB76401BcdE8fBF03B26507Aa40b5DdD)] = true;
_blackListedBots.push(address(0xe8199F30cB76401BcdE8fBF03B26507Aa40b5DdD));

_isBlackListedBot[address(0x212fF33420a144d9f4bf99aAadF671D3303b28BA)] = true;
_blackListedBots.push(address(0x212fF33420a144d9f4bf99aAadF671D3303b28BA));

_isBlackListedBot[address(0xCBDb13e7a9a27F02D9F989239e4c3d3909091604)] = true;
_blackListedBots.push(address(0xCBDb13e7a9a27F02D9F989239e4c3d3909091604));

_isBlackListedBot[address(0xE576ee66af692C3f2E3aAD1b3b185C7E4606A8B5)] = true;
_blackListedBots.push(address(0xE576ee66af692C3f2E3aAD1b3b185C7E4606A8B5));

_isBlackListedBot[address(0x2A1D1EE2FBf5821EC80ECfCf66a948783b48cda8)] = true;
_blackListedBots.push(address(0x2A1D1EE2FBf5821EC80ECfCf66a948783b48cda8));

_isBlackListedBot[address(0x1207ACE450241ed3D4034Ee595dd7673a420D838)] = true;
_blackListedBots.push(address(0x1207ACE450241ed3D4034Ee595dd7673a420D838));

_isBlackListedBot[address(0x0DE49a0983190D1FEAdC8fF5DB8e3Ed7C7f61914)] = true;
_blackListedBots.push(address(0x0DE49a0983190D1FEAdC8fF5DB8e3Ed7C7f61914));

_isBlackListedBot[address(0xA62d7285E66D2e28224ee122Ec00bbf412988427)] = true;
_blackListedBots.push(address(0xA62d7285E66D2e28224ee122Ec00bbf412988427));

_isBlackListedBot[address(0xC1DE4357f5b56b8e5822F4821F08a15FFfbA391E)] = true;
_blackListedBots.push(address(0xC1DE4357f5b56b8e5822F4821F08a15FFfbA391E));

_isBlackListedBot[address(0xB6c3E2A88F28F130b82773eE9b1018D724721Ae2)] = true;
_blackListedBots.push(address(0xB6c3E2A88F28F130b82773eE9b1018D724721Ae2));

_isBlackListedBot[address(0xAdD40FC50b096bbd85B25D1507861d11dD087419)] = true;
_blackListedBots.push(address(0xAdD40FC50b096bbd85B25D1507861d11dD087419));

_isBlackListedBot[address(0xAFe876422fF1460365e43CdfC1c0c07798CD9fb6)] = true;
_blackListedBots.push(address(0xAFe876422fF1460365e43CdfC1c0c07798CD9fb6));

_isBlackListedBot[address(0x5eFcd5a954D68Ea64dFD4cE3044aE87726Ae9c3E)] = true;
_blackListedBots.push(address(0x5eFcd5a954D68Ea64dFD4cE3044aE87726Ae9c3E));

_isBlackListedBot[address(0xCF179269093F59d940E180343c6830473221705b)] = true;
_blackListedBots.push(address(0xCF179269093F59d940E180343c6830473221705b));

_isBlackListedBot[address(0x5ABA6981f17cB8255AF7fe3c3c2Af313c98945a3)] = true;
_blackListedBots.push(address(0x5ABA6981f17cB8255AF7fe3c3c2Af313c98945a3));

_isBlackListedBot[address(0x1E582aee1dC22d11e809E37C4CC7ad2BeB52DBC4)] = true;
_blackListedBots.push(address(0x1E582aee1dC22d11e809E37C4CC7ad2BeB52DBC4));

_isBlackListedBot[address(0x5ba8ad124453caE043B926955F2433F11F6D3d06)] = true;
_blackListedBots.push(address(0x5ba8ad124453caE043B926955F2433F11F6D3d06));

_isBlackListedBot[address(0x1DaCfC44c2fdB9a7B5125DF3cAA5b4eF2E420EAb)] = true;
_blackListedBots.push(address(0x1DaCfC44c2fdB9a7B5125DF3cAA5b4eF2E420EAb));

_isBlackListedBot[address(0xDcACb95ebf8705BA6c64621913987E5C42CdAf4b)] = true;
_blackListedBots.push(address(0xDcACb95ebf8705BA6c64621913987E5C42CdAf4b));

_isBlackListedBot[address(0x74E9BDeFD6C02c3f424F7a4F8d73f7F7F9cf29e5)] = true;
_blackListedBots.push(address(0x74E9BDeFD6C02c3f424F7a4F8d73f7F7F9cf29e5));

_isBlackListedBot[address(0x2948ceFbB62589D50EEdEB6C84DFedf8232ad591)] = true;
_blackListedBots.push(address(0x2948ceFbB62589D50EEdEB6C84DFedf8232ad591));

_isBlackListedBot[address(0xe09CCFfC18eBCdb76f8F4F3c01397Ab581e1af8B)] = true;
_blackListedBots.push(address(0xe09CCFfC18eBCdb76f8F4F3c01397Ab581e1af8B));

_isBlackListedBot[address(0x09a99793cfE86b27740D62719DA66251Df67fB66)] = true;
_blackListedBots.push(address(0x09a99793cfE86b27740D62719DA66251Df67fB66));

_isBlackListedBot[address(0x824eb9faDFb377394430d2744fa7C42916DE3eCe)] = true;
_blackListedBots.push(address(0x824eb9faDFb377394430d2744fa7C42916DE3eCe));

_isBlackListedBot[address(0x92b4167541780138E3d249ABcBd6AeAB5a35f035)] = true;
_blackListedBots.push(address(0x92b4167541780138E3d249ABcBd6AeAB5a35f035));

_isBlackListedBot[address(0x8ad0AE3F933a735A02C06c92E66B51C45D35e4A8)] = true;
_blackListedBots.push(address(0x8ad0AE3F933a735A02C06c92E66B51C45D35e4A8));

_isBlackListedBot[address(0x0E5bBF08D28e4cf401307321afB0b44ce1b5C426)] = true;
_blackListedBots.push(address(0x0E5bBF08D28e4cf401307321afB0b44ce1b5C426));

_isBlackListedBot[address(0x33Af00Ba072101b65078D34624ec19B07dEb2723)] = true;
_blackListedBots.push(address(0x33Af00Ba072101b65078D34624ec19B07dEb2723));

_isBlackListedBot[address(0x4dF905C0b749a0C6C82107997D61d275A7C86AB9)] = true;
_blackListedBots.push(address(0x4dF905C0b749a0C6C82107997D61d275A7C86AB9));

_isBlackListedBot[address(0x37d73351cE8CDA0849002F7bbe593a8a252c30A2)] = true;
_blackListedBots.push(address(0x37d73351cE8CDA0849002F7bbe593a8a252c30A2));

_isBlackListedBot[address(0xf3A0e4b1e643C7c34dFC4ab20539D2AF7682437A)] = true;
_blackListedBots.push(address(0xf3A0e4b1e643C7c34dFC4ab20539D2AF7682437A));

_isBlackListedBot[address(0xe98f2a90BD918A1b0C1D90005c8AE6BDBA87D8F3)] = true;
_blackListedBots.push(address(0xe98f2a90BD918A1b0C1D90005c8AE6BDBA87D8F3));

_isBlackListedBot[address(0xfb548Dba2eD198adD56DF8C9e63724c4D2393DCb)] = true;
_blackListedBots.push(address(0xfb548Dba2eD198adD56DF8C9e63724c4D2393DCb));

_isBlackListedBot[address(0x8e246ca6aB3EDB234d8E2C7d6B07069E249c4d65)] = true;
_blackListedBots.push(address(0x8e246ca6aB3EDB234d8E2C7d6B07069E249c4d65));

_isBlackListedBot[address(0xa8a278E3725a72c1BB6aBef927B87FaC2EF75ECE)] = true;
_blackListedBots.push(address(0xa8a278E3725a72c1BB6aBef927B87FaC2EF75ECE));

_isBlackListedBot[address(0xe936DA35aC456f9A2641ba43f1a537D1e7743314)] = true;
_blackListedBots.push(address(0xe936DA35aC456f9A2641ba43f1a537D1e7743314));

_isBlackListedBot[address(0x2644Bb06649DB068fa54011B60234b073673692F)] = true;
_blackListedBots.push(address(0x2644Bb06649DB068fa54011B60234b073673692F));

_isBlackListedBot[address(0x06a18C04b28EB28EdeAeCea028874F5f8c49eAF5)] = true;
_blackListedBots.push(address(0x06a18C04b28EB28EdeAeCea028874F5f8c49eAF5));

_isBlackListedBot[address(0x49d4645abD04784217e818f1C6f7961558d56a80)] = true;
_blackListedBots.push(address(0x49d4645abD04784217e818f1C6f7961558d56a80));

_isBlackListedBot[address(0xf07D3C5C01839c3EF51c819D7B0b361c898977a7)] = true;
_blackListedBots.push(address(0xf07D3C5C01839c3EF51c819D7B0b361c898977a7));

_isBlackListedBot[address(0x1f88D9C67C3CC04A6c281200e19df139Af70Ba12)] = true;
_blackListedBots.push(address(0x1f88D9C67C3CC04A6c281200e19df139Af70Ba12));

_isBlackListedBot[address(0xbD93987459DAdcc76c6778871fb84d3b11486502)] = true;
_blackListedBots.push(address(0xbD93987459DAdcc76c6778871fb84d3b11486502));

_isBlackListedBot[address(0x7D062AF092e3dc840636798eB7BbCed35cd2130C)] = true;
_blackListedBots.push(address(0x7D062AF092e3dc840636798eB7BbCed35cd2130C));

_isBlackListedBot[address(0x400736912253Ed9312fc6bDabe2ED456655FE458)] = true;
_blackListedBots.push(address(0x400736912253Ed9312fc6bDabe2ED456655FE458));

_isBlackListedBot[address(0x32F0B86F893233abB0999f9Ec72eC4A0fe24A884)] = true;
_blackListedBots.push(address(0x32F0B86F893233abB0999f9Ec72eC4A0fe24A884));

_isBlackListedBot[address(0xC2dD1C4eaD61B03C37d8CE6578480BD149d38941)] = true;
_blackListedBots.push(address(0xC2dD1C4eaD61B03C37d8CE6578480BD149d38941));

_isBlackListedBot[address(0xfef33678088DB8D8A35E78b57a48857f44f68FBE)] = true;
_blackListedBots.push(address(0xfef33678088DB8D8A35E78b57a48857f44f68FBE));

_isBlackListedBot[address(0x1E94b256C7B0B07c7c0AEd932d12F03034c601Ab)] = true;
_blackListedBots.push(address(0x1E94b256C7B0B07c7c0AEd932d12F03034c601Ab));

_isBlackListedBot[address(0x4bdEBC7a8de9164F3fBed3056fCF5b9660a894a2)] = true;
_blackListedBots.push(address(0x4bdEBC7a8de9164F3fBed3056fCF5b9660a894a2));

_isBlackListedBot[address(0x08301C261a663481e8dFfd40Ba6860aF22979874)] = true;
_blackListedBots.push(address(0x08301C261a663481e8dFfd40Ba6860aF22979874));

_isBlackListedBot[address(0xF9Cd297bC89F72Aa3Ed374D36D2007E4dFc86B10)] = true;
_blackListedBots.push(address(0xF9Cd297bC89F72Aa3Ed374D36D2007E4dFc86B10));

_isBlackListedBot[address(0x2bd0e7c68E0A2f817d5010448eCa97682b2c7cE8)] = true;
_blackListedBots.push(address(0x2bd0e7c68E0A2f817d5010448eCa97682b2c7cE8));

_isBlackListedBot[address(0x574eb7CBB98faCfE660586d2b1B04E05ED812829)] = true;
_blackListedBots.push(address(0x574eb7CBB98faCfE660586d2b1B04E05ED812829));

_isBlackListedBot[address(0x865f40EA1E7E5F41a9Bd19eAA505D26757968590)] = true;
_blackListedBots.push(address(0x865f40EA1E7E5F41a9Bd19eAA505D26757968590));

_isBlackListedBot[address(0xD2e10b030659BE38C2C60F6d2fc79497E0A8Cf62)] = true;
_blackListedBots.push(address(0xD2e10b030659BE38C2C60F6d2fc79497E0A8Cf62));

_isBlackListedBot[address(0x1236898C8c1736f52e4e529Dabc0f3A14A047B7e)] = true;
_blackListedBots.push(address(0x1236898C8c1736f52e4e529Dabc0f3A14A047B7e));

_isBlackListedBot[address(0x49b8C565A155F8e73c104fF88BE9E2B8562B6cCF)] = true;
_blackListedBots.push(address(0x49b8C565A155F8e73c104fF88BE9E2B8562B6cCF));

_isBlackListedBot[address(0xB20e4ebc5a30B164FF76ab27aE8eEdd30D774727)] = true;
_blackListedBots.push(address(0xB20e4ebc5a30B164FF76ab27aE8eEdd30D774727));

_isBlackListedBot[address(0x6275cb1EE124Bc8817319d9A353b7aAc875eD9E2)] = true;
_blackListedBots.push(address(0x6275cb1EE124Bc8817319d9A353b7aAc875eD9E2));

_isBlackListedBot[address(0xCB74203377e260ca7EF86e3bc5B18F7a576501ff)] = true;
_blackListedBots.push(address(0xCB74203377e260ca7EF86e3bc5B18F7a576501ff));

_isBlackListedBot[address(0x115Dca92AB295B484f8A96EC0c45dc0627bfb9d4)] = true;
_blackListedBots.push(address(0x115Dca92AB295B484f8A96EC0c45dc0627bfb9d4));

_isBlackListedBot[address(0xe0cb34b700F7CF942Aa9A233d22A173977F8f9C4)] = true;
_blackListedBots.push(address(0xe0cb34b700F7CF942Aa9A233d22A173977F8f9C4));

_isBlackListedBot[address(0xB01D713eBb927924a3fc830CC2d5bD24d866E056)] = true;
_blackListedBots.push(address(0xB01D713eBb927924a3fc830CC2d5bD24d866E056));

_isBlackListedBot[address(0x43c91B1D4485eDf8E83B79f5422A9d954404147a)] = true;
_blackListedBots.push(address(0x43c91B1D4485eDf8E83B79f5422A9d954404147a));

_isBlackListedBot[address(0x820A8eeaDB344F0BDCC6ee7E1f869bc42Ed2136c)] = true;
_blackListedBots.push(address(0x820A8eeaDB344F0BDCC6ee7E1f869bc42Ed2136c));

_isBlackListedBot[address(0xD98A54e09a708Ada3d8599f4fb51716e649fd1F8)] = true;
_blackListedBots.push(address(0xD98A54e09a708Ada3d8599f4fb51716e649fd1F8));

_isBlackListedBot[address(0xc15699DCc9D61192620Af4B34440896DD264379c)] = true;
_blackListedBots.push(address(0xc15699DCc9D61192620Af4B34440896DD264379c));

_isBlackListedBot[address(0x8A33276c05f1EF5EF443fE039F9f77bab0b36C5a)] = true;
_blackListedBots.push(address(0x8A33276c05f1EF5EF443fE039F9f77bab0b36C5a));

_isBlackListedBot[address(0x1FeE584aa6D04078b8873DEbDd8697C3D7503029)] = true;
_blackListedBots.push(address(0x1FeE584aa6D04078b8873DEbDd8697C3D7503029));

_isBlackListedBot[address(0x65a3201bE25F52F1A1Fc9309Cc86F237535c5044)] = true;
_blackListedBots.push(address(0x65a3201bE25F52F1A1Fc9309Cc86F237535c5044));

_isBlackListedBot[address(0xb1FFC3ed9Df573b5e6d639549e6F5d8198cC520B)] = true;
_blackListedBots.push(address(0xb1FFC3ed9Df573b5e6d639549e6F5d8198cC520B));

_isBlackListedBot[address(0xa8E475A39c9Cb44BC1a958849364d7CD65dC35Ae)] = true;
_blackListedBots.push(address(0xa8E475A39c9Cb44BC1a958849364d7CD65dC35Ae));

_isBlackListedBot[address(0xe666A232fAB20e75A9A191471CDa19e8f68bf49D)] = true;
_blackListedBots.push(address(0xe666A232fAB20e75A9A191471CDa19e8f68bf49D));

_isBlackListedBot[address(0x53507C968C442b502e5F7B4D2CfEFbeC61e1e918)] = true;
_blackListedBots.push(address(0x53507C968C442b502e5F7B4D2CfEFbeC61e1e918));

_isBlackListedBot[address(0xb5077DFF519609F5C067f80110f0012F43EfaacC)] = true;
_blackListedBots.push(address(0xb5077DFF519609F5C067f80110f0012F43EfaacC));

_isBlackListedBot[address(0xeCf56b5bdE1386ca4f328a99C8C23DEB6266e6cB)] = true;
_blackListedBots.push(address(0xeCf56b5bdE1386ca4f328a99C8C23DEB6266e6cB));

_isBlackListedBot[address(0x9517bEd19D544688BA0F8D10CaDf3AA3EaF3DFef)] = true;
_blackListedBots.push(address(0x9517bEd19D544688BA0F8D10CaDf3AA3EaF3DFef));

_isBlackListedBot[address(0x790733562cfa875021a000CdD6B9FD633D4ea715)] = true;
_blackListedBots.push(address(0x790733562cfa875021a000CdD6B9FD633D4ea715));

_isBlackListedBot[address(0x1C0C63657b7Af21fE5c326eA0071330290b2edbD)] = true;
_blackListedBots.push(address(0x1C0C63657b7Af21fE5c326eA0071330290b2edbD));

_isBlackListedBot[address(0xc8A40bdC1c4C331abc4515a4C621F5744518c8b3)] = true;
_blackListedBots.push(address(0xc8A40bdC1c4C331abc4515a4C621F5744518c8b3));

_isBlackListedBot[address(0xC55A35B2e5b2A97D7874eaF6d36A37B910c635cb)] = true;
_blackListedBots.push(address(0xC55A35B2e5b2A97D7874eaF6d36A37B910c635cb));

_isBlackListedBot[address(0xfE9aa5a551DF137179a03090fDb13730d5c62b59)] = true;
_blackListedBots.push(address(0xfE9aa5a551DF137179a03090fDb13730d5c62b59));

_isBlackListedBot[address(0x8cb2E2513d7dcF13eefEdc1d1BaBB6aD77eB703D)] = true;
_blackListedBots.push(address(0x8cb2E2513d7dcF13eefEdc1d1BaBB6aD77eB703D));

_isBlackListedBot[address(0x440Ea9825cF1858FF0Bd60D59295Cf68cc736406)] = true;
_blackListedBots.push(address(0x440Ea9825cF1858FF0Bd60D59295Cf68cc736406));

_isBlackListedBot[address(0x2aC6c5118682F9BB4D13Bc088a92C111FFef62a8)] = true;
_blackListedBots.push(address(0x2aC6c5118682F9BB4D13Bc088a92C111FFef62a8));

_isBlackListedBot[address(0x5fD012A0520A9a40d3EaE10E0Da94A0ad2bD7f54)] = true;
_blackListedBots.push(address(0x5fD012A0520A9a40d3EaE10E0Da94A0ad2bD7f54));

_isBlackListedBot[address(0x13504974eCC21a3cB2C0bCB09d5149cB52D7E7ec)] = true;
_blackListedBots.push(address(0x13504974eCC21a3cB2C0bCB09d5149cB52D7E7ec));

_isBlackListedBot[address(0x2B31bc9B086fDE56c3eBd4B97C2e4d643d146678)] = true;
_blackListedBots.push(address(0x2B31bc9B086fDE56c3eBd4B97C2e4d643d146678));

_isBlackListedBot[address(0xd4c4Bf6fF8c55817084853bdf3cEE8Bb2fcd6Fe7)] = true;
_blackListedBots.push(address(0xd4c4Bf6fF8c55817084853bdf3cEE8Bb2fcd6Fe7));

_isBlackListedBot[address(0x238c6d30d1c8f6F99BcDB86E9b50522f8b53027c)] = true;
_blackListedBots.push(address(0x238c6d30d1c8f6F99BcDB86E9b50522f8b53027c));

_isBlackListedBot[address(0x3A7964549C1Fbd428A1EC34D607EEB23a554c8Ce)] = true;
_blackListedBots.push(address(0x3A7964549C1Fbd428A1EC34D607EEB23a554c8Ce));

_isBlackListedBot[address(0x1058e18Ad57dF863aEaC9aDACc9ea1D34db98730)] = true;
_blackListedBots.push(address(0x1058e18Ad57dF863aEaC9aDACc9ea1D34db98730));

_isBlackListedBot[address(0x68a7E47c2DF461738895D19E93Dd9Acfeca0D05b)] = true;
_blackListedBots.push(address(0x68a7E47c2DF461738895D19E93Dd9Acfeca0D05b));

_isBlackListedBot[address(0x47Ff48981BeBBAAb9697CcE968596e756dfd8F10)] = true;
_blackListedBots.push(address(0x47Ff48981BeBBAAb9697CcE968596e756dfd8F10));

_isBlackListedBot[address(0x83e3D2C3ffFFc6dBD196C9f876d434DcccA45ACd)] = true;
_blackListedBots.push(address(0x83e3D2C3ffFFc6dBD196C9f876d434DcccA45ACd));

_isBlackListedBot[address(0x375eC66978cF5C09ea5E5F8E2670Fb9c1a4539C7)] = true;
_blackListedBots.push(address(0x375eC66978cF5C09ea5E5F8E2670Fb9c1a4539C7));

_isBlackListedBot[address(0xD10E651F4C2211a6551f2BB520b6F1aD9E911c74)] = true;
_blackListedBots.push(address(0xD10E651F4C2211a6551f2BB520b6F1aD9E911c74));

_isBlackListedBot[address(0x026c6993dC14e2804027DEf3Ef0C406Bc0793e07)] = true;
_blackListedBots.push(address(0x026c6993dC14e2804027DEf3Ef0C406Bc0793e07));

_isBlackListedBot[address(0x0b9AeCF8c1bcD84e363a33c6Bb7DDb77a8168177)] = true;
_blackListedBots.push(address(0x0b9AeCF8c1bcD84e363a33c6Bb7DDb77a8168177));

_isBlackListedBot[address(0xE5854205A008918fcB604861b97348dC33470C15)] = true;
_blackListedBots.push(address(0xE5854205A008918fcB604861b97348dC33470C15));

_isBlackListedBot[address(0x765eFAe9a27783C805118f91bE010E87EbeFc28b)] = true;
_blackListedBots.push(address(0x765eFAe9a27783C805118f91bE010E87EbeFc28b));

_isBlackListedBot[address(0x014E579425785e20eEe093089Eb0028F2610B764)] = true;
_blackListedBots.push(address(0x014E579425785e20eEe093089Eb0028F2610B764));

_isBlackListedBot[address(0xF698Cd1A1E5e0A830DaFDA02dc32bfA189FFAb35)] = true;
_blackListedBots.push(address(0xF698Cd1A1E5e0A830DaFDA02dc32bfA189FFAb35));

_isBlackListedBot[address(0x2d2c5c5786C278591D10AEb9411EB8DEA3e49FD6)] = true;
_blackListedBots.push(address(0x2d2c5c5786C278591D10AEb9411EB8DEA3e49FD6));

_isBlackListedBot[address(0xDB5d6C7c007d5164490Ef849798c80782Fe05998)] = true;
_blackListedBots.push(address(0xDB5d6C7c007d5164490Ef849798c80782Fe05998));

_isBlackListedBot[address(0x2620a9b36EE904154a8De073410779E530FfD953)] = true;
_blackListedBots.push(address(0x2620a9b36EE904154a8De073410779E530FfD953));

_isBlackListedBot[address(0x4b06801C2cf1184bf8335a584B26b2ACb18e04D1)] = true;
_blackListedBots.push(address(0x4b06801C2cf1184bf8335a584B26b2ACb18e04D1));

_isBlackListedBot[address(0x42F20fE36C6E6e6e590715c88AB87b9595F827ca)] = true;
_blackListedBots.push(address(0x42F20fE36C6E6e6e590715c88AB87b9595F827ca));

_isBlackListedBot[address(0xa20f45364Be30fF11cD89700589b24d4063477bE)] = true;
_blackListedBots.push(address(0xa20f45364Be30fF11cD89700589b24d4063477bE));

_isBlackListedBot[address(0x39786d96b9df5aC2fb9BF1688d42485406F08658)] = true;
_blackListedBots.push(address(0x39786d96b9df5aC2fb9BF1688d42485406F08658));

_isBlackListedBot[address(0xF17Caa802b9156e5bcC4a72a5B8c76976C45AB04)] = true;
_blackListedBots.push(address(0xF17Caa802b9156e5bcC4a72a5B8c76976C45AB04));

_isBlackListedBot[address(0x1ED036376C29e7717f794FA5D43a711033Efe751)] = true;
_blackListedBots.push(address(0x1ED036376C29e7717f794FA5D43a711033Efe751));

_isBlackListedBot[address(0xCAD8D9F4C8966c4Dba3d74Fd94E3e7FD84e36A29)] = true;
_blackListedBots.push(address(0xCAD8D9F4C8966c4Dba3d74Fd94E3e7FD84e36A29));

_isBlackListedBot[address(0xfF9414E48582e64b87f113E8733Bd1986Dbabc72)] = true;
_blackListedBots.push(address(0xfF9414E48582e64b87f113E8733Bd1986Dbabc72));

_isBlackListedBot[address(0x6b0E3032D4FFb56D5d8d1Cfd5f4b513b3593a3Db)] = true;
_blackListedBots.push(address(0x6b0E3032D4FFb56D5d8d1Cfd5f4b513b3593a3Db));

_isBlackListedBot[address(0x5375606573dE4Aa39f95cdbe0a8896ac192d9FC9)] = true;
_blackListedBots.push(address(0x5375606573dE4Aa39f95cdbe0a8896ac192d9FC9));

_isBlackListedBot[address(0xe291993900969ae84ecc3712Ae025C3459045587)] = true;
_blackListedBots.push(address(0xe291993900969ae84ecc3712Ae025C3459045587));

_isBlackListedBot[address(0x3bf5FFF3Db120385AEefa86Ba00A27314a685d33)] = true;
_blackListedBots.push(address(0x3bf5FFF3Db120385AEefa86Ba00A27314a685d33));

_isBlackListedBot[address(0x5B066789f1323C2C6100b8A04C5C23B149212dc7)] = true;
_blackListedBots.push(address(0x5B066789f1323C2C6100b8A04C5C23B149212dc7));

_isBlackListedBot[address(0x61c324cFB8C234AEC28814CfF864a296C8112cb1)] = true;
_blackListedBots.push(address(0x61c324cFB8C234AEC28814CfF864a296C8112cb1));

_isBlackListedBot[address(0x8bC6C41e8Bf7dD4F7d567b4a6173E13c25ED4039)] = true;
_blackListedBots.push(address(0x8bC6C41e8Bf7dD4F7d567b4a6173E13c25ED4039));

_isBlackListedBot[address(0x9cc79078b54aD1fA87aFACF9Ceb5EAa5b8061414)] = true;
_blackListedBots.push(address(0x9cc79078b54aD1fA87aFACF9Ceb5EAa5b8061414));

_isBlackListedBot[address(0xDbbdB4d45B5880DF4BD515c1Ef5dBB6592aEB078)] = true;
_blackListedBots.push(address(0xDbbdB4d45B5880DF4BD515c1Ef5dBB6592aEB078));

_isBlackListedBot[address(0xfF3dD404aFbA451328de089424C74685bf0a43C9)] = true;
_blackListedBots.push(address(0xfF3dD404aFbA451328de089424C74685bf0a43C9));

_isBlackListedBot[address(0x9895C1D2176f4762fa926Dd0Ce6255A45fb5dF08)] = true;
_blackListedBots.push(address(0x9895C1D2176f4762fa926Dd0Ce6255A45fb5dF08));

_isBlackListedBot[address(0x85Cfe8d803fBF61040443299672d5b05324DaF89)] = true;
_blackListedBots.push(address(0x85Cfe8d803fBF61040443299672d5b05324DaF89));

_isBlackListedBot[address(0x5f8C44441F323940501b3d00F606CDEf55eD3B96)] = true;
_blackListedBots.push(address(0x5f8C44441F323940501b3d00F606CDEf55eD3B96));

_isBlackListedBot[address(0x49B9Da9e0A49dAEBeE13e6E0eb307D7DFbef47fE)] = true;
_blackListedBots.push(address(0x49B9Da9e0A49dAEBeE13e6E0eb307D7DFbef47fE));

_isBlackListedBot[address(0xb31d783359E4f4561984863A8967dD560dC740a4)] = true;
_blackListedBots.push(address(0xb31d783359E4f4561984863A8967dD560dC740a4));

_isBlackListedBot[address(0x13D20459361D4e8269f8C0f2813aD94f70031340)] = true;
_blackListedBots.push(address(0x13D20459361D4e8269f8C0f2813aD94f70031340));

_isBlackListedBot[address(0x599283D9A18Bb169b29b31965854Bf88a803F115)] = true;
_blackListedBots.push(address(0x599283D9A18Bb169b29b31965854Bf88a803F115));

_isBlackListedBot[address(0x35af19DCf06D1EFa4536346bddCb11e36C04d8e2)] = true;
_blackListedBots.push(address(0x35af19DCf06D1EFa4536346bddCb11e36C04d8e2));

_isBlackListedBot[address(0x60461055A9187eDB187e50553A53c2884e59F9d6)] = true;
_blackListedBots.push(address(0x60461055A9187eDB187e50553A53c2884e59F9d6));

_isBlackListedBot[address(0x689a9708Ba7f96871F39977a23455B4054734159)] = true;
_blackListedBots.push(address(0x689a9708Ba7f96871F39977a23455B4054734159));

        emit Transfer(address(0), owner(), _tTotal);
    }

    function isBot(address account) public view returns (bool) {
        return  _isBlackListedBot[account];
    }

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

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
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
        require(!_isBlackListedBot[sender], "You have no power here!");
        require(!_isBlackListedBot[recipient], "You have no power here!");
        require(!_isBlackListedBot[tx.origin], "You have no power here!");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

// Bot Functions 

    function addBotToBlackList(address account) external onlyOwner() {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not blacklist Uniswap router.');
        require(!_isBlackListedBot[account], "Account is already blacklisted");
        _isBlackListedBot[account] = true;
        _blackListedBots.push(account);
    }

    function removeBotFromBlackList(address account) external onlyOwner() {
        require(_isBlackListedBot[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _blackListedBots.length; i++) {
            if (_blackListedBots[i] == account) {
                _blackListedBots[i] = _blackListedBots[_blackListedBots.length - 1];
                _isBlackListedBot[account] = false;
                _blackListedBots.pop();
                break;
            }
        }
    }


    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
        function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tmarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takemarketing(tmarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
        function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setmarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        _marketingFee = marketingFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tmarketing) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tmarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tmarketing);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tmarketing = calculatemarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tmarketing);
        return (tTransferAmount, tFee, tLiquidity, tmarketing);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tmarketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rmarketing = tmarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rmarketing);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
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
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function _takemarketing(uint256 tmarketing) private {
        uint256 currentRate =  _getRate();
        uint256 rmarketing = tmarketing.mul(currentRate);
        _rOwned[_marketingWalletAddress] = _rOwned[_marketingWalletAddress].add(rmarketing);
        if(_isExcluded[_marketingWalletAddress])
            _tOwned[_marketingWalletAddress] = _tOwned[_marketingWalletAddress].add(tmarketing);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculatemarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousmarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        
        _taxFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _marketingFee = _previousmarketingFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlackListedBot[from], "You have no power here!");
        require(!_isBlackListedBot[to], "You have no power here!");
        require(!_isBlackListedBot[tx.origin], "You have no power here!");        
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tmarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takemarketing(tmarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tmarketing) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takemarketing(tmarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tmarketing) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takemarketing(tmarketing);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

}