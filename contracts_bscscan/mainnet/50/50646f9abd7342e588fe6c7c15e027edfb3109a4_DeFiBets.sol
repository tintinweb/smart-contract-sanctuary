/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.10;

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


interface ILotteryTracker {
    function updateAccount(address account, uint256 amount) external;
    function removeEntryFromWallet(address account, uint256 amount) external;
    function removeAccount(address account) external;
    function isActiveAccount(address account) external view returns(bool);
}


contract DeFiBets is Context, IERC20, Ownable{

    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromAutoLiquidity;
    mapping (address => bool) private _isBot;
    mapping (address => bool) internal _isExcludedFromTxLimit;
    mapping(address => bool) private _canAddLiquidity;
    mapping (address => bool) private _loweredTaxExclusions;
    address[] private _excluded;
    address payable public _marketingWallet = payable(0x719D57c545ba456f4912370126f4E51f167b0Af1); 
    address payable public _buyBackWallet = payable(0x8e8A4071019ac6fD762131267f6EBC3497B09748); 
    address payable public _lotteryWallet = payable(0xD747D7D81134936f5c27b0C26D466405238FAD6B); 
    address payable public _ecosystemWallet = payable(0x90Cb6fcf37F9dAf726287c715e0993c98c5ED1b6); 
    IERC20 public rewardToken;   
    // set default to BUSD 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    // busd on beta 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47
    IERC20 public busdToken = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    ILotteryTracker public lotteryTracker;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 888_888_888 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    bool public rewardInBNB = false;
    bool public isEarlySellingEnabled = true;
    bool public disableLotteryLogic = false;
    mapping(address => bool) _isExcludedFromEarlySellingLimit;
    mapping (address => uint256) private lastBuyTime;
    uint public earlySellingHour = 24;
    uint public sellSnipeTimeLimitMinute = 30;
    uint256 public earlySellingFeeCutOffPercent = 21;
    uint256 public entryDivider = 25000 * 10**9;
    mapping(address => bool) _isExcludedFromLottery;
    mapping(address => bool) _accountInLottery;
    mapping(address => bool) _isLpPair;
    mapping(address => bool) _allowLotteryEntryOnTransferList;

    string private constant _name     = "CASINO";
    string private constant _symbol   = "TOKENS";
    uint8  private constant _decimals = 9;
    uint256 public  _lowerTaxBy       = 1;// Enter the percentage like 1% or 2% and it will be subtracted from the total. 
    uint256 private  _lotteryTax       = 2;
    uint256 private  _marketingTax       = 3;
    uint256 private  _buyBackTax       = 2;
    uint256 public  _taxFee       = 1; // holders tax
    uint256 public  _ecosystemDevelopmentTax = 1; // ecosystem development tax
    uint256 public  _totalTaxForDistribution  = _lotteryTax.add(_marketingTax).add(_buyBackTax); // total tax for distribution
    uint256 public  _totalFees      = _taxFee.add(_ecosystemDevelopmentTax).add(_totalTaxForDistribution);
    
    uint256 public  _maxTxAmount     = 2500 * 10**3 * 10**9;
    uint256 private _minimumTokenBalance = 500 * 10**3 * 10**9;
    

    bool public isLaunched = false; 
    uint256 public lastSnipeBlock; // set to blocks after liq added
    uint256 public snipeBlocks = 1;
    uint256 public endSnipeLimitPeriod; 

    
    IUniswapV2Router02 public pancakeV2Router;
    address            public pancakeV2Pair;
    bool inSwap;
    bool public swapEnabled = true;
    event MinimumTokensBeforeSwapUpdated(uint256 minimumTokensBeforeSwap);
    event SwapEnabledUpdated(bool enabled);
    event Swap(
        uint256 tokensSwapped,
        uint256 ethReceived
    );
    event UpdateLastBuyTime(address account, uint256 time);
    event RemoveAccountFromLottery(address account);
    event AddAccountToLottery(address account);
    
    modifier ltsTheSwap{
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor (address _lotteryTracker) {
        _rOwned[_msgSender()] = _rTotal;
        // set default to BUSD 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
        // busd on beta 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47
        rewardToken = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

        lotteryTracker = ILotteryTracker(_lotteryTracker);
        // pancake
        //beta router 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        // prod router 0x10ED43C718714eb63d5aA57B78B54704E256024E
        IUniswapV2Router02 _pancakeV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pancakeV2Pair = IUniswapV2Factory(_pancakeV2Router.factory())
            .createPair(address(this), _pancakeV2Router.WETH());
        pancakeV2Router = _pancakeV2Router;
        
        // exclude system address
        _isExcludedFromEarlySellingLimit[_msgSender()] = true;
        _isExcludedFromEarlySellingLimit[address(this)] = true;
        _isExcludedFromEarlySellingLimit[_marketingWallet] = true;
        _isExcludedFromEarlySellingLimit[_buyBackWallet] = true;
        _isExcludedFromEarlySellingLimit[_lotteryWallet] = true;
        _isExcludedFromEarlySellingLimit[_ecosystemWallet] = true;
        _isExcludedFromEarlySellingLimit[pancakeV2Pair] = true;
        _isExcludedFromEarlySellingLimit[address(pancakeV2Router)] = true;
        _isExcludedFromAutoLiquidity[pancakeV2Pair]            = true;
        _isExcludedFromAutoLiquidity[address(pancakeV2Router)] = true;
        _isExcludedFromLottery[address(this)] = true;
        _isExcludedFromLottery[pancakeV2Pair] = true;
        _isExcludedFromLottery[address(pancakeV2Router)] = true;
        _isLpPair[pancakeV2Pair] = true;
        _isLpPair[address(pancakeV2Router)] = true;
        _isExcludedFromTxLimit[owner()] = true;
        _isExcludedFromTxLimit[address(this)] = true;
        _isExcludedFromTxLimit[_marketingWallet] = true;
        _isExcludedFromTxLimit[_buyBackWallet] = true;
        _isExcludedFromTxLimit[_lotteryWallet] = true;
        _isExcludedFromTxLimit[_ecosystemWallet] = true;
        _isExcludedFromLottery[_msgSender()] = true;
        _isExcludedFromLottery[_marketingWallet] = true;
        _isExcludedFromLottery[_lotteryWallet] = true;
        _isExcludedFromLottery[_ecosystemWallet] = true;
        _isExcludedFromLottery[_buyBackWallet] = true;
        _canAddLiquidity[_msgSender()] = true;
        _allowLotteryEntryOnTransferList[_msgSender()] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
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

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        (, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount,0);
        uint256 currentRate = _getRate();

        if (!deductTransferFee) {
            (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
            return rAmount;

        } else {
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
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


    function getLotteryEntryAmount(uint256 amount) internal view returns(uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 entries = amount / entryDivider;
        if (amount % entryDivider > 0) {
            return entries + 1;
        }

        return entries;
    }
    function launch(uint8 _blocks) external onlyOwner {
        require(_blocks < 64 && !isLaunched);
        snipeBlocks = _blocks;
        isLaunched = true;
        lastSnipeBlock = block.number + snipeBlocks;
        endSnipeLimitPeriod = block.timestamp + 1440 minutes; //24 hr
    }
    function setCanAddLiquidity(address holder, bool a) external onlyOwner {
        _canAddLiquidity[holder] = a;
    }

    function isCanAddLiquidity(address holder) external view returns(bool) {
        return _canAddLiquidity[holder];
    }
    
    function setSnipeBlocks(uint8 _blocks) external onlyOwner {
        require(_blocks < 64 && !isLaunched);
        snipeBlocks = _blocks;
    }
    
    function isBot(address _bot) external view returns(bool) {
        return _isBot[_bot];
    }

    function addBot(address _bot) external onlyOwner {
        require(_bot != pancakeV2Pair, "Lp pair is blacklisted");
        require(_bot != address(pancakeV2Router), "Router is blacklisted");
        _isBot[_bot] = true;
    }

    function removeBot(address _bot) external onlyOwner {
        _isBot[_bot] = false;
    }
    
    function bulkAddBots(address[] calldata _bots) external onlyOwner {
        for (uint256 i = 0; i < _bots.length; i++) {
            require(_bots[i] != pancakeV2Pair, "Lp pair is blacklisted");
            require(_bots[i] != address(pancakeV2Router), "Router is blacklisted");
            _isBot[_bots[i]]= true;
        }
    }

    function setLotteryTracker(address _lotteryTracker) external onlyOwner {
        lotteryTracker = ILotteryTracker(_lotteryTracker);
        _isExcludedFromLottery[address(_lotteryTracker)] = true;
    }


    function setRewardInBNB(bool  a) external onlyOwner{
        rewardInBNB = a;
    }

    function setDisableLotteryLogic(bool  a) external onlyOwner{
        disableLotteryLogic = a;
    }

    function setEarlySellingEnabled(bool  a) external onlyOwner{
        isEarlySellingEnabled = a;
    }
    
    function setRewardToken(address token) external onlyOwner{
       rewardToken = IERC20(token);
    }

    function setExcludedFromLottery(address holder, bool a) external onlyOwner {
        _isExcludedFromLottery[holder] = a;
    }

    function isExcludedFromLottery(address holder) external view returns(bool) {
        return _isExcludedFromLottery[holder];
    }

    function setExcludedFromTxLimit(address holder, bool a) external onlyOwner {
        _isExcludedFromTxLimit[holder] = a;
    }

    function isExcludedFromTxLimit(address holder) external view returns(bool) {
        return _isExcludedFromTxLimit[holder];
    }

    function isAccountInLottery(address account) external view returns(bool) {
        if(_accountInLottery[account]){
            return lotteryTracker.isActiveAccount(account);
        }
        return false;
    }

    function setMarketingWallet(address  wallet) external onlyOwner{
        _marketingWallet = payable(wallet);
        _isExcludedFromEarlySellingLimit[_marketingWallet] = true;
        _isExcludedFromTxLimit[_marketingWallet] = true;
        _isExcludedFromLottery[_marketingWallet] = true;
    }

    function setBuyBackWallet(address  wallet) external onlyOwner{
        _buyBackWallet = payable(wallet);
        _isExcludedFromEarlySellingLimit[_buyBackWallet] = true;
        _isExcludedFromTxLimit[_buyBackWallet] = true;
        _isExcludedFromLottery[_buyBackWallet] = true;
    }

    function setLotteryWallet(address  wallet) external onlyOwner{
        _lotteryWallet = payable(wallet);
        _isExcludedFromEarlySellingLimit[_lotteryWallet] = true;
        _isExcludedFromTxLimit[_lotteryWallet] = true;
        _isExcludedFromLottery[_lotteryWallet] = true;
    } 

    function setEcosystemWallet(address  wallet) external onlyOwner{
        _ecosystemWallet = payable(wallet);
        _isExcludedFromEarlySellingLimit[_ecosystemWallet] = true;
        _isExcludedFromTxLimit[_ecosystemWallet] = true;
        _isExcludedFromLottery[_ecosystemWallet] = true;
    } 
    // Quantity required for Loto entry
    function setEntryDivider(uint256 entryDividerAmount) external onlyOwner {
        require(entryDividerAmount>1000000000, "EntryDividerAmount  is less than 1");
        entryDivider = entryDividerAmount;
    }

    function setEarlySellingCutOffTax(uint256 hoursToSet, uint256 taxFee) external onlyOwner {
        require(taxFee>0, "EarlySellingFeeCutOffPercent tax is less than 0");
        require(hoursToSet>0, "Hours can not be 0");
        earlySellingHour = hoursToSet;
        earlySellingFeeCutOffPercent = taxFee;
    }
    
    function setSellSnipeTimeLimitMinute(uint256 minutesToSet) external onlyOwner {
        require(minutesToSet>0, "Minutes can not be 0");
        sellSnipeTimeLimitMinute = minutesToSet;
    }

    function setEndSnipeLimitPeriod(uint256 minutesToSet) external onlyOwner {
        require(minutesToSet>0, "Minutes can not be 0");
        require(isLaunched, "Contract is not launched yet.");
        endSnipeLimitPeriod = block.timestamp + (minutesToSet * (1 minutes));
    }


    function setHoldersFeePercent(uint256 taxFee) external onlyOwner {
        require(taxFee>0, "Holder tax is less than 0");
        _taxFee = taxFee;
        _totalFees      = _taxFee.add(_ecosystemDevelopmentTax).add(_totalTaxForDistribution);
        require(_totalFees<30, "Total tax is more than 30");
    }
    
    function setEcosystemDevelopmentFeePercent(uint256 ecosystemDevelopmentTax) external onlyOwner {
        require(ecosystemDevelopmentTax>0, "EcosystemDevelopmentTax tax is less than 0");
        _ecosystemDevelopmentTax = ecosystemDevelopmentTax;
        _totalFees      = _taxFee.add(_ecosystemDevelopmentTax).add(_totalTaxForDistribution);
        require(_totalFees<30, "Total tax is more than 30");
    }

    function setLowerTaxFeePercent(uint256 lowerTaxBy) external onlyOwner {
        _lowerTaxBy = lowerTaxBy;
    }

    function setTotalTaxForDistribution(uint256 lotteryTax,uint256 marketingTax,uint256 buyBackTax) external onlyOwner {
        require(lotteryTax>0, "Lottery tax is less than 0");
        require(marketingTax>0, "Marketing tax is less than 0");
        require(buyBackTax>0, "BuyBack tax is less than 0");
        _totalTaxForDistribution = lotteryTax.add(marketingTax).add(buyBackTax);
        _lotteryTax = lotteryTax;
        _marketingTax = marketingTax;
        _buyBackTax = buyBackTax;
        _totalFees      = _taxFee.add(_ecosystemDevelopmentTax).add(_totalTaxForDistribution);
        require(_totalFees<30, "Total tax is more than 30");
    }
    
    function setMaxTx(uint256 maxTx) external onlyOwner {
        require(maxTx >100000000000000, "Max transaction is less than 100000");
        _maxTxAmount = maxTx;
    }

    function setContractSellThreshold(uint256 minimumTokenBalance) external onlyOwner {
        require(minimumTokenBalance > 10000000000000, "Max transaction is less than 10000");
        _minimumTokenBalance = minimumTokenBalance;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
        emit SwapEnabledUpdated(_enabled);
    }
    
    receive() external payable {}

    
    function updateNewRouter(address _router) external onlyOwner returns(address _pair) {
       
        IUniswapV2Router02 _pancakeV2Router = IUniswapV2Router02(_router);
        _pair = IUniswapV2Factory(_pancakeV2Router.factory()).getPair(address(this), _pancakeV2Router.WETH());
        if(_pair == address(0)){
            // Pair doesn't exist, create a new one
            _pair = IUniswapV2Factory(_pancakeV2Router.factory())
            .createPair(address(this), _pancakeV2Router.WETH());
        }
        pancakeV2Pair = _pair;
        // Update the router of the contract variables
        pancakeV2Router = _pancakeV2Router;
        _isExcludedFromAutoLiquidity[pancakeV2Pair]            = true;
        _isExcludedFromAutoLiquidity[address(pancakeV2Router)] = true;
        _isExcludedFromEarlySellingLimit[pancakeV2Pair] = true;
        _isExcludedFromEarlySellingLimit[address(pancakeV2Router)] = true;
        _isLpPair[pancakeV2Pair] = true;
        _isLpPair[address(pancakeV2Router)] = true;
        
    }
    

    function setIsLpPair(address a, bool b) external onlyOwner {
        _isLpPair[a] = b;
    }

     function isAddressLpPair(address a) external view returns(bool) {
        return _isLpPair[a];
    }

    function setAllowLotteryEntryOnTransfer(address a, bool b) external onlyOwner {
        _allowLotteryEntryOnTransferList[a] = b;
    }

     function isAllowLotteryEntryOnTransfer(address a) external view returns(bool) {
        return _allowLotteryEntryOnTransferList[a];
    }

    function setExcludedFromAutoLiquidity(address a, bool b) external onlyOwner {
        _isExcludedFromAutoLiquidity[a] = b;
    }

    function setLoweredTaxExclusions(address _address, bool setTo) external onlyOwner {
        _loweredTaxExclusions[_address] = setTo;
    }

    function getLoweredTaxExclusions(address account) external view returns (bool) {
        return _loweredTaxExclusions[account];
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getTValues(uint256 tAmount, uint256 earlySellingTaxAmount) private view returns (uint256, uint256, uint256) {
        //Total fee for distribution and autolp
        uint256 _totalFeesForBNB = _ecosystemDevelopmentTax.add(_totalTaxForDistribution);
        uint256 tFee       = tAmount.mul(_taxFee).div(100);
        uint256 tLiquidity = tAmount.mul(_totalFeesForBNB).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        if(earlySellingTaxAmount>0){
            tLiquidity = tLiquidity.add(earlySellingTaxAmount);
        }
        tTransferAmount = tTransferAmount.sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount    = tAmount.mul(currentRate);
        uint256 rFee       = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rLiquidity);
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
    
    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) private {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    

    function checkTxLimit(address sender,address receiver, uint256 amount) internal view {
        if (_isExcludedFromTxLimit[sender] || _isExcludedFromTxLimit[receiver]) {
            return;
        }
        // allow the LP pair, as they are buy
        if(_isLpPair[sender]){
            return;
        }
        require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        require (!_isBot[sender],'Robot detected');
        
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        checkTxLimit(from,to,amount);

        if(!isLaunched && to == pancakeV2Pair && _canAddLiquidity[from]){ 
            isLaunched = true;
            lastSnipeBlock = block.number + snipeBlocks;
            endSnipeLimitPeriod = block.timestamp + 1440 minutes; //24 hr
        }

        if (isLaunched && !_isExcludedFromTxLimit[to] && block.number <= lastSnipeBlock && !_isBot[to] && from == pancakeV2Pair) {
            _isBot[to] = true;
            _isBot[tx.origin] = true;
        }
        // 1 min dealy for each buy this is valid only for initial 24h
         if (isLaunched && block.timestamp <= endSnipeLimitPeriod && from == pancakeV2Pair && !_isBot[to]) {
             //not required to check for bots
            if (lastBuyTime[to] <= endSnipeLimitPeriod - 1 minutes) {
                // require 1 min wait for 24hr for each buy
                require(
                    lastBuyTime[to] + 1 minutes < block.timestamp,
                    "Cooldown 1 min for buy"
                );
            }
            lastBuyTime[to] = block.timestamp;
        }
        // 30 min dealy for each sell this is valid only for initial 24h
        if (isLaunched && block.timestamp <= endSnipeLimitPeriod && to == pancakeV2Pair ) {
            if (lastBuyTime[from] <= endSnipeLimitPeriod) {
                // require 30 min wait for 24hr for each sell
                require(
                    lastBuyTime[from] +  sellSnipeTimeLimitMinute * 1 minutes < block.timestamp,
                    "Cooldown 30 min for sell"
                );
            }
            lastBuyTime[from] = block.timestamp;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool isOverMinimumTokenBalance = contractTokenBalance >= _minimumTokenBalance;
        if (
            isOverMinimumTokenBalance &&
            !inSwap &&
            !_isExcludedFromAutoLiquidity[from] &&
            swapEnabled
        ) {
            contractTokenBalance = _minimumTokenBalance;
            swapAndTakeFees(contractTokenBalance);
        }
        // When from is LP pair then its a buy
        if(!inSwap && _isLpPair[from]){
            recordLastBuy(to);
        }
        
        bool takeFee = false;
        if (_isLpPair[from] || _isLpPair[to]) {
            takeFee = true;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndTakeFees(uint256 contractTokenBalance) private ltsTheSwap {
        
        
        uint256 distributionPart = contractTokenBalance;
        // swap and take distribution part
        uint256 initialBalance = address(this).balance;
        swapTokensForBnb(distributionPart);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        emit Swap(distributionPart, newBalance);
        uint256 ecosystemPart = newBalance.mul(_ecosystemDevelopmentTax).div(_totalTaxForDistribution + _ecosystemDevelopmentTax );
        uint256 lotteryPart = newBalance.mul(_lotteryTax).div(_totalTaxForDistribution + _ecosystemDevelopmentTax );
        uint256 marketingPart = newBalance.mul(_marketingTax).div(_totalTaxForDistribution + _ecosystemDevelopmentTax );
        uint256 buyBackPart = newBalance.mul(_buyBackTax).div(_totalTaxForDistribution + _ecosystemDevelopmentTax);
        transferToAddressBNB(_marketingWallet,marketingPart);
        transferToAddressBNB(_buyBackWallet,buyBackPart);
        if(rewardInBNB){
            transferToAddressBNB(_lotteryWallet,lotteryPart);
        }else{
            swapAndSendToken(lotteryPart);
        }
        // ecosystem development part
        swapBusdAndSendToken(ecosystemPart);
    }

   
    function swapAndSendToken(uint256 bnbBalance) private ltsTheSwap {
        uint256 initialBalance = rewardToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = pancakeV2Router.WETH();
        path[1] = address(rewardToken);

        pancakeV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbBalance}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tokenReceived = rewardToken.balanceOf(address(this)).sub(initialBalance);
        rewardToken.transfer(_lotteryWallet, tokenReceived);
    }

    function swapBusdAndSendToken(uint256 bnbBalance) private ltsTheSwap {
        uint256 initialBalance = busdToken.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = pancakeV2Router.WETH();
        path[1] = address(busdToken);

        pancakeV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbBalance}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tokenReceived = busdToken.balanceOf(address(this)).sub(initialBalance);
        busdToken.transfer(_ecosystemWallet, tokenReceived);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeV2Router.WETH();

        _approve(address(this), address(pancakeV2Router), tokenAmount);
        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function setExcludedFromEarlySellingLimit(address holder, bool status) external onlyOwner {
        _isExcludedFromEarlySellingLimit[holder] = status;
    }

    function getExcludedFromEarlySellingLimit(address holder) external view returns (bool) {
        return  _isExcludedFromEarlySellingLimit[holder];
    }

    function recordLastBuy(address buyer) internal {
       lastBuyTime[buyer] = block.timestamp;
       emit UpdateLastBuyTime(buyer, block.timestamp);
    }

    function getLastBuy(address buyer) external view returns(uint256) {
        return lastBuyTime[buyer];
    }

    function calculateEarlySellingFee(address from, uint256 amount) internal view returns(uint256) {
        if (_isExcludedFromEarlySellingLimit[from]) {
            return 0;
        }
        if (block.timestamp.sub(lastBuyTime[from]) < earlySellingHour * 1 hours) {
            return amount.mul(earlySellingFeeCutOffPercent).div(100);
        }
        return 0;
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        uint256 previousTaxFee       = _taxFee;
        uint256 previousEcosystemDevelopmentFee = _ecosystemDevelopmentTax;
        uint256 previousTaxForDistributionFee  = _totalTaxForDistribution;
        uint256 earlySellingTaxAmount = 0;
        if(isEarlySellingEnabled && takeFee){
            earlySellingTaxAmount = calculateEarlySellingFee(sender, amount);
        }

        if (!takeFee) {
            _taxFee       = 0;
            _ecosystemDevelopmentTax = 0;
            _totalTaxForDistribution  = 0;
        }
        if(_loweredTaxExclusions[sender] && takeFee){
            if(_lowerTaxBy > _totalTaxForDistribution){
                _totalTaxForDistribution = 0;
            }else{
                _totalTaxForDistribution = _totalTaxForDistribution - _lowerTaxBy;
            }
            
        } 
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount,earlySellingTaxAmount);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount,earlySellingTaxAmount);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount,earlySellingTaxAmount);

        } else {
            _transferStandard(sender, recipient, amount,earlySellingTaxAmount);
        }
        
        if (!takeFee) {
            _taxFee       = previousTaxFee;
            _ecosystemDevelopmentTax = previousEcosystemDevelopmentFee;
            _totalTaxForDistribution  = previousTaxForDistributionFee;
        }

        if(_loweredTaxExclusions[sender] && takeFee){
            _totalTaxForDistribution  = previousTaxForDistributionFee;
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount,uint256 earlySellingTaxAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount,earlySellingTaxAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
        _rOwned[sender]    = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        updateAccountLottery(sender,recipient,tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount,uint256 earlySellingTaxAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount,earlySellingTaxAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        updateAccountLottery(sender,recipient,tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount,uint256 earlySellingTaxAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount,earlySellingTaxAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        updateAccountLottery(sender,recipient,tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount,uint256 earlySellingTaxAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount,earlySellingTaxAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, tFee);
        updateAccountLottery(sender,recipient,tTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function updateAccountLottery(address removeAccount, address addAccount, uint256 amount) internal {
        if(disableLotteryLogic){ 
            return;
        }
        // add a new rule so that if a user transfers tokens it does NOT remove their entries 
        //it only removes the amount of entries based on number of tokens transfered out, do this as long as its not a sell.
        // On claim and on presale lotter entry needs to be allowed.
        if(!_isLpPair[addAccount] && !_isLpPair[removeAccount] && !_allowLotteryEntryOnTransferList[removeAccount]){   
            uint256 entries = getLotteryEntryAmount(amount);
            lotteryTracker.removeEntryFromWallet(removeAccount, entries);
            return;
        }
        // removeaccount is sender and he is a normal user, this is a sell as addaccount user  is a lp pair, remove all sender's entry
        if (_accountInLottery[removeAccount]) {
            _accountInLottery[removeAccount] = false;
            if(lotteryTracker.isActiveAccount(removeAccount)){
                lotteryTracker.removeAccount(removeAccount);
            }
            emit RemoveAccountFromLottery(removeAccount);
        }
        //this is buy case
        if (!_isExcludedFromLottery[addAccount] ) {
            uint256 entries = getLotteryEntryAmount(amount);
            lotteryTracker.updateAccount(addAccount, entries);
            if (!_accountInLottery[addAccount]) {
                _accountInLottery[addAccount] = true;
                emit AddAccountToLottery(addAccount);
            }
        }
    }
    
    function transferToAddressBNB(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    // This is recommended by Certik, if this is not used many BNB will be lost forever.
    function sweep(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }


    function prepareForPresale() external onlyOwner {
        _taxFee       = 0; // holders tax
        _ecosystemDevelopmentTax = 0; // auto lp tax
        _lotteryTax       = 0;
        _marketingTax       = 0;
        _buyBackTax       = 0;
        _totalTaxForDistribution  = 0;
        _totalFees      = _taxFee.add(_ecosystemDevelopmentTax).add(_totalTaxForDistribution);
        _maxTxAmount = _tTotal;
        swapEnabled = false; 
    }
    
    function activateContractAfterPresale() external onlyOwner {
        _maxTxAmount     = 2500 * 10**3 * 10**9;
        swapEnabled = true;
        _taxFee       = 1; // holders tax
        _ecosystemDevelopmentTax = 1; // auto lp tax
        _lotteryTax       = 2;
        _marketingTax       = 3;
        _buyBackTax       = 2;
        _totalTaxForDistribution  = 8;
        _totalFees      = _taxFee.add(_ecosystemDevelopmentTax).add(_totalTaxForDistribution);
    }
        
}