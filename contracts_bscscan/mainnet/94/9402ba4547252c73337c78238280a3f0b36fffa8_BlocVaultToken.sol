/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// SPDX-License-Identifier: Unlicensed



pragma solidity ^0.8.4;


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

        return account.code.length > 0;
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
pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

 // @dev Interface of the ERC20 standard as defined in the EIP.
 
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


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



contract BlocVaultToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    uint256 private _previousTaxFee = _taxFee;
    // General Info
    string private _name     = "BVLT";
    string private _symbol   = "BV";
    uint8  private _decimals = 9;
    
    uint    public _deployTimestamp;
    //uint256 public presale_start_time;
    //uint256 public presale_end_time;

    //presale lockdealine
    //uint256 public _preSaleLockDeadline = 11111111111111111;
    //presale white Limits
    // mapping(address => bool) private preSaleWhiteList_bool;
    // address [] public preSaleWhiteList_address;
    
    // Liquidity Settings
    IUniswapV2Router02 public _pancakeswapV2Router; // The address of the PancakeSwap V2 Router
    address public _pancakeswapV2LiquidityPair;     // The address of the PancakeSwap V2 liquidity pairing for RAINBOW/WBNB
    
    bool currentlySwapping;

    modifier lockSwapping {
        currentlySwapping = true;
        _;
        currentlySwapping = false;
    }
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    
    // Addresses
    
    //address payable public _preSaleAddress; //presale address
    address payable public _marketingAddress = payable(0x0D8a65C6329521a39bf9353705Ca989735E05961); // Marketing address used to pay for marketing
    address payable public _developAddress = payable(0x5cf74db6113290E6294e3B89878017CE618CCC19); 
    address payable public _vestingAddress = payable(0x158153A675027E2C5FC7fCfdffb7a3343008629C); 
    address payable public _burnAddress      = payable(0x000000000000000000000000000000000000dEaD); // Burn address used to burn a portion of tokens
    
    // Balances
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Exclusions
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    // Supply
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 3 * 10**12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _totalReflections; // Total reflections
    
    // Token Tax Settings
    uint256 public  _taxFee           = 12;  // 12% tax 
    //uint256 public  _preSellTaxFee  = 40; // 12% tax 
    //uint256 private _previousTaxFee;
    
    // Token Limits
    uint256 public _maxTxAmount        = 3 * 10**12 * 10**9;  // 1 quadrillion
    uint256 public _tokenSwapThreshold = 300 * 10**6 * 10**9; // 100 billion
    
    // Timer Constants 
    uint private constant DAY = 86400; // How many seconds in a day
    
    //Vesting Variables
    struct VESTINGINFO{
        uint256 lockdeadline;
        uint256 amount;
        uint256 vestingtype;
    }
    mapping (address => VESTINGINFO) private _vesting_info;
    mapping (address => bool) private _isVesting;

    function get_vest_info(address vest_address) public view returns(uint256,uint256,uint256) {
        if(_isVesting[vest_address] == true){
            return (_vesting_info[vest_address].lockdeadline, _vesting_info[vest_address].amount,
        _vesting_info[vest_address].vestingtype);
        }
        else {return (0,0,0);}
    }   

    function vesting(uint256 amount, uint256 lockdays) public {
        require(_isVesting[msg.sender] != true, "address is available");
        require(amount >= 254000000* 10**9, "lack of amount");
        require(amount <= balanceOf(msg.sender), "investor has less than amount");
        require(lockdays == 90 || lockdays == 180 || lockdays == 270 || lockdays == 360, "lack of vestingtype");
        _isVesting[msg.sender] = true;
        _vesting_info[msg.sender] = VESTINGINFO(block.timestamp.add(DAY.mul(lockdays)), amount, lockdays);
        _tokenTransfer_normal(msg.sender, _vestingAddress, amount);
    }

    function cliam_vest() public {
        require(_isVesting[msg.sender] == true, "address is available");
        uint256 lockdeadline = _vesting_info[msg.sender].lockdeadline;
        uint256 vestingtype = _vesting_info[msg.sender].vestingtype;
        uint256 amount = _vesting_info[msg.sender].amount;
        if(lockdeadline > block.timestamp){
            if(vestingtype == 90 || vestingtype == 180)
            {
                uint256 fee = amount.mul(35).div(1000);
                amount = amount.sub(fee);
            }
            else{
                uint256 fee = amount.mul(55).div(1000);
                amount = amount.sub(fee);
            }
        }
        else{
             if(vestingtype == 90)
            {
                uint256 gain = amount.mul(10).div(100);
                amount = amount.add(gain);
            }
            else if(vestingtype == 180)
            {
                uint256 gain = amount.mul(15).div(100);
                amount = amount.add(gain);
            }else if(vestingtype == 270)
            {
                uint256 gain = amount.mul(20).div(100);
                amount = amount.add(gain);
            }
            else{
                uint256 gain = amount.mul(25).div(100);
                amount = amount.add(gain);
            }
        }
        require(balanceOf(_vestingAddress)>=amount, "insufficient amount");
        _tokenTransfer_normal(_vestingAddress,msg.sender, amount);
        _isVesting[msg.sender] = false;
    }

    // LIQUIDITY
    bool public _enableLiquidity = true;//false; // Controls whether the contract will swap tokens
    
    constructor () {
        // Mint the total reflection balance to the deployer of this contract
        _rOwned[_msgSender()] = _rTotal;
        
        // Exclude the owner and the contract from paying fees
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        
        // Set up the pancakeswap V2 router
        IUniswapV2Router02 pancakeswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        //IUniswapV2Router02 pancakeswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _pancakeswapV2LiquidityPair = IUniswapV2Factory(pancakeswapV2Router.factory())
            .createPair(address(this), pancakeswapV2Router.WETH());
        _pancakeswapV2Router = pancakeswapV2Router;
        
        _deployTimestamp = block.timestamp;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    /**
     * @notice Required to recieve BNB from PancakeSwap V2 Router when swaping
     */
    receive() external payable {}
    
    /**
     * @notice Withdraws BNB from the contract
     */
    function withdrawBNB(uint256 amount) public onlyOwner() {
        if(amount == 0) payable(owner()).transfer(address(this).balance);
        else payable(owner()).transfer(amount);
    }
    
    /**
     * @notice Withdraws non-RAINBOW tokens that are stuck as to not interfere with the liquidity
     */
    function withdrawForeignToken(address token) public onlyOwner() {
        require(address(this) != address(token), "Cannot withdraw native token");
        IERC20(address(token)).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    
    /**
     * @notice Transfers BNB to an address
     */
    function transferBNBToAddress(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    /**
     * @notice Allows the contract to change the router, in the instance when PancakeSwap upgrades making the contract future proof
     */
    function setRouterAddress(address router) public onlyOwner() {
        // Connect to the new router
        IUniswapV2Router02 newPancakeSwapRouter = IUniswapV2Router02(router);
        
        // Grab an existing pair, or create one if it doesnt exist
        address newPair = IUniswapV2Factory(newPancakeSwapRouter.factory()).getPair(address(this), newPancakeSwapRouter.WETH());
        if(newPair == address(0)){
            newPair = IUniswapV2Factory(newPancakeSwapRouter.factory()).createPair(address(this), newPancakeSwapRouter.WETH());
        }
        _pancakeswapV2LiquidityPair = newPair;

        _pancakeswapV2Router = newPancakeSwapRouter;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getTotalReflections() external view returns (uint256) {
        return _totalReflections;
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function isExcludedFromReflection(address account) external view returns(bool) {
        return _isExcluded[account];
    }
    
    
    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFees[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFees[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    //function setPreSaleTaxFeePercent(uint256 taxFee) external onlyOwner() {
    //    _preSellTaxFee = taxFee;
    //}
    
    
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }
    
    function setTokenSwapThreshold(uint256 tokenSwapThreshold) external onlyOwner() {
        _tokenSwapThreshold = tokenSwapThreshold;
    }
    
    function setMarketingAddress(address marketingAddress) external onlyOwner() {
        _marketingAddress = payable(marketingAddress);
    }

    //function setPreSaleAddress(address preSaleAddress) external onlyOwner() {
    //    _preSaleAddress = payable(preSaleAddress);
    //}

    /// set presale _preSaleLockDeadline
    //function setPreSaleTime(uint256 time) public onlyOwner{
    //    _preSaleLockDeadline = time;
    //}
    

    function setDevelopAddress(address developAddress) external onlyOwner() {
        _developAddress = payable(developAddress);
    }

    function setVestingAddress(address vestingAddress) external onlyOwner() {
        _vestingAddress = payable(vestingAddress);
        
    }
    

    function setLiquidity(bool b) external onlyOwner() {
        _enableLiquidity = b;
    }

    /**
     * @notice Converts a token value to a reflection value
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    /**
     * @notice Converts a reflection value to a token value
     */
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    /**
     * @notice Generates a random number between 1 and 1000
     */
     /*
    function random() private returns (uint) {
        uint r = uint(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _nonce))) % 1000);
        r = r.add(1);
        _nonce++;
        return r;
    }
    */
    /**
     * @notice Removes all fees and stores their previous values to be later restored
     */
    function removeAllFees() private  {
        if(_taxFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }
    
    /**
     * @notice Restores the fees
     */
    function restoreAllFees() private {
        _taxFee = _previousTaxFee;
    }
    
    
    /**
     * @notice Collects all the necessary transfer values
     */
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    /**
     * @notice Calculates transfer token values
     */
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(_taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    /**
     * @notice Calculates transfer reflection values
     */
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    /**
     * @notice Calculates the rate of reflections to tokens
     */
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    /**
     * @notice Gets the current supply values
     */
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
    
    /**
     * @notice Excludes an address from receiving reflections
     */
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    /**
     * @notice Includes an address back into the reflection system
     */
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
    
   
    
    function getTime() public view returns(uint256){
        return block.timestamp;
    }

    /**
     * @notice Handles the before and after of a token transfer, such as taking fees and firing off a swap and liquify event
     */
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // Only the owner of this contract can bypass the max transfer amount
        if(from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        
       
        // Gets the contracts RAINBOW balance for buybacks, charity, liquidity and marketing
        uint256 tokenBalance = balanceOf(address(this));
        if(tokenBalance >= _maxTxAmount)
        {
            tokenBalance = _maxTxAmount;
        }
        
        // AUTO-LIQUIDITY MECHANISM
        // Check that the contract balance has reached the threshold required to execute a swap and liquify event
        // Do not execute the swap and liquify if there is already a swap happening
        // Do not allow the adding of liquidity if the sender is the PancakeSwap V2 liquidity pool
        if (_enableLiquidity && tokenBalance >= _tokenSwapThreshold && !currentlySwapping && from != _pancakeswapV2LiquidityPair) {
            tokenBalance = _tokenSwapThreshold;
            swapAndLiquify(tokenBalance);
        }
                
       //add to presale whiteList
        // if(preSaleWhiteList_bool[to] != true && from == _preSaleAddress && to != _pancakeswapV2LiquidityPair){
        //     preSaleWhiteList_bool[to] = true;
        //     preSaleWhiteList_address.push(to);
        // }

        // If any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);

       
        // if (takeFee && _preSaleLockDeadline > block.timestamp && preSaleWhiteList_bool[from] == true) {
        //     _previousTaxFee = _taxFee;
        //     _taxFee = _preSellTaxFee;
        //     }
        // Remove fees completely from the transfer if either wallet are excluded
        if (!takeFee) {
            removeAllFees();
        }
        
        // Transfer the token amount from sender to receipient.
        _tokenTransfer(from, to, amount);
        
        // If we removed the fees for this transaction, then restore them for future transactions
        if (!takeFee) {
            restoreAllFees();
        }
        
        // If this transaction was a sell, and we took a fee, restore the fee amount back to the original buy amount
        
         // if (takeFee && _preSaleLockDeadline > block.timestamp && preSaleWhiteList_bool[from] == true) {
         //    _taxFee = _previousTaxFee;
         //    }
        
    }
    
    /**
     * @notice Handles the actual token transfer
     */
     function _tokenTransfer_normal(address sender, address recipient, uint256 tAmount) private {
        // Calculate the values required to execute a transfer
        
        uint256 rAmount = tAmount.mul(_getRate());
        // Transfer from sender to recipient
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        }
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        }
        _rOwned[recipient] = _rOwned[recipient].add(rAmount); 
        
        // Emit an event 
        emit Transfer(sender, recipient, tAmount);
    }
    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        // Calculate the values required to execute a transfer
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, _getRate());
        
        // Transfer from sender to recipient
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        }
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        
        // This is always 1% of a transaction worth of tokens
        if (tFee > 0) {
            uint256 tPortion = tFee.div(_taxFee);

            // Burn some of the taxed tokens 1%
            _burnTokens(tPortion);
            
            // Reflect some of the taxed tokens 
            // 3% HOLDR Rewards
            _reflectTokens(tPortion.add(tPortion).add(tPortion));
            
            // Send the BV Token to the Vesting wallet 1%
            uint256 currentRate = _getRate();
            uint256 rPortion = tPortion.mul(currentRate);
            

            

            if (_isExcluded[_vestingAddress]) {
                _tOwned[_vestingAddress] = _tOwned[_vestingAddress].add(tPortion);
            }
            _rOwned[_vestingAddress] = _rOwned[_vestingAddress].add(rPortion);
            

            // Take the rest of the taxed tokens for the other functions
            //_takeTokens(tFee.sub(tPortion).sub(tPortion).sub(tPortion), tPortion);
            _takeTokens(tFee.sub(tPortion.mul(5)));
        }
            
        // Emit an event 
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    /**
     * @notice Burns RAINBOW tokens straight to the burn address
     */
    function _burnTokens(uint256 tFee) private {
        uint256 rFee = tFee.mul(_getRate());
        _rOwned[_burnAddress] = _rOwned[_burnAddress].add(rFee);
        if(_isExcluded[_burnAddress]) {
            _tOwned[_burnAddress] = _tOwned[_burnAddress].add(tFee);
        }
    }

    /**
     * @notice Increases the rate of how many reflections each token is worth
     */
    function _reflectTokens(uint256 tFee) private {
        uint256 rFee = tFee.mul(_getRate());
        _rTotal = _rTotal.sub(rFee);
        _totalReflections = _totalReflections.add(tFee);
    }
    
    /**
     * @notice The contract takes a portion of tokens from taxed transactions
     */
    function _takeTokens(uint256 tTakeAmount) private {
        uint256 currentRate = _getRate();
        uint256 rTakeAmount = tTakeAmount.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTakeAmount);
        if(_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tTakeAmount);
        }
       
    }
    
  
    /**
     * @notice Generates BNB by selling tokens and pairs some of the received BNB with tokens to add and grow the liquidity pool
     */
    function swapAndLiquify(uint256 tokenAmount) private lockSwapping {
        // Split the contract balance into the swap portion and the liquidity portion
        uint256 seventh      = tokenAmount.div(7);     // 1/7 of the tokens, used for liquidity
        uint256 swapAmount = tokenAmount.sub(seventh); // 6/7 of the tokens, used to swap for BNB

        // Capture the contract's current BNB balance so that we know exactly the amount of BNB that the
        // swap creates. This way the liquidity event wont include any BNB that has been collected by other means.
        uint256 initialBalance = address(this).balance;

        // Swap 6/7ths of RAINBOW tokens for BNB
        swapTokensForBNB(swapAmount); 

        // How much BNB did we just receive
        uint256 receivedBNB = address(this).balance.sub(initialBalance);
        
        
        uint256 liquidityBNB = receivedBNB.div(6);
        
        // Add liquidity via the PancakeSwap V2 Router
        addLiquidity(seventh, liquidityBNB);
        
        // Send the remaining BNB to the marketing wallet 2%
        uint256 marketingBNB = receivedBNB.div(6).mul(2);
        
        transferBNBToAddress(_marketingAddress, marketingBNB);

        // Send the remaining BNB to the development wallet 3%
        uint256 devleopBNB = receivedBNB.div(6).mul(3);
        
        transferBNBToAddress(_developAddress, devleopBNB);
        
        emit SwapAndLiquify(swapAmount, liquidityBNB, seventh);
    }
    
    /**
     * @notice Swap tokens for BNB storing the resulting BNB in the contract
     */
    function swapTokensForBNB(uint256 tokenAmount) private {
        // Generate the Pancakeswap pair for DHT/WBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeswapV2Router.WETH(); // WETH = WBNB on BSC

        _approve(address(this), address(_pancakeswapV2Router), tokenAmount);

        // Execute the swap
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp.add(300)
        );
    }
    
    /**
     * @notice Swaps BNB for tokens and immedietely burns them
     */
    function swapBNBForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = address(this);

        _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // Accept any amount of RAINBOW
            path,
            _burnAddress, // Burn address
            block.timestamp.add(300)
        );
    }

    /**
     * @notice Adds liquidity to the PancakeSwap V2 LP
     */
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(_pancakeswapV2Router), tokenAmount);

        // Adds the liquidity and gives the LP tokens to the owner of this contract
        // The LP tokens need to be manually locked
        _pancakeswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // Take any amount of tokens (ratio varies)
            0, // Take any amount of BNB (ratio varies)
            owner(),
            block.timestamp.add(300)
        );
    }
    
    /**
     * @notice Allows a user to voluntarily reflect their tokens to everyone else
     */
    function reflect(uint256 tAmount) public {
        require(!_isExcluded[_msgSender()], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _totalReflections = _totalReflections.add(tAmount);
    }
}