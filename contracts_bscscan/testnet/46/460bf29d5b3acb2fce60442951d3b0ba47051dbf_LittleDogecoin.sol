/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// !!! Copyright Infringement Notice !!!

// All rights reserved
// This code is for your eyes only.
// This piece of software is not free for public to copy, use, modify or distribute.
// In-contract Mining, Virtual Mining or In-Contract Reselling is Pioneered by LittlDogecoin.
// and we reserve our rights to take action to anyone found using or implementing these features without our permission.
// Do your due diligence!
// This piece of software is publickly available for viewing only. Deploying this into mainnet is not allowed until permission is granted.
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
        require(address(this).balance >= amount, "E41");//Address: insufficient balance

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "E40");//Address: unable to send value, recipient may have reverted
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
      return functionCall(target, data, "E42");//Address: low-level call failed
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
        return functionCallWithValue(target, data, value, "E43");//Address: low-level call with value failed
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "E44");//Address: insufficient balance for call
        require(isContract(target), "E45");//Address: call to non-contract

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
        return functionStaticCall(target, data, "E46");//Address: low-level static call failed
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "E47");//Address: static call to non-contract

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
        return functionDelegateCall(target, data, "E48");//Address: low-level delegate call failed
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "E49");//Address: delegate call to non-contract

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
        require(c >= a, "E50");//SafeMath: addition overflow
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
        require(b <= a, "E51");//SafeMath: subtraction overflow
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
        require(c / a == b, "E52");//SafeMath: multiplication overflow
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
        require(b > 0, "E53");//SafeMath: division by zero
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
        require(b > 0, "E54");//SafeMath: modulo by zero
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
abstract contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) public _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    address public _busd = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    uint256 public _totalSupply;

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
       _mint(msg.sender,100000000000e9);//100billion initial supply
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
        _totalSupply = _totalSupply.sub(amount, 'E78');
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

// File: contracts/LittleDogecoin.sol

pragma solidity >=0.8.6;

// 
// LittleDogecoin with Merchant.
// Hybride BEP-20 Smart Contract with In-Contract Merchant Support 
// to Simplify unlimited 3rd Party Integration such as gaming and Merchants.
// The multi-user feature allow's 3rd party to integrate their 
// business solutions directly into the smart contract.
//
abstract contract Token is BEP20 {
    using SafeMath for uint256;
    
    mapping(address => bool) _adminsAddresses;
    mapping(address => bool) _operator;
    mapping(address => bool) _scammerAddress;
    mapping(address => bool) _botAddress;
    //uint256 _maxSupply = 100000000000e9; //100billion max supply
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Max transfer amount rate in basis points. (default is 0.1% of total supply)
    uint16 public maxTransferAmountRate = 10;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
	// Swap enabled when launch
    bool public swapEnabled = false;
    // The swap router, modifiable. Will be changed to LilDOGE's router when our own AMM release
    IUniswapV2Router02 public LilDOGERouter;// = address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    // The trading pair
    address public lilDOGEPair;
    // In swap and liquify
    bool public _inSwapAndLiquify;
    uint public _lastMint = 0;
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
                IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        lilDOGEPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        LilDOGERouter = _uniswapV2Router;
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
                require(_scammerAddress[sender] == false && _scammerAddress[recipient] == false, "E15");//LilDOGE::swap: Cannot transfer at the moment
            } 
        }
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
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
    function mint(address _to, uint256 _amount) public onlyOwner{
        _mint(_to, _amount);
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
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (bool) {
        return _operator[msg.sender];
    }
    /**
     * @dev Update the swapEnabled. Can only be called by the current Owner.
     */
    function UpdateSwapEnabled(bool _enabled) public onlyOwner {
        emit SwapEnabledUpdated(msg.sender, _enabled);
        if(_lastMint==0) _lastMint = block.timestamp;
        swapEnabled = _enabled;
    }
	
     /// @dev Swap and liquify
    function swapAndLiquify() internal lockTheSwap onlyOperator{
        uint256 minAmountToLiquify = 10e9;
        if (_balances[address(this)] >= minAmountToLiquify) {
            // only min amount to liquify
            //uint256 liquifyAmount = minAmountToLiquify;

            // split the liquify amount into halves
            uint256 half = minAmountToLiquify.div(2);
            uint256 otherHalf = minAmountToLiquify.sub(half);

            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for ETH
            swapTokensForEth(half);

            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);

            // add liquidity
            addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the lava pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = LilDOGERouter.WETH();

        _approve(address(this), address(LilDOGERouter), tokenAmount);

        // make the swap
        LilDOGERouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    /// @dev Add liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(LilDOGERouter), tokenAmount);

        // add the liquidity
        LilDOGERouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateLilDOGERouter(address _router) public onlyOwner {
        LilDOGERouter = IUniswapV2Router02(_router);
        lilDOGEPair = IUniswapV2Factory(LilDOGERouter.factory()).getPair(address(this), _busd);
        require(lilDOGEPair != address(0), "E08");//LilDOGE::updateLilDOGERouter: Invalid pair address.
        emit LilDOGEPairRouterUpdated(msg.sender, address(LilDOGERouter), lilDOGEPair);
    }
}

pragma solidity >=0.8.6;
/**
 * @dev Little Dogecoin contribution to ISO20022 standard.
 * For pure decentralized payment integration.
 * This interface requires the implementation of pay function and
 * defines Paid event to notify specific payment station such as POS 
 * during successful payment using specific transactionId.
 * 
 * Standard-Essential Patent (SEP) - ask permission before implementation.
 */
interface ISO20022ForPaymentV1 {
    
    /**
     * @dev Call pay method to set specific payment information.
     * All input parameter can come from a QR code generated by
     * a specific terminal requesting and receiving a payment.
     */
    function pay(address stationAddress, 
                 uint256 paidAmount, 
                  string calldata transactionId, 
                  string calldata campaignCode,
                    uint expiry,
                  string calldata payMeta)external;
    /**
     * @dev emit Paid event to notify subcribers waiting for payment.
     */
    event Paid(address indexed merchantAddress,
               address stationAddress,
               address indexed payeeAddress, 
               uint256 paidAmount, 
                string indexed transactionId, 
                string campaignCode,
                string payMeta
            );
}

pragma solidity >=0.8.6;
//import "@../contracts/MerchantObject.sol";

contract LittleDogecoin is Token, ISO20022ForPaymentV1{
    using SafeMath for uint256;
    mapping(address => mapping(address => Membership)) private _memberships;
    mapping(address =>Merchant) _merchants;
    mapping(address =>Member) _members;
    mapping(string => Campaign) _campaigns;
    uint public _totalMembers = 0;
    uint public _totalMerchants = 0;
    mapping(address => bool) _merchantAddresses;
    mapping(address => bool) _membersAddresses;
    uint16 public _burnRate = 0;
    uint256 public _currentRewardRate = 11574074074;
    uint256 public _refundPerTransaction = 100000000;
    uint256 public _minHoldingForRefund = 100000e9;
    uint256 public _minMerchantHoldingForRefund = 100000e9;
    uint256 public _minSupplyToRefund = 10000000e9;
    mapping(string=>address) symbols;
    uint public blockTimeStamp = block.timestamp;
    
    struct Member{
        bool exist;
        string meta;
        uint totalMerchant;
        address[] merchants;
    }
    
    struct Membership{
        uint256 rewardRate;
        uint startDate;
        uint expiry;
        bool exist;
        string membershipMeta;
        address merchant;
        address member;
        bool autoClaimLock;
    }
    struct Merchant{
        bool exist;
        uint startDate;
        uint expiry;
        uint totalCustomers;
        uint256 allocatedRate;
        uint256 maxRewardPerAddress;
        uint256 usedRewards;
        address parent;
        address payto;
        bool isSubAccount;
        bool isSubAccountEnabled;
        uint maxSubAccounts;
        uint totalSubAccounts;
        address[] subaccounts;
        address[] members;
        string meta;
        uint subMaxDuration;
        uint256 subMaxRewardPerAddress;
        uint256 subMaxReward;
        uint256 subMaxRewardRate;
        uint256 payRefund;
        string requiredTokenSymbol;
    }
    //merchant can block abbusive customers;
    //mapping(address =>mapping(address=>BlockedAddress)) blocked;
    
    struct Campaign{
        address campaignAddress;
        uint256 reward; //token to be reward
        uint256 minimumSpend;
        uint256 rewardRate; //the rate of token to be mined
        uint rewardDuration; //mining reward duration
        bool enabled;
        address owner;//owner address
        string meta;
        uint expiry;
    }
    
    //struct BlockedAddress{
    //    bool blocked;
    //    string reason;
    //}
    uint256 public _maxGlobalRate = 14000000e9;
    uint256 public _totalMinted;
    /**
     * @dev Throws if called by any account other than the Merchant.
     */
    modifier onlyMerchant() {
        require(_merchantAddresses[msg.sender], "E03");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(_adminsAddresses[msg.sender], "E02");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the Member.
     */
    modifier onlyMember() {
        require(_membersAddresses[msg.sender], "E01");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the MainMerchant.
     */
    modifier onlyMainMerchant() {
        require(_merchants[msg.sender].exist && _merchants[msg.sender].isSubAccount==false, "E30");
        _;
    }
    
    event NewMember(address indexed memberAddress, address indexed addedBy, string meta);
    event NewMembership(address indexed memberAddress, address indexed merchant, address indexed addedBy, uint256 rewardRate, uint duration, uint256 reward, string campaign, string meta);
    event MembershipUpdated(address indexed memberAddress, address indexed merchant, address indexed addedBy, uint256 rewardRate, uint duration, uint256 reward, string campaign, string meta);
    event Reward(address indexed memberAddress, address indexed merchant, address indexed addedBy, uint256 reward, string campaign, string meta);
    event Extend(address indexed memberAddress, address indexed merchant, address indexed addedBy, uint duration, string campaign, string meta);
    event NewMerchant(address indexed merchant, address indexed addedBy, uint duration, uint256 maxRewardRate, uint256 maxRewardPerAddress, uint maxChild, string meta);
    event MerchantUpdated(address indexed merchant, address indexed addedBy, uint duration, uint256 maxRewardRate, uint256 maxRewardPerAddress, uint maxChild, string meta);
    event Claimed(address indexed merchant, address indexed member, uint256 amount);
    event Refunded(address indexed merchant, address indexed member, uint256 amount);
    
    function setSymbolAddress(string calldata symbol, address tokenAddress) public onlyAdmin{
        symbols[symbol]=tokenAddress;
    }
     /** Returns the Current Price of the Token */
    function calculatePrice() public view returns (uint256) {
        uint256 busdBalance = IBEP20(_busd).balanceOf(address(this));
        return busdBalance.div(_totalSupply);
    }
    function setRefundSettings(uint256 refundPerTransaction, uint256 minHoldingForRefund, uint256 minMerchantHoldingForRefund, uint256 minSupplyToRefund)public onlyAdmin{
        _refundPerTransaction = refundPerTransaction;
        _minHoldingForRefund = minHoldingForRefund;
        _minMerchantHoldingForRefund = minMerchantHoldingForRefund;
        _minSupplyToRefund = minSupplyToRefund;
    }
    
    function addUpdateMerchant(address merchantAddress, uint duration, uint256 allocatedRate, 
                               uint256 maxRewardPerAddress, uint maxSubAccount, string calldata meta) public onlyAdmin returns(uint code){
       require((bytes(meta).length  <= 256) && _merchants[merchantAddress].isSubAccount == false,'E55');
        _merchants[merchantAddress].startDate = _merchants[merchantAddress].startDate == 0 ? block.timestamp: _merchants[merchantAddress].startDate;
        
        _merchants[merchantAddress].maxRewardPerAddress = maxRewardPerAddress;
        _merchants[merchantAddress].meta = meta;
        _merchants[merchantAddress].subMaxRewardRate = _merchants[merchantAddress].subMaxRewardRate==0?1e9:_merchants[merchantAddress].subMaxRewardRate;
        _merchants[merchantAddress].subMaxDuration = _merchants[merchantAddress].subMaxDuration==0?86400:_merchants[merchantAddress].subMaxDuration;
        _merchants[merchantAddress].subMaxReward = _merchants[merchantAddress].subMaxReward==0?1e9:_merchants[merchantAddress].subMaxReward;
        _merchants[merchantAddress].allocatedRate = allocatedRate;
        if(_merchants[merchantAddress].exist == false){
            _merchants[merchantAddress].expiry = block.timestamp.add(duration);
            _merchants[merchantAddress].exist = true;
            _merchants[merchantAddress].maxSubAccounts = maxSubAccount;
            _merchantAddresses[merchantAddress]=true;
            _totalMerchants += 1;
            emit NewMerchant(merchantAddress, msg.sender, duration, allocatedRate, maxRewardPerAddress, maxSubAccount, meta);
        } else {
            _merchants[merchantAddress].expiry = _merchants[merchantAddress].expiry.add(duration);
            emit MerchantUpdated(merchantAddress, msg.sender, duration, allocatedRate, maxRewardPerAddress, maxSubAccount, meta);
        }
        return 0;
    }
    
    function addUpdateSubAccount(address childAddress, address paymentDestination, string calldata requiredTokenSymbol)public onlyMainMerchant{
        require(_merchants[childAddress].exist == false || (getParentAccount(childAddress) == msg.sender) &&
        (_merchants[msg.sender].maxSubAccounts <= _merchants[msg.sender].totalSubAccounts.add(1) && 
        (_merchants[msg.sender].expiry > block.timestamp)), 'E37');
        require(symbols[requiredTokenSymbol]!=address(0), 'E81');
        _merchants[childAddress].isSubAccount = true;
        _merchants[childAddress].isSubAccountEnabled = true;
        _merchants[childAddress].parent = msg.sender;
        if(_merchants[childAddress].exist == false){
            _merchants[msg.sender].totalSubAccounts +=1;
            _merchants[msg.sender].subaccounts.push(childAddress);
            _merchantAddresses[childAddress]=true;
            _merchants[childAddress].exist = true;
        }
        _merchants[childAddress].payto = paymentDestination;
        _merchants[childAddress].requiredTokenSymbol = requiredTokenSymbol;
    }
    
    //admin can set the merchat account to expire if found abusive;
    function setMerchantExpiry(address merchantAddress, uint expiry) public onlyAdmin{
        _merchants[merchantAddress].expiry = expiry;
    }
    function addUpdateCampaign(string calldata campaignCode, address campaignAddress, uint256 reward, uint256 minimumSpend, uint rewardRate, uint rewardDuration, string calldata meta, bool enable) public onlyMainMerchant returns(uint code){
        //same merchat can update the existing campaign code;
        require(_campaigns[campaignCode].enabled==false || _campaigns[campaignCode].enabled ==true && _campaigns[campaignCode].owner == msg.sender,'E59');
        //merchant cant setup reward rate higher that the purchased reward rate;
        require(_merchants[getParentAccount(msg.sender)].maxRewardPerAddress >= rewardRate, 'E61');
        require(_merchants[getParentAccount(msg.sender)].subMaxDuration >= rewardDuration, 'E79');
        require(_merchants[getParentAccount(msg.sender)].subMaxReward >= reward, 'E80');
        //campaign does not allow liftime rewards;
        require(rewardDuration > 0,'E62');
        require(_merchants[getParentAccount(msg.sender)].usedRewards.add(rewardRate) <= _merchants[getParentAccount(msg.sender)].allocatedRate,'E68');
        _campaigns[campaignCode].campaignAddress = campaignAddress;
        _campaigns[campaignCode].reward = reward;
        _campaigns[campaignCode].enabled = enable;
        _campaigns[campaignCode].minimumSpend = minimumSpend;
        _campaigns[campaignCode].rewardRate = rewardRate;
        _campaigns[campaignCode].rewardDuration = rewardDuration;
        _campaigns[campaignCode].meta = meta;
        _campaigns[campaignCode].owner = msg.sender;
        return 0;
    }
    
    function updateAccountLimits(uint256 subMaxRewardRate, uint subMaxDuration, uint256 subMaxReward, address paymentDestination) public onlyMainMerchant{
        require(_merchants[msg.sender].expiry > block.timestamp,'E32');
        require(_merchants[msg.sender].maxRewardPerAddress >= subMaxRewardRate, 'E66');
        _merchants[msg.sender].subMaxRewardRate = subMaxRewardRate;
        _merchants[msg.sender].subMaxDuration = subMaxDuration;
        _merchants[msg.sender].subMaxReward = subMaxReward;
        _merchants[msg.sender].payto = paymentDestination;
    }
    
    function getMerchantLimits(address merchantAddress)public view returns (uint256 subMaxRewardRate, uint subMaxDuration, uint256 subMaxReward){
        address merchAddress = getParentAccount(merchantAddress);
        return(_merchants[merchAddress].subMaxRewardRate, _merchants[merchAddress].subMaxDuration, _merchants[merchAddress].subMaxReward);
    }
    
    function getMerchantAccountType(address merchantAddress) public view returns(uint accontType){
        return _merchants[merchantAddress].exist &&_merchants[merchantAddress].isSubAccount?2:1;
    }
    
    function disableSubAccount(address childAddress) public onlyMainMerchant returns(bool result){
        require((_merchants[msg.sender].expiry > block.timestamp) &&
        (_merchants[childAddress].isSubAccount == true) &&
        (_merchants[childAddress].parent == msg.sender),'E31');
        address merchAddress = _merchants[childAddress].parent;
        _merchants[childAddress].isSubAccountEnabled = false;
        _merchants[merchAddress].totalSubAccounts -= 1;
        return true;
    }
    
    /**
     * @dev add member and add or update membership.
     */
    function addUpdateMembership(address memberAddress, uint256 rewardRate, uint duration, uint256 reward, string calldata campaign, string memory membershipMeta)public onlyMerchant returns(uint code){
        address merchAddress = getParentAccount(msg.sender);
        
        // don't allowed to update if the member choose to lock their account.
        
        //// merchant can not use more than the rewards they bought.
        require((_merchants[merchAddress].usedRewards.add(rewardRate) <= _merchants[merchAddress].allocatedRate) &&
        
        //merchant main address will not be allowed once expired.
        (_merchants[merchAddress].expiry >= block.timestamp) &&
        
        //rewarding will stop if we hit the global reward limit.
        (_currentRewardRate.add(rewardRate >= 0 ?rewardRate : 0) < _maxGlobalRate) &&
        
        //only main and enabled sub accounts can add/update membership;
        (_merchants[msg.sender].isSubAccount == false || (_merchants[msg.sender].isSubAccount == true && _merchants[msg.sender].isSubAccountEnabled == true) ) &&
        
        //must set before add membership. don't allow if the reward rate is more than the limit set for merchant;
        (_merchants[merchAddress].subMaxRewardRate >= rewardRate || _merchants[merchAddress].maxRewardPerAddress >= rewardRate) &&
        
        //must set before add membership. don't allow if the expiry duration is more than the limit set by main account.
        (_merchants[merchAddress].subMaxDuration >= duration) &&
        
        //must set before add membership. don't allow if the reward is more than the limit set by main account.
        (_merchants[merchAddress].subMaxReward >= reward) &&
        
        //strings has limits;
        (bytes(membershipMeta).length  <= 256) && (bytes(campaign).length  <= 256),'E35'); 
        
        return addUpdateMembershipInternal(memberAddress, merchAddress, duration, reward, rewardRate, campaign, membershipMeta);
    }
    
    function addUpdateMembershipInternal(address memberAddress, address merchAddress, uint duration, uint256 reward, uint256 rewardRate, string memory campaign, string memory membershipMeta)internal returns(uint code){
        
        if(_members[memberAddress].exist == false) {
            _totalMembers += 1;
            _members[memberAddress].exist = true;
            _membersAddresses[memberAddress] = true;
            _members[memberAddress].meta = '{name:default}';
            emit NewMember(memberAddress, msg.sender, _members[memberAddress].meta);
        }
        
        if (_memberships[merchAddress][memberAddress].exist == false){
            _memberships[merchAddress][memberAddress].expiry = duration != 0? block.timestamp.add(duration):0;
            _memberships[merchAddress][memberAddress].membershipMeta = membershipMeta;
            _memberships[merchAddress][memberAddress].startDate = block.timestamp;
            _memberships[merchAddress][memberAddress].rewardRate = rewardRate;
            _memberships[merchAddress][memberAddress].merchant = merchAddress;
            _memberships[merchAddress][memberAddress].member = memberAddress;
            _memberships[merchAddress][memberAddress].exist = true;
            _members[memberAddress].merchants.push(merchAddress);
            _merchants[merchAddress].totalCustomers += 1;
            _merchants[merchAddress].members.push(memberAddress);
            emit NewMembership(memberAddress, merchAddress, msg.sender, rewardRate, duration, reward, campaign, membershipMeta);
        } else {
            if(duration > 0){
                emit Extend(memberAddress, merchAddress, msg.sender, duration, campaign, membershipMeta);
            }
            claim(merchAddress,memberAddress);
            if(_memberships[merchAddress][memberAddress].expiry < block.timestamp){
                _memberships[merchAddress][memberAddress].expiry = block.timestamp.add(duration);
                _memberships[merchAddress][memberAddress].rewardRate = rewardRate > 0 ? rewardRate : 0;
            } else {
                _memberships[merchAddress][memberAddress].expiry = _memberships[merchAddress][memberAddress].expiry.add(duration);
                _memberships[merchAddress][memberAddress].rewardRate += rewardRate > 0 ? rewardRate : 0;
            }
            emit MembershipUpdated(memberAddress, merchAddress, msg.sender, rewardRate, duration, reward, campaign, membershipMeta);
        }
        
        _memberships[merchAddress][memberAddress].membershipMeta = membershipMeta;
        _merchants[merchAddress].usedRewards = _merchants[merchAddress].usedRewards.add(rewardRate);//todo why the rewards are not set?
        _currentRewardRate = _currentRewardRate.add(rewardRate);//todo why the rewards are not set?
        if(balanceOf(merchAddress) > reward){
            _transfer(merchAddress, memberAddress, reward);
        }
        if(reward !=0) {//todo why still transfering?
            emit Reward(memberAddress, merchAddress, msg.sender, reward, campaign, membershipMeta);
        }
        return 0;
    }
    
    /**
     * 
     * 
     */
    function getMerchantHashRate(address merchantAddress) public view returns(uint256 claimables){
        uint256 total;
        for(uint i = 0; i <_merchants[merchantAddress].members.length; i++ ){
            if(_memberships[merchantAddress][_merchants[merchantAddress].members[i]].expiry > block.timestamp){
                total += _memberships[merchantAddress][_merchants[merchantAddress].members[i]].rewardRate;
            }
        }
        return total;
    }
    /**
     * 
     * 
     */
    function getMerchantClaimables(address merchantAddress) public view returns(uint256 claimables){
        uint256 total;
        for(uint i = 0; i <_merchants[merchantAddress].members.length; i++ ){
            total += getClaimable(merchantAddress,_merchants[merchantAddress].members[i]);
        }
        return total;
    }
    function getMemberClaimables(address memberAddress)public view returns(uint256 claimables){
        uint256 total;
        for(uint i=0; i<_members[memberAddress].merchants.length; i++){
            if(_memberships[_members[memberAddress].merchants[i]][memberAddress].autoClaimLock==false){
                total += getClaimable(_members[memberAddress].merchants[i], memberAddress);
            }
        }
        return total;
    }
    function claimAll(address memberAddress) internal{
        if(_membersAddresses[memberAddress]){
            for(uint i=0; i<_members[memberAddress].merchants.length; i++){
                if(_memberships[_members[memberAddress].merchants[i]][memberAddress].autoClaimLock==false){
                    claim(_members[memberAddress].merchants[i],memberAddress);
                }
            }
        }
    }
    function setAutoClaimLock(address merchantAddress, bool state)public onlyMember{
        _memberships[merchantAddress][msg.sender].autoClaimLock=state;
    }
    function updateUsedRewardRate()public onlyMerchant{
        _merchants[getParentAccount(msg.sender)].usedRewards = getMerchantHashRate(getParentAccount(msg.sender));
    }
    
    function getClaimable(address merchantAddress, address memberAddress) public view returns(uint256 unclaimed){
        address merchAddress = getParentAccount(merchantAddress);
        uint span;
        if(_memberships[merchAddress][memberAddress].expiry == 0){
            span = block.timestamp.sub(_memberships[merchAddress][memberAddress].startDate, 'E70');
        }else{
            span = _memberships[merchAddress][memberAddress].expiry > block.timestamp? block.timestamp.sub(_memberships[merchAddress][memberAddress].startDate,'E72') : _memberships[merchAddress][memberAddress].expiry.sub(_memberships[merchAddress][memberAddress].startDate,'E73');
        }
        return (span.mul(_memberships[merchAddress][memberAddress].rewardRate));
    }
    
    function getMembershipInfo(address merchantAddress, address memberAddress) public view returns(uint256 rewardRate, uint expiry, uint startDate, string memory membershipMeta, uint256 claimable) {
        address merchAddress = getParentAccount(merchantAddress);
        return (_memberships[merchAddress][memberAddress].rewardRate,
            _memberships[merchAddress][memberAddress].expiry,
            _memberships[merchAddress][memberAddress].startDate,
            _memberships[merchAddress][memberAddress].membershipMeta,
            getClaimable(merchAddress,memberAddress));
    }
    
    function getMerchantInfo1(address merchantAddress)public view returns(uint totalCustomers, uint expiry, uint256 allocatedRate, uint256 usedRewards, uint256 maxRewardPerAddress, bool isExpired, uint totalSubAccount){
        address merchAddress = getParentAccount(merchantAddress);
        return (_merchants[merchAddress].totalCustomers, 
        _merchants[merchAddress].expiry, 
        _merchants[merchAddress].allocatedRate, 
        _merchants[merchAddress].usedRewards, 
        _merchants[merchAddress].maxRewardPerAddress, 
        _merchants[merchAddress].expiry < block.timestamp, 
        _merchants[merchAddress].totalSubAccounts);
    }
    
    function getMerchantInfo2(address merchantAddress)public view returns(uint256 subMaxRewardRate, uint256 subMaxReward, uint subMaxDuration, uint256 claimables){
        address merchAddress = getParentAccount(merchantAddress);
        return (_merchants[merchAddress].subMaxRewardRate, 
        _merchants[merchAddress].subMaxReward, 
        _merchants[merchAddress].subMaxDuration,
        getMerchantClaimables(merchAddress));
    }
    
    function getParentAccount(address merchantAddress)public view returns(address merchant){
        return _merchants[merchantAddress].isSubAccount ? _merchants[merchantAddress].parent : merchantAddress;
    }
    
    function getMerchantCount(address memberAddress)public view returns(uint count){
        return _members[memberAddress].merchants.length;
    }
    
    function getMerchantByIndex(address memberAddress, uint index)public view returns(address merchant){
        return _members[memberAddress].merchants[index];
    }
    
    function payShort(address stationAddress, uint256 amount, string memory campaignCode)public {
        string memory tx2 ='default_tx';
        string memory pm2 ='default_pm';
        pay(stationAddress, amount, tx2,campaignCode,block.timestamp,pm2);
    }
    /**
    * @dev use case: A specific merchant cashier's terminal can get notified when a customer completes the payment.
    * It automates rewarding when certain limits set by the merchant for their campaign is met.
    */
    function pay(address stationAddress, uint256 amount, string memory transactionId, string memory  campaignCode, uint expiry, string memory payMeta)public override{
        //payment can be done if transaction is not expired;
        require(expiry >= block.timestamp,'E56');
        //payment must have minimum amount
        require(amount >= 1000000,'E65');//0.0001 $LilDOGE;
        //pay can executed only for merchant account.
        require(_merchants[getParentAccount(stationAddress)].exist && bytes(transactionId).length.add(bytes(payMeta).length) <= 256,'E39');
        //super._transfer(msg.sender, getParentAccount(stationAddress), amount);
        if(_campaigns[campaignCode].enabled==true) executeCampaignReward(campaignCode, amount);
        if(balanceOf(msg.sender).sub(amount,'E74') >= _minHoldingForRefund && balanceOf(address(this)).sub(_refundPerTransaction,'E75')> 0 && _refundPerTransaction > 0) {
            refund(address(this), msg.sender, _refundPerTransaction);
        }
        
        swapTokensForDesiredToken(amount, _merchants[stationAddress].payto, _merchants[stationAddress].requiredTokenSymbol);
        emit Paid(getParentAccount(stationAddress), stationAddress, msg.sender, amount, transactionId, campaignCode, payMeta);
    }
    function balanceOfThis()public view returns(uint256 balance){
        return balanceOf(address(this));
    }
    
    function swapTokensForDesiredToken(uint256 tokenAmount, address recipient, string memory symbol) private {
        require(symbols[symbol]!=address(0),'E82');
        // generate the uniswap pair path of weth -> busd
        address[] memory path = new address[](2);
        path[0] = address(this);
        //path[1] = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
        path[1] = symbols[symbol];
        
        _approve(address(this), address(LilDOGERouter), tokenAmount);

        // make the swap
        uint256[] memory resultAmount = LilDOGERouter.swapExactTokensForTokens(
            tokenAmount,
            0, // accept any amount of BUSD
            path,
            _msgSender(),
            block.timestamp
        );
        IBEP20(symbols[symbol]).transfer(recipient, resultAmount[1]);
    }
    function getEthAddress()public view returns(address ethAddress){
        return LilDOGERouter.WETH();
    }
    function executeCampaignReward(string memory campaignCode, uint256 amount)internal{
        //dont execute the campaign if disabled or already expired.
        if(_campaigns[campaignCode].enabled==false && _campaigns[campaignCode].expiry < block.timestamp) return;

       // getParentAccount(_campaigns[campaignCode].owner);
        if(balanceOf(_campaigns[campaignCode].campaignAddress).sub(_campaigns[campaignCode].reward, 'E76') > 0 && amount >= _campaigns[campaignCode].minimumSpend) {
            refund(_campaigns[campaignCode].campaignAddress, msg.sender, _campaigns[campaignCode].reward);
        }
        if((amount >= _campaigns[campaignCode].minimumSpend) && (_campaigns[campaignCode].rewardRate > 0) && 
            (_merchants[getParentAccount(_campaigns[campaignCode].owner)].usedRewards.add(_campaigns[campaignCode].rewardRate) <= _merchants[getParentAccount(_campaigns[campaignCode].owner)].allocatedRate) &&
            (_currentRewardRate.add(_campaigns[campaignCode].rewardRate >= 0 ?_campaigns[campaignCode].rewardRate : 0) < _maxGlobalRate)){
            addUpdateMembershipInternal(msg.sender, getParentAccount(_campaigns[campaignCode].owner), _campaigns[campaignCode].rewardDuration, 0, _campaigns[campaignCode].rewardRate, campaignCode, _campaigns[campaignCode].meta);
        }
    }

    function claim(address merchantAddress, address memberAddress) internal returns(uint totalClaimed){
        address merchAddress = getParentAccount(merchantAddress);
        uint256 total = getClaimable(merchAddress, memberAddress);
        super._transfer(address(this), _msgSender(), total);
        emit Claimed(merchAddress, _msgSender(), total);
        
        if(balanceOf(address(this)) > total.mul(_burnRate)) _burn(address(this), total.mul(_burnRate));//todo figureout how
        if(_memberships[merchAddress][memberAddress].expiry!=0 && _memberships[merchAddress][memberAddress].expiry < block.timestamp){
            _merchants[merchAddress].usedRewards -= _memberships[merchAddress][memberAddress].rewardRate;
            _currentRewardRate-=_memberships[merchAddress][msg.sender].rewardRate;
            _memberships[merchAddress][memberAddress].rewardRate = 0;
        } else {
            _memberships[merchAddress][memberAddress].startDate = block.timestamp;
        }
        return total;
    }
    
    function setMintNRateSettings(uint256  mintRate, uint16 burnRate)public onlyAdmin{
        _maxGlobalRate = mintRate;
        _burnRate = burnRate;
    }
    
    function refund(address from, address to, uint256 amount) internal{
        if(balanceOf(from).sub(amount,'E77') < _minSupplyToRefund) return;
        super._transfer(from, to, amount);
        emit Refunded(from, to, amount);
    }

    function setAdmin(address adminAddress, bool state) public onlyOwner(){
        _adminsAddresses[adminAddress] = state;
    }
    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function setOperator(address newOperator, bool state) public onlyAdmin {
        require(newOperator != address(0), "E10");//LilDOGE::transferOperator: new operator is the zero address
        _operator[newOperator] = state;
    }
    
    /**
     * @dev Update the burn rate.
     * Can only be called by the current operator.
     */
    function updateBurnRate(uint16 burnRate) public onlyOwner {
        require(_burnRate <= 100, "E13");//LilDOGE::updateBurnRate: Burn rate must not exceed the maximum rate.
        emit BurnRateUpdated(msg.sender, _burnRate, burnRate);
        _burnRate = burnRate;
    }
    
    /**
    * @dev Mint $LilDOGE token.
    * The minted tokens will be used for marking and eco-system growth.
    * public can call this when allowed but the token will go to specific addresses. caller to shoulder the gas fee.
    **/
    function mintRewards() public returns(uint256){
        if(swapEnabled!=true && _lastMint==0) return 0;
        uint256 amount = (block.timestamp.sub(_lastMint, 'E78')).mul(_currentRewardRate);
        if(amount > 0) _mint(address(this), amount);
        //_totalMinted = _totalMinted.add(amount);
        _lastMint = block.timestamp;
        return amount;
    }
    /**
     * @dev when member do any transactions including pay, buy, sell and send, all claimables will be automatically claimed for all unlocked memberships.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override transactionControl(sender, recipient, amount) {
       
        mintRewards();
        claimAll(sender);
        super._transfer(sender, recipient, amount);
    }
    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account].add(getMemberClaimables(account));
    }
}