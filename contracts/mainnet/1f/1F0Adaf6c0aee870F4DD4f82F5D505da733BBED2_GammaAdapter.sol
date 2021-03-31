/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;


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

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

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

// 
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

// 
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

// 
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

library ProtocolAdapterTypes {
    enum OptionType {Invalid, Put, Call}

    // We have 2 types of purchase methods so far - by contract and by 0x.
    // Contract is simple because it involves just specifying the option terms you want to buy.
    // ZeroEx involves an off-chain API call which prepares a ZeroExOrder object to be passed into the tx.
    enum PurchaseMethod {Invalid, Contract, ZeroEx}

    /**
     * @notice Terms of an options contract
     * @param underlying is the underlying asset of the options. E.g. For ETH $800 CALL, ETH is the underlying.
     * @param strikeAsset is the asset used to denote the asset paid out when exercising the option. E.g. For ETH $800 CALL, USDC is the underlying.
     * @param collateralAsset is the asset used to collateralize a short position for the option.
     * @param expiry is the expiry of the option contract. Users can only exercise after expiry in Europeans.
     * @param strikePrice is the strike price of an optio contract. E.g. For ETH $800 CALL, 800*10**18 is the USDC.
     * @param optionType is the type of option, can only be OptionType.Call or OptionType.Put
     * @param paymentToken is the token used to purchase the option. E.g. Buy UNI/USDC CALL with WETH as the paymentToken.
     */
    struct OptionTerms {
        address underlying;
        address strikeAsset;
        address collateralAsset;
        uint256 expiry;
        uint256 strikePrice;
        ProtocolAdapterTypes.OptionType optionType;
        address paymentToken;
    }

    /**
     * @notice 0x order for purchasing otokens
     * @param exchangeAddress [deprecated] is the address we call to conduct a 0x trade. Slither flagged this as a potential vulnerability so we hardcoded it.
     * @param buyTokenAddress is the otoken address
     * @param sellTokenAddress is the token used to purchase USDC. This is USDC most of the time.
     * @param allowanceTarget is the address the adapter needs to provide sellToken allowance to so the swap happens
     * @param protocolFee is the fee paid (in ETH) when conducting the trade
     * @param makerAssetAmount is the buyToken amount
     * @param takerAssetAmount is the sellToken amount
     * @param swapData is the encoded msg.data passed by the 0x api response
     */
    struct ZeroExOrder {
        address exchangeAddress;
        address buyTokenAddress;
        address sellTokenAddress;
        address allowanceTarget;
        uint256 protocolFee;
        uint256 makerAssetAmount;
        uint256 takerAssetAmount;
        bytes swapData;
    }
}

interface IProtocolAdapter {
    /**
     * @notice Emitted when a new option contract is purchased
     */
    event Purchased(
        address indexed caller,
        string indexed protocolName,
        address indexed underlying,
        uint256 amount,
        uint256 optionID
    );

    /**
     * @notice Emitted when an option contract is exercised
     */
    event Exercised(
        address indexed caller,
        address indexed options,
        uint256 indexed optionID,
        uint256 amount,
        uint256 exerciseProfit
    );

    /**
     * @notice Name of the adapter. E.g. "HEGIC", "OPYN_V1". Used as index key for adapter addresses
     */
    function protocolName() external pure returns (string memory);

    /**
     * @notice Boolean flag to indicate whether to use option IDs or not.
     * Fungible protocols normally use tokens to represent option contracts.
     */
    function nonFungible() external pure returns (bool);

    /**
     * @notice Returns the purchase method used to purchase options
     */
    function purchaseMethod()
        external
        pure
        returns (ProtocolAdapterTypes.PurchaseMethod);

    /**
     * @notice Check if an options contract exist based on the passed parameters.
     * @param optionTerms is the terms of the option contract
     */
    function optionsExist(ProtocolAdapterTypes.OptionTerms calldata optionTerms)
        external
        view
        returns (bool);

    /**
     * @notice Get the options contract's address based on the passed parameters
     * @param optionTerms is the terms of the option contract
     */
    function getOptionsAddress(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms
    ) external view returns (address);

    /**
     * @notice Gets the premium to buy `purchaseAmount` of the option contract in ETH terms.
     * @param optionTerms is the terms of the option contract
     * @param purchaseAmount is the number of options purchased
     */
    function premium(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        uint256 purchaseAmount
    ) external view returns (uint256 cost);

    /**
     * @notice Amount of profit made from exercising an option contract (current price - strike price). 0 if exercising out-the-money.
     * @param options is the address of the options contract
     * @param optionID is the ID of the option position in non fungible protocols like Hegic.
     * @param amount is the amount of tokens or options contract to exercise. Only relevant for fungle protocols like Opyn
     */
    function exerciseProfit(
        address options,
        uint256 optionID,
        uint256 amount
    ) external view returns (uint256 profit);

    function canExercise(
        address options,
        uint256 optionID,
        uint256 amount
    ) external view returns (bool);

    /**
     * @notice Purchases the options contract.
     * @param optionTerms is the terms of the option contract
     * @param amount is the purchase amount in Wad units (10**18)
     */
    function purchase(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        uint256 amount,
        uint256 maxCost
    ) external payable returns (uint256 optionID);

    /**
     * @notice Exercises the options contract.
     * @param options is the address of the options contract
     * @param optionID is the ID of the option position in non fungible protocols like Hegic.
     * @param amount is the amount of tokens or options contract to exercise. Only relevant for fungle protocols like Opyn
     * @param recipient is the account that receives the exercised profits. This is needed since the adapter holds all the positions and the msg.sender is an instrument contract.
     */
    function exercise(
        address options,
        uint256 optionID,
        uint256 amount,
        address recipient
    ) external payable;

    /**
     * @notice Opens a short position for a given `optionTerms`.
     * @param optionTerms is the terms of the option contract
     * @param amount is the short position amount
     */
    function createShort(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        uint256 amount
    ) external returns (uint256);

    /**
     * @notice Closes an existing short position. In the future, we may want to open this up to specifying a particular short position to close.
     */
    function closeShort() external returns (uint256);
}

library GammaTypes {
    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }
}

interface OtokenInterface {
    function addressBook() external view returns (address);

    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

interface IOtokenFactory {
    event OtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );

    function oTokens(uint256 index) external returns (address);

    function getOtokensLength() external view returns (uint256);

    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address);
}

interface IController {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    function getPayout(address _otoken, uint256 _amount)
        external
        view
        returns (uint256);

    function operate(ActionArgs[] calldata _actions) external;

    function getAccountVaultCounter(address owner)
        external
        view
        returns (uint256);

    function oracle() external view returns (address);

    function getVault(address _owner, uint256 _vaultId)
        external
        view
        returns (GammaTypes.Vault memory);

    function getProceed(address _owner, uint256 _vaultId)
        external
        view
        returns (uint256);

    function isSettlementAllowed(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) external view returns (bool);
}

interface OracleInterface {
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp)
        external
        view
        returns (bool);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp)
        external
        view
        returns (bool);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp)
        external
        view
        returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer)
        external
        view
        returns (uint256);

    function getPricerDisputePeriod(address _pricer)
        external
        view
        returns (uint256);

    // Non-view function

    function setAssetPricer(address _asset, address _pricer) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setDisputer(address _disputer) external;
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

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

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// 
contract GammaAdapter is IProtocolAdapter, DSMath {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // gammaController is the top-level contract in Gamma protocol which allows users to perform multiple actions on their vaults and positions https://github.com/opynfinance/GammaProtocol/blob/master/contracts/Controller.sol
    address public immutable gammaController;

    // oTokenFactory is the factory contract used to spawn otokens. Used to lookup otokens.
    address public immutable oTokenFactory;

    // _swapWindow is the number of seconds in which a Uniswap swap is valid from block.timestamp.
    uint256 private constant SWAP_WINDOW = 900;

    string private constant _name = "OPYN_GAMMA";
    bool private constant _nonFungible = false;

    // https://github.com/opynfinance/GammaProtocol/blob/master/contracts/Otoken.sol#L70
    uint256 private constant OTOKEN_DECIMALS = 10**8;

    uint256 private constant SLIPPAGE_TOLERANCE = 0.75 ether;

    // MARGIN_POOL is Gamma protocol's collateral pool. Needed to approve collateral.safeTransferFrom for minting otokens. https://github.com/opynfinance/GammaProtocol/blob/master/contracts/MarginPool.sol
    address public immutable MARGIN_POOL;

    // USDCETHPriceFeed is the USDC/ETH Chainlink price feed used to perform swaps, as an alternative to getAmountsIn
    AggregatorV3Interface public immutable USDCETHPriceFeed;

    // UNISWAP_ROUTER is Uniswap's periphery contract for conducting trades. Using this contract is gas inefficient and should only used for convenience i.e. admin functions
    address public immutable UNISWAP_ROUTER;

    // WETH9 contract
    address public immutable WETH;

    // USDC is the strike asset in Gamma Protocol
    address public immutable USDC;

    // 0x proxy for performing buys
    address public immutable ZERO_EX_EXCHANGE_V3;

    /**
     * @notice Constructor for the GammaAdapter which initializes a few immutable variables to be used by instrument contracts.
     * @param _oTokenFactory is the Gamma protocol factory contract which spawns otokens https://github.com/opynfinance/GammaProtocol/blob/master/contracts/OtokenFactory.sol
     * @param _gammaController is a top-level contract which allows users to perform multiple actions in the Gamma protocol https://github.com/opynfinance/GammaProtocol/blob/master/contracts/Controller.sol
     */
    constructor(
        address _oTokenFactory,
        address _gammaController,
        address _marginPool,
        address _usdcEthPriceFeed,
        address _uniswapRouter,
        address _weth,
        address _usdc,
        address _zeroExExchange
    ) {
        require(_oTokenFactory != address(0), "!_oTokenFactory");
        require(_gammaController != address(0), "!_gammaController");
        require(_marginPool != address(0), "!_marginPool");
        require(_usdcEthPriceFeed != address(0), "!_usdcEthPriceFeed");
        require(_uniswapRouter != address(0), "!_uniswapRouter");
        require(_weth != address(0), "!_weth");
        require(_usdc != address(0), "!_usdc");
        require(_zeroExExchange != address(0), "!_zeroExExchange");

        oTokenFactory = _oTokenFactory;
        gammaController = _gammaController;
        MARGIN_POOL = _marginPool;
        USDCETHPriceFeed = AggregatorV3Interface(_usdcEthPriceFeed);
        UNISWAP_ROUTER = _uniswapRouter;
        WETH = _weth;
        USDC = _usdc;
        ZERO_EX_EXCHANGE_V3 = _zeroExExchange;
    }

    receive() external payable {}

    function protocolName() external pure override returns (string memory) {
        return _name;
    }

    function nonFungible() external pure override returns (bool) {
        return _nonFungible;
    }

    function purchaseMethod()
        external
        pure
        override
        returns (ProtocolAdapterTypes.PurchaseMethod)
    {
        return ProtocolAdapterTypes.PurchaseMethod.ZeroEx;
    }

    /**
     * @notice Check if an options contract exist based on the passed parameters.
     * @param optionTerms is the terms of the option contract
     */
    function optionsExist(ProtocolAdapterTypes.OptionTerms calldata optionTerms)
        external
        view
        override
        returns (bool)
    {
        return lookupOToken(optionTerms) != address(0);
    }

    /**
     * @notice Get the options contract's address based on the passed parameters
     * @param optionTerms is the terms of the option contract
     */
    function getOptionsAddress(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms
    ) external view override returns (address) {
        return lookupOToken(optionTerms);
    }

    /**
     * @notice Gets the premium to buy `purchaseAmount` of the option contract in ETH terms.
     */
    function premium(ProtocolAdapterTypes.OptionTerms calldata, uint256)
        external
        pure
        override
        returns (uint256 cost)
    {
        return 0;
    }

    /**
     * @notice Amount of profit made from exercising an option contract abs(current price - strike price). 0 if exercising out-the-money.
     * @param options is the address of the options contract
     * @param amount is the amount of tokens or options contract to exercise. Only relevant for fungle protocols like Opyn
     */
    function exerciseProfit(
        address options,
        uint256,
        uint256 amount
    ) public view override returns (uint256 profit) {
        IController controller = IController(gammaController);
        OracleInterface oracle = OracleInterface(controller.oracle());
        OtokenInterface otoken = OtokenInterface(options);

        uint256 spotPrice = oracle.getPrice(otoken.underlyingAsset());
        uint256 strikePrice = otoken.strikePrice();
        bool isPut = otoken.isPut();

        if (!isPut && spotPrice <= strikePrice) {
            return 0;
        } else if (isPut && spotPrice >= strikePrice) {
            return 0;
        }

        return controller.getPayout(options, amount.div(10**10));
    }

    /**
     * @notice Helper function that returns true if the option can be exercised now.
     * @param options is the address of the otoken
     * @param amount is amount of otokens to exercise
     */
    function canExercise(
        address options,
        uint256,
        uint256 amount
    ) public view override returns (bool) {
        OtokenInterface otoken = OtokenInterface(options);

        address underlying = otoken.underlyingAsset();
        uint256 expiry = otoken.expiryTimestamp();

        if (!isSettlementAllowed(underlying, expiry)) {
            return false;
        }
        // use `0` as the optionID because it doesn't do anything for exerciseProfit
        if (exerciseProfit(options, 0, amount) > 0) {
            return true;
        }
        return false;
    }

    /**
     * @notice Stubbed out for conforming to the IProtocolAdapter interface.
     */
    function purchase(
        ProtocolAdapterTypes.OptionTerms calldata,
        uint256,
        uint256
    ) external payable override returns (uint256) {}

    /**
     * @notice Purchases otokens using a 0x order struct
     * It is the obligation of the delegate-calling contract to return the remaining
     * msg.value back to the user.
     * @param optionTerms is the terms of the option contract
     * @param zeroExOrder is the 0x order struct constructed using the 0x API response passed by the frontend.
     */
    function purchaseWithZeroEx(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        ProtocolAdapterTypes.ZeroExOrder calldata zeroExOrder
    ) external payable {
        require(
            msg.value >= zeroExOrder.protocolFee,
            "Value cannot cover protocolFee"
        );
        require(
            zeroExOrder.sellTokenAddress == USDC,
            "Sell token has to be USDC"
        );

        IUniswapV2Router02 router = IUniswapV2Router02(UNISWAP_ROUTER);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = zeroExOrder.sellTokenAddress;

        (, int256 latestPrice, , , ) = USDCETHPriceFeed.latestRoundData();

        // Because we guard that zeroExOrder.sellTokenAddress == USDC
        // We can assume that the decimals == 6
        uint256 soldETH =
            zeroExOrder.takerAssetAmount.mul(uint256(latestPrice)).div(
                10**assetDecimals(zeroExOrder.sellTokenAddress)
            );

        router.swapETHForExactTokens{value: soldETH}(
            zeroExOrder.takerAssetAmount,
            path,
            address(this),
            block.timestamp + SWAP_WINDOW
        );

        require(
            IERC20(zeroExOrder.sellTokenAddress).balanceOf(address(this)) >=
                zeroExOrder.takerAssetAmount,
            "Not enough takerAsset balance"
        );

        // double approve to fix non-compliant ERC20s
        IERC20(zeroExOrder.sellTokenAddress).safeApprove(
            zeroExOrder.allowanceTarget,
            0
        );
        IERC20(zeroExOrder.sellTokenAddress).safeApprove(
            zeroExOrder.allowanceTarget,
            zeroExOrder.takerAssetAmount
        );

        require(
            address(this).balance >= zeroExOrder.protocolFee,
            "Not enough balance for protocol fee"
        );

        (bool success, ) =
            ZERO_EX_EXCHANGE_V3.call{value: zeroExOrder.protocolFee}(
                zeroExOrder.swapData
            );

        require(success, "0x swap failed");

        require(
            IERC20(zeroExOrder.buyTokenAddress).balanceOf(address(this)) >=
                zeroExOrder.makerAssetAmount,
            "Not enough buyToken balance"
        );

        emit Purchased(
            msg.sender,
            _name,
            optionTerms.underlying,
            soldETH.add(zeroExOrder.protocolFee),
            0
        );
    }

    /**
     * @notice Exercises the options contract.
     * @param options is the address of the options contract
     * @param amount is the amount of tokens or options contract to exercise. Only relevant for fungle protocols like Opyn
     * @param recipient is the account that receives the exercised profits. This is needed since the adapter holds all the positions and the msg.sender is an instrument contract.
     */
    function exercise(
        address options,
        uint256,
        uint256 amount,
        address recipient
    ) public payable override {
        OtokenInterface otoken = OtokenInterface(options);

        require(
            block.timestamp >= otoken.expiryTimestamp(),
            "oToken not expired yet"
        );

        // Since we accept all amounts in 10**18, we need to normalize it down to the decimals otokens use (10**8)
        uint256 scaledAmount = amount.div(10**10);

        // use `0` as the optionID because it doesn't do anything for exerciseProfit
        uint256 profit = exerciseProfit(options, 0, amount);

        require(profit > 0, "Not profitable to exercise");

        IController.ActionArgs memory action =
            IController.ActionArgs(
                IController.ActionType.Redeem,
                address(this), // owner
                address(this), // receiver -  we need this contract to receive so we can swap at the end
                options, // asset, otoken
                0, // vaultId
                scaledAmount,
                0, //index
                "" //data
            );

        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](1);
        actions[0] = action;

        IController(gammaController).operate(actions);

        uint256 profitInUnderlying =
            swapExercisedProfitsToUnderlying(options, profit, recipient);

        emit Exercised(msg.sender, options, 0, amount, profitInUnderlying);
    }

    /**
     * @notice Swaps the exercised profit (originally in the collateral token) into the `underlying` token.
     *         This simplifies the payout of an option. Put options pay out in USDC, so we swap USDC back
     *         into WETH and transfer it to the recipient.
     * @param otokenAddress is the otoken's address
     * @param profitInCollateral is the profit after exercising denominated in the collateral - this could be a token with different decimals
     * @param recipient is the recipient of the underlying tokens after the swap
     */
    function swapExercisedProfitsToUnderlying(
        address otokenAddress,
        uint256 profitInCollateral,
        address recipient
    ) internal returns (uint256 profitInUnderlying) {
        OtokenInterface otoken = OtokenInterface(otokenAddress);
        address collateral = otoken.collateralAsset();
        IERC20 collateralToken = IERC20(collateral);

        require(
            collateralToken.balanceOf(address(this)) >= profitInCollateral,
            "Not enough collateral from exercising"
        );

        IUniswapV2Router02 router = IUniswapV2Router02(UNISWAP_ROUTER);

        IWETH weth = IWETH(WETH);

        if (collateral == address(weth)) {
            profitInUnderlying = profitInCollateral;
            weth.withdraw(profitInCollateral);
            (bool success, ) = recipient.call{value: profitInCollateral}("");
            require(success, "Failed to transfer exercise profit");
        } else {
            // just guard against anything that's not USDC
            // we will revisit opening up other collateral types for puts
            // when they get added
            require(collateral == USDC, "!USDC");

            address[] memory path = new address[](2);
            path[0] = collateral;
            path[1] = address(weth);

            (, int256 latestPrice, , , ) = USDCETHPriceFeed.latestRoundData();

            profitInUnderlying = wdiv(profitInCollateral, uint256(latestPrice))
                .mul(10**assetDecimals(collateral));

            require(profitInUnderlying > 0, "Swap is unprofitable");

            collateralToken.safeApprove(UNISWAP_ROUTER, 0);
            collateralToken.safeApprove(UNISWAP_ROUTER, profitInCollateral);

            uint256[] memory amountsOut =
                router.swapExactTokensForETH(
                    profitInCollateral,
                    wmul(profitInUnderlying, SLIPPAGE_TOLERANCE),
                    path,
                    recipient,
                    block.timestamp + SWAP_WINDOW
                );

            profitInUnderlying = amountsOut[1];
        }
    }

    /**
     * @notice Creates a short otoken position by opening a vault, depositing collateral and minting otokens.
     * The sale of otokens is left to the caller contract to perform.
     * @param optionTerms is the terms of the option contract
     * @param depositAmount is the amount deposited to open the vault. This amount will determine how much otokens to mint.
     */
    function createShort(
        ProtocolAdapterTypes.OptionTerms calldata optionTerms,
        uint256 depositAmount
    ) external override returns (uint256) {
        IController controller = IController(gammaController);
        uint256 newVaultID =
            (controller.getAccountVaultCounter(address(this))).add(1);

        address oToken = lookupOToken(optionTerms);
        require(oToken != address(0), "Invalid oToken");

        address collateralAsset = optionTerms.collateralAsset;
        if (collateralAsset == address(0)) {
            collateralAsset = WETH;
        }
        IERC20 collateralToken = IERC20(collateralAsset);

        uint256 collateralDecimals = assetDecimals(collateralAsset);
        uint256 mintAmount;

        if (optionTerms.optionType == ProtocolAdapterTypes.OptionType.Call) {
            mintAmount = depositAmount;
            if (collateralDecimals >= 8) {
                uint256 scaleBy = 10**(collateralDecimals - 8); // oTokens have 8 decimals
                mintAmount = depositAmount.div(scaleBy); // scale down from 10**18 to 10**8
                require(
                    mintAmount > 0,
                    "Must deposit more than 10**8 collateral"
                );
            }
        } else {
            mintAmount = wdiv(depositAmount, optionTerms.strikePrice)
                .mul(OTOKEN_DECIMALS)
                .div(10**collateralDecimals);
        }

        // double approve to fix non-compliant ERC20s
        collateralToken.safeApprove(MARGIN_POOL, 0);
        collateralToken.safeApprove(MARGIN_POOL, depositAmount);

        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](3);

        actions[0] = IController.ActionArgs(
            IController.ActionType.OpenVault,
            address(this), // owner
            address(this), // receiver -  we need this contract to receive so we can swap at the end
            address(0), // asset, otoken
            newVaultID, // vaultId
            0, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.DepositCollateral,
            address(this), // owner
            address(this), // address to transfer from
            collateralAsset, // deposited asset
            newVaultID, // vaultId
            depositAmount, // amount
            0, //index
            "" //data
        );

        actions[2] = IController.ActionArgs(
            IController.ActionType.MintShortOption,
            address(this), // owner
            address(this), // address to transfer to
            oToken, // deposited asset
            newVaultID, // vaultId
            mintAmount, // amount
            0, //index
            "" //data
        );

        controller.operate(actions);

        return mintAmount;
    }

    /**
     * @notice Close the existing short otoken position. Currently this implementation is simple.
     * It closes the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time. Since calling `closeShort` deletes vaults,
     * this assumption should hold.
     */
    function closeShort() external override returns (uint256) {
        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.getAccountVaultCounter(address(this));

        GammaTypes.Vault memory vault =
            controller.getVault(address(this), vaultID);

        require(vault.shortOtokens.length > 0, "No active short");

        IERC20 collateralToken = IERC20(vault.collateralAssets[0]);
        OtokenInterface otoken = OtokenInterface(vault.shortOtokens[0]);

        bool settlementAllowed =
            isSettlementAllowed(
                otoken.underlyingAsset(),
                otoken.expiryTimestamp()
            );

        uint256 startCollateralBalance =
            collateralToken.balanceOf(address(this));

        IController.ActionArgs[] memory actions;

        // If it is after expiry, we need to settle the short position using the normal way
        // Delete the vault and withdraw all remaining collateral from the vault
        //
        // If it is before expiry, we need to burn otokens in order to withdraw collateral from the vault
        if (settlementAllowed) {
            actions = new IController.ActionArgs[](1);

            actions[0] = IController.ActionArgs(
                IController.ActionType.SettleVault,
                address(this), // owner
                address(this), // address to transfer to
                address(0), // not used
                vaultID, // vaultId
                0, // not used
                0, // not used
                "" // not used
            );

            controller.operate(actions);
        } else {
            // Burning otokens given by vault.shortAmounts[0] (closing the entire short position),
            // then withdrawing all the collateral from the vault
            actions = new IController.ActionArgs[](2);

            actions[0] = IController.ActionArgs(
                IController.ActionType.BurnShortOption,
                address(this), // owner
                address(this), // address to transfer to
                address(otoken), // otoken address
                vaultID, // vaultId
                vault.shortAmounts[0], // amount
                0, //index
                "" //data
            );

            actions[1] = IController.ActionArgs(
                IController.ActionType.WithdrawCollateral,
                address(this), // owner
                address(this), // address to transfer to
                address(collateralToken), // withdrawn asset
                vaultID, // vaultId
                vault.collateralAmounts[0], // amount
                0, //index
                "" //data
            );

            controller.operate(actions);
        }

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        return endCollateralBalance.sub(startCollateralBalance);
    }

    /**
     * @notice Gas-optimized getter for checking if settlement is allowed. Looks up from the oracles with asset address and expiry
     * @param underlying is the address of the underlying for an otoken
     * @param expiry is the timestamp of the otoken's expiry
     */
    function isSettlementAllowed(address underlying, uint256 expiry)
        private
        view
        returns (bool)
    {
        IController controller = IController(gammaController);
        OracleInterface oracle = OracleInterface(controller.oracle());

        bool underlyingFinalized =
            oracle.isDisputePeriodOver(underlying, expiry);

        bool strikeFinalized = oracle.isDisputePeriodOver(USDC, expiry);

        // We can avoid checking the dispute period for the collateral for now
        // Because the collateral is either the underlying or USDC at this point
        // We do not have, for example, ETH-collateralized UNI otoken vaults
        // bool collateralFinalized = oracle.isDisputePeriodOver(isPut ? USDC : underlying, expiry);

        return underlyingFinalized && strikeFinalized;
    }

    /**
     * @notice Helper function to get the decimals of an asset. Will just hardcode for the time being.
     * @param asset is the token which we want to know the decimals
     */
    function assetDecimals(address asset) private view returns (uint256) {
        // USDC
        if (asset == USDC) {
            return 6;
        }
        return 18;
    }

    /**
     * @notice Function to lookup oToken addresses. oToken addresses are keyed by an ABI-encoded byte string
     * @param optionTerms is the terms of the option contract
     */
    function lookupOToken(ProtocolAdapterTypes.OptionTerms memory optionTerms)
        public
        view
        returns (address oToken)
    {
        IOtokenFactory factory = IOtokenFactory(oTokenFactory);

        bool isPut =
            optionTerms.optionType == ProtocolAdapterTypes.OptionType.Put;
        address underlying = optionTerms.underlying;

        /**
         * In many instances, we just use 0x0 to indicate ETH as the underlying asset.
         * We need to unify usage of 0x0 as WETH instead.
         */
        if (optionTerms.underlying == address(0)) {
            underlying = WETH;
        }

        // Put otokens have USDC as the backing collateral
        // so we can ignore the collateral asset passed in option terms
        address collateralAsset;
        if (isPut) {
            collateralAsset = USDC;
        } else {
            collateralAsset = underlying;
        }

        oToken = factory.getOtoken(
            underlying,
            optionTerms.strikeAsset,
            collateralAsset,
            optionTerms.strikePrice.div(10**10),
            optionTerms.expiry,
            isPut
        );
    }
}