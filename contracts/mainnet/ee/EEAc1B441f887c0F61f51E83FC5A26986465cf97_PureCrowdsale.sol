// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol

pragma solidity >=0.5.0;

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        )
            .getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: @uniswap/v2-periphery/contracts/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// File: @uniswap/lib/contracts/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// File: contracts/PureCrowdsale.sol

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

contract PureCrowdsale {
    using SafeMath for uint256;

    /**
     * @dev start and end timestamps where investments are allowed (both inclusive)
     */
    uint256 public startTime;
    uint256 public endTime;

    /**
     * @dev amount of already sold vPURE
     */
    uint256 private _soldvPURE;

    /**
     * @dev contract owner address
     */
    address private _owner;

    /**
     * @dev uniswap router address
     */
    address private _uniswapRouterAddress;

    /**
     * @dev vBRIGHT token address
     */
    address private _vBRIGHTAddress;

    /**
     * @dev vPURE token address
     */
    address private _vPUREAddress;

    /**
     * @dev VIVID token address
     */
    address private _VIVIDAddress;

    /**
     * @dev uniswap factory address
     */
    address private _uniswapFactory;

    /**
     * @dev uniswap router
     */
    IUniswapV2Router02 private _uniswapRouter02;

    /**
     * @dev helper constants to compute the vPURE/ETH ratio
     */
    uint256 private constant _VPURENUMERATOR = 1000;
    uint256 private constant _VPUREDENOMINATOR = 42;

    /**
     * @dev maximum and minimum eth needed for a purchase
     */
    uint256 private constant _ETHMIN = 1 * 10**18;
    uint256 private constant _ETHMAX = 50 * 10**18;
    
    uint256 private _ethMINValue;

    /**
     * @dev vPURE token
     */
    IERC20 private _vPUREToken;

    /**
     * @dev vBRIGHT token
     */
    IERC20 private _vBRIGHTToken;

    /**
     * @dev VIVID token
     */
    IERC20 private _VIVIDToken;

    /**
     * @dev WETH address
     */
    address private _weth;

    /**
     * struct to keep the amount of vPURE boght and the total ETH sent
     */
    struct trackCrowdsaleAmount {
        uint256 ethAmount;
        uint256 vPUREAmount;
    }

    /**
     * @dev it keeps the mapping between the vPURE sold to the specific address
     */
    mapping(address => trackCrowdsaleAmount) private _vCrowdsaleBalance;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param ethAmount ETH paid for purchase
     * @param vPUREAmount amount of tokens purchased
     */
    event onVPURETokenPurchase(
        address indexed purchaser,
        uint256 ethAmount,
        uint256 vPUREAmount
    );

    /**
     * event for LP added to vBRIGHT
     * @param tokenAmount amount of tokens added to LP
     * @param ethAmount ETH paid for purchase
     * @param liquidity the LP
     * @param tokenAddress address
     */
    event onLpvAdded(
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 liquidity,
        address tokenAddress
    );

    /**
     * event for claim tokens action
     * @param beneficiary address
     * @param amount amount of VPURE
     */
    event onClaimPurchasedTokens(address beneficiary, uint256 amount);

    /**
     * @dev constructor
     */
    constructor() public {
        _owner = msg.sender;

        setVBRIGHTAddress(0x3E88f8C31E1F9D26c1904584EFbCA58b75F53568);

        setVPUREAddress(0x12ED21C3d2E966162c4C65Ea8a62d13061D46eb6);

        setVIVIDAddress(0xF32544D1Ab31814160054bD6371Db4DE389E0083);

        setUniswapRouterAddress(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        setUniswapFactoryAddress(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

        startTime = 1605121200;
        endTime = startTime + 10 days;

        _weth = _uniswapRouter02.WETH();
        
        _ethMINValue = _ETHMIN;
    }

    /**
     * @dev access modifier to restrict different functionalities
     */
    modifier _onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    /**
     * @dev fallback function can be used to buy tokens
     */
    receive() external payable {
        buyTokens();
    }

    /**
     * @dev helper to set VIVID contract address
     * _onlyOwner available
     */
    function setVIVIDAddress(address VIVIDAddress) public _onlyOwner {
        _VIVIDAddress = VIVIDAddress;
        _VIVIDToken = IERC20(_VIVIDAddress);
    }

    /**
     * @dev helper to set vBRIGHT contract address
     * _onlyOwner available
     */
    function setVBRIGHTAddress(address vBRIGHTAddress) public _onlyOwner {
        _vBRIGHTAddress = vBRIGHTAddress;
        _vBRIGHTToken = IERC20(_vBRIGHTAddress);
    }

    /**
     * @dev helper to set vPURE contract address
     * _onlyOwner available
     */
    function setVPUREAddress(address vPUREAddress) public _onlyOwner {
        _vPUREAddress = vPUREAddress;
        _vPUREToken = IERC20(_vPUREAddress);
    }

    /**
     * @dev helper to set uniswap factory address
     * _onlyOwner available
     */
    function setUniswapFactoryAddress(address factoryAddress)
        public
        _onlyOwner
    {
        _uniswapFactory = factoryAddress;
    }

    /**
     * @dev helper to set uniswap router address
     * _onlyOwner available
     */
    function setUniswapRouterAddress(address routerAddress) public _onlyOwner {
        _uniswapRouterAddress = routerAddress;
        _uniswapRouter02 = IUniswapV2Router02(_uniswapRouterAddress);
    }

    /**
     * @dev set the start time for the crowdsale period
     * _onlyOwner available
     */
    function setStartTime(uint256 start) public _onlyOwner {
        startTime = start;
    }

    /**
     * @dev set the end time for the crowdsale period
     * _onlyOwner available
     */
    function setEndTime(uint256 end) public _onlyOwner {
        endTime = end;
    }

    /**
     * @dev set the minimum ETH purchase value, only unsed for testing purposes
     * _onlyOwner available
     */
    function setETHMin(uint256 ethMinValue) public _onlyOwner {
        _ethMINValue = ethMinValue;
    }
    
    /**
     * @return the vPURE balance available for the given address.
     * _onlyOwner available
     */
    function getvPUREBalance(address from)
        public
        view
        _onlyOwner
        returns (uint256)
    {
        return _vCrowdsaleBalance[from].vPUREAmount;
    }

    /**
     * @return the ETH balance available for the given address
     * _onlyOwner available
     */
    function getEthBalance(address from)
        public
        view
        _onlyOwner
        returns (uint256)
    {
        return _vCrowdsaleBalance[from].ethAmount;
    }

    /**
     * @return the ETH balance available for the contract address
     */
    function getAvailableEth() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @return the vPURE balance available for the sender address
     */
    function getvPUREBalance() public view returns (uint256) {
        return _vCrowdsaleBalance[msg.sender].vPUREAmount;
    }

    /**
     * @return the ETH balance available for the sender address
     */
    function getEthBalance() public view returns (uint256) {
        return _vCrowdsaleBalance[msg.sender].ethAmount;
    }

    /**
     * @return the cap of the crowdsale
     * As long as the crowsale is running, vPURE is not yet delivered, so the capital will remain the same during the crowdsale.
     */
    function getCurrentCap() public view returns (uint256) {
        return _vPUREToken.balanceOf(address(this));
    }

    /**
     * @return the remaining cap of the crowdsale
     */
    function getAvailablevPURE() public view returns (uint256) {
        uint256 available = getCurrentCap();
        available = available.sub(_soldvPURE);
        return available;
    }

    /**
     * @return the ratio vPURE to ETH of the Crowdsale in wei
     */
    function getConversionvPUREtoETHRatio() public pure returns (uint256) {
        uint256 ratio = _VPURENUMERATOR * 10**18;
        ratio = ratio.div(_VPUREDENOMINATOR);
        return ratio;
    }

    /**
     * @return the price of vPURE in ETH of the Crowdsale in wei
     */
    function getPricevPUREinETH() public pure returns (uint256) {
        uint256 ratio = _VPUREDENOMINATOR * 10**18;
        ratio = ratio.div(_VPURENUMERATOR);
        return ratio;
    }

    /**
     * @return the min and max ETH required for a sale in wei
     */
    function getMinMaxETHForPurchase() public view returns (uint256, uint256) {
        return ( _ethMINValue, _ETHMAX );
    }

    /**
     * @return get the total amount of vPURE already sold
     */
    function getSoldvPURE() public view returns (uint256) {
        return _soldvPURE;
    }

    /**
     * @dev low level token purchase function
     */
    function buyTokens() public payable {
        uint256 ethAmount = msg.value;
        require(ethAmount >= _ethMINValue, "Minimum amount is 1 ETH");
        require(ethAmount <= _ETHMAX, "Maximum amount is 50 ETH");
        require(_isValidPurchase(ethAmount), "Wrong data sent to contract");
        require(!_isCapReached(), "Cap exceeded");

        // calculate token amount to be delivered
        uint256 vPUREAmount = ethAmount.mul(_VPURENUMERATOR);
        vPUREAmount = vPUREAmount.div(_VPUREDENOMINATOR);

        require(
            vPUREAmount <= getAvailablevPURE(),
            "Not enough vPURE available."
        );

        // update state
        _soldvPURE = _soldvPURE.add(vPUREAmount);

        // update the balance for the msg.sender
        _updateBalance(ethAmount, vPUREAmount);

        uint256 ethAmoutToLPvBRIGHT = ethAmount.mul(16).div(100); // 16% goes to LP for vBRIGHT;
        _adLp(ethAmoutToLPvBRIGHT, _vBRIGHTAddress);

        uint256 ethAmountToLpVIVID = ethAmount.mul(18).div(100); // 18% goes to LP for VIVID;
        // add LP for VIVID
        _adLp(ethAmountToLpVIVID, _VIVIDAddress);

        emit onVPURETokenPurchase(msg.sender, ethAmount, vPUREAmount);
    }
    
    /**
     * @dev low level token purchase function
     */
    

    /**
     * @dev withdraw the remaining tokens (UNIV2) at the end of presale period
     */
    function withdrawToken(address tokenAddress) public _onlyOwner {
        require(hasEnded(), "Presale still active");
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        TransferHelper.safeTransfer(tokenAddress, msg.sender, balance);
    }

    /**
     * @dev withdraw 9.8% of ETH to be used for marketing purpose
     */
    function withdrawETHForMarketing() public _onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= 0, "Insuficient founds");
        uint256 amount = balance.mul(98).div(1000);
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    /**
     * @dev used by the Vivid Finance team to support development
     * this is allowed only after the presale has ended
     */
    function withdrawRemainingETH() public _onlyOwner {
        require(hasEnded(), "Presale still active");

        uint256 balance = address(this).balance;
        require(balance >= 0, "Insuficient founds");
        TransferHelper.safeTransferETH(msg.sender, balance);
    }

    /**
     * @return true if crowdsale event has ended or the cap has been reached
     */
    function hasEnded() public view returns (bool) {
        return now > endTime || _isCapReached();
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return bool
     */
    function _isCapReached() private view returns (bool) {
        return getAvailablevPURE() == 0;
    }

    /**
     * @dev Checks whether the presale is active.
     * @return bool
     */
    function isActive() public view returns (bool) {
        return now > startTime && !hasEnded();
    }

    /**
     * @dev used to claim de purchased tokens at the end of presale event
     */
    function claimvPURE() public {
        require(hasEnded(), "Presale still active.");

        uint256 pureAmount = _vCrowdsaleBalance[msg.sender].vPUREAmount;
        require(pureAmount > 0, "No purchase has been made");
        _processPurchase(msg.sender, pureAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount)
        private
    {
        TransferHelper.safeTransfer(_vPUREAddress, beneficiary, tokenAmount);

        // reset the beneficiary balance
        _vCrowdsaleBalance[beneficiary].vPUREAmount = 0;
        _vCrowdsaleBalance[beneficiary].ethAmount = 0;

        emit onClaimPurchasedTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev add liquidity to LP
     */
    function _adLp(uint256 ethAmount, address tokenAddress)
        private
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        uint256 reserveA;
        uint256 reserveB;

        (reserveA, reserveB) = UniswapV2Library.getReserves(
            _uniswapFactory,
            _weth,
            tokenAddress
        );

        uint256 tokenAmount = UniswapV2Library.quote(
            ethAmount,
            reserveA,
            reserveB
        );

        TransferHelper.safeApprove(
            tokenAddress,
            _uniswapRouterAddress,
            tokenAmount
        );

        (amountToken, amountETH, liquidity) = _uniswapRouter02.addLiquidityETH{
            value: ethAmount
        }(
            tokenAddress,
            tokenAmount,
            tokenAmount,
            1,
            address(this),
            block.timestamp + 1 days
        );

        emit onLpvAdded(tokenAmount, amountETH, liquidity, tokenAddress);
    }

    /**
     * @return true if the transaction can buy tokens
     */
    function _isValidPurchase(uint256 amount) private view returns (bool) {
        bool withinPeriod = block.timestamp >= startTime &&
            block.timestamp <= endTime;
        bool nonZeroPurchase = amount != 0;
        return withinPeriod && nonZeroPurchase;
    }

    /**
     * @dev update the internal list of purchases
     */
    function _updateBalance(uint256 ethAmount, uint256 vPUREAmount) private {
        _vCrowdsaleBalance[msg.sender].ethAmount = _vCrowdsaleBalance[msg
            .sender]
            .ethAmount
            .add(ethAmount);
        // safetly check for the total amount of ETH bought by a single user
        // it should not exceed 50 ETH
        require(
            _vCrowdsaleBalance[msg.sender].ethAmount <= _ETHMAX * 10**18,
            "The total amount of ETH exceeded maximul value: 50 ETH"
        );

        _vCrowdsaleBalance[msg.sender].vPUREAmount = _vCrowdsaleBalance[msg
            .sender]
            .vPUREAmount
            .add(vPUREAmount);
    }
}