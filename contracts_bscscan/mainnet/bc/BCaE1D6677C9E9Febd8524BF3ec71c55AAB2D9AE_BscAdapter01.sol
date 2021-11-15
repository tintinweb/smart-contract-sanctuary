// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol



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

// File: openzeppelin-solidity/contracts/utils/Address.sol



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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol



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

// File: original_contracts/ITokenTransferProxy.sol

pragma solidity 0.7.5;


interface ITokenTransferProxy {

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        external;
}

// File: original_contracts/lib/Utils.sol

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;





interface IERC20Permit {
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant ETH_ADDRESS = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );
    
    uint256 constant MAX_UINT = type(uint256).max;

    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;

    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
    }

    struct BuyData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address payable beneficiary;
        Utils.BuyAdapter[] adapters;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee;
        Route[] route;
    }

    struct Route {
        uint256 index;//Adapter at which index needs to be used
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;//Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    struct BuyAdapter {
        address payable adapter;
        bytes payload;
        uint256 networkFee;
        BuyRoute[] route;
    }

    struct BuyRoute {
        uint256 index;//Adapter at which index needs to be used
        address targetExchange;
        uint256 fromAmount;
        uint256 toAmount;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    function ethAddress() internal pure returns (address) {return ETH_ADDRESS;}

    function maxUint() internal pure returns (uint256) {return MAX_UINT;}

    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint allowance = _token.allowance(address(this), addressToApprove);

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    )
    internal
    {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{value: amount, gas: 10000}("");
                require(result, "Failed to transfer Ether");
            }
            else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }

    }

    function tokenBalance(
        address token,
        address account
    )
    internal
    view
    returns (uint256)
    {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function permit(
        address token,
        bytes memory permit
    )
        internal
    {
        if (permit.length == 32 * 7) {
            (bool success,) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            require(success, "Permit failed");
        }
    }

}

// File: original_contracts/adapters/IAdapter.sol

pragma solidity 0.7.5;



interface IAdapter {

    /**
    * @dev Certain adapters needs to be initialized.
    * This method will be called from Augustus
    */
    function initialize(bytes calldata data) external;

    /**
   * @dev The function which performs the swap on an exchange.
   * @param fromToken Address of the source token
   * @param toToken Address of the destination token
   * @param fromAmount Amount of source tokens to be swapped
   * @param networkFee Network fee to be used in this router
   * @param route Route to be followed
   */
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 networkFee,
        Utils.Route[] calldata route
    )
        external
        payable;
}

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: original_contracts/lib/uniswapv2/IUniswapV2Pair.sol

pragma solidity 0.7.5;

interface IUniswapV2Pair {

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    )
        external;
}

// File: original_contracts/lib/uniswapv2/UniswapV2Lib.sol

pragma solidity >=0.5.0;




library UniswapV2Lib {
    using SafeMath for uint256;

    function checkAndConvertETHToWETH(address token, address weth) internal pure returns(address) {

        if(token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            return weth;
        }
        return token;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {

        return(tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA));
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 initCode
    )
        internal
        pure
        returns (address)
    {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        return(address(uint(keccak256(abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            initCode // init code hash
        )))));
    }

    function getReservesByPair(
        address pair,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee,
        uint256 feeFactor
    )
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "UniswapV3Library: INSUFFICIENT_INPUT_AMOUNT");
        uint256 amountInWithFee = amountIn.mul(fee);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(feeFactor).add(amountInWithFee);
        amountOut = uint256(numerator / denominator);
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountInAndPair(
        address factory,
        uint amountOut,
        address tokenA,
        address tokenB,
        bytes32 initCode,
        uint256 fee,
        uint256 feeFactor,
        address weth
    )
        internal
        view
        returns (uint256 amountIn, address pair)
    {
        tokenA = checkAndConvertETHToWETH(tokenA, weth);
        tokenB = checkAndConvertETHToWETH(tokenB, weth);

        pair = pairFor(factory, tokenA, tokenB, initCode);
        (uint256 reserveIn, uint256 reserveOut) = getReservesByPair(pair, tokenA, tokenB);
        require(amountOut > 0, "UniswapV3Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveOut > amountOut, "UniswapV3Library: reserveOut should be greater than amountOut");
        uint numerator = reserveIn.mul(amountOut).mul(feeFactor);
        uint denominator = reserveOut.sub(amountOut).mul(fee);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountOutByPair(
        uint256 amountIn,
        address pair,
        address tokenA,
        address tokenB,
        uint256 fee,
        uint256 feeFactor
    )
        internal
        view
        returns(uint256 amountOut)
    {
        (uint256 reserveIn, uint256 reserveOut) = getReservesByPair(pair, tokenA, tokenB);
        return (getAmountOut(amountIn, reserveIn, reserveOut, fee, feeFactor));
    }
}

// File: original_contracts/lib/weth/IWETH.sol

pragma solidity 0.7.5;



abstract contract IWETH is IERC20 {
    function deposit() external virtual payable;
    function withdraw(uint256 amount) external virtual;
}

// File: original_contracts/lib/WethProvider.sol

pragma solidity 0.7.5;


contract WethProvider {
    address public immutable WETH;

    constructor(address weth) public {
        WETH = weth;
    }
}

// File: original_contracts/lib/uniswapv2/UniswapV2.sol

pragma solidity 0.7.5;








abstract contract UniswapV2 is WethProvider {
    using SafeMath for uint256;

    address immutable public factory;
    bytes32 immutable public initCode;
    uint256 immutable public fee;
    uint256 immutable public feeFactor;

    struct UniswapV2Data {
        address[] path;
    }

    struct UniswapV2ForkData {
        address[] path;
        uint256 fee;
        uint256 feeFactor;
        address factory;
        bytes32 initCode;
    }

    constructor(
        address _factory,
        bytes32 _initCode,
        uint256 _fee,
        uint256 _feeFactor
    )
    {
       factory = _factory;
       initCode = _initCode;
       fee = _fee;
       feeFactor = _feeFactor;
    }

    function swapOnUniswap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    )
        internal
    {

        UniswapV2Data memory data = abi.decode(payload, (UniswapV2Data));
        _swapOnUniswapV2(
            fromAmount,
            data.path
        );

    }

    function buyOnUniswap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        bytes calldata payload
    )
        internal
    {

        UniswapV2Data memory data = abi.decode(payload, (UniswapV2Data));

        _buyOnUniswapV2(
            fromAmount,
            toAmount,
            fee,
            feeFactor,
            factory,
            initCode,
            data.path
        );
    }

    function swapOnUniswapFork(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    )
        internal
    {

        UniswapV2ForkData memory data = abi.decode(payload, (UniswapV2ForkData));
        _swapOnUniswapV2Fork(
            fromAmount,
            data.path,
            data
        );

    }

    function buyOnUniswapFork(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        bytes calldata payload
    )
        internal
    {

        UniswapV2ForkData memory data = abi.decode(payload, (UniswapV2ForkData));

        _buyOnUniswapV2(
            fromAmount,
            toAmount,
            data.fee,
            data.feeFactor,
            data.factory,
            data.initCode,
            data.path
        );
    }

    function _buyOnUniswapV2(
        uint256 amountInMax,
        uint256 amountOut,
        uint256 _fee,
        uint256 _feeFactor,
        address _factory,
        bytes32 _initCode,
        address[] memory path
    )
        private
        returns (uint256 tokensSold)
    {

        require(path.length > 1, "More than 1 token required");
        bool tokensBoughtEth;
        uint8 length = uint8(path.length);

        uint256[] memory amounts = new uint256[](length);
        address[] memory pairs = new address[](length - 1);

        amounts[length - 1] = amountOut;

        for (uint8 i = length - 1; i > 0; i--) {
            (amounts[i - 1], pairs[i - 1]) = UniswapV2Lib.getAmountInAndPair(
                _factory,
                amounts[i],
                path[i-1],
                path[i],
                _initCode,
                _fee,
                _feeFactor,
                WETH
            );
        }

        tokensSold = amounts[0];
        require(tokensSold <= amountInMax, "UniswapV3Router: INSUFFICIENT_INPUT_AMOUNT");

        for(uint8 i = 0; i < length - 1; i++) {
            address tokenSold = path[i];
            address tokenBought = path[i+1];

            if (i == length - 2) {
                if (tokenBought == Utils.ethAddress()) {
                    tokenBought = WETH;
                    tokensBoughtEth = true;
                }
            }
            if (i == 0) {
                if (tokenSold == Utils.ethAddress()) {
                    tokenSold = WETH;
                    IWETH(WETH).deposit{value: tokensSold}();
                    assert(IWETH(WETH).transfer(pairs[i], tokensSold));
                }
                else {
                    TransferHelper.safeTransfer(
                        tokenSold, pairs[i], tokensSold
                    );
                }
            }

            address receiver;

            if (i == length - 2) {

                receiver = address(this);

            }
            else {
                receiver = pairs[i+1];
            }

            (address token0,) = UniswapV2Lib.sortTokens(tokenSold, tokenBought);
            (uint256 amount0Out, uint256 amount1Out) = tokenSold == token0 ? (uint256(0), amounts[i+1]) : (amounts[i+1], uint256(0));
            IUniswapV2Pair(pairs[i]).swap(
                amount0Out, amount1Out, receiver, new bytes(0)
            );

        }
        if (tokensBoughtEth) {
            IWETH(WETH).withdraw(amountOut);
        }
    }

    function _swapOnUniswapV2Fork(
        uint256 fromAmount,
        address[] memory path,
        UniswapV2ForkData memory data
    )
        private
        returns(uint256 tokensBought)
    {
        require(path.length > 1, "More than 1 token required");
        uint8 pairs = uint8(path.length - 1);
        bool tokensBoughtEth;
        tokensBought = fromAmount;
        address receiver;

        for(uint8 i = 0; i < pairs; i++) {
            address tokenSold = path[i];
            address tokenBought = path[i+1];

            address currentPair = receiver;
            if (i == pairs - 1) {
                if (tokenBought == Utils.ethAddress()) {
                    tokenBought = WETH;
                    tokensBoughtEth = true;
                }
            }
            if (i == 0) {
                if (tokenSold == Utils.ethAddress()) {
                    tokenSold = WETH;
                    currentPair = UniswapV2Lib.pairFor(data.factory, tokenSold, tokenBought, data.initCode);
                    IWETH(WETH).deposit{value: fromAmount}();
                    assert(IWETH(WETH).transfer(currentPair, fromAmount));
                }
                else {
                    currentPair = UniswapV2Lib.pairFor(data.factory, tokenSold, tokenBought, data.initCode);
                    TransferHelper.safeTransfer(
                        tokenSold, currentPair, fromAmount
                    );
                }
            }

            tokensBought = UniswapV2Lib.getAmountOutByPair(tokensBought, currentPair, tokenSold, tokenBought, data.fee, data.feeFactor);

            if ((i + 1) == pairs) {
                receiver = address(this);
            }
            else {
                receiver = UniswapV2Lib.pairFor(data.factory, tokenBought, path[i+2] == Utils.ethAddress() ? WETH : path[i+2], data.initCode);
            }

            (address token0,) = UniswapV2Lib.sortTokens(tokenSold, tokenBought);
            (uint256 amount0Out, uint256 amount1Out) = tokenSold == token0 ? (uint256(0), tokensBought) : (tokensBought, uint256(0));
            IUniswapV2Pair(currentPair).swap(
                amount0Out, amount1Out, receiver, new bytes(0)
            );

        }

        if (tokensBoughtEth) {
            IWETH(WETH).withdraw(tokensBought);
        }
    }

    function _swapOnUniswapV2(
        uint256 fromAmount,
        address[] memory path
    )
        private
        returns(uint256 tokensBought)
    {
        require(path.length > 1, "More than 1 token required");
        uint8 pairs = uint8(path.length - 1);
        bool tokensBoughtEth;
        tokensBought = fromAmount;
        address receiver;

        for(uint8 i = 0; i < pairs; i++) {
            address tokenSold = path[i];
            address tokenBought = path[i+1];

            address currentPair = receiver;
            if (i == pairs - 1) {
                if (tokenBought == Utils.ethAddress()) {
                    tokenBought = WETH;
                    tokensBoughtEth = true;
                }
            }
            if (i == 0) {
                if (tokenSold == Utils.ethAddress()) {
                    tokenSold = WETH;
                    currentPair = UniswapV2Lib.pairFor(factory, tokenSold, tokenBought, initCode);
                    IWETH(WETH).deposit{value: fromAmount}();
                    assert(IWETH(WETH).transfer(currentPair, fromAmount));
                }
                else {
                    currentPair = UniswapV2Lib.pairFor(factory, tokenSold, tokenBought, initCode);
                    TransferHelper.safeTransfer(
                        tokenSold, currentPair, fromAmount
                    );
                }
            }

            tokensBought = UniswapV2Lib.getAmountOutByPair(tokensBought, currentPair, tokenSold, tokenBought, fee, feeFactor);

            if ((i + 1) == pairs) {
                receiver = address(this);
            }
            else {
                receiver = UniswapV2Lib.pairFor(factory, tokenBought, path[i+2] == Utils.ethAddress() ? WETH : path[i+2], initCode);
            }

            (address token0,) = UniswapV2Lib.sortTokens(tokenSold, tokenBought);
            (uint256 amount0Out, uint256 amount1Out) = tokenSold == token0 ? (uint256(0), tokensBought) : (tokensBought, uint256(0));
            IUniswapV2Pair(currentPair).swap(
                amount0Out, amount1Out, receiver, new bytes(0)
            );

        }

        if (tokensBoughtEth) {
            IWETH(WETH).withdraw(tokensBought);
        }
    }
}

// File: original_contracts/lib/curve/ICurve.sol

pragma solidity 0.7.5;


interface IPool {
  function underlying_coins(int128 index) external view returns (address);

  function coins(int128 index) external view returns (address);
}

interface IPoolV3 {
    function underlying_coins(uint256 index) external view returns(address);

    function coins(uint256 index) external view returns(address);
}

interface ICurvePool {
  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 minDy) external;

  function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;

}

interface ICurveEthPool {

  function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external payable;
}

interface ICompoundPool {
  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 minDy, uint256 deadline) external;

  function exchange(int128 i, int128 j, uint256 dx, uint256 minDy, uint256 deadline) external;
}

// File: original_contracts/lib/curve/Curve.sol

pragma solidity 0.7.5;




contract Curve {

  struct CurveData {
    int128 i;
    int128 j;
    uint256 deadline;
    bool underlyingSwap;
  }

  function swapOnCurve(
    IERC20 fromToken,
    IERC20 toToken,
    uint256 fromAmount,
    address exchange,
    bytes calldata payload
  )
    internal

  {

    CurveData memory curveData = abi.decode(payload, (CurveData));

    Utils.approve(address(exchange), address(fromToken), fromAmount);

    if (curveData.underlyingSwap) {
      ICurvePool(exchange).exchange_underlying(curveData.i, curveData.j, fromAmount, 1);

    }
    else {
      if (address(fromToken) == Utils.ethAddress()) {
        ICurveEthPool(exchange).exchange{value: fromAmount}(curveData.i, curveData.j, fromAmount, 1);
      }
      else {
        ICurvePool(exchange).exchange(curveData.i, curveData.j, fromAmount, 1);
      }

    }
  }
}

// File: original_contracts/lib/weth/WethExchange.sol

pragma solidity 0.7.5;






abstract contract WethExchange is WethProvider {

    function swapOnWETH(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    )
        internal

    {

        _swapOnWeth(
            fromToken,
            toToken,
            fromAmount
        );
    }

    function buyOnWeth(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    )
        internal

    {

        _swapOnWeth(
            fromToken,
            toToken,
            fromAmount
        );
    }

    function _swapOnWeth(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    )
        private
    {
        address weth = WETH;

        if (address(fromToken) == weth){
            require(address(toToken) == Utils.ethAddress(), "Destination token should be ETH");
            IWETH(weth).withdraw(fromAmount);
        }
        else if (address(fromToken) == Utils.ethAddress()) {
            require(address(toToken) == weth, "Destination token should be weth");
            IWETH(weth).deposit{value: fromAmount}();
        }
        else {
            revert("Invalid fromToken");
        }

    }

}

// File: original_contracts/lib/curve/ICurveV2.sol

pragma solidity 0.7.5;

interface ICurveV2Pool {
    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 minDy) external;
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 minDy) external;
}

// File: original_contracts/lib/curve/CurveV2.sol

pragma solidity 0.7.5;






abstract contract CurveV2 is WethProvider {

    struct CurveV2Data {
        uint256 i;
        uint256 j;
        bool underlyingSwap;
    }

    constructor () {}

    function swapOnCurveV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    )
    internal

    {

        CurveV2Data memory curveV2Data = abi.decode(payload, (CurveV2Data));

        address _fromToken = address(fromToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{value: fromAmount}();
            _fromToken = WETH;
        }

        Utils.approve(address(exchange), address(_fromToken), fromAmount);
        if (curveV2Data.underlyingSwap) {
            ICurveV2Pool(exchange).exchange_underlying(curveV2Data.i, curveV2Data.j, fromAmount, 1);
        }
        else {
            ICurveV2Pool(exchange).exchange(curveV2Data.i, curveV2Data.j, fromAmount, 1);
        }

        if (address(toToken) == Utils.ethAddress()) {
            uint256 receivedAmount = Utils.tokenBalance(WETH, address(this));
            IWETH(WETH).withdraw(receivedAmount);
        }
    }
}

// File: original_contracts/lib/curveFork/ICurveV1Fork.sol

pragma solidity 0.7.5;

interface ICurveV1Fork {
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    )
    external;
}

// File: original_contracts/lib/curveFork/CurveV1ForkAdapter.sol

pragma solidity 0.7.5;




contract CurveV1ForkAdapter {
    struct CurveV1ForkData {
        uint8 i;
        uint8 j;
        uint256 deadline;
    }

    function swapOnCurveV1Fork(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    )
    internal

    {

        CurveV1ForkData memory curveV1ForkData = abi.decode(payload, (CurveV1ForkData));

        Utils.approve(address(exchange), address(fromToken), fromAmount);

        ICurveV1Fork(exchange).swap(curveV1ForkData.i, curveV1ForkData.j, fromAmount, 1, curveV1ForkData.deadline);

    }
}

// File: original_contracts/lib/dodo/IDODO.sol

pragma solidity 0.7.5;

interface IDODO {
  function dodoSwapV1(
    address fromToken,
    address toToken,
    uint256 fromTokenAmount,
    uint256 minReturnAmount,
    address[] memory dodoPairs,
    uint256 directions,
    bool isIncentive,
    uint256 deadLine
    ) external payable returns (uint256 returnAmount);
}

// File: original_contracts/lib/dodo/DODO.sol

pragma solidity 0.7.5;




contract DODO {

  struct DODOData {
    address[] dodoPairs;
    uint256 directions;
  }

  address public immutable erc20ApproveProxy;
  uint256 public immutable dodoSwapLimitOverhead;

  constructor(address _erc20ApproveProxy, uint256 _swapLimitOverhead) public {
    dodoSwapLimitOverhead = _swapLimitOverhead;
    erc20ApproveProxy = _erc20ApproveProxy;
  }

  function swapOnDodo(
    IERC20 fromToken,
    IERC20 toToken,
    uint256 fromAmount,
    address exchange,
    bytes calldata payload
  )
    internal
  {
    DODOData memory dodoData = abi.decode(payload, (DODOData));

    Utils.approve(erc20ApproveProxy, address(fromToken), fromAmount);

    IDODO(exchange).dodoSwapV1{
      value: address(fromToken) == Utils.ethAddress() ? fromAmount : 0
    }(
      address(fromToken),
      address(toToken),
      fromAmount,
      1,
      dodoData.dodoPairs,
      dodoData.directions,
      false,
      block.timestamp + dodoSwapLimitOverhead
    );
  }
}

// File: original_contracts/lib/dodov2/IDODOV2Proxy.sol

pragma solidity 0.7.5;

interface IDODOV2Proxy {
    function dodoSwapV2ETHToToken(
        address toToken,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external payable returns (uint256 returnAmount);

    function dodoSwapV2TokenToETH(
        address fromToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);

    function dodoSwapV2TokenToToken(
        address fromToken,
        address toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        address[] memory dodoPairs,
        uint256 directions,
        bool isIncentive,
        uint256 deadLine
    ) external returns (uint256 returnAmount);
}

// File: original_contracts/lib/dodov2/DODOV2.sol

pragma solidity 0.7.5;




contract DODOV2 {

  uint256 public immutable dodoV2SwapLimitOverhead;
  address public immutable dodoErc20ApproveProxy;

  struct DODOV2Data {
    address[] dodoPairs;
    uint256 directions;
  }

  constructor(uint256 _dodoV2SwapLimitOverhead, address _dodoErc20ApproveProxy) public {
    dodoV2SwapLimitOverhead = _dodoV2SwapLimitOverhead;
    dodoErc20ApproveProxy = _dodoErc20ApproveProxy;
  }

  function swapOnDodoV2(
    IERC20 fromToken,
    IERC20 toToken,
    uint256 fromAmount,
    address exchange,
    bytes calldata payload
  )
    internal
  {
    DODOV2Data memory dodoData = abi.decode(payload, (DODOV2Data));

    if (address(fromToken) == Utils.ethAddress()) {
      IDODOV2Proxy(exchange).dodoSwapV2ETHToToken{value: fromAmount}(
        address(toToken),
        1,
        dodoData.dodoPairs,
        dodoData.directions,
        false,
        block.timestamp + dodoV2SwapLimitOverhead
      );
    } else if (address(toToken) == Utils.ethAddress()) {
      Utils.approve(dodoErc20ApproveProxy, address(fromToken), fromAmount);

      IDODOV2Proxy(exchange).dodoSwapV2TokenToETH(
        address(fromToken),
        fromAmount,
        1,
        dodoData.dodoPairs,
        dodoData.directions,
        false,
        block.timestamp + dodoV2SwapLimitOverhead
      );
    } else {
      Utils.approve(dodoErc20ApproveProxy, address(fromToken), fromAmount);

      IDODOV2Proxy(exchange).dodoSwapV2TokenToToken(
        address(fromToken),
        address(toToken),
        fromAmount,
        1,
        dodoData.dodoPairs,
        dodoData.directions,
        false,
        block.timestamp + dodoV2SwapLimitOverhead
      );
    }
  }
}

// File: original_contracts/lib/zeroxv4/LibOrderV4.sol

/* solium-disable */

pragma solidity 0.7.5;



library LibOrderV4 {
    struct Order {
        IERC20 makerToken;
        IERC20 takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP712,
        ETHSIGN
    }

    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }
}

// File: original_contracts/lib/zeroxv4/ZeroxV4.sol

pragma solidity 0.7.5;






interface IZeroxV4 {

    function fillRfqOrder(
        // The order
        LibOrderV4.Order calldata order,
        // The signature
        LibOrderV4.Signature calldata signature,
        // How much taker token to fill the order with
        uint128 takerTokenFillAmount
    )
        external
        payable
        // How much maker token from the order the taker received.
        returns (uint128, uint128);
}

abstract contract ZeroxV4 is WethProvider {

    struct ZeroxV4Data {
        LibOrderV4.Order order;
        LibOrderV4.Signature signature;
    }

    function swapOnZeroXv4(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    )
        internal
    {
        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{value: fromAmount}();
        }

        _swapOn0xV4(
            fromToken,
            toToken,
            fromAmount,
            exchange,
            payload
        );
    }

    function buyOnZeroXv4(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    )
        internal
    {
        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{value: fromAmount}();
        }

        _swapOn0xV4(
            fromToken,
            toToken,
            fromAmount,
            exchange,
            payload
        );

        if (address(fromToken) == Utils.ethAddress()) {
            uint256 remainingAmount = Utils.tokenBalance(WETH, address(this));
            if (remainingAmount > 0) {
              IWETH(WETH).withdraw(remainingAmount);
            }
        }
    }

    function _swapOn0xV4(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes memory payload) private {

        ZeroxV4Data memory data = abi.decode(payload, (ZeroxV4Data));

        address _fromToken = address(fromToken);
        address _toToken = address(toToken);
        require(_fromToken != _toToken, "fromToken should be different from toToken");

        if (address(fromToken) == Utils.ethAddress()) {
            _fromToken = WETH;
        }
        else if (address(toToken) == Utils.ethAddress()) {
            _toToken = WETH;
        }

        require(address(data.order.takerToken) == address(_fromToken), "Invalid from token!!");
        require(address(data.order.makerToken) == address(_toToken), "Invalid to token!!");

        Utils.approve(exchange, address(_fromToken), fromAmount);

        IZeroxV4(exchange).fillRfqOrder(
            data.order,
            data.signature,
            uint128(fromAmount)
        );

        if (address(toToken) == Utils.ethAddress()) {
            uint256 receivedAmount = Utils.tokenBalance(WETH, address(this));
            IWETH(WETH).withdraw(receivedAmount);
        }
    }
}

// File: original_contracts/lib/smoothy/ISmoothyV1.sol

pragma solidity 0.7.5;

interface ISmoothyV1 {

  function swap(
    uint256 bTokenIdxIn,
    uint256 bTokenIdxOut,
    uint256 bTokenInAmount,
    uint256 bTokenOutMin
  )
  external;

}

// File: original_contracts/lib/smoothy/SmoothyV1.sol

pragma solidity 0.7.5;





contract SmoothyV1 {

  struct SmoothyV1Data {
    uint256 i;
    uint256 j;
  }

  function swapOnSmoothyV1(
    IERC20 fromToken,
    IERC20 toToken,
    uint256 fromAmount,
    address exchange,
    bytes calldata payload
  )
    internal
  {

    SmoothyV1Data memory data = abi.decode(payload, (SmoothyV1Data));

    Utils.approve(exchange, address(fromToken), fromAmount);

    ISmoothyV1(exchange).swap(data.i, data.j, fromAmount, 1);

  }
}

// File: original_contracts/lib/oneinchlp/IOneInchPool.sol

pragma solidity 0.7.5;


interface IOneInchPool {
    function swap(
        IERC20 src,
        IERC20 dst,
        uint256 amount,
        uint256 minReturn,
        address referral
    ) external payable returns(uint256 result);
}

// File: original_contracts/lib/oneinchlp/OneInchPool.sol

pragma solidity 0.7.5;




contract OneInchPool {

    function swapOnOneInch(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange
    )
        internal
    {

        address _fromToken = address(fromToken) == Utils.ethAddress()
        ? address(0) : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress()
        ? address(0) : address(toToken);

        if (address(fromToken) != Utils.ethAddress()) {
            Utils.approve(address(exchange), _fromToken, fromAmount);
        }

        IOneInchPool(exchange).swap{
            value: address(fromToken) == Utils.ethAddress() ? fromAmount : 0
        }(
            IERC20(_fromToken),
            IERC20(_toToken),
            fromAmount,
            1,
            address(0)
        );
    }

}

// File: original_contracts/lib/zeroxv2/LibOrderV2.sol

/* solium-disable */

pragma solidity 0.7.5;

//Taken from 0x exchange
library LibOrderV2{


    struct Order {
        address makerAddress;           // Address that created the order.
        address takerAddress;           // Address that is allowed to fill the order. If set to 0, any address is allowed to fill the order.
        address feeRecipientAddress;    // Address that will recieve fees when order is filled.
        address senderAddress;          // Address that is allowed to call Exchange contract methods that affect this order. If set to 0, any address is allowed to call these methods.
        uint256 makerAssetAmount;       // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 takerAssetAmount;       // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 makerFee;               // Amount of ZRX paid to feeRecipient by maker when order is filled. If set to 0, no transfer of ZRX from maker to feeRecipient will be attempted.
        uint256 takerFee;               // Amount of ZRX paid to feeRecipient by taker when order is filled. If set to 0, no transfer of ZRX from taker to feeRecipient will be attempted.
        uint256 expirationTimeSeconds;  // Timestamp in seconds at which order expires.
        uint256 salt;                   // Arbitrary number to facilitate uniqueness of the order's hash.
        bytes makerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset. The last byte references the id of this proxy.
        bytes takerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset. The last byte references the id of this proxy.
    }

    struct FillResults {
        uint256 makerAssetFilledAmount;  // Total amount of makerAsset(s) filled.
        uint256 takerAssetFilledAmount;  // Total amount of takerAsset(s) filled.
        uint256 makerFeePaid;            // Total amount of ZRX paid by maker(s) to feeRecipient(s).
        uint256 takerFeePaid;            // Total amount of ZRX paid by taker to feeRecipients(s).
    }
}

// File: original_contracts/lib/libraries/LibBytesRichErrors.sol

/*
  Copyright 2019 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity 0.7.5;


library LibBytesRichErrors {

    enum InvalidByteOperationErrorCodes {
        FromLessThanOrEqualsToRequired,
        ToLessThanOrEqualsLengthRequired,
        LengthGreaterThanZeroRequired,
        LengthGreaterThanOrEqualsFourRequired,
        LengthGreaterThanOrEqualsTwentyRequired,
        LengthGreaterThanOrEqualsThirtyTwoRequired,
        LengthGreaterThanOrEqualsNestedBytesLengthRequired,
        DestinationLengthGreaterThanOrEqualSourceLengthRequired
    }

    // bytes4(keccak256("InvalidByteOperationError(uint8,uint256,uint256)"))
    bytes4 internal constant INVALID_BYTE_OPERATION_ERROR_SELECTOR =
        0x28006595;

    // solhint-disable func-name-mixedcase
    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_BYTE_OPERATION_ERROR_SELECTOR,
            errorCode,
            offset,
            required
        );
    }
}

// File: original_contracts/lib/libraries/LibRichErrors.sol

/*
  Copyright 2019 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity 0.7.5;


library LibRichErrors {

    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(
        string memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

// File: original_contracts/lib/libraries/LibBytes.sol

/*
  Copyright 2019 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity 0.7.5;




library LibBytes {

    using LibBytes for bytes;

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        if (b.length < index + 20) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20 // 20 is length of address
            ));
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

}

// File: original_contracts/lib/zeroxv2/ZeroxV2.sol

pragma solidity 0.7.5;








interface IZeroxV2 {

    function marketSellOrdersNoThrow(
        LibOrderV2.Order[] calldata orders,
        uint256 takerAssetFillAmount,
        bytes[] calldata signatures
    )
        external
        returns(LibOrderV2.FillResults memory);
}

abstract contract ZeroxV2 is WethProvider {
    using LibBytes for bytes;

    struct ZeroxV2Data {
        LibOrderV2.Order[] orders;
        bytes[] signatures;
    }

    address public immutable erc20Proxy;

    constructor(address _erc20Proxy) {
        erc20Proxy = _erc20Proxy;
    }

    function swapOnZeroXv2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    )
        internal

    {
        address _fromToken = address(fromToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{value: fromAmount}();
        }

        _swapOn0xV2(
            fromToken,
            toToken,
            fromAmount,
            exchange,
            payload
        );

    }

    function buyOnZeroXv2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    )
        internal

    {

        address _fromToken = address(fromToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{value: fromAmount}();
            _fromToken = WETH;
        }

        _swapOn0xV2(
            fromToken,
            toToken,
            fromAmount,
            exchange,
            payload
        );

        if (address(fromToken) == Utils.ethAddress()) {
            uint256 remainingAmount = Utils.tokenBalance(address(_fromToken), address(this));
            if (remainingAmount > 0) {
              IWETH(WETH).withdraw(remainingAmount);
            }
        }
    }

    function _swapOn0xV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes memory payload
    )
        private
    {

        address _fromToken = address(fromToken);
        address _toToken = address(toToken);
        require(_fromToken != _toToken, "fromToken should be different from toToken");

        if (_fromToken == Utils.ethAddress()) {
            _fromToken = WETH;
        }

        else if (_toToken == Utils.ethAddress()) {
            _toToken = WETH;
        }

        ZeroxV2Data memory data = abi.decode(payload, (ZeroxV2Data));

        for (uint256 i = 0; i < data.orders.length; i++) {
            address srcToken = data.orders[i].takerAssetData.readAddress(16);
            require(srcToken == address(_fromToken), "Invalid from token!!");

            address destToken = data.orders[i].makerAssetData.readAddress(16);
            require(destToken == address(_toToken), "Invalid to token!!");
        }

        Utils.approve(erc20Proxy, address(_fromToken), fromAmount);

        IZeroxV2(exchange).marketSellOrdersNoThrow(
            data.orders,
            fromAmount,
            data.signatures
        );

        if (address(toToken) == Utils.ethAddress()) {
            uint256 receivedAmount = Utils.tokenBalance(WETH, address(this));
            IWETH(WETH).withdraw(receivedAmount);
        }
    }
}

// File: original_contracts/adapters/bsc/BscAdapter01.sol

pragma solidity 0.7.5;













/**
* @dev This contract will route call to:
* 0- UniswapV2 (PancakeSwap)
* 1- WETH
* 2- Curve
* 3- UniswapV2Forks
* 4- CurveV1Fork
* 5- DODOV2
* 6- DODO
* 7- ZeroxV4
* 8- SmoothyV1
* 9- OneInchLP
* 10- ZeroxV2
* The above are the indexes
*/
contract BscAdapter01 is IAdapter, UniswapV2, Curve, WethExchange, CurveV1ForkAdapter, DODOV2, DODO, ZeroxV4, ZeroxV2, SmoothyV1, OneInchPool {
    using SafeMath for uint256;

    constructor(
        address _factory,
        bytes32 _initCode,
        uint256 _fee,
        uint256 _feeFactor,
        uint256 _dodoV2SwapLimitOverhead,
        address _dodoV2Erc20ApproveProxy,
        uint256 _dodoSwapLimitOverhead,
        address _dodoErc20ApproveProxy,
        address _zeroXv2erc20Proxy,
        address _weth
    )
    WethProvider(_weth)
    UniswapV2(_factory, _initCode, _fee, _feeFactor)
    DODOV2(_dodoV2SwapLimitOverhead, _dodoV2Erc20ApproveProxy)
    DODO(_dodoErc20ApproveProxy, _dodoSwapLimitOverhead)
    ZeroxV2(_zeroXv2erc20Proxy)
    public
    {
    }

    function initialize(bytes calldata data) override external {
        revert("METHOD NOT IMPLEMENTED");
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 networkFee,
        Utils.Route[] calldata route
    )
    external
    override
    payable
    {
        for (uint256 i = 0; i < route.length; i++) {
            if (route[i].index == 0) {
                //swap on PancakeSwap
                swapOnUniswap(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].payload
                );
            }
            else if (route[i].index == 1) {
                //swap on WETH
                swapOnWETH(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000)
                );
            }
            else if (route[i].index == 2) {
                //swap on curve
                swapOnCurve(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 3) {
                //swap on uniswapV2Fork
                swapOnUniswapFork(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].payload
                );
            }
            else if (route[i].index == 4) {
                //swap on CurveV1Fork
                swapOnCurveV1Fork(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 5) {
                //swap on DODOV2
                swapOnDodoV2(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 6) {
                //swap on DODO
                swapOnDodo(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 7) {
                //swap on ZeroxV4
                swapOnZeroXv4(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 8) {
                //swap on SmoothyV1
                swapOnSmoothyV1(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else if (route[i].index == 9) {
                //swap on OneInchLP
                swapOnOneInch(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange
                );
            }
            else if (route[i].index == 10) {
                //swap on ZeroxV2
                swapOnZeroXv2(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            }
            else {
                revert("Index not supported");
            }
        }
    }
}

