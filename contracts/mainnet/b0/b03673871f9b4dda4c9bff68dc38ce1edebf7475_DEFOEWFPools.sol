/**
 *Submitted for verification at Etherscan.io on 2020-12-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

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

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
	
	event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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


// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}


library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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

contract UniswapOracle {
	using FixedPoint for *;
	//Defo - ETH Price Oracle
	uint public constant PERIOD = 24 hours;
	uint public priceCumulativeLast;
	uint32 public blockTimestampLast;
	FixedPoint.uq112x112 public defoPrice;
	
	// The WETH Token
    IERC20 internal weth;
	IERC20 internal defholdLP; // The address of the DEFO-ETH Uniswap pool
	IERC20 internal defhold; // Defhold Token
	
	// The Uniswap v2 Factory
    IUniswapV2Factory internal uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
	
	// Info of token deposit .
	struct TokenList {
		address token;
		bool tokenStatus;
		uint256	totalAmount;
		uint	priceCumulativeLast;
		uint32	blockTimestampLast;
	}
	TokenList[] public tokenList;
	mapping(address => FixedPoint.uq112x112) public tokenPrice;
	mapping(address => uint256) public tokenIndex;
	mapping(address => bool) public existingToken;
	
	function _updateDefoPrice() internal {
		IUniswapV2Pair _pair = IUniswapV2Pair(address(defholdLP));
		
		address token0 = _pair.token0();
		uint price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
		uint price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
		uint112 reserve0;
		uint112 reserve1;
		if(blockTimestampLast == 0){
			(reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
			
			if (address(defhold) == token0) {
				priceCumulativeLast = price1CumulativeLast;
			} else {
				priceCumulativeLast = price0CumulativeLast;
			}
		}
		
		(uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(_pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
		
        // ensure that at least one full period has passed since the last update
        if(timeElapsed >= PERIOD){
			// overflow is desired, casting never truncates
			// cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
			
			if (address(defhold) == token0) {
				defoPrice = FixedPoint.uq112x112(uint224((price1Cumulative - priceCumulativeLast) / timeElapsed));
				priceCumulativeLast = price1Cumulative;
				
			} else {
				defoPrice = FixedPoint.uq112x112(uint224((price0Cumulative - priceCumulativeLast) / timeElapsed));
				priceCumulativeLast = price0Cumulative;
			}
			
			blockTimestampLast = blockTimestamp;
		}
	}
	
	function _updateTokenPrice(uint256 tid) internal {
		//Get Token to Eth Price
		IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(address(uniswapFactory), tokenList[tid].token, address(weth)));
		address token0 = _pair.token0();
		uint price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
		uint price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
		uint112 reserve0;
		uint112 reserve1;
		if(tokenList[tid].blockTimestampLast == 0){
			(reserve0, reserve1, tokenList[tid].blockTimestampLast) = _pair.getReserves();
			
			if (tokenList[tid].token == token0) {
				tokenList[tid].priceCumulativeLast = price0CumulativeLast;
			} else {
				tokenList[tid].priceCumulativeLast = price1CumulativeLast;
			}
		}
		
		(uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(_pair));
        uint32 timeElapsed = blockTimestamp - tokenList[tid].blockTimestampLast; // overflow is desired
		
		// ensure that at least one full period has passed since the last update
        if(timeElapsed >= PERIOD){
			// overflow is desired, casting never truncates
			// cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
			
			if (tokenList[tid].token == token0) {
				tokenPrice[tokenList[tid].token] = FixedPoint.uq112x112(uint224((price0Cumulative - tokenList[tid].priceCumulativeLast) / timeElapsed));
				tokenList[tid].priceCumulativeLast = price0Cumulative;
			} else {
				tokenPrice[tokenList[tid].token] = FixedPoint.uq112x112(uint224((price1Cumulative - tokenList[tid].priceCumulativeLast) / timeElapsed));
				tokenList[tid].priceCumulativeLast = price1Cumulative;
			}
			
			tokenList[tid].blockTimestampLast = blockTimestamp;
		}
	}
	
	function getAmountOut(uint256 tid, uint amountIn) public view returns (uint amountOut) {
		 uint ethAmount = tokenPrice[tokenList[tid].token].mul(amountIn).decode144();
		 amountOut = defoPrice.mul(ethAmount).decode144();
    }	
	
}

contract DEFOEWFPools is UniswapOracle, Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	
	// The Uniswap v2 Router
    IUniswapV2Router02 internal uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		
	
	address private devAddress; // Dev Address
	
	uint256 public LONGESTFARMINGPOOLTIME; // Longest Farming pool time
	uint256 public LONGESTSTAKINGPOOLTIME; // Longest Staking pool time
	uint256 public LONGESTFARMINGPOOLID; // Longest Farming pool id
	uint256 public LONGESTSTAKINGPOOLID; // Longest Staking pool id
	uint256 public FARMPOOLCOUNT; // Farming pool Count
	uint256 public STAKINGPOOLCOUNT; // Staking pool Count
	uint256 public tokenCount;
	
	uint256 private _decimal = 18; //pool decimal
	uint256 private _decimalConverter = 10**18; //pool decimal converter
	uint256 private _divRate = 10000; // Using for div precentage rate
	
	// All pools will be available at any time (i.e. there will be no commencement date). 
	// Each investor can join the desired pool whenever he wants. 
	// The end of his lock-up period will be calculated automatically by the Smart Contract.
	// Moreover, each time a pool reaches the lock-up period of a faster pool, investorsâ€™ funds will be automatically transferred into the faster pool 
	// (in this case the EWF and rewards will automatically change to match those of the pool in which the tokens are transferred).
	
	// Info of each pool.
	struct PoolLists{
		bool is_farming; // true is farming pool, false is staking pool
		string pool_name; // Pool Name
		uint256 EWFTime; // Early Withdraw Fee Time limit in second
		uint256 EWFRate; // Early Withdraw Fee Rate with mul 10000
		uint256 totalUsers; // Total User Join
		uint256 activeAmount; // Total active amount
		uint256 overTimeAmount; // Total over time amount
		uint256 totalAmount; // Total amount
		uint256 activeDeposit; // total of active Farming deposit 
		uint256 depositCount; // total of Farming deposit 
		uint256 depositIndex; // last over time deposit index
		uint256 fasterPoolTime; // faster pool time
		uint256 fasterPoolId; // faster pool id
		uint256 pendingEWFReward; // Pending EWFReward
	}
	PoolLists[] public poolLists;
			
	// Info of active deposit .
	struct DepositList {
		address account; // User address
		uint256 amount; // amount of deposit
		uint256 timeStart; // Farming started 
		uint256 timeEnd; // Farming ended 
		bool is_active; // 1 = active deposite
		mapping(address => uint256)  tokenAmount;
	}
	mapping (uint256 => mapping (uint256 => DepositList)) public depositList;
	
	// Info of each user on pool.
	struct UserList {
		uint256 activeAmount; // active amount
        uint256 overTimeAmount; // over time amount
        uint256 totalAmount; // total amount
		uint256 pendingReward; // claimable reward 
		uint256 pendingRewardLP; // claimable reward 
        uint256 claimReward; // total claim DEFO reward
        uint256 claimRewardLP; // total claim LP token reward
		mapping(address => uint256)  tokenActiveAmount;
		mapping(address => uint256)  tokenOverTimeAmount;
    }
	
	mapping (uint256 => mapping (address => UserList)) public userList;
	mapping(uint => address[]) private poolDatas;
		
	struct PoolTemp {
		uint256 pid;
		uint256 poolCount;
		uint256 tokenAmount;
		uint256 depositAmount;
		uint256 defholdAmount;
		uint256 depositCount;
		address account;
		uint256 timeStart;
		uint256 timeEnd;
		uint256 amount;
		uint256 counter;
		uint256 counter2;
		uint256 counter3;
		uint256 fasterPoolTime;
		uint256 fasterPoolId;
		uint256 remainTime;
		uint256 pendingReward;
		uint256 pendingRewardLP;
		uint256 activeAmount;
		uint256 penaltyAmount;
		uint256 withdrawAmount;
		uint256 overTimeAmount;
		uint256 farmAmount;
		uint256 stakeAmount;
		uint256 farmRewardAmount;
		uint256 stakeRewardAmount;
		uint256 devRewardAmount;
		uint256 farmUsers;
		uint256 stakeUsers;
		uint256 totalAmount;
		uint256 rewardShare;
		uint256 rewardAmount;
		uint256 pendingEWFReward;
		uint256 tokenDecimal;
		uint256 decimalDiff;
		uint256 decimalDiffConverter;
		uint256 beforeTransaction;
		uint256 afterTransaction;
		uint256 swapAmount;
		uint256 tokenPriceRate;
		uint256 tokenPrice;
		uint256 amountChange;
		uint256 realTokenAmount;
		uint256 getAmountsOut;
		bool is_active;
		IERC20 tokenAddress;
	}
		
	constructor(address _defholdLP, address _defhold, address _devAddress, address _weth) public Ownable() {	
		defholdLP = IERC20(_defholdLP);
		defhold = IERC20(_defhold);
		weth = IERC20(_weth);
		devAddress = _devAddress;
		
		_initialPool();
	}
	
	function _initialPool() internal {
		_addPool(false, "1st Pool", 864000, 100);
		_addPool(false, "2nd Pool", 2592000, 350);
		_addPool(false, "3rd Pool", 5184000, 820);
		_addPool(false, "4th Pool", 7776000, 1430);
		_addPool(false, "5th Pool", 15552000, 3330);
		
		_addPool(true, "1st Pool", 864000, 200);
		_addPool(true, "2nd Pool", 2592000, 700);
		_addPool(true, "3rd Pool", 5184000, 1630);
		_addPool(true, "4th Pool", 7776000, 2860);
		_addPool(true, "5th Pool", 15552000, 6660);
		
		_updateToken(address(defholdLP), true);
		_updateToken(address(defhold), true);
	}
	
	function _addPool(bool _is_farming, string memory _pool_name, uint256 _EWFTime, uint256 _EWFRate) internal {
		PoolTemp memory temp;
		
		temp.poolCount = poolLists.length;
				
		if(_is_farming){
			if(FARMPOOLCOUNT == 0){
				temp.fasterPoolId = 5;
				temp.fasterPoolTime = 0;
			} else {
				temp.fasterPoolId = LONGESTFARMINGPOOLID;
				temp.fasterPoolTime = LONGESTFARMINGPOOLTIME;
			}
			
			FARMPOOLCOUNT += 1;
			LONGESTFARMINGPOOLID = temp.poolCount;
			LONGESTFARMINGPOOLTIME = _EWFTime;
		} else {
			if(STAKINGPOOLCOUNT == 0){
				temp.fasterPoolId = 0;
				temp.fasterPoolTime = 0;
			} else {
				temp.fasterPoolId = LONGESTSTAKINGPOOLID;
				temp.fasterPoolTime = LONGESTSTAKINGPOOLTIME;
			}
			
			STAKINGPOOLCOUNT += 1;
			LONGESTSTAKINGPOOLID = temp.poolCount;
			LONGESTSTAKINGPOOLTIME = _EWFTime;
		}
		
		poolLists.push(PoolLists(_is_farming, _pool_name, _EWFTime, _EWFRate, 0, 0, 0, 0, 0, 0, 0, temp.fasterPoolTime, temp.fasterPoolId, 0));
	}
	
	// function addPool(bool _is_farming, string calldata _pool_name, uint256 _EWFTime, uint256 _EWFRate) external onlyOwner {
		// _addPool(_is_farming, _pool_name, _EWFTime, _EWFRate);
	// }
	
	function updateToken(address tokenAddress, bool tokenStatus) external onlyOwner {
		_updateToken(tokenAddress, tokenStatus);
	}

	function _updateToken(address tokenAddress, bool tokenStatus) internal {
		if(existingToken[tokenAddress] != true){
			existingToken[tokenAddress] = true;
			tokenIndex[tokenAddress] = tokenCount;
			tokenCount += 1;
			
			tokenList.push(TokenList(tokenAddress, tokenStatus, 0, 0, 0));
			
			if(tokenAddress != address(defholdLP)){
				if(tokenAddress == address(defhold)){
					_updateDefoPrice();
				} else {
					_updateTokenPrice(tokenIndex[tokenAddress]);
				}
			}
		} else {
			tokenList[tokenIndex[tokenAddress]].tokenStatus = tokenStatus;
		}
	}
		
	 // Deposits in the specified pool to start
	function deposit(uint256 _pid, uint256 _amount, address tokenAddress) external nonReentrant {    
		PoolTemp memory temp;
		require(existingToken[tokenAddress], "Token not yet registered");
		//Check Deposit amount
		require(_amount > 0, "deposit something");
		//Check Pool
		uint256 countPool = poolLists.length;
		require(_pid < countPool, "Not a valid Pool");
		
		_updatePool(_pid);
			
		if(userList[_pid][msg.sender].totalAmount == 0){
			poolLists[_pid].totalUsers += 1;
			poolDatas[_pid].push(msg.sender);
		}
		
		if(poolLists[_pid].is_farming){
			defholdLP.safeTransferFrom(msg.sender, address(this), _amount);
			temp.depositAmount = _amount;
			temp.tokenAmount = _amount;
		} else {
			temp.beforeTransaction = IERC20(tokenAddress).balanceOf(address(this));
			IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), _getTokenAmount(address(tokenAddress), _amount));
			temp.afterTransaction = IERC20(tokenAddress).balanceOf(address(this));
			temp.tokenAmount = temp.afterTransaction - temp.beforeTransaction;
			temp.tokenAmount = _getReverseTokenAmount(address(tokenAddress), temp.tokenAmount);
			
			if(address(tokenAddress) != address(defhold)){				
				_updateDefoPrice();
				_updateTokenPrice(tokenIndex[tokenAddress]);
				
				temp.swapAmount = _getTokenAmount(address(tokenAddress), temp.tokenAmount);
				temp.getAmountsOut = getAmountOut(tokenIndex[tokenAddress], temp.swapAmount);
				temp.depositAmount = _getReverseTokenAmount(address(defhold), temp.getAmountsOut);	
			} else {
				temp.depositAmount = _amount;
			}
		}
						
		temp.timeStart = now;
		temp.timeEnd = now + poolLists[_pid].EWFTime;
		temp.depositCount = poolLists[_pid].depositCount;
		
		tokenList[tokenIndex[tokenAddress]].totalAmount += temp.tokenAmount;
		userList[_pid][msg.sender].tokenActiveAmount[tokenAddress] += temp.tokenAmount;
		depositList[_pid][temp.depositCount].tokenAmount[tokenAddress] = temp.tokenAmount;
		
		depositList[_pid][temp.depositCount].account = msg.sender;
		depositList[_pid][temp.depositCount].timeStart = temp.timeStart;
		depositList[_pid][temp.depositCount].timeEnd = temp.timeEnd;
		depositList[_pid][temp.depositCount].amount = temp.depositAmount;
		depositList[_pid][temp.depositCount].is_active = true;
				
		poolLists[_pid].activeDeposit += 1;
		poolLists[_pid].depositCount += 1;
		poolLists[_pid].totalAmount += temp.depositAmount;
		poolLists[_pid].activeAmount += temp.depositAmount;
		
		temp.pendingEWFReward = poolLists[_pid].pendingEWFReward;
		
		userList[_pid][msg.sender].activeAmount += temp.depositAmount;
		userList[_pid][msg.sender].totalAmount += temp.depositAmount;
		if(temp.pendingEWFReward > 0){
			poolLists[_pid].pendingEWFReward = 0;
			EWFReward(_pid, temp.pendingEWFReward);
		}
		emit Deposit(msg.sender, _pid, temp.timeStart, temp.timeEnd ,temp.depositAmount);
	}
		
	function _updatePool(uint256 _pid) internal {
		PoolTemp memory temp;
		
		temp.fasterPoolTime = poolLists[_pid].fasterPoolTime;
		temp.fasterPoolId = poolLists[_pid].fasterPoolId;
		
		if(poolLists[_pid].activeDeposit > 0){
			for(temp.counter = poolLists[_pid].depositIndex; temp.counter < poolLists[_pid].depositCount;temp.counter++){
				temp.is_active = depositList[_pid][temp.counter].is_active;
				temp.remainTime = 0;
				
				if(temp.is_active){
					temp.account = depositList[_pid][temp.counter].account;
					temp.timeStart = depositList[_pid][temp.counter].timeStart;
					temp.timeEnd = depositList[_pid][temp.counter].timeEnd;
					temp.amount = depositList[_pid][temp.counter].amount;
					
					if(temp.timeEnd > now){
						temp.remainTime = temp.timeEnd - now;
					}
					
					if(temp.fasterPoolTime >= temp.remainTime){
						poolLists[_pid].activeDeposit -= 1;
						poolLists[_pid].depositIndex = temp.counter + 1;
						poolLists[_pid].activeAmount -= temp.amount;
						
						delete depositList[_pid][temp.counter];
						
						if(_pid == temp.fasterPoolId){
							poolLists[_pid].overTimeAmount += temp.amount;
							userList[_pid][temp.account].overTimeAmount += temp.amount;
							userList[_pid][temp.account].activeAmount -= temp.amount;
							
								for(temp.counter2 = 0; temp.counter2 < tokenCount; temp.counter2++){
									temp.tokenAmount = depositList[_pid][temp.counter].tokenAmount[tokenList[temp.counter2].token];

									userList[_pid][msg.sender].tokenActiveAmount[tokenList[temp.counter2].token] -= temp.tokenAmount;
									userList[_pid][msg.sender].tokenOverTimeAmount[tokenList[temp.counter2].token] += temp.tokenAmount;
								}
								
						} else {
							
							temp.pendingReward = userList[_pid][temp.account].pendingReward;	
							temp.pendingRewardLP = userList[_pid][temp.account].pendingRewardLP;	
							
							poolLists[_pid].totalAmount -= temp.amount;
							userList[_pid][temp.account].activeAmount -= temp.amount;						
							userList[_pid][temp.account].totalAmount -= temp.amount;						
							userList[_pid][temp.account].pendingReward -= temp.pendingReward;
							userList[_pid][temp.account].pendingRewardLP -= temp.pendingRewardLP;
							
							if(userList[_pid][temp.account].totalAmount == 0){
								poolLists[_pid].totalUsers -= 1;
								if(poolLists[_pid].totalUsers  > 0){
									for(uint256 i = 0; i < poolDatas[_pid].length; i++) {
										if(poolDatas[_pid][i] == msg.sender){
											delete poolDatas[_pid][i];
											i = poolDatas[_pid].length;
										}
									}
								} else {
									delete poolDatas[_pid];
								}			
							}
							
							temp.depositCount = poolLists[temp.fasterPoolId].depositCount;
							
							if(userList[temp.fasterPoolId][temp.account].totalAmount == 0){
								poolLists[temp.fasterPoolId].totalUsers += 1;
								poolDatas[temp.fasterPoolId].push(temp.account);
							}
							
							poolLists[temp.fasterPoolId].activeDeposit += 1;
							poolLists[temp.fasterPoolId].depositCount += 1;
							poolLists[temp.fasterPoolId].totalAmount += temp.amount;
							poolLists[temp.fasterPoolId].activeAmount += temp.amount;
							
							depositList[temp.fasterPoolId][temp.depositCount].account = temp.account;
							depositList[temp.fasterPoolId][temp.depositCount].timeStart = temp.timeStart;
							depositList[temp.fasterPoolId][temp.depositCount].timeEnd = temp.timeEnd;
							depositList[temp.fasterPoolId][temp.depositCount].amount = temp.amount;
							depositList[temp.fasterPoolId][temp.depositCount].is_active = true;
							
							for(temp.counter2 = 0; temp.counter2 < tokenCount; temp.counter2++){
								temp.tokenAmount = depositList[_pid][temp.counter].tokenAmount[tokenList[temp.counter2].token];
								depositList[temp.fasterPoolId][temp.depositCount].tokenAmount[tokenList[temp.counter2].token] = temp.tokenAmount;
								
								userList[_pid][msg.sender].tokenActiveAmount[tokenList[temp.counter2].token] -= temp.tokenAmount;
								userList[temp.fasterPoolId][msg.sender].tokenActiveAmount[tokenList[temp.counter2].token] += temp.tokenAmount;
							}
							
							userList[temp.fasterPoolId][temp.account].activeAmount += temp.amount;
							userList[temp.fasterPoolId][temp.account].totalAmount += temp.amount;
							userList[temp.fasterPoolId][temp.account].pendingReward += temp.pendingReward;
							userList[temp.fasterPoolId][temp.account].pendingRewardLP += temp.pendingRewardLP;
						
						}
					}
				}
			}
		}
	}
		
	function TotalPool() public view returns (uint256) {
		return poolLists.length;
	}
		
	function UserTokenAmount(uint256 _pid, address _user, uint256 _tokenIndex) public view returns (
		uint256 tokenActiveAmount,
		uint256 tokenOverTimeAmount
	) {
		
		return (
			userList[_pid][_user].tokenActiveAmount[tokenList[_tokenIndex].token],
			userList[_pid][_user].tokenOverTimeAmount[tokenList[_tokenIndex].token]
		);
	}
	
	function percent(uint numerator, uint denominator, uint precision) internal pure returns(uint quotient) {
		uint _numerator  = numerator * 10 ** (precision+1);
		uint _quotient =  ((_numerator / denominator) + 5) / 10;
		return ( _quotient);
	}
	
	function claim() public nonReentrant {	
		PoolTemp memory temp;
		
		for(temp.counter = poolLists.length; temp.counter > 0;temp.counter--){
			temp.pid = temp.counter - 1;
			_updatePool(temp.pid);
		}
		
		_claim();
	}
	
	function _claim() internal {
		PoolTemp memory temp;
		
		temp.pendingReward = 0;
		temp.pendingRewardLP = 0;
		for(temp.counter = 0; temp.counter < poolLists.length;temp.counter++){
			temp.pendingReward += userList[temp.counter][msg.sender].pendingReward;
			temp.pendingRewardLP += userList[temp.counter][msg.sender].pendingRewardLP;
			
			userList[temp.counter][msg.sender].claimReward += userList[temp.counter][msg.sender].pendingReward;
			userList[temp.counter][msg.sender].pendingReward = 0;
			
			userList[temp.counter][msg.sender].claimRewardLP += userList[temp.counter][msg.sender].pendingRewardLP;
			userList[temp.counter][msg.sender].pendingRewardLP = 0;
		}
		
		if(temp.pendingReward > 0){
			defhold.safeTransfer(msg.sender, temp.pendingReward);
			emit ClaimReward(msg.sender, temp.pendingReward);
		}
		
		if(temp.pendingRewardLP > 0){
			defholdLP.safeTransfer(msg.sender, temp.pendingRewardLP);
			emit ClaimReward(msg.sender, temp.pendingRewardLP);
		}		
	}
	
	function withdraw(uint256 _pid) public nonReentrant {
		PoolTemp memory temp;
		
		uint256 countPool = poolLists.length;
		require(_pid < countPool, "Not a valid Pool");
		require(userList[_pid][msg.sender].totalAmount > 0, "not have withdrawn balance");
			
		_updatePool(_pid);
		_claim();
		
		temp.activeAmount = userList[_pid][msg.sender].activeAmount;		
		temp.totalAmount = userList[_pid][msg.sender].totalAmount;		
		temp.overTimeAmount = userList[_pid][msg.sender].overTimeAmount;		
		
		if(temp.overTimeAmount > 0){
			for(temp.counter2 = 0; temp.counter2 < tokenCount; temp.counter2++){
				temp.withdrawAmount = userList[_pid][msg.sender].tokenOverTimeAmount[tokenList[temp.counter2].token];
				
				if(temp.withdrawAmount > 0){
					userList[_pid][msg.sender].tokenOverTimeAmount[tokenList[temp.counter2].token] -= temp.withdrawAmount;

					if(poolLists[_pid].is_farming){
						defholdLP.safeTransfer(msg.sender, temp.withdrawAmount);
					} else {
						temp.withdrawAmount = _getTokenAmount(address(tokenList[temp.counter2].token), temp.withdrawAmount);
						IERC20(tokenList[temp.counter2].token).safeTransfer(msg.sender, temp.withdrawAmount);
						temp.withdrawAmount = _getReverseTokenAmount(address(tokenList[temp.counter2].token), temp.withdrawAmount);
					}
					tokenList[temp.counter2].totalAmount -= temp.withdrawAmount;
					emit Withdraw(msg.sender, _pid ,temp.withdrawAmount);
				}
					
			}
		}
				
		if(temp.activeAmount > 0){
			uint256 deadline = block.timestamp + 5 minutes;		
			address[] memory uniswapPath;
		
			for(temp.counter2 = 0; temp.counter2 < tokenCount; temp.counter2++){
				temp.tokenAmount = userList[_pid][msg.sender].tokenActiveAmount[tokenList[temp.counter2].token];
				temp.withdrawAmount = temp.tokenAmount;
									
				if(temp.withdrawAmount > 0){
					if(poolLists[_pid].is_farming){
						temp.penaltyAmount = (temp.withdrawAmount * poolLists[_pid].EWFRate) / _divRate;
						temp.withdrawAmount -= temp.penaltyAmount;
						defholdLP.safeTransfer(msg.sender, temp.withdrawAmount);
					} else {
						temp.realTokenAmount = IERC20(tokenList[temp.counter2].token).balanceOf(address(this));
						temp.amountChange = percent(tokenList[temp.counter2].totalAmount, _getReverseTokenAmount(tokenList[temp.counter2].token, temp.realTokenAmount), 4);
						temp.withdrawAmount = temp.withdrawAmount * temp.amountChange / _divRate;
						temp.swapAmount = (temp.withdrawAmount * poolLists[_pid].EWFRate) / _divRate;
						temp.withdrawAmount -= temp.swapAmount;
						temp.withdrawAmount = _getTokenAmount(address(tokenList[temp.counter2].token), temp.withdrawAmount);
						IERC20(tokenList[temp.counter2].token).safeTransfer(msg.sender, temp.withdrawAmount);
						
						if(address(tokenList[temp.counter2].token) != address(defhold)){
							temp.beforeTransaction = defhold.balanceOf(address(this));
							temp.swapAmount = _getTokenAmount(address(tokenList[temp.counter2].token), temp.swapAmount);
							
							uniswapPath = new address[](3);
							uniswapPath[0] = address(tokenList[temp.counter2].token);
							uniswapPath[1] = address(weth);
							uniswapPath[2] = address(defhold);
							IERC20(tokenList[temp.counter2].token).safeApprove(address(uniswapRouter), 0);
							IERC20(tokenList[temp.counter2].token).safeApprove(address(uniswapRouter), temp.swapAmount);
							uniswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(temp.swapAmount, 0, uniswapPath, address(this), deadline);
							
							temp.afterTransaction = defhold.balanceOf(address(this));
							temp.penaltyAmount = _getReverseTokenAmount(address(defhold), temp.afterTransaction - temp.beforeTransaction);

						} else {
							temp.penaltyAmount = temp.swapAmount;
						}
					}
					userList[_pid][msg.sender].tokenActiveAmount[tokenList[temp.counter2].token] -= temp.tokenAmount;
					tokenList[temp.counter2].totalAmount -= temp.tokenAmount;
					emit Withdraw(msg.sender, _pid ,temp.withdrawAmount);	
					emit PenaltyFee(msg.sender, _pid, poolLists[_pid].EWFRate, temp.penaltyAmount);
					EWFReward(_pid, temp.penaltyAmount);
				}				
			}
		}
		
		for(temp.counter = poolLists[_pid].depositIndex; temp.counter < poolLists[_pid].depositCount;temp.counter++){
			temp.account = depositList[_pid][temp.counter].account;
			temp.is_active = depositList[_pid][temp.counter].is_active;
			temp.remainTime = 0;
			
			if(temp.is_active){
				if(temp.account == msg.sender){
					delete depositList[_pid][temp.counter];
					poolLists[_pid].activeDeposit -= 1;
				}
			}
		}
		
		userList[_pid][msg.sender].activeAmount -= temp.activeAmount;
		userList[_pid][msg.sender].totalAmount -= temp.totalAmount;
		userList[_pid][msg.sender].overTimeAmount -= temp.overTimeAmount;
				
		poolLists[_pid].activeAmount -= temp.activeAmount;
		poolLists[_pid].totalAmount -= temp.totalAmount;
		poolLists[_pid].overTimeAmount -= temp.overTimeAmount;
		
		if(userList[_pid][temp.account].totalAmount == 0){
			poolLists[_pid].totalUsers -= 1;
			if(poolLists[_pid].totalUsers  > 0){
				for(uint256 i = 0; i < poolDatas[_pid].length; i++) {
					if(poolDatas[_pid][i] == msg.sender){
						delete poolDatas[_pid][i];
						i = poolDatas[_pid].length;
					}
				}
			} else {
				delete poolDatas[_pid];
			}			
		}
	}
		
	function withdrawOverTime(uint256 _pid) public nonReentrant {
		PoolTemp memory temp;
		
		uint256 countPool = poolLists.length;
		require(_pid < countPool, "Not a valid Pool");
		require(userList[_pid][msg.sender].overTimeAmount > 0, "not have withdrawn balance");
			
		_updatePool(_pid);
		_claim();
		
		temp.overTimeAmount = userList[_pid][msg.sender].overTimeAmount;
		if(temp.overTimeAmount > 0){
			for(temp.counter2 = 0; temp.counter2 < tokenCount; temp.counter2++){
				temp.withdrawAmount = userList[_pid][msg.sender].tokenOverTimeAmount[tokenList[temp.counter2].token];
				
				if(temp.withdrawAmount > 0){
					userList[_pid][msg.sender].tokenOverTimeAmount[tokenList[temp.counter2].token] -= temp.withdrawAmount;

					if(poolLists[_pid].is_farming){
						defholdLP.safeTransfer(msg.sender, temp.withdrawAmount);
					} else {
						temp.withdrawAmount = _getTokenAmount(address(tokenList[temp.counter2].token), temp.withdrawAmount);
						IERC20(tokenList[temp.counter2].token).safeTransfer(msg.sender, temp.withdrawAmount);
						temp.withdrawAmount = _getReverseTokenAmount(address(tokenList[temp.counter2].token), temp.withdrawAmount);
					}
					tokenList[temp.counter2].totalAmount -= temp.withdrawAmount;
					emit Withdraw(msg.sender, _pid ,temp.withdrawAmount);
				}
					
			}
			
			userList[_pid][msg.sender].totalAmount -= temp.overTimeAmount;
			userList[_pid][msg.sender].overTimeAmount -= temp.overTimeAmount;
					
			poolLists[_pid].totalAmount -= temp.overTimeAmount;
			poolLists[_pid].overTimeAmount -= temp.overTimeAmount;
		}
		
		for(temp.counter = poolLists[_pid].depositIndex; temp.counter < poolLists[_pid].depositCount;temp.counter++){
			temp.account = depositList[_pid][temp.counter].account;
			temp.is_active = depositList[_pid][temp.counter].is_active;
			temp.remainTime = 0;
			
			if(temp.is_active){
				if(temp.account == msg.sender){
					delete depositList[_pid][temp.counter];
					poolLists[_pid].activeDeposit -= 1;
				}
			}
		}
	}
	
	function EWFReward(uint _pid, uint256 _amount) internal {
		PoolTemp memory temp;
		
		if(poolLists[_pid].totalUsers > 0){
			for(temp.counter = 0; temp.counter < poolDatas[_pid].length;temp.counter++){
				temp.account = poolDatas[_pid][temp.counter];
				if(temp.account != address(0)){
					temp.rewardShare = percent(userList[_pid][temp.account].activeAmount, poolLists[_pid].activeAmount, 4);
					temp.rewardAmount = _amount * temp.rewardShare / _divRate;
					
					if(poolLists[_pid].is_farming){
						userList[_pid][temp.account].pendingRewardLP += temp.rewardAmount;
					} else {
						userList[_pid][temp.account].pendingReward += temp.rewardAmount;
					}
				}
			}	
		} else {
			poolLists[_pid].pendingEWFReward = _amount;
		}		
	}
	
	function externalReward(uint256 _amount) external nonReentrant {
		PoolTemp memory temp;
		
		defhold.safeTransferFrom(msg.sender, address(this), _amount);

		temp.farmRewardAmount = (_amount * 55) / 100; // 55% of reward supply
		temp.stakeRewardAmount = (_amount * 40) / 100; // 40% of reward supply
		temp.devRewardAmount = _amount - temp.farmRewardAmount - temp.stakeRewardAmount; // 5% of reward supply
		
		temp.farmAmount = 0;
		temp.stakeAmount = 0;
		
		temp.farmUsers = 0;
		temp.stakeUsers = 0;
		
		for(temp.counter = poolLists.length; temp.counter > 0;temp.counter--){
			temp.pid = temp.counter - 1;
			_updatePool(temp.pid);
			if(poolLists[temp.pid].is_farming){
				temp.farmAmount += poolLists[temp.pid].activeAmount;
				temp.farmUsers += poolLists[temp.pid].totalUsers;
			} else {
				temp.stakeAmount += poolLists[temp.pid].activeAmount;
				temp.stakeUsers += poolLists[temp.pid].totalUsers;
			}
		}
		
		if(temp.farmAmount == 0){
			temp.devRewardAmount += temp.farmRewardAmount;
			temp.farmRewardAmount = 0;
		}
		
		if(temp.stakeAmount == 0){
			temp.devRewardAmount += temp.stakeRewardAmount;
			temp.stakeRewardAmount = 0;
		}
		
		for(temp.counter = 0; temp.counter < poolLists.length;temp.counter++){
			for(temp.counter2 = 0; temp.counter2 < poolDatas[temp.counter].length;temp.counter2++){
				temp.account = poolDatas[temp.counter][temp.counter2];
				
				if(temp.account != address(0)){
					temp.activeAmount = userList[temp.counter][temp.account].activeAmount;
					if(temp.activeAmount > 0){
						if(poolLists[temp.counter].is_farming){
							if(temp.farmAmount > 0){
								temp.rewardShare = percent(userList[temp.counter][temp.account].activeAmount, temp.farmAmount, 4);
								temp.rewardAmount = temp.farmRewardAmount * temp.rewardShare / _divRate;
							}							
						} else {
							if(temp.stakeAmount > 0){
								temp.rewardShare = percent(userList[temp.counter][temp.account].activeAmount, temp.stakeAmount, 4);
								temp.rewardAmount = temp.stakeRewardAmount * temp.rewardShare / _divRate;
							}
						}
						
						userList[temp.counter][temp.account].pendingReward += temp.rewardAmount;
					}
				}
			}
		}
		
		if(temp.devRewardAmount > 0){
			defhold.safeTransfer(devAddress, temp.devRewardAmount);
		}
	}
	
	function updatePool(uint _pid) public nonReentrant {
		_updatePool(_pid);
	}
	
	function updateAllPool() public nonReentrant {
		PoolTemp memory temp;
		
		for(temp.counter = poolLists.length; temp.counter > 0;temp.counter--){
			temp.pid = temp.counter - 1;
			_updatePool(temp.pid);
		}
		
	}
	
	function _getTokenAmount(address _tokenAddress, uint256 _amount) internal view returns (uint256 quotient) {
		PoolTemp memory temp;
		
		temp.tokenAddress = IERC20(_tokenAddress);
		temp.tokenDecimal = temp.tokenAddress.decimals();
			
		if(_decimal != temp.tokenDecimal){
			if(_decimal > temp.tokenDecimal){
				temp.decimalDiff = _decimal - temp.tokenDecimal;
				temp.decimalDiffConverter = 10**temp.decimalDiff;
				temp.amount = _amount.div(temp.decimalDiffConverter);
			} else {
				temp.decimalDiff = temp.tokenDecimal - _decimal;
				temp.decimalDiffConverter = 10**temp.decimalDiff;
				temp.amount = _amount.mul(temp.decimalDiffConverter);
			}		
		} else {
			temp.amount = _amount;
		}
		
		uint256 _quotient = temp.amount;
		
		return (_quotient);
    }
	
	function _getReverseTokenAmount(address _tokenAddress, uint256 _amount) internal view returns (uint256 quotient) {
		PoolTemp memory temp;
		
		temp.tokenAddress = IERC20(_tokenAddress);
		temp.tokenDecimal = temp.tokenAddress.decimals();
			
		if(_decimal != temp.tokenDecimal){
			if(_decimal > temp.tokenDecimal){
				temp.decimalDiff = _decimal - temp.tokenDecimal;
				temp.decimalDiffConverter = 10**temp.decimalDiff;
				temp.amount = _amount.mul(temp.decimalDiffConverter);
			} else {
				temp.decimalDiff = temp.tokenDecimal - _decimal;
				temp.decimalDiffConverter = 10**temp.decimalDiff;
				temp.amount = _amount.div(temp.decimalDiffConverter);
			}		
		} else {
			temp.amount = _amount;
		}
		
		uint256 _quotient = temp.amount;
		
		return (_quotient);
    }
		
	event Deposit(address indexed user, uint256 pool_id, uint256 timeStart, uint256 timeEnd, uint256 amount);
	event ClaimReward(address indexed user, uint256 amount);
	event PenaltyFee(address indexed user, uint256 pool_id, uint256 fee, uint256 amount);
	event Withdraw(address indexed user, uint256 pool_id, uint256 amount);
	event WithdrawOverTime(address indexed user, uint256 pool_id, uint256 amount);
}