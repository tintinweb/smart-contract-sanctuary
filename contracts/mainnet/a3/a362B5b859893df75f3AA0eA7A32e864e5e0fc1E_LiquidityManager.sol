/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol
// SPDX-License-Identifier: MIT
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

// File: src/UniswapV2Library.sol

pragma solidity >=0.6.0;




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

// File: src/FullMath.sol
pragma solidity >=0.6.0;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: @uniswap/lib/contracts/libraries/FixedPoint.sol

pragma solidity >=0.4.0;

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
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// File: [email protected]/contracts/utils/Address.sol


pragma solidity >=0.6.2 <0.8.0;

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

// File: [email protected]/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: [email protected]/contracts/token/ERC20/IERC20.sol





pragma solidity >=0.6.0 <0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: [email protected]/contracts/utils/ReentrancyGuard.sol




pragma solidity >=0.6.0 <0.8.0;

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: src/LiquidityManager.sol

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2 ;

//import {IERC20} from "../[email protected]/contracts/token/ERC20/IERC20.sol";


//import {Babylonian} from "@uniswap/lib/contracts/libraries/Babylonian.sol";




interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LiquidityManager is ReentrancyGuard {
    //----------------------------------------
    // Type definitions
    //----------------------------------------
    using SafeMath for uint256;
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    //----------------------------------------
    // State variables
    //----------------------------------------
    uint112 private constant _MAX_UINT112 = uint112(-1);
    uint256 private constant _UNISWAP_V2_DEADLINE_DELTA = 15 minutes;
    // Limit slippage to 0.5%
    //uint112 private constant _UNISWAP_V2_SLIPPAGE_LIMIT = 200;
    uint112 public constant MAX_LOAN_PER_USER_PER_PAIR = 100 ether;
    uint256 public constant CAPITAL = 40000 ether;
    uint256 public constant REWARDS = 21600 ether;
    mapping (address => address) _referrals;
    mapping (address => address[]) public referrals;
    mapping (address =>uint256) users;
    uint256 public TotalLoans = 0;
    address internal _uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router01 private immutable _uniswapRouter;
    address private immutable _WETH;
    address  devTeam;
    //mapping(address => mapping(address => uint256)) public loans;
    IERC20 private immutable TOLL;
    uint256 MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    //user info
     struct UserInfo {
        uint256 last; 
        uint256 loan; 
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }
    // Info of each pool.
    struct PoolInfo {    // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. ERC20s to distribute per block.
        uint256 lastRewardBlock;    // Last block number that ERC20s distribution occurs.
        uint256 accTOLLPerShare;
        uint256 total;
        bool isPool ; // Accumulated ERC20s per share, times 1e36.
    }
    // The total amount of ERC20 that's paid out as reward.
    uint256 public paidOut = 0;
    // ERC20 tokens rewarded per block.
    uint256 public rewardPerBlock = 40000000000000000; // 0.02TOLL
    // Info of each pool.
    mapping(address => PoolInfo) public poolInfo;
    address[] public poolList;
    // Info of each user that stakes LP tokens.
    mapping (address => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when farming starts.
    uint256 public startBlock;
    // The block number when farming ends.
    uint256 public endBlock;
    bool public started;
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Repaid(address indexed user, address indexed lpToken, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event EmergencyWithdraw(address indexed user, address indexed token, uint256 amount);
    event referralEvent(address indexed ref, address indexed user);
    event referralPayout(address indexed ref, address indexed user, uint256 amt);
     

    //----------------------------------------
    // Constructor
    //----------------------------------------
    constructor( IERC20 toll) public {
        IUniswapV2Router01 uniswapRouter =  IUniswapV2Router01(_uniswapRouterAddress);
        _WETH = uniswapRouter.WETH();
        _uniswapRouter = uniswapRouter;
        TOLL = toll;
        devTeam = msg.sender;
    }

     modifier onlyDev() {
        require(devTeam == msg.sender, "Only Devs");
        _;
    }

    //set the governance address
    function start() public {
        require(!started, "Already Started");
        TOLL.mint(address(this), CAPITAL.add(REWARDS));
        TOLL.approve(address(_uniswapRouter), MAX_INT);
        endBlock = block.number.add(REWARDS.div(rewardPerBlock));
        startBlock = block.number;
        started = true;
    }

    // Number of LP pools
    function poolLength() external view returns (uint256) {
        return poolList.length;
    }
    
     // Number of LP pools
    function pools() external view returns (address[] memory _pools ) {
        return poolList;
    }


    function isPool(address poolAddress) public view returns(bool isAPool) {
      return poolInfo[poolAddress].isPool;
  }
    
    // Add a new lp to the pool using a token address.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addByToken(uint256 _allocPoint, address _token, bool _withUpdate) public onlyDev{
        require(msg.sender == devTeam , "Only DevTeams");
        if (_withUpdate) {
            massUpdatePools();
        }
        address lpTokenAddress = getUniswapPair(_token);
        PoolInfo storage lpPool =  poolInfo[lpTokenAddress];
        if(lpPool.isPool){
            totalAllocPoint = totalAllocPoint.sub(lpPool.allocPoint).add(_allocPoint);
            lpPool.allocPoint = _allocPoint;
        }else{
            IERC20(_token).approve(address(_uniswapRouter), MAX_INT);
            IERC20(lpTokenAddress).approve(address(_uniswapRouter), MAX_INT);
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
            lpPool.allocPoint = _allocPoint;
            lpPool.lastRewardBlock = block.number > startBlock ? block.number : startBlock;
            lpPool.isPool = true;
            poolList.push(lpTokenAddress);
        }
    }
    
    // View function to see pending TOLL rewards for a user.
    function pending(address poolAddress, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[poolAddress];
        UserInfo storage user = userInfo[poolAddress][_user];
        if(!pool.isPool) return 0;
        uint256 accTOLLPerShare = pool.accTOLLPerShare;
        uint256 lpSupply = IERC20(poolAddress).balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
            uint256 nrOfBlocks = lastBlock.sub(pool.lastRewardBlock);
            uint256 tollReward = nrOfBlocks.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTOLLPerShare = accTOLLPerShare.add(tollReward.mul(1e36).div(lpSupply));
        }
        return user.amount.mul(accTOLLPerShare).div(1e36).sub(user.rewardDebt);
    }

    // View function for total reward the farm has yet to pay out.
    function totalPending() external view returns (uint256) {
        if (block.number <= startBlock) {
            return 0;
        }
        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
        return rewardPerBlock.mul(lastBlock - startBlock).sub(paidOut);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolList.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(poolList[pid]);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(address poolAddress) public {
        PoolInfo storage pool = poolInfo[poolAddress];
        require(pool.isPool, "No Pool") ;
        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
        if (lastBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = IERC20(poolAddress).balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = lastBlock;
            return;
        }

        uint256 nrOfBlocks = lastBlock.sub(pool.lastRewardBlock);
        uint256 tollReward = nrOfBlocks.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accTOLLPerShare = pool.accTOLLPerShare.add(tollReward.mul(1e36).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }


    // Deposit ERC20 tokens to borrow LP and Farm.
    function payLoan(address poolAddress, uint256 tollAmount) public {
        UserInfo storage user = userInfo[poolAddress][msg.sender];
        if(tollAmount > user.loan) tollAmount = user.loan;
        user.loan = user.loan.sub(tollAmount);
        TOLL.transferFrom(msg.sender, address(this), tollAmount);
        emit Repaid(msg.sender,poolAddress,tollAmount);
    }
    
        // Deposit ERC20 tokens to borrow LP and Farm.
    function borrowTollForERC20Farm(address token, uint256 tokenAmount , address _ref) public {
        saveReferral(_ref);
        ( uint256 liquidity, address poolAddress) =  depositTokenLiquidity( token, tokenAmount);
        updatePool(poolAddress);
        PoolInfo storage pool = poolInfo[poolAddress];
        UserInfo storage user = userInfo[poolAddress][msg.sender];
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accTOLLPerShare).div(1e36).sub(user.rewardDebt);
            tollTransfer(msg.sender, pendingAmount);
        }
        pool.total =  pool.total.add(tokenAmount);
        user.amount = user.amount.add(liquidity);
        user.last = now;
        user.rewardDebt = user.amount.mul(pool.accTOLLPerShare).div(1e36);
        emit Deposit(msg.sender, poolAddress, liquidity);
    }

    // Deposit ETH to borrow LP and Farm.
    function borrowTollForETHFarm( address _ref) public payable {
        require(msg.value > 0, "Please Send ETH to Farm ETH");
        borrowTollForERC20Farm(_WETH, msg.value, _ref);
    }
    
    
    function  saveReferral(address _ref) internal returns (bool) {
        if( users[msg.sender] == 1 || _ref == address(0) || _ref == address(this)) return false;
        _referrals[msg.sender] = _ref;
        referrals[_ref].push(msg.sender);
        users[msg.sender] = 1;
        emit referralEvent(_ref, msg.sender);
        return true;
    }
    
    function getReferral(address _ref) public view returns( address[] memory refs){
        return  referrals[_ref];
    }
    
    // Withdraw LP rewards from Farm.
    function rewards( address poolAddress) public {
        updatePool(poolAddress);
        PoolInfo memory pool = poolInfo[poolAddress];
        UserInfo storage user = userInfo[poolAddress][msg.sender];
        require(now > user.last.add( 1 days),"Rewards are available Once a day");
        user.last = now;
        uint256 pendingAmount = user.amount.mul(pool.accTOLLPerShare).div(1e36).sub(user.rewardDebt);
        user.rewardDebt = user.amount.mul(pool.accTOLLPerShare).div(1e36);
        emit Withdraw(msg.sender, poolAddress, user.amount);
        if(user.loan >  pendingAmount.div(2)){
             user.loan =  user.loan.sub(pendingAmount.div(2));
             tollTransfer(msg.sender, pendingAmount.div(2));
        }else{ // loan can paid in full by half the reward
             user.loan =  0;
             tollTransfer(msg.sender, pendingAmount.sub(user.loan));
        }
    }


   // Withdraw LP tokens from Farm.
    function withdraw( address poolAddress, uint256 _amount) public {
        updatePool(poolAddress);
        PoolInfo storage pool = poolInfo[poolAddress];
        UserInfo storage user = userInfo[poolAddress][msg.sender];
        require(user.amount >= _amount, "Can't withdraw more than deposit");
        uint256 pendingAmount = user.amount.mul(pool.accTOLLPerShare).div(1e36).sub(user.rewardDebt);
        if(pendingAmount > 0)  require(now > user.last.add( 1 days),"Withdraw available Once daily");
        uint256 taken = withdrawLqdToken(poolAddress,  _amount ,pendingAmount);
        pool.total =  pool.total.sub(taken);
        user.amount = user.amount.sub(_amount);
        user.last = now;
        user.rewardDebt = user.amount.mul(pool.accTOLLPerShare).div(1e36);
        emit Withdraw(msg.sender, poolAddress, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address poolAddress) public {
        //PoolInfo storage pool = poolInfo[poolAddress];
        UserInfo storage user = userInfo[poolAddress][msg.sender];
        uint256 taken = withdrawLqdToken(poolAddress,  user.amount,0);
        poolInfo[poolAddress].total =  poolInfo[poolAddress].total.sub(taken);
        emit EmergencyWithdraw(msg.sender, poolAddress, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Transfer ERC20 and update the required ERC20 to payout all rewards
    function tollTransfer(address _to, uint256 _amount) internal {
        TOLL.transfer(_to, _amount);
        if(_referrals[_to] != address(0)){
            uint256 amt = FullMath.mulDiv(50,_amount,1000 ); 
            TOLL.transfer(_referrals[_to], amt);
            emit referralPayout( _referrals[_to], _to, amt);
        }
        paidOut += _amount;
        
    }
    //----------------------------------------
    // Receive function
    //----------------------------------------
    receive() external payable {}
    //----------------------------------------
    // Public views
    //----------------------------------------

    function getUniswapPair(address token) public view returns (address pair) {
        return
            address(
                UniswapV2Library.pairFor(_uniswapRouter.factory(), address(TOLL), token)
            );
    }

   

    //----------------------------------------
    // Internal functions
    //----------------------------------------
    /**
     * @notice Add liquidity to a Uniswap pool
     * @dev The larger the discrepancy between WETH <-> token pairs and the token <-> token pair,
     *      the more ETH will be left behind after adding liquidity.
     * @param token  for the Uniswap pair
     * @param tokenAmount  Amount of Tokens  Provided
     */
    function depositTokenLiquidity(address token, uint256 tokenAmount) internal returns(uint256 , address){
      
        (uint112 amountTokenDesired, uint112 amountTollDesired) =
            _getAmountDesiredAmounts(token, tokenAmount);//ok
        address lpToken = getUniswapPair(token); //ok
        require(isPool(lpToken), "No Pool") ;
        canBorrow(lpToken, amountTollDesired);
        // Approve tokens for transfer to Uniswap pair
        if(token == _WETH){
            IWETH(_WETH).deposit{value:msg.value}();
        }else{
            IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
        }
        (uint256 tollAmt,, uint256 liquidity) =
            _uniswapRouter.addLiquidity(
                address(TOLL),
                token,
                amountTollDesired,
                amountTokenDesired,
                0, // slippage unavoidable
                0, // slippage unavoidable
                address(this),
                now + _UNISWAP_V2_DEADLINE_DELTA // solhint-disable-line not-rely-on-time
            );
        userInfo[lpToken][msg.sender].loan = tollAmt.add(userInfo[lpToken][msg.sender].loan);
        TotalLoans = TotalLoans.add(tollAmt);
        return (liquidity, lpToken);
    }
    
    
    function canBorrow(address lpTokenPair, uint256 tollAmount) internal view {
        uint256 newLoanTotal = tollAmount.add(userInfo[lpTokenPair][msg.sender].loan);
        uint256 _totalLoans = TotalLoans.add(tollAmount);
        require(newLoanTotal <= MAX_LOAN_PER_USER_PER_PAIR, "Loan max Exceeded");
        require(_totalLoans <= CAPITAL, "Reserve Low on Capital");
    }
    
    
    function withdrawLqdToken(address lpToken, uint256 liquidity, uint256 reward)
        internal
        returns (uint256)
    {
        require(liquidity <= _MAX_UINT112, "overflow");
        IUniswapV2Pair pair = IUniswapV2Pair(lpToken);
        address token0 = pair.token0();
        address token1 = pair.token1();
        (uint256 token0Amount, uint256 token1Amount) = _uniswapRouter.removeLiquidity(
            token0,
            token1,
            liquidity,
            0,  // slippage unavoidable
            0, // slippage unavoidable
            address(this),
            now + _UNISWAP_V2_DEADLINE_DELTA // solhint-disable-line not-rely-on-time
        );
         ( address tokenAddrr , uint256 tokenAmount , uint256 amountToll ) = 
            token0 == address(TOLL) 
            ? (token1, token1Amount,token0Amount) 
            : (token0, token0Amount,token1Amount);
            
        UserInfo storage user = userInfo[lpToken][msg.sender];
        uint256 availablePay = amountToll.add(reward);
        uint256 requiredPayBack = FullMath.mulDiv(liquidity, user.loan, user.amount);
        uint256 withHoldToken = 0;
        if(requiredPayBack > availablePay ){
            uint256 requiredToll = requiredPayBack.sub(availablePay);
            if(requiredToll > 1e9) // lets forgive anything less than one gwei
            withHoldToken =_getAmountOutForUniswapV2(address(TOLL),tokenAddrr,requiredToll);
        }
        require(tokenAmount > withHoldToken, "TOLL Cant Cover Loan");
        if(availablePay > user.loan ){
            uint256 extraToll = availablePay.sub(user.loan);
            TOLL.transfer(msg.sender, extraToll);
        }
        user.loan = user.loan.sub(requiredPayBack);
        sendToUser(tokenAmount.sub(withHoldToken) , tokenAddrr);
        return tokenAmount;
    } 
    
    
    function sendToUser(uint256 _amount , address _token)internal{
        if(_token == _WETH){
            IWETH(_WETH).withdraw(_amount);
            msg.sender.transfer(_amount);
        }else{
            IERC20(_token).transfer(msg.sender, _amount);
        }
    }
    
    function _withdrawLqd(address lpToken, uint256 liquidity, uint256 reward)
        internal
        returns (uint256)
    {
        require(liquidity <= _MAX_UINT112, "overflow");
        IUniswapV2Pair pair = IUniswapV2Pair(lpToken);
        address token0 = pair.token0();
        address token1 = pair.token1();
        (uint256 token0Amount, uint256 token1Amount) = _uniswapRouter.removeLiquidity(
            token0,
            token1,
            liquidity,
            0,  // slippage unavoidable
            0, // slippage unavoidable
            address(this),
            now + _UNISWAP_V2_DEADLINE_DELTA // solhint-disable-line not-rely-on-time
        );
         ( address tokenAddrr , uint256 tokenAmount , uint256 amountToll ) = 
            token0 == address(TOLL) 
            ? (token1, token1Amount,token0Amount) 
            : (token0, token0Amount,token1Amount);
            
        UserInfo storage user = userInfo[lpToken][msg.sender];
        uint256 availablePay = amountToll.add(reward);
        uint256 requiredPayBack = FullMath.mulDiv(liquidity, user.loan, user.amount);
        uint256 withHoldToken = 0;
        if(requiredPayBack > availablePay ){
            uint256 requiredToll = requiredPayBack.sub(availablePay);
            if(requiredToll > 1e9) // lets forgive anything less than one gwei
            withHoldToken =_getAmountOutForUniswapV2(address(TOLL),tokenAddrr,requiredToll);
        }
        require(tokenAmount > withHoldToken, "TOLL Cant Cover Loan");
        if(availablePay > user.loan ){
            uint256 extraToll = availablePay.sub(user.loan);
            TOLL.transfer(msg.sender, extraToll);
        }
        user.loan = user.loan.sub(requiredPayBack);
        IERC20(tokenAddrr).transfer(msg.sender, tokenAmount.sub(withHoldToken));
        return tokenAmount;
    } 
    

    /**
     * @notice Get the amount of toll user afford to add to a Uniswap v2 WETH pair
     * @dev It was necessary to refactor this code out of `_addUniswapV2Liquidity` to avoid a
     *      "Stack too deep" error.
     * @param token The token paired with WETH
     * @return The desired amount of WETH and tokens
     */
    function _getAmountDesiredAmounts(address token, uint256 amount)
        internal
        view
        returns (uint112, uint112)
    {
        // Get the toll needed for the provided ETH
        uint256 amountToll = _getEquivalentToll(token, amount);
        require(amount <= _MAX_UINT112, "overflow");
        uint112 amountDesired = uint112(amount);
        require(amountToll <= _MAX_UINT112, "overflow");
        uint112 amountTollDesired = uint112(amountToll);
        return (amountDesired, amountTollDesired);
    }
    /**
     * @notice Get the amount of TOLL that is equivalent to the given amount of a token
     * @param token The address of token
     * @param tokenAmount The amount of tokens
     * @return The equivalent amount TOLL, returns 0 if the token pair has no reserves
     */
    function _getEquivalentToll(address token, uint256 tokenAmount)
        internal
        view
        returns (uint256)
    {
        (uint256 tollReserve, uint256 tokenReserve) =
            UniswapV2Library.getReserves(_uniswapRouter.factory(), address(TOLL), token);
        if (tollReserve == 0 && tokenReserve == 0) {
            return 0;
        }
        return _uniswapRouter.quote(tokenAmount, tokenReserve, tollReserve);
    }

    /**
     * @notice Get the amount of token B that can be swapped for the given amount of token A
     * @param tokenA The address of token A
     * @param tokenB The address of token B
     * @param amountInA The amount of token A
     * @return The amount of token B that can be swapped for token A
     */
    function _getAmountOutForUniswapV2(
        address tokenA,
        address tokenB,
        uint256 amountInA
    ) public view returns (uint256) {
        (uint256 reserveA, uint256 reserveB) =
            UniswapV2Library.getReserves(_uniswapRouter.factory(), tokenA, tokenB);
        return _uniswapRouter.getAmountOut(amountInA, reserveA, reserveB);
    }
  
    /**
     * @notice This contract should not hold TOKENS! this function will add any Token as Liquidity
     **/
    function liquifyTokenHoldings(address token) public {
        if(token == _WETH && address(this).balance > 1 szabo ){
            IWETH(_WETH).deposit{value:address(this).balance}();
        } 
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >  1 szabo, "Low Balance 4 Token" );
         (uint112 amountTokenDesired, uint112 amountTollDesired) =
            _getAmountDesiredAmounts(token, balance);
        TOLL.mint(address(this), amountTollDesired);
        // Approve tokens for transfer to Uniswap pair
         _uniswapRouter.addLiquidity(
                address(TOLL),
                token,
                amountTollDesired,
                amountTokenDesired,
                0,  // slippage unavoidable
                0, // slippage unavoidable
                address(devTeam),
                now + _UNISWAP_V2_DEADLINE_DELTA // solhint-disable-line not-rely-on-time
            );
    }
}