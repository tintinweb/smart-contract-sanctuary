// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

/**

All Coins Yield Capital: $ACYC

- The Meme Coin Index
- You aim for one moon shot, we grab them all.

Tokenomics:

- Buy side taxes:
    - 10% of each buy goes to reflections.
- Sell side taxes:
    - 5% of each sell to our proprietary trading algorithm; and
    - 5% to the liquidity pool.
- You do the marketing

Distribution of profits from farming:

- 50% reflected back to token holders.
- 35% reflected back to farming pool.
- 15% to team and advisors.

Website:
https://acy.capital

Telegram:
https://t.me/ACYCapital

Twitter:
https://twitter.com/ACYCapital

Medium:
https://acycapital.medium.com

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// Contract implementation
contract AllCoinsYieldCapital is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // standard variables
    string private _name = "AllCoinsYieldCapital";
    string private _symbol = "ACYC";
    uint8 private _decimals = 18;

    // baseline token construction
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalTokenSupply = 1 * 10**12 * 10**_decimals;
    uint256 private _totalReflections = (MAX - (MAX % _totalTokenSupply));
    uint256 private _totalTaxesReflectedToHodlers;
    uint256 private _totalTaxesSentToTreasury;
    mapping(address => uint256) private _reflectionsOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    // taxes and fees
    address payable public _treasuryAddress;
    uint256 private _currentTaxForReflections = 10; // modified depending on context of tx
    uint256 private _currentTaxForTreasury = 10; // modified depending on context of tx
    uint256 public _fixedTaxForReflections = 10; // unchanged save by owner transaction
    uint256 public _fixedTaxForTreasury = 10; // unchanged save by owner transaction

    // tax exempt addresses
    mapping(address => bool) private _isExcludedFromTaxes;

    // uniswap matters -- n.b. we are married to this particular uniswap v2 pair
    // contract will not survive as is and will require migration if a new pool
    // is stood up on sushiswap, uniswapv3, etc.
    address private uniDefault = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public immutable uniswapV2Router;
    bool private _inSwap = false;
    address public immutable uniswapV2Pair;

    // minimum tokens to initiate a swap
    uint256 private _minimumTokensToSwap = 10 * 10**3 * 10**_decimals;

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(address payable treasuryAddress, address router) {
        require(
            (treasuryAddress != address(0)),
            "Give me the treasury address"
        );
        _treasuryAddress = treasuryAddress;
        _reflectionsOwned[_msgSender()] = _totalReflections;

        // connect to uniswap router
        if (router == address(0)) {
            router = uniDefault;
        }
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);

        // setup uniswap pair
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
        uniswapV2Router = _uniswapV2Router;

        // Exclude owner, treasury, and this contract from fee
        _isExcludedFromTaxes[owner()] = true;
        _isExcludedFromTaxes[address(this)] = true;
        _isExcludedFromTaxes[_treasuryAddress] = true;

        emit Transfer(address(0), _msgSender(), _totalTokenSupply);
    }

    // recieve ETH from uniswapV2Router when swaping
    receive() external payable {
        return;
    }

    // We expose this function to modify the address where the treasuryTax goes
    function setTreasuryAddress(address payable treasuryAddress) external {
        require(_msgSender() == _treasuryAddress, "You cannot call this");
        require(
            (treasuryAddress != address(0)),
            "Give me the treasury address"
        );
        address _previousTreasuryAddress = _treasuryAddress;
        _treasuryAddress = treasuryAddress;
        _isExcludedFromTaxes[treasuryAddress] = true;
        _isExcludedFromTaxes[_previousTreasuryAddress] = false;
    }

    // We allow the owner to set addresses that are unaffected by taxes
    function excludeFromTaxes(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromTaxes[account] = excluded;
    }

    // We expose these functions to be able to modify the fees and tx amounts
    function setReflectionsTax(uint256 tax) external onlyOwner {
        require(tax >= 0 && tax <= 10, "ERC20: tax out of band");
        _currentTaxForReflections = tax;
        _fixedTaxForReflections = tax;
    }

    function setTreasuryTax(uint256 tax) external onlyOwner {
        require(tax >= 0 && tax <= 10, "ERC20: tax out of band");
        _currentTaxForTreasury = tax;
        _fixedTaxForTreasury = tax;
    }

    // We expose these functions to be able to manual swap and send
    function manualSend() external onlyOwner {
        uint256 _contractETHBalance = address(this).balance;
        _sendETHToTreasury(_contractETHBalance);
    }

    function manualSwap() external onlyOwner {
        uint256 _contractBalance = balanceOf(address(this));
        _swapTokensForEth(_contractBalance);
    }

    // public functions to do things
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // used by smart contracts rather than users
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
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
        uint256 currentRate = _getRate();
        return _totalReflections.div(currentRate);
    }

    function isExcludedFromTaxes(address account) public view returns (bool) {
        return _isExcludedFromTaxes[account];
    }

    function totalTaxesSentToReflections() public view returns (uint256) {
        return tokensFromReflection(_totalTaxesReflectedToHodlers);
    }

    function totalTaxesSentToTreasury() public view returns (uint256) {
        return tokensFromReflection(_totalTaxesSentToTreasury);
    }

    function getETHBalance() public view returns (uint256 balance) {
        return address(this).balance;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokensFromReflection(_reflectionsOwned[account]);
    }

    function reflectionFromToken(
        uint256 amountOfTokens,
        bool deductTaxForReflections
    ) public view returns (uint256) {
        require(
            amountOfTokens <= _totalTokenSupply,
            "Amount must be less than supply"
        );
        if (!deductTaxForReflections) {
            (uint256 reflectionsToDebit, , , ) = _getValues(amountOfTokens);
            return reflectionsToDebit;
        } else {
            (, uint256 reflectionsToCredit, , ) = _getValues(amountOfTokens);
            return reflectionsToCredit;
        }
    }

    function tokensFromReflection(uint256 amountOfReflections)
        public
        view
        returns (uint256)
    {
        require(
            amountOfReflections <= _totalReflections,
            "ERC20: Amount too large"
        );
        uint256 currentRate = _getRate();
        return amountOfReflections.div(currentRate);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from 0 address");
        require(spender != address(0), "ERC20: approve to 0 address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // transfer function that sets up the context so that the
    // _tokenTransfer function can do the accounting work
    // to perform the transfer function
    function _transfer(
        address sender,
        address recipient,
        uint256 amountOfTokens
    ) private {
        require(sender != address(0), "ERC20: transfer from 0 address");
        require(recipient != address(0), "ERC20: transfer to 0 address");
        require(amountOfTokens > 0, "ERC20: Transfer more than zero");

        // if either side of transfer account belongs to _isExcludedFromTaxes
        // account then remove the fee
        bool takeFee = true;
        if (_isExcludedFromTaxes[sender] || _isExcludedFromTaxes[recipient]) {
            takeFee = false;
        }

        // check if we're buy side or sell side in a swap; if buy side apply
        // buy side taxes; if sell side then apply those taxes; duh
        bool buySide = false;
        if (sender == address(uniswapV2Pair)) {
            buySide = true;
        }

        // based on context set the correct fee structure
        if (!takeFee) {
            _setNoFees();
        } else if (buySide) {
            _setBuySideFees();
        } else {
            _setSellSideFees();
        }

        // conduct the transfer
        _tokenTransfer(sender, recipient, amountOfTokens);

        // reset the fees for the next go around
        _restoreAllFees();
    }

    // primary transfer function that does all the work
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amountOfTokens
    ) private {
        // when treasury transfers to the contract we automatically
        // remove these reflections from pool such that all token hodlers
        // benefit prorata and the treasury's reflections are removed.
        //
        // this allows for gas effective distribution of farming profits
        // to be returned cleanly to all token hodlers.
        //
        // we do not emit a Transfer event here because it is not strictly
        // speaking a transfer due to the lack of a recipient
        if (sender == _treasuryAddress && recipient == address(this)) {
            _manualReflect(amountOfTokens);
            return;
        }

        // the below allows for a consolidated handling of the necessary
        // math to support the possible transfer+tax combinations
        (
            uint256 reflectionsToDebit, // sender
            uint256 reflectionsToCredit, // recipient
            uint256 reflectionsToRemove, // to all the hodlers
            uint256 reflectionsForTreasury // to treasury
        ) = _getValues(amountOfTokens);

        // take taxes -- this is not a tax free zone ser
        _takeTreasuryTax(reflectionsForTreasury);
        _takeReflectionTax(reflectionsToRemove);

        // we potentially do any "inline" swapping after the taxes are taken
        // so that we know if there's balance to take.
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= _minimumTokensToSwap;
        if (!_inSwap && overMinTokenBalance && reflectionsForTreasury != 0) {
            _swapTokensForEth(contractTokenBalance);
        }
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            _sendETHToTreasury(address(this).balance);
        }

        // debit the correct reflections from the sender's account and credit
        // the correct number of reflections to the recipient's (accounting for
        // taxes)
        _reflectionsOwned[sender] = _reflectionsOwned[sender].sub(
            reflectionsToDebit
        );
        _reflectionsOwned[recipient] = _reflectionsOwned[recipient].add(
            reflectionsToCredit
        );

        // let the world know
        emit Transfer(sender, recipient, reflectionsToCredit.div(_getRate()));
    }

    // allows for treasury to cleanly distribute earnings back to
    // tokenhodlers pro rata
    function _manualReflect(uint256 amountOfTokens) private {
        uint256 currentRate = _getRate();
        uint256 amountOfReflections = amountOfTokens.mul(currentRate);

        // we remove the reflections from the treasury address and then
        // burn them by removing them from the reflections pool thus
        // reducing the denominator and "distributing" the reflections
        // to all hodlers pro rata
        _reflectionsOwned[_treasuryAddress] = _reflectionsOwned[
            _treasuryAddress
        ].sub(amountOfReflections);
        _totalReflections = _totalReflections.sub(amountOfReflections);
    }

    // reflections are added to the balance of this contract and are
    // subsequently swapped out with the uniswap pair within the same
    // transaction; the resulting eth is transfered to the treasury.
    //
    // the below function is simple accounting which will not survive
    // to the end of the transaction as long as the totaly amount of
    // reflections taken by the tax are more than the _minimumTokensToSwap
    //
    // in the case where they are not more than _minimumTokensToSwap
    // the tokens will not be swapped due to gas concerns and will simply
    // accrue within the contract until the contract's acyc balance is
    // more than _minimumTokensToSwap at which time the automatic swap
    // will occur sending eth to the treasury.
    function _takeTreasuryTax(uint256 reflectionsForTreasury) private {
        _reflectionsOwned[address(this)] = _reflectionsOwned[address(this)].add(
            reflectionsForTreasury
        );
        _totalTaxesSentToTreasury = _totalTaxesSentToTreasury.add(
            reflectionsForTreasury
        );
    }

    // reflections are "reflected" back to hodlers via a mechanism which
    // seeks to simply remove the amount of the tax from the total reflection
    // pool. since the token balance is a simple product of the amount of
    // reflections a hodler has in their account to the ratio of all the
    // reflections to the total token supply, removing reflections is a
    // gas efficient way of applying a benefit to all hodlers pro rata as
    // it lowers the denominator in the ratio thus increasing the result
    // of the product. in other words, by removing reflections the
    // numbers folks care about go up.
    function _takeReflectionTax(uint256 reflectionsToRemove) private {
        _totalReflections = _totalReflections.sub(reflectionsToRemove);
        _totalTaxesReflectedToHodlers = _totalTaxesReflectedToHodlers.add(
            reflectionsToRemove
        );
    }

    // baking this in so deeply will mean if the uni v2 pool ever dries up
    // then the contract will effectively stop functioning and it will need
    // to be migrated
    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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
            address(_treasuryAddress),
            block.timestamp
        );
    }

    function _sendETHToTreasury(uint256 amount) private {
        _treasuryAddress.transfer(amount);
    }

    // on buy side we collect tax and apply that to reflections; there is
    // no tax taken for the treasury on the buy side
    function _setBuySideFees() private {
        _currentTaxForReflections = _fixedTaxForReflections;
        _currentTaxForTreasury = 0;
    }

    // on sell side we collect tax and apply that to the treasury account;
    // there is no sell side tax taken for reflections
    function _setSellSideFees() private {
        _currentTaxForReflections = 0;
        _currentTaxForTreasury = _fixedTaxForTreasury;
    }

    // if a tax exempt address is transfering we turn off all the taxes
    function _setNoFees() private {
        _currentTaxForReflections = 0;
        _currentTaxForTreasury = 0;
    }

    // once a transfer occurs we reset the taxes. this is strictly speaking
    // not necessary due to the construction of the transfer function which
    // will opinionated-ly always set the tax structure before performing
    // the math (in the functions below). however, for reasons of super-
    // stition it remains
    function _restoreAllFees() private {
        _currentTaxForReflections = _fixedTaxForReflections;
        _currentTaxForTreasury = _fixedTaxForTreasury;
    }

    // this function is the primary math function which calculates the
    // proper accounting to support a transfer based on the context of
    // that transfer (buy side; sell side; tax free).
    function _getValues(uint256 amountOfTokens)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // given tokens split those out into what goes where (reflections,
        // treasury, and recipient)
        (
            uint256 tokensToTransfer,
            uint256 tokensForReflections,
            uint256 tokensForTreasury
        ) = _getTokenValues(amountOfTokens);

        // given the proper split of tokens, turn those into reflections
        // based on the current ratio of _tokenTokenSupply:_totalReflections
        uint256 currentRate = _getRate();
        uint256 reflectionsTotal = amountOfTokens.mul(currentRate);
        uint256 reflectionsToTransfer = tokensToTransfer.mul(currentRate);
        uint256 reflectionsToRemove = tokensForReflections.mul(currentRate);
        uint256 reflectionsForTreasury = tokensForTreasury.mul(currentRate);

        return (
            reflectionsTotal,
            reflectionsToTransfer,
            reflectionsToRemove,
            reflectionsForTreasury
        );
    }

    // the golden and necssary function that allows us to calculate the
    // ratio of total token supply to total reflections on which the
    // entire token accounting infrastructure resides
    function _getRate() private view returns (uint256) {
        return _totalReflections.div(_totalTokenSupply);
    }

    // the below function calculates where tokens needs to go based on the
    // inputted amount of tokens. n.b., this function does not work in
    // reflections, those typically happen later in the processing when the
    // token distribution calculated by this function is turned to reflections
    // based on the golden ratio of total token supply to total reflections.
    function _getTokenValues(uint256 amountOfTokens)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tokensForReflections = amountOfTokens
            .mul(_currentTaxForReflections)
            .div(100);
        uint256 tokensForTreasury = amountOfTokens
            .mul(_currentTaxForTreasury)
            .div(100);
        uint256 tokensToTransfer = amountOfTokens.sub(tokensForReflections).sub(
            tokensForTreasury
        );
        return (tokensToTransfer, tokensForReflections, tokensForTreasury);
    }
}