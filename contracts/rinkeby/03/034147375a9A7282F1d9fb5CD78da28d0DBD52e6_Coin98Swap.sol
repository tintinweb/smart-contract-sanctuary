/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
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

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint` to its ASCII `string` decimal representation.
     */
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

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

/**
 * @title SafeERC20
 */
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

contract Coin98Swap is Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  struct FeeInfo {
       uint256 fee;
       uint256 total;
  }

  mapping(address => FeeInfo) private FeeInfos;

  uint256 unlimit_approve = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

  uint256 fee = 30;
  uint256 private Percent = 10000;

  function configureFee(
       uint256 _fee 
    )
        public
        onlyOwner()
    {
        fee = _fee;
    }

    function calAmountOut(uint256 swap_amount,uint256 amount_out,uint256 amount_in) private pure returns (uint256){
     return swap_amount.mul(amount_out).div(amount_in);
    }

    function calFee(uint256 amount) internal view returns (uint256){
     return amount.div(Percent).mul(fee);
    }

    function callApprove(IERC20 swapToken,address amm_address, uint256 amount) internal{
        if(swapToken.allowance(address(this), amm_address) < amount){
            swapToken.safeApprove(amm_address, unlimit_approve);
        }
   }

   function swapExactTokensForTokens(
        address amm_address,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
   ) public{
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(amm_address);
        uint256 swap_fee = calFee(amountIn);
        IERC20 swapToken = IERC20(path[0]);
        // Get fee from user
        swapToken.safeTransferFrom(msg.sender, address(this), amountIn);
        callApprove(swapToken,amm_address,amountIn);
        uint256 amountSubFee = amountIn.sub(swap_fee);

        swapRouter.swapExactTokensForTokens(amountSubFee,calAmountOut(amountSubFee,amountOutMin,amountIn),path,to,deadline);

        FeeInfo storage feeInfo = FeeInfos[path[0]];

        feeInfo.fee = feeInfo.fee.add(swap_fee);
        feeInfo.total = feeInfo.total.add(1);
   }

    function swapTokensForExactTokens(
        address amm_address,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
   ) public{
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(amm_address);
        uint256 swap_fee = calFee(amountInMax);
        IERC20 swapToken = IERC20(path[0]);
        // Get fee from user
        swapToken.safeTransferFrom(msg.sender, address(this), amountInMax);
        callApprove(swapToken,amm_address,amountInMax);
        uint256 amountSubFee = amountInMax.sub(swap_fee);

        swapRouter.swapExactTokensForTokens(calAmountOut(amountSubFee,amountOut,amountInMax),amountSubFee,path,to,deadline);
        
        FeeInfo storage feeInfo = FeeInfos[path[0]];

        feeInfo.fee = feeInfo.fee.add(swap_fee);
        feeInfo.total = feeInfo.total.add(1);
   }

    function swapExactETHForTokens(
        address amm_address,
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
   ) public payable{
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(amm_address);
        uint256 swap_fee = calFee(msg.value);
        // Get fee from user
        require(msg.value > 0 && msg.value > swap_fee,"C98Swap: Fee not enough");

        uint256 amountSubFee = msg.value.sub(swap_fee);

        swapRouter.swapExactETHForTokens{ value: amountSubFee }(calAmountOut(amountSubFee,amountOutMin,msg.value),path,to,deadline);

        FeeInfo storage feeInfo = FeeInfos[address(0)];
        feeInfo.fee = feeInfo.fee.add(swap_fee);
        feeInfo.total = feeInfo.total.add(1);
   }

    function swapETHForExactTokens(
       address amm_address,
       uint amountOut, 
       address[] calldata path, 
       address to, 
       uint deadline
   ) public payable{
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(amm_address);
        uint256 swap_fee = calFee(msg.value);
        // Get fee from user
        uint256 amountSubFee = msg.value.sub(swap_fee);

        require(msg.value > 0 && msg.value > swap_fee,"C98Swap: Fee not enough");
        swapRouter.swapETHForExactTokens{ value: amountSubFee }(calAmountOut(amountSubFee,amountOut,msg.value),path,to,deadline);

        FeeInfo storage feeInfo = FeeInfos[address(0)];
        feeInfo.fee = feeInfo.fee.add(swap_fee);
        feeInfo.total = feeInfo.total.add(1);
   }

    function swapTokensForExactETH(
       address amm_address,
       uint amountOut, 
       uint amountInMax, 
       address[] calldata path, 
       address to, 
       uint deadline
   ) public{
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(amm_address);
        uint256 swap_fee = calFee(amountInMax);
        IERC20 swapToken = IERC20(path[0]);
        // Get fee from user
        swapToken.safeTransferFrom(msg.sender, address(this), amountInMax);
        callApprove(swapToken,amm_address,amountInMax);
        uint256 amountSubFee = amountInMax.sub(swap_fee);

        swapRouter.swapTokensForExactETH(calAmountOut(amountSubFee,amountOut,amountInMax),amountSubFee,path,to,deadline);
        FeeInfo storage feeInfo = FeeInfos[path[0]];

        feeInfo.fee = feeInfo.fee.add(swap_fee);
        feeInfo.total = feeInfo.total.add(1);
   }

    function swapExactTokensForETH(
       address amm_address,
       uint amountIn, 
       uint amountOutMin, 
       address[] calldata path, 
       address to, 
       uint deadline
   ) public{
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(amm_address);
        uint256 swap_fee = calFee(amountIn);
        IERC20 swapToken = IERC20(path[0]);
        // Get fee from user
        swapToken.safeTransferFrom(msg.sender, address(this), amountIn);
        callApprove(swapToken,amm_address,amountIn);
        uint256 amountSubFee = amountIn.sub(swap_fee);

        swapRouter.swapExactTokensForETH(amountSubFee,calAmountOut(amountSubFee,amountOutMin,amountIn),path,to,deadline);
        FeeInfo storage feeInfo = FeeInfos[path[0]];

        feeInfo.fee = feeInfo.fee.add(swap_fee);
        feeInfo.total = feeInfo.total.add(1);
   }

   function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address amm_address,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
   ) public{
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(amm_address);
        uint256 swap_fee = calFee(amountIn);
        IERC20 swapToken = IERC20(path[0]);
        // Get fee from user
        swapToken.safeTransferFrom(msg.sender, address(this), amountIn);
        callApprove(swapToken,amm_address,amountIn);
        uint256 amountSubFee = amountIn.sub(swap_fee);

        swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountSubFee,calAmountOut(amountSubFee,amountOutMin,amountIn),path,to,deadline);
        FeeInfo storage feeInfo = FeeInfos[path[0]];

        feeInfo.fee = feeInfo.fee.add(swap_fee);
        feeInfo.total = feeInfo.total.add(1);
   }

   function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address amm_address,
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
   ) public payable{
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(amm_address);
        uint256 swap_fee = calFee(msg.value);
        // Get fee from user
        require(msg.value > 0 && msg.value > swap_fee,"C98Swap: Fee not enough");

        uint256 amountSubFee = msg.value.sub(swap_fee);

        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountSubFee }(calAmountOut(amountSubFee,amountOutMin,msg.value),path,to,deadline);

        FeeInfo storage feeInfo = FeeInfos[address(0)];
        feeInfo.fee = feeInfo.fee.add(swap_fee);
        feeInfo.total = feeInfo.total.add(1);
   }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
       address amm_address,
       uint amountIn, 
       uint amountOutMin, 
       address[] calldata path, 
       address to, 
       uint deadline
   ) public{
        IUniswapV2Router02 swapRouter = IUniswapV2Router02(amm_address);
        uint256 swap_fee = calFee(amountIn);
        IERC20 swapToken = IERC20(path[0]);
        // Get fee from user
        swapToken.safeTransferFrom(msg.sender, address(this), amountIn);
        callApprove(swapToken,amm_address,amountIn);
        uint256 amountSubFee = amountIn.sub(swap_fee);

        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amountSubFee,calAmountOut(amountSubFee,amountOutMin,amountIn),path,to,deadline);
        FeeInfo storage feeInfo = FeeInfos[path[0]];

        feeInfo.fee = feeInfo.fee.add(swap_fee);
        feeInfo.total = feeInfo.total.add(1);
   }

  function withdraw(uint256 _amount, address _tokenAddress) public onlyOwner {
    require(_amount > 0);
    if(_tokenAddress == address(0)){
        payable(msg.sender).transfer(_amount);
    }else{
        IERC20 _token = IERC20(_tokenAddress);
        require(_token.balanceOf(address(this)) >= _amount);
        _token.safeTransferFrom(address(this),msg.sender, _amount);
    }
  }
  
  receive() payable external {}
}