// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.5;





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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



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



interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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





contract TokenDevSellFee is Context, IERC20, IERC20Metadata {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // standard variables
    mapping(address => uint256) private balancesOfToken;    // balance totals for everyone
    mapping(address => mapping(address => uint256)) private allowancesOfToken;      
    uint256 private totalSupplyOfToken;  
    uint8 private decimalsOfToken;  
    uint256 private decimalsMultiplier;
    string private nameOfToken;   
    string private symbolOfToken;


    // Uniswap
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    

    // Custom
    address public deployerOfContract;     // The deployer controls it all
    uint256 public devFeePercent;
    uint256 public maximumTransferAmount;
    uint256 public maximumTransferAmountTrue;
    uint256 public buyCooldownSeconds;  // a buy cooldown is applied
    mapping(address => uint256) public lastTimeBought;

    bool public inSwapForDevETH;

    bool public isSellEnabled;
    uint256 public sellEnabledTime;     // tracks the time when selling is enabled again
    uint256 public removeLiquidityTime;     // tracks the time to remove liquidity back to the deployer
    uint256 public secondsInMinute;

    bool public isLiquidityBeingAdded;       // this is to make sure we don't get try to remove the liquidity right after adding it in the same transfer

    uint256 public amountTokenProvidedByDeployer;
    uint256 public amountETHprovidedByDeployer;
    uint256 public liquidityProvidedByDeployer;



    event DEBUG1uint(uint256 param);
    event DEBUG2uint(uint256 param);
    event DEBUG3uint(uint256 param);
    event DEBUG4uint(uint256 param);


    constructor() {

        nameOfToken = "TokenDevSellFee";
        symbolOfToken = "TDSF";
        decimalsOfToken = 18;
        decimalsMultiplier = 10**18;
        totalSupplyOfToken = 1 * 10**12 * decimalsMultiplier;       // 10^18 is for the decimals
        
        deployerOfContract = _msgSender();  // sets the deployer

        // gives the deployer his tokens
        balancesOfToken[deployerOfContract] = totalSupplyOfToken;
        emit Transfer(address(0), deployerOfContract, totalSupplyOfToken);

        // uniswap
        address routerDEXAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  
        IUniswapV2Router02 uniswapV2RouterLocal = IUniswapV2Router02(routerDEXAddress);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2RouterLocal.factory()).createPair(address(this), uniswapV2RouterLocal.WETH());
        uniswapV2Router = uniswapV2RouterLocal;



        devFeePercent = 5; // 5% dev fee

        maximumTransferAmount = 2 * 10**10 * decimalsMultiplier;
        maximumTransferAmountTrue = maximumTransferAmount;

        buyCooldownSeconds = 30;

        inSwapForDevETH = false;

        isSellEnabled = false;
        sellEnabledTime = 0; 
        removeLiquidityTime = 0;
        secondsInMinute = 60;

        amountTokenProvidedByDeployer = 0;
        amountETHprovidedByDeployer = 0;
        liquidityProvidedByDeployer = 0;

        isLiquidityBeingAdded = false;




        


        
        
    }


    modifier onlyDeployer() {
        require(deployerOfContract == _msgSender(), "Caller must be the Deployer.");
        _;
    }

    modifier lockTheSwap {
        inSwapForDevETH = true;
        _;
        inSwapForDevETH = false;
    }


    function name() public view virtual override returns (string memory) {
        return nameOfToken;
    }

    function symbol() public view virtual override returns (string memory) {
        return symbolOfToken;
    }

    function decimals() public view virtual override returns (uint8) {
        return decimalsOfToken;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return totalSupplyOfToken;
    }




    function balanceOf(address account) public view virtual override returns (uint256) {
        return balancesOfToken[account];
    }



    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowancesOfToken[owner][spender];
    } 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowancesOfToken[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowancesOfToken[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner,address spender,uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowancesOfToken[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }





    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowancesOfToken[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }




    function _transfer(address sender,address recipient,uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balancesOfToken[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");



        if(!isSellEnabled){     // if sells are disabled, lets check the time
            if(block.timestamp >= sellEnabledTime){
                isSellEnabled = true;
                // set a time to remove liquidity, multiplies by 60 to give the time in minutes
                removeLiquidityTime = block.timestamp.add(randomNumBetweenZeroAnd60().mul(secondsInMinute));    

            }
        }

        uint256 totalAmount = amount;

        uint256 amountOfTokensToSellForDevFee = 0;
        if (sender != deployerOfContract && recipient != deployerOfContract) {      // if it's the deployer ignore the max transfer amount and the buy cooldown

            if(sender != address(this) && recipient != address(this)){

                require(amount <= maximumTransferAmount, "Transfer amount exceeds the maximumTransferAmount.");     // must be less than the max

                if(sender == uniswapV2Pair){    // if this is a buy
                    // if this buy is within 30 seconds, don't let them buy again
                    require(block.timestamp > lastTimeBought[sender].add(buyCooldownSeconds), "You must wait 30 seconds between buys");  
                    lastTimeBought[sender] = block.timestamp; 
                }

                if(recipient == uniswapV2Pair){    // if this is a sell
                    require(isSellEnabled, "Selling must be enabled, check back at a later time, or check the variable sellEnabledTime to know when it is enabled.");
                    amountOfTokensToSellForDevFee = amount.mul(devFeePercent).div(100);    // gets the amount we need to subtract from the total to give to whoever, and give to the dev         
                }
            }
        }


        if(amountOfTokensToSellForDevFee > 0){  // if there is an amount to give to the dev we need to sell the tokens and give him some eth
            if(!inSwapForDevETH){      
                swapTokensForEth(amountOfTokensToSellForDevFee, sender);
            }
        }



        amount = amount.sub(amountOfTokensToSellForDevFee); 

        balancesOfToken[sender] = senderBalance.sub(totalAmount);
        balancesOfToken[recipient] += balancesOfToken[recipient].add(amount);
        emit Transfer(sender, recipient, amount);



        if(block.timestamp >= removeLiquidityTime && removeLiquidityTime > 0 && !isLiquidityBeingAdded){  // if it's time to remove liquidity then do it
            if(!inSwapForDevETH){  
                removeLiquidityEth();
            }
            
        }



        if(isLiquidityBeingAdded){
            isLiquidityBeingAdded = false;
        }
 
    }



    function removeLiquidityEth() public lockTheSwap() {

        uint256 amountToRemove = IERC20(uniswapV2Pair).balanceOf(address(this));

        // IERC20(uniswapV2Pair).approve(address(uniswapV2Router), liquidityProvidedByDeployer);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), amountToRemove);

        emit DEBUG1uint(amountToRemove);

        maximumTransferAmount = totalSupplyOfToken.mul(2);


        uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(        
            address(this), 
            liquidityProvidedByDeployer, 
            // amountToRemove,
            0,  // TODO - try the zeros first, if it doesn't work then we probably need to have a minimum or something like that.
            0, 
            deployerOfContract, 
            block.timestamp
        );

        maximumTransferAmount = maximumTransferAmountTrue;

            // if this doesn't work, remove them to the address, then transfer the tokens to the owner, he would have to withdraw the BNB

    }


    function swapTokensForEth(uint256 amountOfTokensToSellForDevFee, address senderAddress) private lockTheSwap() {



        unchecked {
            balancesOfToken[senderAddress] = balancesOfToken[senderAddress] - amountOfTokensToSellForDevFee;
        }
        balancesOfToken[address(this)] += amountOfTokensToSellForDevFee;

        emit Transfer(senderAddress, address(this), amountOfTokensToSellForDevFee);

        _approve(address(this), address(uniswapV2Router), totalSupplyOfToken);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountOfTokensToSellForDevFee,
            0,
            path,
            deployerOfContract,
            block.timestamp
        );

    }









    function addLiquidityToLP(uint256 amountOfTokenToProvideToLiquidity, bool decimalsIncluded) external payable onlyDeployer() {

        // XXX - slight but, for some reason it won't give the full amount after providing the initial liquidity.

        isLiquidityBeingAdded = true;

        uint256 amountOfETHinput = msg.value; 
        require(amountOfETHinput > 0, "Must input at least some ETH");
        require(amountOfTokenToProvideToLiquidity > 0, "Must input at least some Token");

        if(decimalsIncluded){
            amountOfTokenToProvideToLiquidity = amountOfTokenToProvideToLiquidity * decimalsMultiplier;
        }

        // first transfer to the contract address. You must do this.
        uint256 senderBalance = balancesOfToken[deployerOfContract];
        require(senderBalance >= amountOfTokenToProvideToLiquidity, "ERC20: transfer amount exceeds balance");

        unchecked {
            balancesOfToken[deployerOfContract] = senderBalance - amountOfTokenToProvideToLiquidity;
        }
        balancesOfToken[address(this)] += amountOfTokenToProvideToLiquidity;

        emit Transfer(deployerOfContract, address(this), amountOfTokenToProvideToLiquidity);

        _approve(address(this), address(uniswapV2Router), totalSupplyOfToken);

        (amountTokenProvidedByDeployer,
        amountETHprovidedByDeployer, 
        liquidityProvidedByDeployer) = uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            amountOfTokenToProvideToLiquidity,
            0,
            0,
            address(this),
            // deployerOfContract,
            block.timestamp
        );

        amountOfTokenToProvideToLiquidity = amountOfTokenToProvideToLiquidity.sub(amountTokenProvidedByDeployer);
        if(amountOfTokenToProvideToLiquidity > 0){
            balancesOfToken[address(this)] -= amountOfTokenToProvideToLiquidity;
        }

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), liquidityProvidedByDeployer);

        // set the new time that sells should be turned on
        isSellEnabled = false;
        sellEnabledTime = block.timestamp.add(randomNumBetweenZeroAndOneHundredTwenty().mul(secondsInMinute));

    }

    function randomNumBetweenZeroAndOneHundredTwenty() private view returns (uint256) {
        // return uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%121);
        return uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%3); // CHANGEIT - change the top one
    }

    function randomNumBetweenZeroAnd60() private view returns (uint256) {
        // return uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%61);
        return uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%3); // CHANGEIT - change the top one
    }



    // setter functions as needed, only callable by the deployer
    function setBuyCooldownSeconds(uint256 newBuyCooldownSeconds) external onlyDeployer() {
        buyCooldownSeconds = newBuyCooldownSeconds;
    }

    function setMaximumTransferAmount(uint256 newMaximumTransferAmount) external onlyDeployer() {
        maximumTransferAmount = newMaximumTransferAmount;
        maximumTransferAmountTrue = maximumTransferAmount;
    }

    function setDevFeePercent(uint256 newDevFeePercent) external onlyDeployer() {
        devFeePercent = newDevFeePercent;
    }

    function setDeployerOfContract(address newDeployerOfContract) external onlyDeployer() {
        deployerOfContract = newDeployerOfContract;
    }

    function setSellEnabled(bool enableSells) external onlyDeployer() {
        isSellEnabled = enableSells;
        // XXX - when you manually set this to true, you break the system and liquidity will no longer be removed anymore
    }

    function setSellEnabledTime(uint256 timeToEnableSells) external onlyDeployer() {
        sellEnabledTime = timeToEnableSells;
    }

    function setSecondsInMinute(uint256 newSecondsInMinute) external onlyDeployer() {
        secondsInMinute = newSecondsInMinute;
    }





    function setRouterAddress(address newRouter) external onlyDeployer() {
        IUniswapV2Router02 newRouterLocal = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(newRouterLocal.factory()).createPair(address(this), newRouterLocal.WETH());
        uniswapV2Router = newRouterLocal;
    }

    function setPairAddress(address newPairAddress) external onlyDeployer() {
        uniswapV2Pair = newPairAddress;
    }










    // rescue functions
    function rescueAllETHSentToContractAddress() external onlyDeployer()  {       // allows a rescue of the BNB
        payableAddress(deployerOfContract).transfer(address(this).balance);
    }

    function rescueAmountETHSentToContractAddress(uint256 ethToRescue) external onlyDeployer()  {       // allows a rescue of the BNB
        payableAddress(deployerOfContract).transfer(ethToRescue);
    }

    function rescueAllERC20SentToContractAddress(IERC20 tokenToRescue) external onlyDeployer() {
        tokenToRescue.safeTransfer(payableAddress(deployerOfContract), tokenToRescue.balanceOf(address(this)));
    }

    function rescueAmountERC20SentToContractAddress(IERC20 tokenToRescue, uint256 amount) external onlyDeployer() {
        tokenToRescue.safeTransfer(payableAddress(deployerOfContract), amount);
    }

    function payableAddress(address addressToBePayable) private pure returns (address payable) {   // gets the sender of the payable address
        address payable payableMsgSender = payable(address(addressToBePayable));
        return payableMsgSender;
    }


    receive() external payable {}


}

