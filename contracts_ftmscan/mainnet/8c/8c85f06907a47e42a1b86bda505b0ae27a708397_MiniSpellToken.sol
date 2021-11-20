/**
 *Submitted for verification at FtmScan.com on 2021-11-17
*/

/**
 *Submitted for verification at FtmScan.com on 2021-11-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

// IUniswapV2Factory interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
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

// IUniswapV2Pair interface taken from: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
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

// IUniswapV2Router01 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
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

// IUniswapV2Router02 interface taken from: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol 
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


contract MiniSpellToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    string private _name     = "Mini Spell Token";
    string private _symbol   = "MINI SPELL";
    uint8  private _decimals = 9;
    
    // Liquidity Settings
    IUniswapV2Router02 public _spookyswapV2Router; // Spookyswap V2 Router
    address public _spookyswapV2LiquidityPair;     // Spookyswap V2 liquidity pairing for FBSI/WFTM
    
    bool currentlySwapping;

    modifier lockSwapping {
        currentlySwapping = true;
        _;
        currentlySwapping = false;
    }
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ftmReceived,
        uint256 tokensIntoLiqudity
    );
    
    // Addresses
    address payable public _marketingAddress = payable(0x2f636C9bFFaC4c275A8De130E95184B3107C9722); // Marketing address used to pay for marketing
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
    uint256 private _tTotal = 1 * 10**11 * 10**9; // 1 quadrillion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _totalReflections; // Total reflections
    
    // Token Tax Settings
    uint256 public  _taxFee           = 6;  // 6% tax 
    uint256 public  _sellTaxFee       = 99; // 12% tax 
    uint256 public  _whaleSellTaxFee  = 99; // 18% tax 
    uint256 private _previousTaxFee;
    
    // Min / Max for Token Tax settings and limits. These values can not be changed anymore.
    uint256 public constant _maxTaxFee = 10; // Tax fee cannot be set beyond 10%
    uint256 public constant _maxSellTaxFee = 20; // Sell tax fee cannot be set beyond 20%
    uint256 public constant _maxWhaleSellTaxFee = 30; // Whale sell tax fee cannot be set beyond 30%
    uint256 public constant _minMaxTxAmount = 500 * 10**9 * 10**9; // Max Tx amount must be set to 500 billion or more
    
    // Token Limits
    uint256 public _maxTxAmount        = 1 * 10**11 * 10**9;  // 1 quadrillion
    uint256 public _tokenSwapThreshold = 1 * 10**6 * 10**9; // 100 billion
    
    // Anti-Whale Settings 
    uint256 public _whaleSellThreshold = 180 * 10**12 * 10**9; // 180 trillion (30% of initial supply)
    uint    public _whaleSellTimer     = 1 days;            
    mapping (address => uint256) private _amountSold;
    mapping (address => uint) private _timeSinceFirstSell;
    
    // BUYBACK 
    bool    public _enableBuyback        = false;             // Disabled on deployment
    uint256 public _buybackFTMThreshold  = 50 * 10**18;       // 50 FTM will be required to be inside the contract before a buyback will be performed
    uint256 public _buybackFTMPercentage = 100;               // 100% of reserved FTMs is used to buyback tokens
    
    // LIQUIDITY
    bool public _enableLiquidity = false; // Controls whether the contract will swap tokens
    uint256 private liquidityAddedAtTimestamp; // Timestamp when liquidity is added for the first time
    
    constructor () {
        // Mint the total reflection balance to the deployer of this contract
        _rOwned[_msgSender()] = _rTotal;
        
        // Exclude the owner and the contract from paying fees
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        
        // Set up the SpookySwap V2 router
        IUniswapV2Router02 spookyswapV2Router = IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        
        _spookyswapV2LiquidityPair = IUniswapV2Factory(spookyswapV2Router.factory())
            .createPair(address(this), spookyswapV2Router.WETH());
        _spookyswapV2Router = spookyswapV2Router;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    /**
     * @notice Required to receive FTM from Spookyswap V2 Router when swapping
     */
    receive() external payable {}
    
    /**
     * @notice Withdraws FTM from the contract. Used to clean dust.
     */
    function withdrawFTM(uint256 amount) public onlyOwner() {
        if(amount == 0) {
            payable(owner()).transfer(address(this).balance);
        }
        else {
            payable(owner()).transfer(amount);
        }
    }
    
    /**
     * @notice Withdraws non-native tokens that are stuck as to not interfere with the liquidity
     */
    function withdrawForeignToken(address token) public onlyOwner() {
        require(address(this) != address(token), "Cannot withdraw native token");
        IERC20(address(token)).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    
    /**
     * @notice Transfers FTM to an address
     */
    function transferFTMToAddress(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    /**
     * @notice Allows the contract to change the router, in the instance when SpookySwap upgrades making the contract future proof
     */
    function setRouterAddress(address router) public onlyOwner() {
        // Connect to the new router
        IUniswapV2Router02 newSpookySwapRouter = IUniswapV2Router02(router);
        
        // Grab an existing pair, or create one if it doesnt exist
        address newPair = IUniswapV2Factory(newSpookySwapRouter.factory()).getPair(address(this), newSpookySwapRouter.WETH());
        if(newPair == address(0)){
            newPair = IUniswapV2Factory(newSpookySwapRouter.factory()).createPair(address(this), newSpookySwapRouter.WETH());
        }
        _spookyswapV2LiquidityPair = newPair;
        _spookyswapV2Router = newSpookySwapRouter;
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
    
    function amountSold(address account) external view returns (uint256) {
        return _amountSold[account];
    }
    
    function getTimeSinceFirstSell(address account) external view returns (uint) {
        return _timeSinceFirstSell[account];
    }
    
    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFees[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFees[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        require(taxFee != _taxFee, "New tax is same as the current tax");
        require(taxFee <= _maxTaxFee, "Tax too high");
        _taxFee = taxFee;
    }
    
    function setSellTaxFeePerecent(uint256 taxFee) external onlyOwner() {
        require(taxFee != _sellTaxFee, "New tax is same as the current tax");
        require(taxFee <= _maxSellTaxFee, "Tax too high");
        _sellTaxFee = taxFee;
    }
    
    function setWhaleSellTaxFeePerecent(uint256 taxFee) external onlyOwner() {
        require(taxFee != _maxWhaleSellTaxFee, "New tax is same as the current tax");
        require(taxFee <= _maxWhaleSellTaxFee, "Tax too high");
        _whaleSellTaxFee = taxFee;
    }
    
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount != _maxTxAmount, "New max tx amount is same as the current");
        require(maxTxAmount >= _minMaxTxAmount, "Amount too low.");
        _maxTxAmount = maxTxAmount;
    }
    
    function setTokenSwapThreshold(uint256 tokenSwapThreshold) external onlyOwner() {
        require(_tokenSwapThreshold != tokenSwapThreshold, "Threshold must be different");
        _tokenSwapThreshold = tokenSwapThreshold;
    }
    
    function setMarketingAddress(address marketingAddress) external onlyOwner() {
        require(_marketingAddress != marketingAddress, "Marketing address must be different");
        _marketingAddress = payable(marketingAddress);
    }
    
    function setBuyback(bool b) external onlyOwner() {
        require(_enableBuyback != b, "Choose another state");
        _enableBuyback = b;
    }
    
    function setBuybackFTMThreshold(uint256 ftmAmount) external onlyOwner() {
        require(_buybackFTMThreshold != ftmAmount, "Set a different amount");
        _buybackFTMThreshold = ftmAmount;
    }
    
    function setBuybackFTMPercentage(uint256 percentage) external onlyOwner() {
        require(percentage >= 0 && percentage <= 100, "Set a value between 0 and 100");
        require(_buybackFTMPercentage != percentage, "Set another percentage");
        _buybackFTMPercentage = percentage;
    }

    function setLiquidity(bool b) external onlyOwner() {
        require(_enableLiquidity != b, "Choose another state");
        _enableLiquidity = b;
    }

    function setWhaleSellThreshold(uint256 amount) external onlyOwner() {
        require(_whaleSellThreshold != amount, "Threshold must be different");
        _whaleSellThreshold = amount;
    }
    
    function setWhaleSellTimer(uint time) external onlyOwner() {
        require(_whaleSellTimer != time, "Time value must be different");
        _whaleSellTimer = time;
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
     * @notice Removes all fees and stores their previous values to be later restored
     */
    function removeAllFees() private {
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
    
    /**
     * @notice Handles the before and after of a token transfer, such as taking fees and firing off a swap and liquify event
     */
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // Init) Check if liquidity is being added
        if (liquidityAddedAtTimestamp == 0 && to == _spookyswapV2LiquidityPair) {
            liquidityAddedAtTimestamp = block.timestamp;
        }
        
        // 1) Check for maximum transaction amount
        // Only the owner of this contract can bypass the max transfer amount
        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        
        // 2) Swap fee tokens stored in this contract. Used for buyback, liquidity, marketing.
        // Check that the contract balance has reached the threshold required to execute a swap and liquify event
        // Do not execute the swap and liquify if there is already a swap happening
        // Do not allow the adding of liquidity if the sender is the SpookySwap V2 liquidity pool
        uint256 tokenBalance = balanceOf(address(this));
        if (_enableLiquidity && tokenBalance >= _tokenSwapThreshold && !currentlySwapping && from != _spookyswapV2LiquidityPair) {
            tokenBalance = _tokenSwapThreshold;
            swapAndLiquify(tokenBalance);
        }
                
        // 3) Buyback
        // If buyback is enabled, and someone is sending tokens to the liquidity pool (i.e. a sell), then we buy back tokens.
        // Do not execute the buyback if there is already a swap happening
        if (_enableBuyback && !currentlySwapping && to == _spookyswapV2LiquidityPair) {
	        uint256 balance = address(this).balance;
	        
	        // Only execute a buyback when the contract has more FTM than the threshold is
            if (balance > _buybackFTMThreshold) {
                balance = _buybackFTMThreshold;
                
                // Buy back tokens with _buybackFTMPercentage of the FTM inside the contract
                buyBackTokens(balance.mul(_buybackFTMPercentage).div(100));
            }
        }
        
        // 4) Fees - If any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);
        bool adjustedFee = false;
        
        // 4.1) Anti S-n-i-p-e - Do not ruin this network and give everyone the chance to buy.
        if (takeFee && liquidityAddedAtTimestamp > 0 && from == _spookyswapV2LiquidityPair) {
            uint delta = block.timestamp.sub(liquidityAddedAtTimestamp);
            if (delta < 3) {
                // Set the tax rate to 90, if a buy occured within a few seconds after liquidity is provided.
                _previousTaxFee = _taxFee;
                _taxFee = 90;
                adjustedFee = true;
            }
        }
        
        // 4.2) Anti Whale - If we are taking fees and sending tokens to the liquidity pool (i.e. a sell), check for anti-whale tax
        else if (takeFee && to == _spookyswapV2LiquidityPair) {
            // We will assume that the normal sell tax rate will apply
            uint256 fee = _sellTaxFee;
            
            // Get the time difference in seconds between now and the first sell
            uint delta = block.timestamp.sub(_timeSinceFirstSell[from]);
            
            // Get the new total to see if it has spilled over the threshold
            uint256 newTotal = _amountSold[from].add(amount);
            
            // If a known wallet started their selling within the whale sell timer window, check if they're trying to spill over the threshold
            // If they are then increase the tax amount
            if (delta > 0 && delta < _whaleSellTimer && _timeSinceFirstSell[from] != 0) {
                if (newTotal > _whaleSellThreshold) {
                    fee = _whaleSellTaxFee; 
                }
                _amountSold[from] = newTotal;
            } else if (_timeSinceFirstSell[from] == 0 && newTotal > _whaleSellThreshold) {
                fee = _whaleSellTaxFee;
                _amountSold[from] = newTotal;
            } else {
                // Otherwise we reset their sold amount and timer
                _timeSinceFirstSell[from] = block.timestamp;
                _amountSold[from] = amount;
            }
                
            // Set the tax rate to the sell tax rate, if the whale sell tax rate applies then we set that
            _previousTaxFee = _taxFee;
            _taxFee = fee;
            adjustedFee = true;
        }
        
        // Remove fees completely from the transfer if either wallet is excluded
        if (!takeFee) {
            removeAllFees();
        }
        
        // 5) Transfer, finally.
        // Transfer the token amount from sender to recipient.
        _tokenTransfer(from, to, amount);
        
        // 6) Restore fees.
        // If we removed the fees for this transaction, then restore them for future transactions
        if (!takeFee) {
            restoreAllFees();
        }
        
        // If we took a fee, restore the fee amount back to the original buy amount
        if (takeFee && adjustedFee) {
            _taxFee = _previousTaxFee;
        }
    }
    
    /**
     * @notice Handles the actual token transfer
     */
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
            // Take the rest of the taxed tokens for the other functions
            _takeTokens(tFee);
		}
            
        // Emit an event 
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    /**
     * @notice Burns FBSI tokens straight to the burn address
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
     * @notice Buys tokens using the contract balance
     */
    function buyBackTokens(uint256 amount) private lockSwapping {
    	if (amount > 0) {
    	    swapFTMForTokens(amount);
	    }
    }
    
    /**
     * @notice Generates FTM by selling tokens and pairs some of the received FTM with tokens to add and grow the liquidity pool
     */
    function swapAndLiquify(uint256 tokenAmount) private lockSwapping {
        // Split the contract balance into the swap portion and the liquidity portion
        uint256 eigth      = tokenAmount.div(8);     // 1/8 of the tokens, used for liquidity
        uint256 swapAmount = tokenAmount.sub(eigth); // 7/8 of the tokens, used to swap for FTM

        // Capture the contract's current FTM balance so that we know exactly the amount of FTM that the
        // swap creates. This way the liquidity event wont include any FTM that has been collected by other means.
        uint256 initialBalance = address(this).balance;

        // Swap 7/8ths of FBSI tokens for FTM
        swapTokensForFTM(swapAmount); 

        // How much FTM did we just receive
        uint256 receivedFTM = address(this).balance.sub(initialBalance);
        
        // A seventh of the received FTM will be paired with the eigth of tokens left behind
        uint256 liquidityFTM = receivedFTM.div(7);
        
        // Add liquidity via the SpookySwap V2 Router
        addLiquidity(eigth, liquidityFTM);
        
        // Send the remaining FTM to the marketing wallet
        transferFTMToAddress(_marketingAddress, address(this).balance);
        
        emit SwapAndLiquify(swapAmount, liquidityFTM, eigth);
    }
    
    /**
     * @notice Swap tokens for FTM storing the resulting FTM in the contract
     */
    function swapTokensForFTM(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _spookyswapV2Router.WETH(); // WETH = WFTM on Fantom Opera Network

        _approve(address(this), address(_spookyswapV2Router), tokenAmount);

        // Execute the swap
        _spookyswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of FTM
            path,
            address(this),
            block.timestamp.add(300)
        );
    }
    
    /**
     * @notice Swaps FTM for tokens and immedietely burns them
     */
    function swapFTMForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = _spookyswapV2Router.WETH();
        path[1] = address(this);

        _spookyswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // Accept any amount of FBSI
            path,
            _burnAddress, // Burn address
            block.timestamp.add(300)
        );
    }

    /**
     * @notice Adds liquidity to the SpookySwap V2 LP
     */
    function addLiquidity(uint256 tokenAmount, uint256 ftmAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(_spookyswapV2Router), tokenAmount);

        // Adds the liquidity and gives the LP tokens to the owner of this contract
        // The LP tokens need to be manually locked
        _spookyswapV2Router.addLiquidityETH{value: ftmAmount}(
            address(this),
            tokenAmount,
            0, // Take any amount of tokens (ratio varies)
            0, // Take any amount of FTM (ratio varies)
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