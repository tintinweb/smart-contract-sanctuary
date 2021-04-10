/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

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

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.6.0;




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

// File: contracts/interfaces/weth/IWETH.sol


pragma solidity ^0.6.12;


interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

// File: contracts/interfaces/uniswap-v2/IUniswapV2Router01.sol


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

// File: contracts/interfaces/uniswap-v2/IUniswapV2Router02.sol


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

// File: contracts/interfaces/kaya/ISmartPool.sol


pragma solidity ^0.6.12;
interface ISmartPool{

    function joinPool(uint256 amount) external;

    function exitPool(uint256 amount) external;

    function transferCash(address to,uint256 amount)external;

    function token()external view returns(address);

    function assets()external view returns(uint256);
}

// File: contracts/interfaces/kaya/IController.sol


pragma solidity ^0.6.12;
interface IController {

    function invest(address _vault, uint256 _amount) external;

    function exec(
        address _strategy,
        bool _useToken,
        uint256 _useAmount,
        string memory _signature,
        bytes memory _data) external;

    function harvest(uint256 _amount) external;

    function harvestAll(address _vault)external;

    function harvestOfUnderlying(address to,uint256 _scale)external;

    function extractableUnderlyingNumber(uint256 _scale)external view returns(uint256[] memory);

    function assets() external view returns (uint256);

    function vaults(address _strategy) external view returns(address);

    function strategies(address _vault) external view returns(address);

    function inRegister(address _contract) external view returns (bool);
}

// File: contracts/interfaces/uniswap-v2/IUniswapV2Pair.sol


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

// File: contracts/libraries/UniswapV2ExpandLibrary.sol


pragma solidity ^0.6.12;





library UniswapV2ExpandLibrary{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address constant internal factory=address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0,address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    function pairFor(address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function quote(uint amountA,uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getAmountIn(address inputToken,address outputToken,uint256 amountOut)internal view returns(uint256 amountIn){
        (uint reserveIn, uint reserveOut) = getReserves(inputToken, outputToken);
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountOut(address inputToken,address outputToken,uint256 amountIn)internal view returns(uint256 amountOut){
        (uint reserveIn, uint reserveOut) = getReserves(inputToken, outputToken);
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountsOut(uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            amounts[i + 1] = getAmountOut(path[i], path[i + 1],amounts[i]);
        }
    }

    function getAmountsIn(uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            amounts[i - 1] = getAmountIn(path[i - 1], path[i],amounts[i]);
        }
    }

    function calcLiquidityToTokens(address tokenA,address tokenB,uint256 liquidity) internal view returns (uint256 amountA, uint256 amountB) {
        if(liquidity==0){
            return (0,0);
        }
        address pair=pairFor(tokenA,tokenB);
        uint256 balanceA = IERC20(tokenA).balanceOf(address(pair));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(pair));
        uint256 totalSupply=IERC20(pair).totalSupply();
        amountA = liquidity.mul(balanceA).div(totalSupply);
        amountB = liquidity.mul(balanceB).div(totalSupply);
        return(amountA,amountB);
    }

    function tokens(address _pair)internal view returns(address,address){
        IUniswapV2Pair pair=IUniswapV2Pair(_pair);
        return (pair.token0(),pair.token1());
    }

    function liquidityBalance(address _pair,address _owner)internal view returns(uint256){
        return IUniswapV2Pair(_pair).balanceOf(_owner);
    }

    function calcLiquiditySwapToToken(address _pair,address _target,address bridgeToken,uint256 liquidity) internal view returns (uint256) {
        if(liquidity==0){
            return 0;
        }
        IUniswapV2Pair pair=IUniswapV2Pair(_pair);
        (address tokenA,address tokenB)=(pair.token0(),pair.token1());
        (uint256 amountA,uint256 amountB)=calcLiquidityToTokens(tokenA,tokenB,liquidity);
        if(tokenA!=bridgeToken&&tokenA!=_target){
            amountA=getAmountOut(tokenA,bridgeToken,amountA);
        }
        if(tokenB!=bridgeToken&&tokenB!=_target){
            amountB=getAmountOut(tokenB,bridgeToken,amountB);
        }
        uint256 tokenAOut=getAmountOut(bridgeToken,_target,amountA);
        uint256 tokenBOut=getAmountOut(bridgeToken,_target,amountB);
        return tokenAOut.add(tokenBOut);
    }

    function swap(address to,address inputToken,address outputToken,uint256 amountIn,uint256 amountOut) internal{
        IUniswapV2Pair pair=IUniswapV2Pair(pairFor(inputToken,outputToken));
        IERC20(inputToken).safeTransfer(address(pair), amountIn);
        (address token0,) = sortTokens(inputToken, outputToken);
        (uint amount0Out, uint amount1Out) = inputToken == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        pair.swap(amount0Out,amount1Out, to, new bytes(0));
    }

    function swapExactIn(address to,address inputToken,address outputToken, uint256 amountIn) internal returns(uint256 amountOut){
        amountOut=amountIn;
        if (amountIn > 0 && inputToken != outputToken) {
            amountOut = getAmountOut(inputToken, outputToken, amountIn);
            swap(to, inputToken, outputToken, amountIn, amountOut);
        }
    }

    function swapExactOut(address to,address inputToken,address outputToken,uint256 amountOut) internal returns(uint256 amountIn){
        amountIn=amountOut;
        if (amountOut > 0 && inputToken != outputToken) {
            amountIn = getAmountIn(inputToken, outputToken, amountOut);
            swap(to, inputToken, outputToken, amountIn, amountOut);
        }
    }

}

// File: contracts/libraries/MathExpandLibrary.sol


pragma solidity ^0.6.12;

// a library for performing various math operations

library MathExpandLibrary {

    uint256 internal constant BONE = 10**18;

    // Add two numbers together checking for overflows
    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    // subtract two numbers and return diffecerence when it underflows
    function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    // Subtract two numbers checking for underflows
    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    // Multiply two 18 decimals numbers
    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BONE;
        return c2;
    }

    // Divide two 18 decimals numbers
    function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ERR_DIV_ZERO");
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint256 c2 = c1 / b;
        return c2;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: contracts/libraries/EnumerableExpandSet.sol



pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableExpandSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }


    function _index(Set storage set, bytes32 value) private view returns (uint256) {
        return set._indexes[value];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    function indexs(AddressSet storage set, address value) internal view returns (uint256) {
        return _index(set._inner, bytes32(uint256(value)));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function indexs(UintSet storage set, uint256 value) internal view returns (uint256) {
        return _index(set._inner, bytes32(value));
    }
}

// File: contracts/libraries/ERC20Helper.sol


pragma solidity ^0.6.12;



library ERC20Helper{

    using SafeERC20 for IERC20;

    function safeApprove(address _token,address _to,uint256 _amount)internal{
        IERC20 token=IERC20(_token);
        uint256 allowance= token.allowance(address(this),_to);
        if(allowance<_amount){
            if(allowance>0){
                token.safeApprove(_to,0);
            }
            token.safeApprove(_to,_amount);
        }
    }
}

// File: contracts/storage/GovIdentityStorage.sol


pragma solidity ^0.6.12;


library GovIdentityStorage {

  bytes32 public constant govSlot = keccak256("GovIdentityStorage.storage.location");

  struct Identity{
    address governance;
    address strategist;
    address rewards;
  }

  function load() internal pure returns (Identity storage gov) {
    bytes32 loc = govSlot;
    assembly {
      gov_slot := loc
    }
  }
}

// File: contracts/GovIdentity.sol


pragma solidity ^0.6.12;


contract GovIdentity {

    constructor() public {
        _build();
    }

    function _build() internal{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.governance = msg.sender;
        identity.strategist = msg.sender;
        identity.rewards = msg.sender;
    }

    modifier onlyStrategist() {
        GovIdentityStorage.Identity memory identity= GovIdentityStorage.load();
        require(msg.sender == identity.strategist, "GovIdentity.onlyStrategist: !strategist");
        _;
    }

    modifier onlyGovernance() {
        GovIdentityStorage.Identity memory identity= GovIdentityStorage.load();
        require(msg.sender == identity.governance, "GovIdentity.onlyGovernance: !governance");
        _;
    }

    modifier onlyStrategistOrGovernance() {
        GovIdentityStorage.Identity memory identity= GovIdentityStorage.load();
        require(msg.sender == identity.strategist || msg.sender == identity.governance, "GovIdentity.onlyGovernance: !governance and !strategist");
        _;
    }

    function setRewards(address _rewards) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.rewards = _rewards;
    }

    function setStrategist(address _strategist) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.strategist = _strategist;
    }

    function setGovernance(address _governance) public onlyGovernance{
        GovIdentityStorage.Identity storage identity= GovIdentityStorage.load();
        identity.governance = _governance;
    }

    function getRewards() public pure returns(address){
        GovIdentityStorage.Identity memory identity= GovIdentityStorage.load();
        return identity.rewards ;
    }

    function getStrategist() public pure returns(address){
        GovIdentityStorage.Identity memory identity= GovIdentityStorage.load();
        return identity.strategist;
    }

    function getGovernance() public pure returns(address){
        GovIdentityStorage.Identity memory identity= GovIdentityStorage.load();
        return identity.governance;
    }

}

// File: contracts/strategies/UniDynamicLiquidityStrategy.sol


pragma solidity ^0.6.12;











pragma experimental ABIEncoderV2;

contract UniDynamicLiquidityStrategy is GovIdentity {

    using SafeERC20 for IERC20;
    using MathExpandLibrary for uint256;
    using SafeMath for uint256;
    using EnumerableExpandSet for EnumerableExpandSet.AddressSet;

    IController public controller;
    IUniswapV2Router02 constant public route=IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    EnumerableExpandSet.AddressSet private _tokens;
    EnumerableExpandSet.AddressSet private _pools;

    event AddLiquidity(address indexed from,address indexed pool,uint256 liquidity);
    event RemoveLiquidity(address indexed from,address indexed pool,uint256 liquidity);

    constructor(address _controller)
    public {
        controller = IController(_controller);
    }

    modifier onlyAuthorize() {
        require(msg.sender == getGovernance()
        ||msg.sender==getStrategist()
        ||msg.sender==address(controller), "Strategy.onlyAuthorize: !authorize");
        _;
    }

    receive() external payable {

    }

    function init()external{

    }

    function _vaultInfo() internal view returns (address, address){
        address _vault = controller.vaults(address(this));
        address _token = ISmartPool(_vault).token();
        return (_vault, _token);
    }

    function pools()public view returns(address[] memory ps){
        uint256 length=_pools.length();
        ps=new address[](length);
        for(uint256 i=0;i<length;i++){
            ps[i]=_pools.at(i);
        }
    }

    function _updatePools(address _pool)internal{
        bool isNeedPool=IERC20(_pool).balanceOf(address(this))>0?true:false;
        if(!_pools.contains(_pool)&&isNeedPool){
            _pools.add(_pool);
        }else if(_pools.contains(_pool)&&!isNeedPool){
            _pools.remove(_pool);
        }
    }

    function setUnderlyingTokens(address[] memory _ts)public onlyAuthorize{
        for(uint256 i=0;i<_ts.length;i++){
            if(!_tokens.contains(_ts[i])){
                _tokens.add(_ts[i]);
            }
        }
    }

    function removeUnderlyingTokens(address[] memory _ts)public onlyAuthorize{
        for(uint256 i=0;i<_ts.length;i++){
            if(_tokens.contains(_ts[i])){
                _tokens.remove(_ts[i]);
            }
        }
    }

    function addLiquidity(address _pool,uint256 liquidityExpect,uint256 amount0,uint256 amount1)public onlyAuthorize{
        require(amount0>0&&amount1>0,'Strategy.addLiquidity: Must be greater than 0 amount');
        (address token0,address token1)=UniswapV2ExpandLibrary.tokens(_pool);
        ERC20Helper.safeApprove(token0,address(route),amount0);
        ERC20Helper.safeApprove(token1,address(route),amount1);
        (,,uint256 liquidityActual)=route.addLiquidity(token0,token1,amount0,amount1,0,0,address(this),block.timestamp);
        require(liquidityActual>=liquidityExpect,'Strategy.addLiquidity: Actual quantity is less than the expected quantity');
        _updatePools(_pool);
        emit AddLiquidity(msg.sender,_pool,liquidityActual);
    }

    function removeLiquidity(address _pool,uint256 liquidity)public onlyAuthorize{
        require(liquidity>0,'Strategy.removeLiquidity: Must be greater than 0 liquidity');
        _removeLiquidity(_pool,liquidity,address(this));
        emit RemoveLiquidity(msg.sender,_pool,liquidity);
    }

    function _removeLiquidity(address _pool,uint256 liquidity,address _to)internal returns(uint256 amount0,uint256 amount1){
        if(liquidity>0){
            ERC20Helper.safeApprove(_pool,address(route),liquidity);
            (address token0,address token1)=UniswapV2ExpandLibrary.tokens(_pool);
            (amount0,amount1)=UniswapV2ExpandLibrary.calcLiquidityToTokens(token0,token1,liquidity);
            (amount0,amount1)=route.removeLiquidity(token0,token1,liquidity,amount0,amount1,_to,block.timestamp);
            _updatePools(_pool);
        }
    }

    function swapExactInByUni(address inputToken,address outputToken, uint256 amountIn)public onlyAuthorize returns(uint256 amountOut){
        if(inputToken==WETH||outputToken==WETH){
            return UniswapV2ExpandLibrary.swapExactIn(address(this),inputToken,outputToken,amountIn);
        }else{
            uint256 wethOut=UniswapV2ExpandLibrary.swapExactIn(address(this),inputToken,WETH,amountIn);
            return UniswapV2ExpandLibrary.swapExactIn(address(this),WETH,outputToken,wethOut);
        }
    }

    function swapExactOutByUni(address inputToken,address outputToken, uint256 amountOut)public onlyAuthorize returns(uint256 amountIn){
        if(inputToken==WETH||outputToken==WETH){
            return UniswapV2ExpandLibrary.swapExactOut(address(this),inputToken,outputToken,amountOut);
        }else{
            uint256 wethIn=UniswapV2ExpandLibrary.getAmountIn(WETH,outputToken,amountOut);
            if(IERC20(WETH).balanceOf(address(this))<wethIn){
                UniswapV2ExpandLibrary.swapExactOut(address(this),inputToken,WETH,wethIn);
            }
            return UniswapV2ExpandLibrary.swapExactIn(address(this),WETH,outputToken,wethIn);
        }
    }

    function ethToWeth(uint256 amountIn)public onlyAuthorize{
        IWETH(WETH).deposit{value: amountIn}();
    }


    function deposit(uint256 _amount) external {
        require(msg.sender == address(controller), 'Strategy.deposit: !controller');
        (,address _vaultToken) = _vaultInfo();
        require(_amount > 0, 'Strategy.deposit: token balance is zero');
        IERC20 tokenContract = IERC20(_vaultToken);
        require(tokenContract.balanceOf(msg.sender) >= _amount, 'Strategy.deposit: Insufficient balance');
        tokenContract.safeTransferFrom(msg.sender, address(this), _amount);
        if(!_tokens.contains(_vaultToken)){
            _tokens.add(_vaultToken);
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == address(controller), 'Strategy.withdraw: !controller');
        require(_amount > 0, 'Strategy.withdraw: Must be greater than 0 amount');
        require(_amount <= assets(), 'Strategy.withdraw: Must be less than assets');
        (address _vault,address _vaultToken) = _vaultInfo();
        IERC20 tokenContract=IERC20(_vaultToken);
        uint256 cashAmount=tokenContract.balanceOf(address(this));
        if(cashAmount<_amount){
            uint256 scale=_amount.bdiv(assets());
            uint256[] memory underlyingNumbers=_withdrawOfUnderlying(scale);
            uint256 wethAmountOut;
            for(uint256 i=0;i<_tokens.length();i++){
                address token=_tokens.at(i);
                if(token==WETH){
                    wethAmountOut=wethAmountOut.add(underlyingNumbers[i]);
                }else if(token!=_vaultToken&&underlyingNumbers[i]>0){
                    wethAmountOut=wethAmountOut.add(UniswapV2ExpandLibrary.swapExactIn(address(this),token,WETH,underlyingNumbers[i]));
                }
            }
            UniswapV2ExpandLibrary.swapExactIn(address(this),WETH,_vaultToken,wethAmountOut);
        }
        cashAmount=tokenContract.balanceOf(address(this));
        if(cashAmount<_amount){
            _amount=cashAmount;
        }
        tokenContract.safeTransfer(_vault,_amount);
    }

    function withdrawOfUnderlying(address payable _to,uint256 _scale)external{
        require(msg.sender == address(controller), 'Strategy.withdrawOfUnderlying: !controller');
        require(_scale > 0, 'Strategy.withdrawOfUnderlying: Must be greater than 0');
        uint256[] memory underlyingNumbers= _withdrawOfUnderlying(_scale);
        for(uint256 i=0;i<underlyingNumbers.length;i++){
            if(underlyingNumbers[i]>0){
                IERC20(_tokens.at(i)).safeTransfer(_to,underlyingNumbers[i]);
            }
        }
    }

    function _withdrawOfUnderlying(uint256 _scale)internal returns(uint256[] memory underlyingNumbers){
        underlyingNumbers=new uint256[](_tokens.length());
        for(uint256 i=0;i<_tokens.length();i++){
            uint256 bal=IERC20(_tokens.at(i)).balanceOf(address(this));
            underlyingNumbers[i]=bal.mul(_scale).div(1e18);
        }
        for(uint256 i=_pools.length();i>0;i--){
            address pool=_pools.at(i.sub(1));
            uint256 liquidityBalance=UniswapV2ExpandLibrary.liquidityBalance(pool,address(this));
            uint256 liquidity=liquidityBalance.mul(_scale).div(1e18);
            if(liquidity>0){
                (uint256 amount0,uint256 amount1)=_removeLiquidity(pool,liquidity,address(this));
                (address token0,address token1)=UniswapV2ExpandLibrary.tokens(pool);
                uint256 token0Index= _tokens.indexs(token0).sub(1);
                uint256 token1Index= _tokens.indexs(token1).sub(1);
                underlyingNumbers[token0Index]=amount0.add(underlyingNumbers[token0Index]);
                underlyingNumbers[token1Index]=amount1.add(underlyingNumbers[token1Index]);
            }
        }
    }

    function withdraw(address _token) external onlyGovernance returns (uint256 balance){
        IERC20 token=IERC20(_token);
        balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(msg.sender, balance);
        }
    }

    function withdrawAll() external {
        require(msg.sender == address(controller), 'Strategy.withdrawAll: !controller');
        for(uint256 i=_pools.length();i>0;i--){
            address pool=_pools.at(i.sub(1));
            uint256 liquidity=UniswapV2ExpandLibrary.liquidityBalance(pool,address(this));
            _removeLiquidity(pool,liquidity,address(this));
        }
        (address _vault,address _vaultToken) = _vaultInfo();
        for(uint256 j=0;j<_tokens.length();j++){
            address token=_tokens.at(j);
            uint256 bal=IERC20(token).balanceOf(address(this));
            if(token!=_vaultToken&&token!=WETH&&bal>0){
               UniswapV2ExpandLibrary.swapExactIn(address(this),token,WETH,bal);
            }
        }
        uint256 amountIn = IERC20(WETH).balanceOf(address(this));
        UniswapV2ExpandLibrary.swapExactIn(address(this),WETH,_vaultToken,amountIn);
        IERC20 vaultToken=IERC20(_vaultToken);
        vaultToken.safeTransfer(_vault, vaultToken.balanceOf(address(this)));
    }

    function extractableUnderlyingNumber(uint256 _scale)public view returns(uint256[] memory tokenNumbers){
        uint256[] memory tokenTotalNumbers=getTokenNumbers();
        tokenNumbers=new uint256[](tokenTotalNumbers.length);
        for(uint256 i=0;i<tokenTotalNumbers.length;i++){
            if(tokenTotalNumbers[i]>0){
                tokenNumbers[i]=tokenTotalNumbers[i].mul(_scale).div(1e18);
            }
        }
    }

    function getTokenNumbers()public view returns(uint256[] memory amounts){
        amounts=new uint256[](_tokens.length());
        for(uint256 i=_pools.length();i>0;i--){
            address pool=_pools.at(i.sub(1));
            (address token0,address token1)=UniswapV2ExpandLibrary.tokens(pool);
            (uint256 amount0,uint256 amount1)=liquidityTokenOut(pool);
            uint256 token0Index= _tokens.indexs(token0).sub(1);
            uint256 token1Index= _tokens.indexs(token1).sub(1);
            amounts[token0Index]=amount0.add(amounts[token0Index]);
            amounts[token1Index]=amount1.add(amounts[token1Index]);
        }
        for(uint256 i=0;i<_tokens.length();i++){
            amounts[i]=amounts[i].add(IERC20(_tokens.at(i)).balanceOf(address(this)));
        }
    }

    function getTokens()public view returns(address[] memory ts){
        uint256 length=_tokens.length();
        ts=new address[](length);
        for(uint256 i=0;i<length;i++){
            ts[i]=_tokens.at(i);
        }
    }

    function getWeights()public view returns(uint256[] memory ws){
        uint256 assets=assets();
        (,address _vaultToken) = _vaultInfo();
        ws=new uint256[](_tokens.length());
        uint256[] memory tokenNumbers=getTokenNumbers();
        for(uint256 i=0;i<_tokens.length();i++){
            uint256 ta=tokenValueByIn(_tokens.at(i),_vaultToken,tokenNumbers[i]);
            if(assets!=0){
                ws[i]=ta.bdiv(assets).mul(100);
            }
        }
    }

    function assets() public view returns (uint256){
        (,address _vaultToken) = _vaultInfo();
        uint256 total=0;
        uint256[] memory tokenNumbers=getTokenNumbers();
        for(uint256 i=0;i<_tokens.length();i++){
            uint256 ta=tokenValueByIn(_tokens.at(i),_vaultToken,tokenNumbers[i]);
            total=total.add(ta);
        }
        return total;
    }

    function available() public view returns (uint256){
        (,address _vaultToken) = _vaultInfo();
        uint256 total=0;
        uint256 wethBal=0;
        for(uint256 i=0;i<_tokens.length();i++){
            address token=_tokens.at(i);
            uint256 bal=IERC20(token).balanceOf(address(this));
            if(token==WETH){
                wethBal=wethBal.add(bal);
            }else if(token!=_vaultToken&&bal>0){
                wethBal=wethBal.add(UniswapV2ExpandLibrary.getAmountOut(token,WETH,bal));
            }
        }
        if(wethBal>0){
            total=total.add(UniswapV2ExpandLibrary.getAmountOut(WETH,_vaultToken,wethBal));
        }
        total=total.add(IERC20(_vaultToken).balanceOf(address(this)));
        return total;
    }

    function tokenValueByIn(address _fromToken,address _toToken,uint256 _amount)public view returns (uint256){
        if(_amount==0)return _amount;
        if(_fromToken==_toToken){
            return _amount;
        }else if(_fromToken==WETH){
            return UniswapV2ExpandLibrary.getAmountOut(_fromToken,_toToken,_amount);
        }else{
            uint256 wethAmount=UniswapV2ExpandLibrary.getAmountOut(_fromToken,WETH,_amount);
            return UniswapV2ExpandLibrary.getAmountOut(WETH,_toToken,wethAmount);
        }
    }

    function tokenValueByOut(address _fromToken,address _toToken,uint256 _amount)public view returns (uint256){
        if(_amount==0)return _amount;
        if(_fromToken==_toToken){
            return _amount;
        }else if(_fromToken==WETH){
            return UniswapV2ExpandLibrary.getAmountIn(_fromToken,_toToken,_amount);
        }else{
            uint256 wethOut=UniswapV2ExpandLibrary.getAmountIn(_fromToken,WETH,_amount);
            return UniswapV2ExpandLibrary.getAmountIn(_fromToken,WETH,wethOut);
        }
    }


    function liquidityTokenOut(address _pool) public view returns (uint256,uint256){
        (address token0,address token1)=UniswapV2ExpandLibrary.tokens(_pool);
        uint256 liquidity=UniswapV2ExpandLibrary.liquidityBalance(_pool,address(this));
        return UniswapV2ExpandLibrary.calcLiquidityToTokens(token0,token1,liquidity);
    }
}