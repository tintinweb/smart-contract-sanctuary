/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

// !!! Copyright Infringement Notice !!!

// All rights reserved
// This code is for your eyes only.
// This piece of software is not free for public to copy, use, modify or distribute.
// In-contract Mining, Virtual Mining or In-Contract Reselling is Pioneered by LittlDogecoin.
// and we reserve our rights to take action to anyone found using or implementing these features without our permission.
// Do your due diligence!
// This piece of software is publickly available for viewing only. Deploying this into mainnet is not allowed until permission is granted.
// Patent application Filling; see _patentMetaData. Empty does not mean nothing was filed.
// see: https://choosealicense.com/no-permission/
/**
 #                                    ######                                           
 #       # ##### ##### #      ######  #     #  ####   ####  ######   #####   ####  # #    # 
 #       #   #     #   #      #       #     # #    # #    # #       #     # #    # # ##   # 
 #       #   #     #   #      #####   #     # #    # #      #####   #       #    # # # #  # 
 #       #   #     #   #      #       #     # #    # #  ### #       #       #    # # #  # # 
 #       #   #     #   #      #       #     # #    # #    # #       #     # #    # # #   ## 
 ####### #   #     #   ###### ######  ######   ####   ####  ######   #####   ####  # #    #  
**/
// SPDX-License-Identifier: No License

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.8.6;

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity >=0.8.6;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity >=0.8.6;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libs/IBEP20.sol

pragma solidity >=0.4.0;

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

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity >=0.8.6;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity >=0.8.6;

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
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "E27");
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
        require(newOwner != address(0), "E28");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/libs/BEP20.sol

pragma solidity >=0.4.0;

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public _name;
    string public _symbol;
    uint8 public _decimals;
 /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor()  {
        _name = "Little Dogecoin";
        _symbol = "ImDoge";
        _decimals = 9;
       _mint(msg.sender,10000000000e9);//10billion initial supply
    }
    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
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
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "E26")
        );
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
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "E25")
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "E22");
        require(recipient != address(0), "E23");

        _balances[sender] = _balances[sender].sub(amount, "E24");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "E29");

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
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "E20");

        _balances[account] = _balances[account].sub(amount, "E21");
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
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "E19");
        require(spender != address(0), "E18");

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
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, "E17")
        );
    }
}


abstract contract MerchantObject{
    using SafeMath for uint256;
    mapping(address => mapping(address => Membership)) private _memberships;
    mapping(address =>Merchant) _merchants;
    mapping(address =>Member) _members;
    uint public _totalMembers = 0;
    uint public _totalReseller = 0;
    uint256 public _totalBurned;
    address public _rewardAddress;
    address public _claimAddress;
    mapping(address => bool) _adminsAddresses;
    mapping(address => bool) _resellersAddresses;
    mapping(address => bool) _membersAddresses;
    uint16 public _burnRate = 0;
    uint256 public _currentRewardRate;
    mapping(address => Merchant) _subMerchant;
    struct Member{
        bool exist;
        string meta;
        bool locked;
        uint totalReseller;
        address[] resellers;
    }
    
    struct Membership{
        uint256 rewardRate;
        uint startDate;
        uint expiry;
        bool exist;
        string membershipMeta;
        bool locked;
        address reseller;
        address member;
    }
    
    struct Merchant{
        bool exist;
        uint startDate;
        uint expiry;
        uint totalCustomers;
        uint256 allocatedRate;
        uint256 maxRewardPerAddress;
        uint256 usedRewardRate;
        address parent;
        bool isChild;
        uint maxChild;
        uint totalChild;
        address[] members;
        string meta;
    }
    
    bool public _userCanMint = true;
    uint public _lastMint;
    uint256 public _maxMintingRate = 166666666700;
    uint256 public _totalMinted;
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMerchant() {
        require(_resellersAddresses[msg.sender], "E03");
        _;
    }
    
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(_adminsAddresses[msg.sender], "E02");
        _;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMember() {
        require(_membersAddresses[msg.sender], "E01");
        _;
    }
    
    event NewMember(address indexed memberAddress, address indexed merchant, address indexed addedBy, string meta);
    event NewMembership(address indexed memberAddress, address indexed merchant, address indexed addedBy, uint256 rewardRate, uint duration, uint256 reward, string meta);
    event Reward(address indexed memberAddress, address indexed merchant, address indexed addedBy, uint256 reward, string meta);
    event Extend(address indexed memberAddress, address indexed merchant, address indexed addedBy, uint duration, string meta);
    event Paid(address indexed merchant, address indexed childMerchant, address indexed fromAddress, uint256 amount, string payMeta);
    event NewReseller(address indexed reseller, address indexed addedBy, uint duration, uint256 maxRewardRate, uint256 maxRewardPerAddress, uint maxChild, string meta);
    event ResellerUpdated(address indexed reseller, address indexed addedBy, uint duration, uint256 maxRewardRate, uint256 maxRewardPerAddress, uint maxChild, string meta);
    
    function setRewardAddress(address rewardAddress) public virtual onlyAdmin{
        _rewardAddress = rewardAddress;
        _lastMint = block.timestamp;
    }
    
    function addUpdateMerchant(address reseller, uint duration, uint256 allocatedRate, uint256 maxRewardPerAddress, uint maxSubAccount, string calldata meta) public onlyAdmin{
        _merchants[reseller].startDate = _merchants[reseller].startDate == 0 ? block.timestamp: _merchants[reseller].startDate;
        _merchants[reseller].expiry += duration > 0 ? block.timestamp.add(duration) : 0;
        _merchants[reseller].allocatedRate += allocatedRate > 0 ? allocatedRate : 0;
        _merchants[reseller].maxRewardPerAddress += maxRewardPerAddress > 0 ? maxRewardPerAddress : 0;
        _merchants[reseller].meta = meta;
        if(_merchants[reseller].exist == false){
            _merchants[reseller].exist = true;
            _merchants[reseller].maxChild = maxSubAccount;
            _resellersAddresses[reseller]=true;
            _totalReseller += 1;
            emit NewReseller(reseller, msg.sender, duration, allocatedRate, maxRewardPerAddress, maxSubAccount, meta);
        } else {
            emit ResellerUpdated(reseller, msg.sender, duration, allocatedRate, maxRewardPerAddress, maxSubAccount, meta);
        }
    }
    function addSubAccount(address childAddress)public onlyMerchant returns(uint code){
        if(_merchants[msg.sender].exist == false) return 1;
        if(_merchants[msg.sender].isChild == true) return 2;
        if(_merchants[msg.sender].maxChild > _merchants[msg.sender].totalChild.add(1)) return 3;
        if(_merchants[childAddress].exist == true) return 4;
        _merchants[childAddress].isChild = true;
        _merchants[childAddress].parent = msg.sender;
        _merchants[msg.sender].totalChild +=1;
    }
    
    function isSubAccount(address merchantAddress) public view returns(bool isChild){
        return _merchants[merchantAddress].exist &&_merchants[merchantAddress].isChild;
    }
    
    
    function isMainAccount(address merchantAddress) public view returns(bool isChild){
        return _merchants[merchantAddress].exist &&_merchants[merchantAddress].isChild==false;
    }
    function removeSubAccount(address merchantAddress) public onlyMerchant returns(uint code){
        if(_merchants[merchantAddress].isChild == false) return 1;
        if(_merchants[merchantAddress].parent != msg.sender) return 2;
        address merchAddress = _merchants[merchantAddress].parent;
        _merchants[merchAddress].isChild = false;
        _merchants[merchAddress].totalChild -= 1;
    }
    
    function addUpdateMember(address memberAddress, string calldata memberMeta)public onlyMerchant returns(uint result){
        address merchAddress = _merchants[msg.sender].isChild ? _merchants[msg.sender].parent : msg.sender;
        if(_members[memberAddress].locked == true) return 1;
        if(_merchants[merchAddress].expiry < block.timestamp) return 2;
        if(_members[memberAddress].exist == false){
            _totalMembers += 1;
            _members[memberAddress].exist = true;
            _membersAddresses[memberAddress] = true;
            _merchants[merchAddress].members.push(memberAddress);
            _members[memberAddress].resellers.push(merchAddress);
            emit NewMember(memberAddress, merchAddress, msg.sender, memberMeta);
        }
        _members[memberAddress].meta = memberMeta;
        return 0;
    }
    
    function addMembership(address memberAddress, uint256 rewardRate, uint duration, uint256 reward, string calldata membershipMeta)public onlyMerchant returns(uint code){
        address merchAddress = _merchants[msg.sender].isChild ? _merchants[msg.sender].parent : msg.sender;
        if(_members[memberAddress].exist && _members[memberAddress].locked == true) return 1;
        if(_memberships[merchAddress][memberAddress].exist == true) return 2;
        if(_merchants[merchAddress].expiry < block.timestamp) return 3;
        
        if(_members[memberAddress].exist == false) {
            _totalMembers += 1;
            _members[memberAddress].exist = true;
            _membersAddresses[memberAddress] = true;
            _members[memberAddress].meta = '{name:default}';
            _merchants[merchAddress].members.push(memberAddress);
            emit NewMember(memberAddress, merchAddress, msg.sender, _members[memberAddress].meta);
        }
        
        if(_currentRewardRate.add(rewardRate > 0 ? rewardRate : 0) > _maxMintingRate) return 4;
        
        if(_memberships[merchAddress][memberAddress].exist == false){
            _memberships[merchAddress][memberAddress].expiry = duration!=0? block.timestamp.add(duration):0;
            _memberships[merchAddress][memberAddress].membershipMeta = membershipMeta;
            _memberships[merchAddress][memberAddress].startDate = block.timestamp;
            _memberships[merchAddress][memberAddress].rewardRate = rewardRate;
            _memberships[merchAddress][memberAddress].reseller = merchAddress;
            _memberships[merchAddress][memberAddress].member = memberAddress;
            _memberships[merchAddress][memberAddress].exist = true;
            _members[memberAddress].totalReseller += 1;
            _members[memberAddress].resellers.push(merchAddress);
            _merchants[merchAddress].totalCustomers += 1;
            _merchants[merchAddress].members.push(memberAddress);
            _currentRewardRate += rewardRate > 0 ? rewardRate : 0;
            
            if(reward > 0) transferMerchant(memberAddress, reward);
            emit NewMembership(memberAddress, merchAddress, msg.sender, rewardRate, duration, reward, membershipMeta);
        }
        return 0;
    }
    
    function updateMembership(address memberAddress, uint256 rewardRate, uint duration, uint256 reward, string calldata membershipMeta)public onlyMerchant returns(uint code){
        address merchAddress = _merchants[msg.sender].isChild ? _merchants[msg.sender].parent : msg.sender;
        if(_members[memberAddress].exist && _members[memberAddress].locked == true) return 1;
        if(_merchants[merchAddress].usedRewardRate.add(rewardRate) > _merchants[merchAddress].allocatedRate) return 2;
        if(_memberships[merchAddress][memberAddress].exist == false) return 3;
        if(_memberships[merchAddress][memberAddress].locked == true) return 4;
        if(_memberships[merchAddress][memberAddress].rewardRate !=0) return 5;
        if(_members[memberAddress].exist == false)  return 6;
        if(_memberships[merchAddress][memberAddress].expiry == 0) return 7;
        if(_merchants[merchAddress].expiry < block.timestamp) return 8;
        if(_currentRewardRate.add(rewardRate > 0 ?rewardRate : 0) > _maxMintingRate) return 9;
        
        _memberships[merchAddress][memberAddress].expiry += duration != 0? block.timestamp.add(duration) : 0;
        _memberships[merchAddress][memberAddress].membershipMeta = membershipMeta;
        _memberships[merchAddress][memberAddress].rewardRate += rewardRate > 0 ? rewardRate : 0;
        _memberships[merchAddress][memberAddress].reseller = merchAddress;
        _merchants[merchAddress].usedRewardRate += rewardRate > 0 ? rewardRate : 0;
        _currentRewardRate += rewardRate > 0 ? rewardRate : 0;
        
        if(reward > 0) transferMerchant(memberAddress, reward);
        if(reward > 0)  emit Reward(memberAddress, merchAddress, msg.sender, reward, membershipMeta);
        if(duration >0) emit Extend(memberAddress, merchAddress, msg.sender, duration, membershipMeta);
        emit NewMembership(memberAddress, merchAddress, msg.sender, rewardRate, duration, reward, membershipMeta);
        return 0;
    }
    
    function updateLifeTimeMembership(address memberAddress, uint256 rewardRate, string calldata updateMeta)public onlyMerchant returns(uint code){
        address merchAddress = _merchants[msg.sender].isChild ? _merchants[msg.sender].parent : msg.sender;
        if(_memberships[merchAddress][memberAddress].exist == false || _memberships[merchAddress][memberAddress].exist == true && _memberships[merchAddress][memberAddress].expiry != 0) return 1;
        if(_memberships[merchAddress][memberAddress].rewardRate >= rewardRate) return 2;
        if(_merchants[merchAddress].expiry < block.timestamp) return 3;
        _memberships[merchAddress][memberAddress].rewardRate = rewardRate;
        //
        //event NewMembership(address indexed memberAddress, address indexed merchant, address indexed addedBy, uint256 rewardRate, uint duration, uint256 reward, string meta);
        emit NewMembership(memberAddress, merchAddress, msg.sender, rewardRate, 0e9, 0, updateMeta);
        return 0;
    }
    
    function getClaimable(address merchantAddress, address memberAddress) public view returns(uint code, uint256 unclaimed){
        address merchAddress = _merchants[merchantAddress].isChild ? _merchants[merchantAddress].parent : merchantAddress;
        if(_members[memberAddress].exist == false) return (1, 0e9);
        if(_memberships[merchAddress][memberAddress].exist == false) return (2, 0e9);
        if(_memberships[merchAddress][memberAddress].expiry < block.timestamp && _memberships[merchAddress][memberAddress].rewardRate == 0) return (3, 0e9);
        uint span = _memberships[merchAddress][memberAddress].expiry > block.timestamp? block.timestamp.sub(_memberships[merchAddress][memberAddress].startDate) : _memberships[merchAddress][memberAddress].expiry.sub(_memberships[merchAddress][memberAddress].startDate);
        return (0, span.mul(_memberships[merchAddress][memberAddress].rewardRate));
    }
    
    function getMembershipInfo(address merchantAddress, address memberAddress) public view returns(uint256 rate, uint expiry, uint startDate, string memory meta, bool locked) {
        address merchAddress = _merchants[merchantAddress].isChild ? _merchants[merchantAddress].parent : merchantAddress;
        return (_memberships[merchAddress][memberAddress].rewardRate,
            _memberships[merchAddress][memberAddress].expiry,
            _memberships[merchAddress][memberAddress].startDate,
            _memberships[merchAddress][memberAddress].membershipMeta,
            _memberships[merchAddress][memberAddress].locked
        );
    }
    
    function getMerchantInfo(address merchantAddress)public view returns(uint totalCustomers, uint expiry, uint256 allocatedRate, uint256 usedReward, uint256 maxReward, bool isExpired){
        address merchAddress = _merchants[merchantAddress].isChild ? _merchants[merchantAddress].parent : merchantAddress;
        return (_merchants[merchAddress].totalCustomers, _merchants[merchAddress].expiry, _merchants[merchAddress].allocatedRate, _merchants[merchAddress].usedRewardRate, _merchants[merchAddress].maxRewardPerAddress, _merchants[merchAddress].expiry<block.timestamp);
    }
    
    function getMerchantCount(address memberAddress)public view returns(uint count){
        return _members[memberAddress].resellers.length;
    }
    
    function getMerchantByIndex(address memberAddress, uint index)public view returns(address merchant){
        return _members[memberAddress].resellers[index];
    }
    /**
    * @dev use case: A specific merchant cashier's terminal can get notified when a customer completes the payment.
    */
    function pay(address merchantAddress, uint256 amount, string calldata payMeta)public returns(bool success){
        address merchAddress = _merchants[merchantAddress].isChild ? _merchants[merchantAddress].parent : merchantAddress;
        transferMerchant(merchAddress, amount);
        emit Paid(merchAddress, merchantAddress, msg.sender, amount, payMeta);
        return true;
    }
    
    function updateLock(address merchantAddress, bool state) public onlyMember returns(uint code){
        address merchAddress = _merchants[merchantAddress].isChild ? _merchants[merchantAddress].parent : merchantAddress;
        if(_memberships[merchAddress][msg.sender].exist==false) return 1;
        
        _memberships[merchAddress][msg.sender].locked = state;
        return 0;
    }
    
    function claim(address merchantAddress) public onlyMember returns(uint claimCode, uint totalClaimed){
        address merchAddress = _merchants[merchantAddress].isChild ? _merchants[merchantAddress].parent : merchantAddress;
        uint time = block.timestamp;
        (uint code, uint256 total) = getClaimable(merchAddress, msg.sender);
        if(balanceOfMerchant(_rewardAddress) > total.mul(_burnRate)) burnMerchant(_rewardAddress, total.mul(_burnRate));
        if(_memberships[merchAddress][msg.sender].expiry > time){
            _memberships[merchAddress][msg.sender].rewardRate = 0;
        } else {
            _memberships[merchAddress][msg.sender].startDate = time;
        }
        claimRewards(merchAddress);
        return (code, total);
    }
    
    function setSettings(address newRewardAddress, uint16 bRate)public onlyAdmin{
        _rewardAddress = newRewardAddress;
        _burnRate = bRate;
    }
    
    
    function setClaimFrom(address claimAddress) public onlyAdmin{
        _claimAddress = claimAddress;
    }
    
    function claimRewards(address reseller) public virtual;
    function transferMerchant(address merchantAddress, uint256 amount) public virtual;
    function balanceOfMerchant(address owner)public virtual view returns (uint256 balance);
    function burnMerchant(address from, uint256 amount) public virtual;
}
// File: contracts/LittleDogecoin.sol

pragma solidity >=0.8.6;

// 
// LittleDogecoin with Governance and Merchant.
// Hybride BEP-20 Smart Contract with In-Contract Merchant Support 
// to Simplify unlimited 3rd Party Integration such as gaming and Merchants.
// The multi-user feature allow's 3rd party to integrate their 
// business solutions directly into the smart contract.
//
contract LittleDogecoin is BEP20, MerchantObject {
    using SafeMath for uint256;
    
    mapping(address => bool) _operator;
    mapping(address => bool) _scammerAddress;
    mapping(address => bool) _botAddress;
    string public _patentMetaData;
    uint256 _maxSupply = 100000000000e9; //100billion max supply
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Max transfer amount rate in basis points. (default is 0.1% of total supply)
    uint16 public maxTransferAmountRate = 10;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
	// Swap enabled when launch
    bool public swapEnabled = true;
    // The swap router, modifiable. Will be changed to LilDOGE's router when our own AMM release
    IUniswapV2Router02 public LilDOGERouter;
    // The trading pair
    address public lilDOGEPair;
    // In swap and liquify
    bool private _inSwapAndLiquify;
    // Events
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event BurnRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event MaxTransferAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event SwapEnabledUpdated(address indexed owner, bool enabled);
    event MinAmountToLiquifyUpdated(address indexed operator, uint256 previousAmount, uint256 newAmount);
    event LilDOGEPairRouterUpdated(address indexed operator, address indexed router, address indexed pair);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);


    /**
     * @notice Constructs the LilDOGEToken contract.
     */
    constructor() BEP20() {
        _operator[_msgSender()] = true;
        _adminsAddresses[msg.sender] = true;
        emit OperatorTransferred(address(0), msg.sender);
        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;
    }

    
    modifier onlyOperator() {
        require(_operator[msg.sender], "E16");
        _;
    }

    modifier transactionControl(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxTransferAmount(), "E12");//LilDOGE::antiWhale: Transfer amount exceeds the maxTransferAmount
                require(swapEnabled == true, "E11");//LilDOGE::swap: Cannot transfer at the moment
                require(_botAddress[recipient] == false, "E14");//LilDOGE::swap: Cannot transfer at the moment
                require(_scammerAddress[sender] == false ||_scammerAddress[recipient] == false, "E15");//LilDOGE::swap: Cannot transfer at the moment
            } 
        }
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    /**
    * @dev Mint $LilDOGE token.
    * The minted tokens will be used for marking and eco-system growth.
    * public can call this when allowed but the token will go to specific addresses. caller to shoulder the gas fee.
    **/
    function mintRewards() public returns(uint256){
        if(swapEnabled!=true && (_msgSender() != owner()) && _userCanMint == false) return 0;
        uint256 amount = (block.timestamp.sub(_lastMint)).mul(_currentRewardRate);
        if(_totalMinted.add(amount)>_maxSupply){
            amount = _maxSupply.sub(_totalMinted);
            _userCanMint = false;
        }
        if(amount > 0) _mint(_rewardAddress, amount);
        _totalMinted = _totalMinted.add(amount);
        _lastMint = block.timestamp;
        return amount;
    }
    
    function setPatentMeta(string calldata patentMeta) public onlyOwner{
        _patentMetaData = patentMeta;
    }
    function updateMintingRate(uint256 rate)public onlyOperator{
        _maxMintingRate = rate;
    }
    function updateUserCanMint(bool state)public  onlyOperator{
        _userCanMint = state;
    }
    function setScamAddess(address scammerAddress, bool state) public onlyOperator{
        _scammerAddress[scammerAddress] = state;
    }
    function setBotAddess(address botAddress, bool state) public onlyOperator{
        _botAddress[botAddress] = state;
    }
    
    function isScammerAddress(address scammerAddress) public view returns(bool state){
        return _scammerAddress[scammerAddress];
    }
    function isBotAddress(address botAddress) public view returns(bool state){
        return _botAddress[botAddress];
    }
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override transactionControl(sender, recipient, amount) {
        
        mintRewards();
        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(1000000);
    }
    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    // To receive BNB from LilDOGERouter when swapping
    receive() external payable {}

    /**
     * @dev Update the burn rate.
     * Can only be called by the current operator.
     */
    function updateBurnRate(uint16 burnRate) public onlyOperator {
        require(_burnRate <= 100, "E13");//LilDOGE::updateBurnRate: Burn rate must not exceed the maximum rate.
        emit BurnRateUpdated(msg.sender, _burnRate, burnRate);
        _burnRate = burnRate;
    }

    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOperator {
        require(_maxTransferAmountRate <= 10000, "E09");//LilDOGE::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOperator {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    /**
     * @dev Update the swapEnabled. Can only be called by the current Owner.
     */
    function UpdateSwapEnabled(bool _enabled) public onlyOwner {
        emit SwapEnabledUpdated(msg.sender, _enabled);
        swapEnabled = _enabled;
    }	
	
    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateLilDOGERouter(address _router) public onlyOperator {
        LilDOGERouter = IUniswapV2Router02(_router);
        lilDOGEPair = IUniswapV2Factory(LilDOGERouter.factory()).getPair(address(this), LilDOGERouter.WETH());
        require(lilDOGEPair != address(0), "E08");//LilDOGE::updateLilDOGERouter: Invalid pair address.
        emit LilDOGEPairRouterUpdated(msg.sender, address(LilDOGERouter), lilDOGEPair);
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (bool) {
        return _operator[msg.sender];
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function serOperator(address newOperator, bool state) public onlyOperator {
        require(newOperator != address(0), "E10");//LilDOGE::transferOperator: new operator is the zero address
        _operator[newOperator] = state;
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "E05");//LilDOGE::delegateBySig: invalid signature
        require(nonce == nonces[signatory]++, "E06");//LilDOGE::delegateBySig: invalid nonce
        require(block.timestamp <= expiry, "E07");//LilDOGE::delegateBySig: signature expired
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "E04");//LilDOGE::getPriorVotes: not yet determined

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying LilDOGEs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "E13");//LilDOGE::_writeCheckpoint: block number exceeds 32 bits

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
    
    function transferMerchant(address to, uint256 amount) public override {
        transfer(to, amount);
    }
    function balanceOfMerchant(address owner) public override view returns(uint256 balance){
        return balanceOf(owner);
    }
    function burnMerchant(address source, uint256 amount) public override {
        _totalBurned += amount;
        _burn(source, amount);
    }
    function claimRewards(address reseller) public override{
        (, uint256 total) = getClaimable(reseller, _msgSender());
        super._transfer(_claimAddress, _msgSender(), total);
    }
    function setRewardAddress(address rewardAddress) public override onlyAdmin{
        if(swapEnabled != true) return;
        super.setRewardAddress(rewardAddress);
    }
}